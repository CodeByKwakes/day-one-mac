#!/usr/bin/env bash
# macOS ships no timeout(1). Run a command with a deadline, writing its combined
# output to the file named first. Returns the command's exit status, or 124 when
# the deadline was reached and the command was killed. Used for calls that can
# raise a GUI prompt and would otherwise block the runner indefinitely.
run_with_deadline() {
  local output_file="$1" seconds="$2"
  shift 2
  local cmd_pid watch_pid status marker="${output_file}.deadline"
  rm -f "$marker"
  : > "$output_file"
  "$@" >"$output_file" 2>&1 &
  cmd_pid=$!
  # Record the deadline BEFORE signalling: the main shell's wait returns as soon
  # as the child dies, so writing the marker after the kill races against the
  # check below and intermittently reports a timeout as an ordinary failure.
  ( sleep "$seconds"
    if kill -0 "$cmd_pid" 2>/dev/null; then
      : > "$marker"
      kill -TERM "$cmd_pid" 2>/dev/null
    fi ) >/dev/null 2>&1 &
  watch_pid=$!
  set +e
  # The shell announces "Terminated" on stderr when it reaps a killed job;
  # silence that so a deadline reads as our own message, not shell noise.
  { wait "$cmd_pid"; status=$?; } 2>/dev/null
  kill -TERM "$watch_pid" >/dev/null 2>&1
  { wait "$watch_pid"; } >/dev/null 2>&1
  set -e
  if [[ -e "$marker" ]]; then
    rm -f "$marker"
    return 124
  fi
  return "$status"
}
