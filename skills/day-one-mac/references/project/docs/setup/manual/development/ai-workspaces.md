# Choose an AI working directory

Use a repository or worktree for code changes and a separate private folder for
projectless work. A folder boundary is organisational; the client's permissions
and credentials determine what it can actually access.

## 1. Choose the task location

For code, use the [worktree task](worktrees/README.md) for your client. For a
projectless task, create a new empty folder in Finder under a private location
such as `~/Documents/AI Tasks`. Give it a unique descriptive name.

Expected result: the task has a clearly identified root, not the whole home
directory, an application-state folder or an unrelated repository.

## 2. Add only the required inputs

Copy approved source material into that folder. Retain originals and keep
credentials, production data and unrelated personal documents outside it.

Expected result: every supplied file is within the task's approved scope.

## 3. Open the chosen client at the root

In Terminal, change to the exact task folder before running `codex` or `claude`.
For VS Code, use **File > Open Folder** and select that folder. In a desktop AI
app, choose the task/project directory through its supported UI.

Expected result: the client shows the intended root. Check `pwd` in a terminal;
a remembered session or profile name is not proof of the current directory.

## 4. Set instructions and permissions

Follow [instructions, agents and skills](../ai/instructions-agents-skills.md).
State the outcome, permitted files, output location and verification command.
Review the client's approval mode before allowing edits or external tools.

Expected result: the client can explain the task boundary and required checks.
Profiles do not isolate client credentials, servers or account permissions.

## 5. Review and retain the result

Inspect the output and run the relevant checks before using it. For code,
review the Git diff and tests. For a document, check facts, links and sensitive
content. Export or back up needed outputs independently of chat history.

Expected result: the retained artifact can be located and opened without the
client's temporary session. Archive only after checking originals and outputs.

## Troubleshooting and recovery

If the wrong folder is open, stop edits and reopen the intended task root.
If an agent changed unrelated files, preserve the diff and restore only those
changes after review; do not reset a whole dirty repository. Keep one editing
agent per worktree and use a separate branch for independent code tasks.

The [optional workspace utility](ai-workspaces.md) is an
optional alternative for users of that route; it is not needed for this task.
