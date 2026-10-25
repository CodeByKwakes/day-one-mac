[← Worktree overview](README.md) · [Environment files](environment.md) · [Troubleshooting](troubleshooting.md)

# Worktree environment files and running applications

Use this shared procedure after creating a worktree with any route and before
launching an application or running tests. Examples use the terminal route's
`acme` folders; substitute the actual path reported by VS Code, Codex, or Claude.

For the copy commands, define your repository and worktree container first:

```bash
REPO="$HOME/Developer/github.com/example/acme"
WORKTREE_ROOT="${REPO}.worktrees"
```

Tool-managed folders can be elsewhere. Use their actual paths rather than
assuming they are under this container.

**Example:** run main on port 4100, the feature on 4101, and the hotfix on 4102.
Each points to a different local database. Tests use a disposable test database
so they cannot clear data used by your development app.

Yes: each worktree can have its own `.env`, `.env.local`, or `.env.test` with
different values. Git does not automatically copy ignored files from the
primary checkout. It also does not choose or load an environment file for your
application. Follow your framework or test runner's loading rules.

```text
acme/                              .env.local → PORT=4100
acme.worktrees/feature-user-auth/   .env.local → PORT=4101
acme.worktrees/hotfix-payment-timeout/
                                   .env.local → PORT=4102
acme.worktrees/test-main/           .env.test  → separate test database
```

These port names are examples; the application must support them. Environment
files live inside each worktree, not at the `.worktrees` container level.

## Create independent files from a template

Use a committed template containing placeholders, such as `.env.example`.
First ensure the repository ignores real environment files. A typical reviewed
`.gitignore` policy is:

```gitignore
.env
.env.*
!.env.example
!.env.*.example
```

Adapt this to the repository rather than replacing its existing policy. Ignore
rules do not untrack files already committed. Before adding any credentials,
check that the intended file is untracked and ignored:

```bash
cd "$WORKTREE_ROOT/feature-user-auth"
git ls-files -- .env.local
git check-ignore -v .env.local
```

The first command should print nothing; the second should show the matching
ignore rule. If either check disagrees, resolve that before adding secrets.
Then create the file without overwriting an existing configuration:

```bash
cp -i .env.example .env.local
chmod 600 .env.local
code .env.local
```

Set development-only values appropriate to this worktree. Repeat inside the
test folder using `.env.test` if the test runner expects it. Keep templates
committed and actual secrets out of commits, PRs, and test logs.

## Example: file contents for development and tests

If this example application reads `PORT` and `DATABASE_URL`, edit the files
created from its template to contain values such as these. The databases must
be created separately using the project's setup instructions; writing these
values does not create a database or configure the application to use them.

In `acme.worktrees/feature-user-auth/.env.local`:

```dotenv
PORT=4101
DATABASE_URL=postgresql://localhost:5432/acme_feature_auth
```

In `acme.worktrees/hotfix-payment-timeout/.env.local`:

```dotenv
PORT=4102
DATABASE_URL=postgresql://localhost:5432/acme_hotfix_payment
```

In `acme.worktrees/test-main/.env.test`:

```dotenv
PORT=4200
DATABASE_URL=postgresql://localhost:5432/acme_test_main
```

In `acme.worktrees/test-user-auth/.env.test`:

```dotenv
PORT=4201
DATABASE_URL=postgresql://localhost:5432/acme_test_auth
```

These URLs deliberately omit credentials. Supply development credentials
through your project's normal local setup if required. Use the same filename
in multiple worktrees when your framework expects it: the containing folder
makes each file independent.

## Copy a known local configuration

If the existing file contains suitable development settings, copy it explicitly
after checking the destination's ignore rules as above:

```bash
cp -i "$REPO/.env.local" "$WORKTREE_ROOT/feature-user-auth/.env.local"
chmod 600 "$WORKTREE_ROOT/feature-user-auth/.env.local"
```

Edit its ports and database names before launching another copy of the app.
This is an independent copy; later edits do not synchronize. Avoid symlinking
one writable environment file across worktrees when you need different values.
Do not copy production credentials into a PR review or test environment.

## Select the file explicitly when supported

File names have no universal precedence. For an application using Node's
built-in environment-file support, an explicit example is:

```bash
node --env-file=.env.local app.js
node --env-file=.env.test --test
```

Replace `app.js` with the real entry point; `--test` is Node's own test runner,
not a replacement for a project's custom test command. With this Node option,
variables already in the process environment take precedence over the file.
Check for stale exported values when switching worktrees. See the
[Node CLI reference](https://nodejs.org/api/cli.html#--env-filefile).
Other frameworks and tools can use different precedence and syntax. Merely
running `pnpm test` does not guarantee `.env.test` will be loaded. Avoid
blindly running `source .env`: shell sourcing can execute code and is not a
general-purpose dotenv parser.

## Example: verify the selected file without printing secrets

With Node environment-file support, run from the feature folder:

```bash
cd "$WORKTREE_ROOT/feature-user-auth"
node --env-file=.env.local -p 'process.env.PORT'
```

Expected for the example above: `4101`, unless the terminal already exports
`PORT`. In the main test folder:

```bash
cd "$WORKTREE_ROOT/test-main"
node --env-file=.env.test -p 'process.env.PORT'
```

Expected: `4200`. Inspect a harmless value like the port rather than printing
all environment variables, which could expose credentials.

## Optional VS Code copying

When VS Code creates a worktree, its `git.worktreeIncludeFiles` setting can
copy narrowly selected ignored files, for example `.env.test`. Use it only for
reviewed local test settings; terminal-created worktrees still need explicit
setup. Independent copies are useful, but their ports and database names still
need to be adjusted before concurrent runs.

## Isolate running applications

Worktrees isolate files and branches, not ports, databases, containers, or
shared caches. Give each running copy distinct resources:

```bash
PORT=4101 docker compose -p acme-codex-payment up
PORT=4102 docker compose -p acme-claude-auth up
```

Where relevant, also separate database names, test output, local emulators, and
cache directories.
