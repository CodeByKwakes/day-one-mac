#!/usr/bin/env python3
"""Check category selection on a real terminal with a private Homebrew fixture."""

import errno
import os
from pathlib import Path
import pty
import select
import signal
import subprocess
import tempfile
import time


SCRIPT = Path(__file__).resolve().parents[1] / "configure-cli-tools.sh"


def exercise(env, keys, expected, status=0, args=("--dry-run",), command=None,
             ready=b"q: quit", check_category=True):
    pid, master = pty.fork()
    if pid == 0:
        target = command or SCRIPT.parent / "day-one-mac"
        arguments = list(args) if command else ["cli-tools", *args]
        os.execve("/bin/bash", ["/bin/bash", str(target), *arguments], env)
    output = bytearray()
    sent = False
    finished = False
    try:
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            if not select.select([master], [], [], 0.1)[0]:
                continue
            try:
                chunk = os.read(master, 65536)
            except OSError as exc:
                if exc.errno == errno.EIO:
                    break
                raise
            if not chunk:
                break
            output.extend(chunk)
            if not sent and ready in output:
                first = output.decode()
                if check_category:
                    assert "Navigation (5/7)" in first
                    assert "lazydocker" not in first and "shellcheck" not in first
                assert first.count("\n") < 25, first
                if env.get("COLUMNS") == "40":
                    lines = first.splitlines()
                    assert len(lines) <= 18, first
                    assert all(len(line) <= 40 for line in lines), first
                assert "━━" not in first
                if env.get("TERM") == "dumb" or env.get("DAY_ONE_MAC_ASCII") == "1":
                    assert "🎛" not in first
                os.write(master, keys)
                sent = True
        else:
            raise AssertionError("CLI selector timed out")
        _, result = os.waitpid(pid, 0)
        finished = True
        text = output.decode()
        assert os.waitstatus_to_exitcode(result) == status, text
        assert expected in text, text
        return text
    finally:
        if not finished:
            os.kill(pid, signal.SIGKILL)
            os.waitpid(pid, 0)
        os.close(master)


with tempfile.TemporaryDirectory(prefix="day-one-cli-", dir="/private/tmp") as root:
    home = Path(root) / "home with spaces"
    binary = home / "bin"
    binary.mkdir(parents=True)
    brew = binary / "brew"
    brew.write_text('#!/bin/sh\n[ "$1:$2" = list:--formula ] || exit 97\nprintf "eza\\n"\n')
    brew.chmod(0o700)
    env = dict(os.environ, HOME=str(home), PATH=f"{binary}:/usr/bin:/bin:/usr/sbin:/sbin",
               TERM="dumb", NO_COLOR="1", COLUMNS="80", LINES="24", DAY_ONE_MAC_STATE_ROOT=str(home / "state"),
               DAY_ONE_MAC_STATE_DIR=str(home / "state"))
    output = exercise(env, b"j \x1b[C \r", "Selected: eza direnv")
    assert "$ brew install direnv" in output and "$ brew install eza" not in output
    exercise(env, b"a\x1b[C \x1b[Dn\r", "Selected: direnv")
    exercise(env, b"k \r", "Selected: zoxide")
    exercise(env, b"lll \r", "Selected: dive")
    exercise(env, b"\r", "nothing selected; no changes made")
    exercise(env, b"q", "Navigation (5/7)", status=10)
    exercise(env, b"b", "Navigation (5/7)", status=10)
    narrow = dict(env, COLUMNS="40", LINES="18", DAY_ONE_MAC_ASCII="1")
    output = exercise(narrow, b"k \r", "Selected: zoxide")
    assert "Item 1 of 6 (showing 1-1)" in output
    assert "Item 6 of 6 (showing 6-6)" in output
    assert "\x1b" not in output, "TERM=dumb emitted terminal controls"
    colourless = dict(env, TERM="xterm-256color")
    output = exercise(colourless, b"q", "Navigation (5/7)", status=10)
    assert "\x1b[36m" not in output, "NO_COLOR was ignored"
    assert "🎛" in output, "NO_COLOR should retain the heading icon"
    coloured = dict(env, TERM="xterm-256color")
    coloured.pop("NO_COLOR", None)
    output = exercise(coloured, b"q", "Navigation (5/7)", status=10)
    assert "\x1b[36m" in output and "\x1b[1m" in output
    assert "🎛" in output, "interactive heading icon is missing"
    # Run the production wizard selectors with private, harmless catalogues.
    # Extract only function definitions; never execute setup or preferences.
    bootstrap = (SCRIPT.parent / "bootstrap-day-one-mac.sh").read_text()
    selectors = bootstrap[bootstrap.index("clear_screen() {"):
                          bootstrap.index("prompt_value() {")]
    fixture = Path(root) / "wizard.sh"
    fixture.write_text('set -euo pipefail\nsource "' + str(SCRIPT.parent / "lib/terminal-ui.sh") +
                       '"\n' + selectors + """
for ((i=0; i<20; i++)); do
  SINGLE_VALUES+=("$i"); SINGLE_LABELS+=("Choice $i café")
  MENU_VALUES+=("$i"); MENU_LABELS+=("Choice $i café"); MENU_SELECTED+=(0)
done
if [[ "$1" == single ]]; then
  select_one 'Choose one' 0
  printf 'RESULT:%s\n' "$SINGLE_RESULT"
else
  select_toggles 'Choose tools'
  printf 'RESULT:%s\n' "$MENU_RESULT"
fi
""")
    output = exercise(narrow, b"k\r", "RESULT:19", command=fixture, args=("single",),
                      check_category=False)
    assert "Choice 19 café" in output and "Item 20 of 20" in output
    output = exercise(narrow, b"k j \r", "RESULT:0,19", command=fixture,
                      args=("toggle",), check_category=False)
    assert "Choice 19 café" in output
    exercise(narrow, b"a\r", "RESULT:" + ",".join(map(str, range(20))),
             command=fixture, args=("toggle",), check_category=False)
    exercise(narrow, b"an\r", "RESULT:\r", command=fixture, args=("toggle",),
             check_category=False)
    fixture.write_text(fixture.read_text().replace("  select_toggles 'Choose tools'",
                       "  MENU_LABELS[0]='A longer preference label with café'\n"
                       "  select_toggles 'Choose tools'"))
    output = exercise(narrow, b"q", "A longer preference label with", command=fixture,
                      args=("toggle",), check_category=False)
    assert output.count("> [ ]") == 1, "wrapped label repeats focus/checkbox"
    assert "        café" in output, "wrapped text lost its continuation indent"
    review = bootstrap[bootstrap.index("print_review_body() {"):
                       bootstrap.index("application_review_line() {")]
    fixture.write_text(fixture.read_text().split('for ((i=0; i<20; i++))')[0] + review + """
PRESET=core TRACK=2 STACK=both FOLDER_LAYOUT=purpose GHQ_CHOICE=no FOLDER_GHQ_ROOT=''
GIT_NAME=Fixture GIT_EMAIL=fixture@example.invalid PRIMARY_IDE=other
MACOS_SETTINGS_PLAN=skip AUTH_MODE=https HTTPS_HELPER=existing DOTFILES_REPO=''
DOTFILES_VERSIONING=none SHELL_CHOICE=apple PROMPT_CHOICE=none
SHOW_OPTIONAL_REVIEW=0 APPLICATION_REVIEW_CACHE=''
track_label() { printf 'Azure DevOps'; }
stack_label() { printf 'Node and Python'; }
show_required_base() { printf 'FULL PLAN\n'; }
SINGLE_VALUES=(start quit); SINGLE_LABELS=('Start setup' 'Quit')
SINGLE_SHOW_REVIEW=1
select_one 'Confirm setup' 0
printf 'RESULT:%s\n' "$SINGLE_RESULT"
""")
    output = exercise(env, b"d\r", "RESULT:start", command=fixture, args=(),
                      ready=b"d: toggle full setup details", check_category=False)
    before, after = output.split("d: toggle full setup details", 1)
    assert "FULL PLAN" not in before and "FULL PLAN" in after
    assert "Day One Mac setup wizard" not in output, "duplicate review heading"
    settings = (SCRIPT.parent / "configure-macos-settings.sh").read_text()
    chooser = settings[settings.index("choose_settings() {"):settings.index("confirm() {")]
    fixture.write_text('set -euo pipefail\nsource "' + str(SCRIPT.parent / "lib/terminal-ui.sh") +
                       '"\n' + """
OPTIONS=(); LABELS=(); OPTION_GROUPS=(); SELECTED_FLAGS=()
for ((i=0; i<22; i++)); do
  OPTIONS+=("setting$i"); LABELS+=("Preference $i café")
  OPTION_GROUPS+=("Group $((i/4))"); SELECTED_FLAGS+=(0)
done
clear_screen() { ui_clear_screen; }
load_selection_flags() { :; }
""" + chooser + """
choose_settings
printf 'RESULT:%s\n' "$SELECTED"
""")
    exercise(narrow, b"k \r", "RESULT:setting21", command=fixture, args=(),
             ready=b"Enter: review", check_category=False)
    exercise(narrow, b"q", "Preference 0 café", status=10, command=fixture, args=(),
             ready=b"Enter: review", check_category=False)
    for script_name, end in [("prepare-existing-mac.sh", "count_lines() {"),
                             ("remove-day-one-mac.sh", "manifest_owns_brew_item() {")]:
        source = (SCRIPT.parent / script_name).read_text()
        selectors = source[source.index("SINGLE_VALUES=()") : source.index(end)]
        fixture.write_text('set -euo pipefail\nsource "' + str(SCRIPT.parent / "lib/terminal-ui.sh") +
                           '"\nclear_screen() { ui_clear_screen; }\n' + selectors + """
append_csv() { printf '%s%s%s' "$1" "${1:+,}" "$2"; }
for ((i=0; i<20; i++)); do
  SINGLE_VALUES+=("$i"); SINGLE_LABELS+=("Choice $i café")
  MENU_VALUES+=("$i"); MENU_LABELS+=("Choice $i café"); MENU_SELECTED+=(0)
done
if [[ "$1" == single ]]; then
  select_one 'Choose one' 0
  printf 'RESULT:%s\n' "$SINGLE_RESULT"
else
  select_toggles 'Choose tools'
  printf 'RESULT:%s,%s\n' "${MENU_SELECTED[0]}" "${MENU_SELECTED[19]}"
fi
""")
        exercise(narrow, b"k\r", "RESULT:19", command=fixture, args=("single",),
                 check_category=False)
        exercise(narrow, b"k j \r", "RESULT:1,1", command=fixture, args=("toggle",),
                 check_category=False)
        exercise(narrow, b"q", "Choose tools", command=fixture, args=("toggle",),
                 check_category=False)
    raycast = (SCRIPT.parent / "configure-raycast.sh").read_text()
    chooser = raycast[raycast.index("interactive_groups() {"):raycast.index("write_library() {")]
    fixture.write_text('set -euo pipefail\nsource "' + str(SCRIPT.parent / "lib/terminal-ui.sh") +
                       '"\n' + chooser + """
GROUP_IDS=(core github azure containers ai optional)
GROUP_LABELS=('Core commands' 'GitHub commands' 'Azure commands' 'Containers' 'AI clients' 'Optional')
GROUP_SELECTED=(0 0 0 0 0 0)
interactive_groups
printf 'RESULT:%s\n' "$(IFS=,; printf '%s' "${GROUP_SELECTED[*]}")"
""")
    exercise(narrow, b"ak \r", "RESULT:1,1,1,1,0,1", command=fixture, args=(),
             check_category=False)
    exercise(narrow, b"q", "Core commands", status=10, command=fixture, args=(),
             check_category=False)
    # Exercise the production centre and selectors without invoking installers.
    selectors = bootstrap[bootstrap.index("clear_screen() {"):
                          bootstrap.index("prompt_value() {")]
    centre = Path(root) / "centre.sh"
    post_menu = bootstrap[bootstrap.index("post_required_menu() {"):
                          bootstrap.index("configure_wizard() {")]
    centre.write_text('set -euo pipefail\nsource "' + str(SCRIPT.parent / "lib/terminal-ui.sh") +
                      '"\n' + selectors + '\nsource "' +
                      str(SCRIPT.parent / "lib/required-phase-catalog.sh") + '\"\nsource "' +
                      str(SCRIPT.parent / "lib/wizard-centre.sh") + '\"\n' + post_menu + """
HERE="$2/scripts"; PROJECT_DIR="$2"; DOC_DIR="$2/docs"
STATE_DIR="$HOME/centre-state"; COMPLETED_DIR="$STATE_DIR/completed"
DRY_RUN="${CENTRE_DRY_RUN:-0}"
day_one_require_apple_silicon() { return 0; }
load_saved_choices() { :; }
has_saved_core_choices() { return 0; }
die() { printf '%s\\n' "$*"; exit 2; }
warn() { ui_warning "$@"; }
centre_command() {
  printf 'RUN:%s\\n' "$*"
  printf 'ARGCOUNT:%s\\n' "$#"
  CENTRE_COMMAND_STATUS=0
  [[ "${CENTRE_FAIL_PLAN:-0}" != 1 || "$*" != *--plan* ]] || CENTRE_COMMAND_STATUS=1
}
if [[ "$1" == router ]]; then
  centre_module_command optional 10 --apply --clients codex
  centre_module_command advanced 16 --resume
  exit 0
fi
if [[ "$1" == post ]]; then
  centre_modules() { printf 'MODULES:%s\\n' "$1"; }
  post_required_menu
  exit 0
fi
run_setup_centre
""")
    routed = subprocess.run(["/bin/bash", str(centre), "router", str(SCRIPT.parent.parent)],
                            env=env, capture_output=True, text=True, check=True).stdout
    assert "RUN:optional --module 10 --apply --clients codex --app-install-policy prompt" in routed
    assert "RUN:advanced --module 16 --resume --app-install-policy prompt" in routed
    exercise(env, b"jj\r", "MODULES:advanced", command=centre,
             args=("post", str(SCRIPT.parent.parent)), check_category=False)
    centre_args = ("hub", str(SCRIPT.parent.parent))
    output = exercise(env, b"j\r\r\r\rk\rk\r", "RUN:setup --plan --phase 01",
                      command=centre, args=centre_args, check_category=False)
    assert "Required phases" in output and "Advanced modules" in output
    output = exercise(env, b"j\r\rbbq", "Setup centre", command=centre,
                      args=centre_args, check_category=False)
    assert "RUN:" not in output, "back launched a phase action"
    exercise(env, b"jj\r\x1b[Dq", "Optional modules", command=centre,
             args=centre_args, check_category=False)
    # Production setup sections propagate back without discarding accepted answers.
    choices = bootstrap[bootstrap.index("choose_track() {"):
                        bootstrap.index("choose_preset() {")]
    configuration = bootstrap[bootstrap.index("configure_wizard() {"):
                              bootstrap.index("has_saved_core_choices() {")]
    back_fixture = Path(root) / "back.sh"
    back_fixture.write_text('set -euo pipefail\nsource "' + str(SCRIPT.parent / "lib/terminal-ui.sh") +
                            '"\n' + selectors + choices + configuration + """
TRACK=1 STACK=both
if configure_wizard; then status=0; else status=$?; fi
printf 'BACK:%s TRACK:%s STACK:%s\\n' "$status" "$TRACK" "$STACK"
""")
    exercise(env, b"j\rb\rbb", "BACK:11 TRACK:2 STACK:both",
             command=back_fixture, args=(), check_category=False)
    prompt = bootstrap[bootstrap.index("prompt_value() {"):
                       bootstrap.index("csv_label() {")]
    back_fixture.write_text('set -euo pipefail\nsource "' + str(SCRIPT.parent / "lib/terminal-ui.sh") +
                            '"\n' + prompt + """
WIZARD_BACK_ENABLED=1
if prompt_value 'Repository URL' ''; then status=0; else status=$?; fi
printf 'BACK:%s\\n' "$status"
""")
    exercise(env, b":back\n", "BACK:11", command=back_fixture, args=(),
             ready=b"Repository URL:", check_category=False)
    auth = bootstrap[bootstrap.index("choose_auth_mode() {"):
                     bootstrap.index("choose_verification_repos() {")]
    back_fixture.write_text('set -euo pipefail\nsource "' + str(SCRIPT.parent / "lib/terminal-ui.sh") +
                            '"\n' + selectors + auth + """
TRACK=2 AUTH_MODE=https HTTPS_HELPER=existing
choose_auth_mode
printf 'HELPER:%s\\n' "$HTTPS_HELPER"
""")
    exercise(env, b"\r\r", "HELPER:existing", command=back_fixture,
             args=(), check_category=False)
    back_fixture.write_text('set -euo pipefail\nsource "' + str(SCRIPT.parent / "lib/terminal-ui.sh") +
                            '"\n' + selectors + prompt + choices + """
FOLDER_LAYOUT=existing GHQ_CHOICE=yes FOLDER_GHQ_ROOT="$HOME/root kept"
choose_folders
printf 'ROOT:%s\\n' "$FOLDER_GHQ_ROOT"
""")
    exercise(env, b"\r\r\n", "ROOT:" + str(home / "root kept"),
             command=back_fixture, args=(), check_category=False)
    output = exercise(env, b"jj\r\rjjjj\r\rk\rk\r", "Optional setup remains locked",
                      command=centre, args=centre_args, check_category=False)
    assert "RUN:" not in output, "locked module launched a runner"
    output = exercise(env, b"jjj\r\rjjjj\r\rk\rk\r", "Optional setup remains locked",
                      command=centre, args=centre_args, check_category=False)
    assert "RUN:" not in output, "advanced module bypassed Phase 8"
    output = exercise(env, b"jj\rjjjjjj\rjjj\r\rk\rk\r",
                      "Preview only: complete required Phase 8", command=centre,
                      args=centre_args, check_category=False)
    assert "RUN:optional --module 14 --plan" in output and "--apply" not in output
    completed = home / "centre-state/completed"
    completed.mkdir(parents=True)
    (completed / "08").write_text("fixture\n")
    output = exercise(dict(env, CENTRE_FAIL_PLAN="1"), b"jj\rjjjjjj\rjjj\r\rk\rk\r",
                      "RUN:optional --module 14 --plan", command=centre, args=centre_args,
                      check_category=False)
    assert "Apply the reviewed selection" not in output
    assert "--apply" not in output, "failed plan advanced to apply"
    manifest = home / "reviewed manifest.tsv"
    manifest.write_text("fixture\n")
    keys = b"jjj\r\rjjj\r" + str(manifest).encode() + b"\n\rj\r\rk\rk\r"
    output = exercise(env, keys, "RUN:advanced --module 15 --apply --manifest " + str(manifest),
                      command=centre, args=centre_args, check_category=False)
    assert "ARGCOUNT:6" in output, "manifest path with spaces was split"
    assert "Review this preview" in output
    output = exercise(dict(env, CENTRE_DRY_RUN="1"), b"jj\r\rjjjj\r\rk\rk\r",
                      "RUN:optional --module 09 --plan", command=centre, args=centre_args,
                      check_category=False)
    assert "--resume" not in output and "--apply" not in output
    output = exercise(dict(env, CENTRE_DRY_RUN="1"), b"jjjj\r" + b"j" * 13 + b"\r\rk\rk\r",
                      "RUN:remove --guided", command=centre, args=centre_args,
                      check_category=False)
    assert "--execute" not in output and "--dry-run" not in output
    output = exercise(dict(env, CENTRE_DRY_RUN="1"), b"jjjj\rjjjjjjj\r\rk\rk\r",
                      "RUN:cli-tools --dry-run", command=centre, args=centre_args,
                      check_category=False)
    for dry_run, expected in (("1", "RUN:shortcuts --plan"), ("0", "RUN:shortcuts --guided")):
        exercise(dict(env, CENTRE_DRY_RUN=dry_run), b"jjjj\r" + b"j" * 9 + b"\r\rk\rk\r",
                 expected, command=centre, args=centre_args, check_category=False)
    coloured_centre = exercise(coloured, b"q", "Setup centre", command=centre,
                              args=centre_args, check_category=False)
    assert "◆" in coloured_centre and "●" in coloured_centre
    assert "\x1b[35m" in coloured_centre and "\x1b[36m" in coloured_centre
    exercise(narrow, b"q", "Setup centre", command=centre, args=centre_args,
             check_category=False)
    assert not (home / "state").exists(), "browsing the centre saved setup state"
    assert not (home / "state.operation.lock").exists(), "browsing acquired a setup lock"
    # The actual no-argument entry point must browse without a supervisor lock.
    uname = binary / "uname"
    uname.write_text('#!/bin/sh\ncase "$1" in -s) echo Darwin ;; -m) echo arm64 ;; esac\n')
    uname.chmod(0o700)
    exercise(env, b"q", "Setup centre", args=(), command=SCRIPT.parent / "day-one-mac",
             check_category=False)
    assert not (home / "state").exists() and not (home / "state.operation.lock").exists()
    exercise(env, b"\rq\nq", "What state is this Mac in?", args=(),
             command=SCRIPT.parent / "day-one-mac", check_category=False)
    assert not (home / "state").exists(), "cancelling setup saved choices"
    assert not (home / "state.operation.lock").exists(), "setup cancellation leaked its lock"

    listing = subprocess.run(["/bin/bash", str(SCRIPT), "--list"], env=env,
                             check=True, capture_output=True, text=True).stdout
    assert "lazydocker" in listing and "zoxide" in listing and "[installed]" in listing
    preview = subprocess.run(["/bin/bash", str(SCRIPT), "--packages", "eza,direnv", "--dry-run"],
                             env=env, check=True, capture_output=True, text=True).stdout
    assert "Selected: eza direnv" in preview and "lazydocker" not in preview
    assert not (home / "state").exists(), "read-only selector wrote state"
    # Exercise the real no-argument command, including lock supervision. The
    # preview tests above deliberately skip that path and cannot catch an
    # empty ORIGINAL_ARGS expansion under macOS Bash 3.2 nounset.
    exercise(env, b"q", "Navigation (5/7)", status=10, args=())
    exercise(env, b"\r", "nothing selected; no changes made", args=())
    exercise(env, b"j \rn\n", "Selected: eza", status=10, args=())
    assert not (home / "state").exists(), "cancelled selector saved state"
    assert not (home / "state.operation.lock").exists(), "cancelled selector leaked lock"
    subprocess.run(["/bin/bash", str(SCRIPT), "--packages", "eza", "--yes"],
                   env=env, check=True, capture_output=True, text=True)
    assert (home / "state/optional-cli-packages").read_text().strip() == "eza"
    assert not (home / "state.operation.lock").exists(), "applied selection leaked lock"
    # Installation consent and alias consent are separate interactive choices.
    (home / ".config/zsh").mkdir(parents=True)
    (home / ".zshrc").write_text('source "$HOME/.config/zsh/aliases.zsh"\n')
    aliases = home / ".config/zsh/aliases.zsh"
    aliases.write_text("alias ls='ls -G'\n")
    (home / "state/dotfiles-versioning").write_text("none\n")
    original = aliases.read_bytes()
    exercise(env, b"y\nn\n", "Add these aliases?", args=("--packages", "eza"),
             ready=b"Save this selection", check_category=False)
    assert aliases.read_bytes() == original, "declining alias setup changed configuration"
    exercise(env, b"y\ny\n", "Optional eza aliases configured", args=("--packages", "eza"),
             ready=b"Save this selection", check_category=False)
    assert aliases.read_bytes().startswith(original)
    assert "# Day One Mac optional eza aliases" in aliases.read_text()

print("PASS: compact selectors and setup centre navigation, styling, preview/apply boundaries and Phase 8 gates")
