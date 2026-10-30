-- Paste the complete source into Automator's Run AppleScript action.
-- Finder supplies the selected folders; installation alone never moves them.
use framework "Foundation"
use framework "AppKit"
use scripting additions

on fileManager()
	return current application's NSFileManager's defaultManager()
end fileManager

on existsAt(p)
	return (my fileManager()'s fileExistsAtPath:p) as boolean
end existsAt

on cleanName(s)
	if s is "" or s is "." or s is ".." or s starts with "." then error "Choose a visible category name."
	if s contains "/" or s contains ":" then error "A category name cannot contain / or :."
	repeat with n from 0 to 31
		if s contains (character id n) then error "Control characters are not supported in folder names."
	end repeat
	if s contains (character id 127) then error "Control characters are not supported in folder names."
	return s
end cleanName

on ordinaryFolder(p)
	set original to (current application's NSString's stringWithString:p)'s stringByStandardizingPath() as text
	set resolved to (current application's NSString's stringWithString:original)'s stringByResolvingSymlinksInPath() as text
	if original is not resolved then error "Symbolic links are not supported: " & p
	if not my existsAt(resolved) then error "Folder is missing: " & p
	set attrs to my fileManager()'s attributesOfItemAtPath:resolved |error|:(missing value)
	if attrs is missing value then error "Cannot inspect folder: " & p
	if (attrs's objectForKey:(current application's NSFileType)) as text is not (current application's NSFileTypeDirectory as text) then error "Select ordinary folders only: " & p
	if (current application's NSWorkspace's sharedWorkspace()'s isFilePackageAtPath:resolved) as boolean then error "Application and package bundles cannot be archived with this action."
	return resolved
end ordinaryFolder

on withinPath(p, rootPath)
	return p is rootPath or p starts with (rootPath & "/")
end withinPath

on folderIdentity(p)
	set p to my ordinaryFolder(p)
	set attrs to my fileManager()'s attributesOfItemAtPath:p |error|:(missing value)
	if attrs is missing value then error "Cannot inspect folder identity: " & p
	return ((attrs's objectForKey:(current application's NSFileSystemNumber)) as text) & ":" & ((attrs's objectForKey:(current application's NSFileSystemFileNumber)) as text)
end folderIdentity

on verifyFolderIdentity(p, expectedIdentity)
	if my folderIdentity(p) is not expectedIdentity then error "A selected folder changed since the preview. Review the selection again: " & p
end verifyFolderIdentity

on planMoves(sourcePaths, rootPath, category, dateLabel)
	set rootPath to my ordinaryFolder(rootPath)
	set category to my cleanName(category)
	if (count sourcePaths) is 0 then error "Select one or more project folders in Finder."
	if (count characters of dateLabel) is not 10 then error "Invalid date label."
	repeat with n from 1 to 10
		set dateCharacter to character n of dateLabel
		if n is 5 or n is 8 then
			if dateCharacter is not "-" then error "Invalid date label."
		else
			if "0123456789" does not contain dateCharacter then error "Invalid date label."
		end if
	end repeat
	set categoryPath to rootPath & "/" & category
	if my existsAt(categoryPath) then my ordinaryFolder(categoryPath)
	set datePath to categoryPath & "/" & dateLabel
	if my existsAt(datePath) then my ordinaryFolder(datePath)
	set sources to {}
	set targets to {}
	set names to {}
	repeat with sourceValue in sourcePaths
		set sourcePath to my ordinaryFolder(sourceValue as text)
		if sourcePath is "/" or sourcePath is (current application's NSHomeDirectory() as text) then error "Select individual project folders, not a system or home folder."
		if my withinPath(sourcePath, rootPath) or my withinPath(rootPath, sourcePath) then error "The Archive root, its contents, and its parent folders cannot be selected as projects."
		set gitPath to sourcePath & "/.git"
		if my existsAt(gitPath) then
			set attrs to my fileManager()'s attributesOfItemAtPath:gitPath |error|:(missing value)
			if attrs is missing value then error "Cannot inspect Git metadata."
			if (attrs's objectForKey:(current application's NSFileType)) as text is not (current application's NSFileTypeDirectory as text) then error "A linked Git worktree or submodule needs its own move procedure: " & sourcePath
			if my existsAt(gitPath & "/worktrees") then error "This repository has worktree metadata. Move or remove its registered worktrees before archiving it: " & sourcePath
		end if
		set leafName to (current application's NSString's stringWithString:sourcePath)'s lastPathComponent() as text
		my cleanName(leafName)
		set foldedName to (current application's NSString's stringWithString:leafName)'s lowercaseString() as text
		if names contains foldedName then error "Two selected projects have the same folder name: " & leafName
		repeat with otherPath in sources
			if my withinPath(sourcePath, otherPath as text) or my withinPath(otherPath as text, sourcePath) then error "Select a project or its parent, not both."
		end repeat
		set targetPath to datePath & "/" & leafName
		if my existsAt(targetPath) then error "Nothing moved. The destination already exists: " & targetPath
		set end of sources to sourcePath
		set end of targets to targetPath
		set end of names to foldedName
	end repeat
	return {sources, targets, datePath}
end planMoves

on saveRecord(recordPath, sources, targets, completed)
	if not my existsAt(recordPath) then
		set privateAttributes to current application's NSDictionary's dictionaryWithObject:384 forKey:(current application's NSFilePosixPermissions)
		if not ((my fileManager()'s createFileAtPath:recordPath |contents|:(current application's NSData's |data|()) attributes:privateAttributes) as boolean) then error "Cannot reserve a private recovery record."
	end if
	set recordObject to current application's NSMutableDictionary's dictionary()
	recordObject's setObject:1 forKey:"schema"
	recordObject's setObject:sources forKey:"originalFolders"
	recordObject's setObject:targets forKey:"archiveFolders"
	recordObject's setObject:completed forKey:"completedMoves"
	set dataValue to current application's NSJSONSerialization's dataWithJSONObject:recordObject options:1 |error|:(missing value)
	if dataValue is missing value then error "Cannot prepare the recovery record."
	if not ((dataValue's writeToFile:recordPath options:1 |error|:(missing value)) as boolean) then error "Cannot save the recovery record."
	my fileManager()'s setAttributes:{NSFilePosixPermissions:384} ofItemAtPath:recordPath |error|:(missing value)
end saveRecord

on executeMoves(sourcePaths, rootPath, category, dateLabel)
	-- Rebuild the plan after confirmation to catch destination/source changes.
	set {sources, targets, datePath} to my planMoves(sourcePaths, rootPath, category, dateLabel)
	set identities to {}
	repeat with sourcePath in sources
		set end of identities to my folderIdentity(sourcePath as text)
	end repeat
	set madeDirectory to my fileManager()'s createDirectoryAtPath:datePath withIntermediateDirectories:true attributes:(missing value) |error|:(missing value)
	if not (madeDirectory as boolean) then error "Cannot create the archive destination."
	set recordID to current application's NSUUID's UUID()'s UUIDString() as text
	set recordPath to datePath & "/.archive-move-" & recordID & ".json"
	set completed to {}
	my saveRecord(recordPath, sources, targets, completed)
	try
		repeat with i from 1 to count sources
			my verifyFolderIdentity(item i of sources, item i of identities)
			my ordinaryFolder(datePath)
			if my existsAt(item i of targets) then error "A destination appeared after confirmation; stopped without overwriting it."
			set moved to my fileManager()'s moveItemAtPath:(item i of sources) toPath:(item i of targets) |error|:(missing value)
			if not (moved as boolean) then error "Cannot move: " & item i of sources
			set end of completed to item i of targets
			my saveRecord(recordPath, sources, targets, completed)
		end repeat
	on error messageText
		error messageText & return & return & "Completed moves: " & (count completed) & ". No automatic rollback was attempted. Inspect the source and destination folders before retrying." & return & "Recovery record: " & recordPath
	end try
	return {datePath, recordPath, completed}
end executeMoves

on selectionPaths(input)
	set sourcePaths to {}
	repeat with selectedItem in input
		-- Coercing a file to alias here would resolve symlinks before validation.
		set end of sourcePaths to POSIX path of selectedItem
	end repeat
	return sourcePaths
end selectionPaths

on run {input, parameters}
	try
		if (count input) is 0 then error "Select one or more project folders in Finder, then choose Quick Actions > Send to Archive."
		set sourcePaths to my selectionPaths(input)
		set rootPath to (current application's NSHomeDirectory() as text) & "/Developer/Archive"
		set rootPath to my ordinaryFolder(rootPath)
		set entries to my fileManager()'s contentsOfDirectoryAtPath:rootPath |error|:(missing value)
		if entries is missing value then error "Cannot list the Archive folder."
		set choices to {"+ New category…"}
		repeat with entry in (entries as list)
			set categoryName to entry as text
			if categoryName does not start with "." then
				try
					my ordinaryFolder(rootPath & "/" & categoryName)
					set end of choices to categoryName
				end try
			end if
		end repeat
		set chosen to choose from list choices with title "Send to Archive" with prompt "Choose a category inside ~/Developer/Archive:" OK button name "Choose" cancel button name "Cancel"
		if chosen is false then return input
		set category to item 1 of chosen
		if category is "+ New category…" then
			set category to text returned of (display dialog "New category name:" default answer "" with title "Send to Archive" buttons {"Cancel", "Continue"} default button "Continue")
		end if
		set dateLabel to do shell script "/bin/date '+%Y-%m-%d'"
		set {sources, targets, datePath} to my planMoves(sourcePaths, rootPath, category, dateLabel)
		set previewIdentities to {}
		repeat with sourcePath in sources
			set end of previewIdentities to my folderIdentity(sourcePath as text)
		end repeat
		set summary to "Move " & (count sources) & " project folder(s) to:" & return & datePath & return & return
		repeat with sourcePath in sources
			set summary to summary & "• " & (sourcePath as text) & return
		end repeat
		display dialog summary & return & "Close these projects in editors and stop their development servers before moving them. Folder contents will stay intact." with title "Send to Archive" buttons {"Cancel", "Move to Archive"} default button "Cancel"
		repeat with i from 1 to count sources
			my verifyFolderIdentity(item i of sources, item i of previewIdentities)
		end repeat
		set {datePath, recordPath, completed} to my executeMoves(sourcePaths, rootPath, category, dateLabel)
		set resultButton to button returned of (display dialog "Archived " & (count completed) & " project folder(s)." & return & datePath & return & return & "To undo, move each folder back to its original location. A hidden recovery record in this date folder lists the original paths." with title "Send to Archive" buttons {"Done", "Show in Finder"} default button "Show in Finder")
		if resultButton is "Show in Finder" then current application's NSWorkspace's sharedWorkspace()'s openURL:(current application's NSURL's fileURLWithPath:datePath)
		return input
	on error messageText number messageNumber
		if messageNumber is -128 then return input
		display dialog messageText with title "Send to Archive: needs attention" buttons {"OK"} default button "OK"
		return input
	end try
end run
