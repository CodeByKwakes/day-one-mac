#!/usr/bin/env bash
# Shared required-phase names and bundled guides (Bash 3.2).
phase_doc() {
  case "$1" in
    01) printf '%s/01-required/01-first-boot-and-decisions.md\n' "$DOC_DIR" ;;
    02) printf '%s/01-required/02-command-line-foundation.md\n' "$DOC_DIR" ;;
    03) printf '%s/01-required/03-security-and-ssh.md\n' "$DOC_DIR" ;;
    04) printf '%s/01-required/04-core-tools-and-hosting.md\n' "$DOC_DIR" ;;
    05) printf '%s/01-required/05-dotfiles-and-shell.md\n' "$DOC_DIR" ;;
    06) printf '%s/01-required/06-language-toolchains.md\n' "$DOC_DIR" ;;
    07) printf '%s/01-required/07-vscode-base.md\n' "$DOC_DIR" ;;
    08) printf '%s/01-required/08-verify-and-reproduce.md\n' "$DOC_DIR" ;;
  esac
}

phase_title() {
  case "$1" in
    01) printf 'First boot and decisions\n' ;;
    02) printf 'Command-line foundation\n' ;;
    03) printf 'Security and SSH\n' ;;
    04) printf 'Core tools and hosting\n' ;;
    05) printf 'Configuration ownership, shell and prompt\n' ;;
    06) printf 'Language toolchains and pnpm\n' ;;
    07) printf 'VS Code base\n' ;;
    08) printf 'Verify and reproduce\n' ;;
  esac
}
