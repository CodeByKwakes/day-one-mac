-- Combine this shared source with exactly one folder-app entry source.
use framework "Foundation"
use framework "AppKit"
use scripting additions

on cleanText(value)
	if value is "" then error "An empty value is not allowed."
	repeat with codePoint from 0 to 31
		if value contains (character id codePoint) then error "Control characters are not supported."
	end repeat
	if value contains (character id 127) then error "Control characters are not supported."
	return value
end cleanText

on validatedFolder(folderPath)
	set folderPath to my cleanText(folderPath)
	if folderPath does not start with "/" or folderPath is "/" then error "Choose an existing project folder, not the filesystem root."
	set folderAlias to (POSIX file folderPath) as alias
	set details to info for folderAlias
	if not folder of details or package folder of details then error "Choose an ordinary folder, not a file or application bundle."
	set folderPath to POSIX path of folderAlias
	if folderPath ends with "/" then set folderPath to text 1 thru -2 of folderPath
	return folderPath
end validatedFolder

on folderFromItems(itemsToOpen)
	if (count itemsToOpen) is not 1 then error "Select or drop exactly one project folder."
	return my validatedFolder(POSIX path of ((item 1 of itemsToOpen) as alias))
end folderFromItems

on chooseProject(itemsToOpen)
	if (count itemsToOpen) > 0 then return my folderFromItems(itemsToOpen)
	-- Finder permission is optional: a denied request falls back to the picker.
	set finderItems to {}
	try
		tell application "Finder" to set finderItems to selection as alias list
	end try
	set finderItems to my excludeOwnLauncher(finderItems, POSIX path of (path to me))
	if (count finderItems) > 0 then return my folderFromItems(finderItems)
	return my validatedFolder(POSIX path of (choose folder with prompt "Choose the project folder:"))
end chooseProject

on excludeOwnLauncher(itemsToOpen, launcherPath)
	if (count itemsToOpen) is 1 then
		if (POSIX path of ((item 1 of itemsToOpen) as alias)) is launcherPath then return {}
	end if
	return itemsToOpen
end excludeOwnLauncher

on requiredApplication(bundleID)
	set appURL to current application's NSWorkspace's sharedWorkspace()'s URLForApplicationWithBundleIdentifier:bundleID
	if appURL is missing value then error "Required application is unavailable: " & bundleID & ". Install or locate it manually, then retry."
	return (appURL's |path|()) as text
end requiredApplication

on warpURL(folderPath)
	set allowed to current application's NSCharacterSet's characterSetWithCharactersInString:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
	set encoded to (current application's NSString's stringWithString:folderPath)'s stringByAddingPercentEncodingWithAllowedCharacters:allowed
	return "warp://action/new_tab?path=" & (encoded as text)
end warpURL

on profileNames(jsonText)
	set dataValue to (current application's NSString's stringWithString:jsonText)'s dataUsingEncoding:(current application's NSUTF8StringEncoding)
	set state to current application's NSJSONSerialization's JSONObjectWithData:dataValue options:0 |error|:(missing value)
	if state is missing value then error "Cannot read VS Code profile metadata. Use VS Code's Profiles menu."
	if not ((state's isKindOfClass:(current application's NSDictionary)) as boolean) then error "Unsupported VS Code profile metadata. Use the Profiles menu."
	set entries to state's objectForKey:"userDataProfiles"
	if entries is missing value then error "Profile metadata is unavailable. Open VS Code and use its Profiles menu first."
	if not ((entries's isKindOfClass:(current application's NSArray)) as boolean) then error "Unsupported VS Code profile list. Use the Profiles menu."
	-- The built-in default name is localized and is not registered in this list.
	set names to {}
	repeat with entry in entries
		if not ((entry's isKindOfClass:(current application's NSDictionary)) as boolean) then error "Unsupported profile entry."
		set profileLocation to entry's objectForKey:"location"
		if profileLocation is missing value then error "Profile location is missing. Use VS Code's Profiles menu."
		if not ((profileLocation's isKindOfClass:(current application's NSString)) as boolean) then error "Unsupported profile location. Use VS Code's Profiles menu."
		my cleanText(profileLocation as text)
		set profileName to entry's objectForKey:"name"
		if profileName is missing value then error "Profile name is missing."
		if not ((profileName's isKindOfClass:(current application's NSString)) as boolean) then error "Invalid profile name."
		set profileName to my cleanText(profileName as text)
		if names contains profileName then error "Ambiguous profile names. Use VS Code's Profiles menu."
		set end of names to profileName
	end repeat
	return names
end profileNames

on profileState()
	set metadataPath to (current application's NSHomeDirectory() as text) & "/Library/Application Support/Code/User/globalStorage/storage.json"
	return my readProfileState(metadataPath)
end profileState

on readProfileState(metadataPath)
	-- Foundation avoids implicit Standard Additions targets in loaded app scripts.
	set metadataText to current application's NSString's stringWithContentsOfFile:metadataPath encoding:(current application's NSUTF8StringEncoding) |error|:(missing value)
	if metadataText is missing value then error "Cannot read VS Code profile metadata. Use VS Code's Profiles menu."
	return metadataText as text
end readProfileState

on verifiedProfile(profileName, jsonText)
	set names to my profileNames(jsonText)
	considering case
		if names does not contain profileName then error "That profile is no longer available. Choose an existing profile in VS Code."
	end considering
	return profileName
end verifiedProfile

on codeCommand(codePath, folderPath, profileName)
	return quoted form of codePath & " --new-window --profile " & quoted form of profileName & " " & quoted form of folderPath
end codeCommand

on launchFolderApp(modeName, suppliedItems)
	try
		set folderPath to my chooseProject(suppliedItems)
		if modeName is "code" or modeName is "profile" or modeName is "workspace" then set codeApp to my requiredApplication("com.microsoft.VSCode")
		if modeName is "warp" or modeName is "workspace" then set warpApp to my requiredApplication("dev.warp.Warp-Stable")
		if modeName is "profile" then
			set codePath to codeApp & "/Contents/Resources/app/bin/code"
			do shell script "/bin/test -x " & quoted form of codePath
			set availableNames to my profileNames(my profileState())
			if (count availableNames) is 0 then error "No registered named profiles. Use VS Code's Profiles menu to select the built-in default."
			set chosen to choose from list availableNames with title "Open with VS Code Profile" with prompt "Choose an existing named profile. Select the built-in default in VS Code's Profiles menu."
			if chosen is false then return
			set profileName to my verifiedProfile(item 1 of chosen, my profileState())
			do shell script my codeCommand(codePath, folderPath, profileName)
		else
			if modeName is "code" or modeName is "workspace" then do shell script "/usr/bin/open -a " & quoted form of codeApp & " " & quoted form of folderPath
			if modeName is "warp" or modeName is "workspace" then do shell script "/usr/bin/open -a " & quoted form of warpApp & " " & quoted form of (my warpURL(folderPath))
		end if
	on error messageText number messageNumber
		if messageNumber is -128 then return
		display dialog messageText & return & return & "No project files were changed by this launcher. If one app already opened, keep that window and open the other manually." with title "Developer shortcut: needs attention" buttons {"OK"} default button "OK"
	end try
end launchFolderApp
