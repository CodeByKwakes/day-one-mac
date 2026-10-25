-- Paste this complete source into one Run AppleScript action in Shortcuts.
-- Local shortcut identifiers, application launchers and credentials are not needed.
on run argv
	try
		set repoURL to my validatedRepositoryURL(text returned of (display dialog "Repository clone URL (HTTPS or SSH). Do not include passwords or access tokens." default answer "" with title "Git Clone" buttons {"Cancel", "Next"} default button "Next"))
		set parentFolder to choose folder with prompt "Choose the parent folder for the new clone:" default location (path to home folder)
		set folderName to my validatedFolderName(text returned of (display dialog "Folder name: keep the suggested name or enter a new one." default answer (my suggestedFolderName(repoURL)) with title "Git Clone" buttons {"Cancel", "Next"} default button "Next"))
		set destination to (POSIX path of parentFolder) & folderName
		set collision to do shell script "if [ -e " & quoted form of destination & " ] || [ -L " & quoted form of destination & " ]; then printf yes; else printf no; fi"
		if collision is "yes" then error "That destination already exists. Choose another name; nothing has been overwritten."
		display dialog "Clone into:" & return & destination & return & return & "This downloads and checks out the repository. It does not install dependencies. Git uses your existing authentication and filter configuration. Clone hooks are disabled for this operation." with title "Git Clone" buttons {"Cancel", "Clone"} default button "Clone"
		set gitPath to "/usr/bin/git"
		if (do shell script "test -x /opt/homebrew/bin/git && printf yes || printf no") is "yes" then set gitPath to "/opt/homebrew/bin/git"
		with timeout of 3600 seconds
			do shell script my cloneCommand(repoURL, destination, gitPath)
		end timeout
		set nextAction to button returned of (display dialog "Clone complete:" & return & destination with title "Git Clone" buttons {"Done", "Show in Finder", "Open in VS Code"} default button "Show in Finder")
		if nextAction is "Show in Finder" then do shell script "/usr/bin/open -R " & quoted form of destination
		if nextAction is "Open in VS Code" then do shell script "/usr/bin/open -b com.microsoft.VSCode " & quoted form of destination
		return destination
	on error errorMessage number errorNumber
		if errorNumber is -128 then return
		display dialog errorMessage & return & return & "For private repositories, verify Git/SSH access first in Terminal. Interactive password and SSH prompts are disabled. A failed clone can leave a partial folder; inspect it before retrying. Nothing is removed automatically." with title "Git Clone: needs attention" buttons {"OK"} default button "OK"
	end try
end run

on rejectControlCharacters(value)
	repeat with codePoint from 0 to 31
		if value contains (character id codePoint) then error "Control characters are not allowed."
	end repeat
	if value contains (character id 127) then error "Control characters are not allowed."
end rejectControlCharacters

on splitText(value, separator)
	set savedDelimiters to AppleScript's text item delimiters
	try
		set AppleScript's text item delimiters to separator
		set parts to text items of value
		set AppleScript's text item delimiters to savedDelimiters
		return parts
	on error messageText number messageNumber
		set AppleScript's text item delimiters to savedDelimiters
		error messageText number messageNumber
	end try
end splitText

on validatedRepositoryURL(value)
	my rejectControlCharacters(value)
	if value is "" or value contains " " then error "Enter one repository URL without whitespace."
	if value contains "?" or value contains "#" then error "Query strings and fragments are not accepted. Use the repository's clone URL without tokens."
	if value starts with "https://" or value starts with "ssh://" then
		set schemeParts to my splitText(value, "://")
		if (count schemeParts) is not 2 then error "Enter one HTTPS or SSH clone URL."
		set locationParts to my splitText(item 2 of schemeParts, "/")
		if (count locationParts) < 2 then error "The clone URL must include a host and repository path."
		set authority to item 1 of locationParts
		if authority is "" or item 2 of schemeParts is authority & "/" then error "The clone URL must include a host and repository path."
		if authority contains "%" then error "Use an unescaped host and SSH username."
		if value starts with "https://" and authority contains "@" then error "HTTPS credentials must stay in your credential manager, not the clone URL."
		if value starts with "ssh://" and authority contains "@" then
			set userParts to my splitText(authority, "@")
			if (count userParts) is not 2 or item 1 of userParts is "" or item 2 of userParts is "" then error "Invalid SSH username or host."
			if item 1 of userParts contains ":" then error "Do not put an SSH password in the clone URL."
		end if
	else if value starts with "git@" then
		set locationParts to my splitText(value, ":")
		if (count locationParts) is not 2 then error "Use git@host:repository for this SSH form, or use an ssh:// URL."
		if item 1 of locationParts is "git@" or item 2 of locationParts is "" then error "The SSH clone URL needs a host and repository path."
		if (count (my splitText(item 1 of locationParts, "@"))) is not 2 then error "Invalid SSH host."
	else
		error "Use an HTTPS URL, ssh:// URL, or git@host:owner/repo.git address."
	end if
	return value
end validatedRepositoryURL

on validatedFolderName(value)
	my rejectControlCharacters(value)
	if value is "" or value is "." or value is ".." or value contains "/" or value contains ":" then error "Use one non-empty folder name without /, :, or control characters."
	return value
end validatedFolderName

on suggestedFolderName(repoURL)
	set value to my validatedRepositoryURL(repoURL)
	repeat while value ends with "/"
		set value to text 1 thru -2 of value
	end repeat
	if value starts with "git@" then set value to item 2 of (my splitText(value, ":"))
	set candidate to last item of (my splitText(value, "/"))
	if candidate ends with ".git" then
		if (length of candidate) > 4 then
			set candidate to text 1 thru -5 of candidate
		else
			set candidate to "repository"
		end if
	end if
	try
		return my validatedFolderName(candidate)
	on error
		return "repository"
	end try
end suggestedFolderName

on cloneCommand(repoURL, destination, gitPath)
	set repoURL to my validatedRepositoryURL(repoURL)
	-- Do not replace a configured SSH transport with our noninteractive defaults.
	-- Check before reserving a folder; ordinary ~/.ssh/config remains supported.
	set transportMessage to "Git Clone does not support a custom SSH command (core.sshCommand, GIT_SSH_COMMAND or GIT_SSH). Clone in Terminal with your existing configuration; no destination was created."
	set transportCheck to "PATH=/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin; export PATH; if [ \"${GIT_SSH_COMMAND+x}\" = x ] || [ \"${GIT_SSH+x}\" = x ]; then /usr/bin/printf '%s\\n' " & quoted form of transportMessage & " >&2; exit 2; fi; if " & quoted form of gitPath & " config --get core.sshCommand >/dev/null; then /usr/bin/printf '%s\\n' " & quoted form of transportMessage & " >&2; exit 2; else transport_status=$?; if [ \"$transport_status\" -ne 1 ]; then exit \"$transport_status\"; fi; fi; "
	-- mkdir is the final, exclusive reservation after the user approves the path.
	-- Existing empty directories and dangling symlinks must also stop before Git.
	return transportCheck & "/bin/mkdir -m 700 " & quoted form of destination & " && /usr/bin/env GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=20' " & quoted form of gitPath & " -c protocol.ext.allow=never -c core.hooksPath=/dev/null clone -- " & quoted form of repoURL & " " & quoted form of destination
end cloneCommand
