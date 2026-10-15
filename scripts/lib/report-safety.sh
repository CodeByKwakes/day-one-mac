#!/usr/bin/env bash
# Public-safe remote metadata. Never echo rejected input or parser errors.
day_one_remote_display() {
  local value="$1" scheme authority path
  value="${value%%\?*}"; value="${value%%\#*}"
  if [[ "$value" == *$'\n'* || "$value" == *$'\r'* || "$value" == *$'\t'* ]]; then
    printf '[redacted remote]\n'; return
  fi
  case "$value" in
    https://*|http://*|ssh://*|git://*)
      scheme="${value%%://*}"; value="${value#*://}"
      authority="${value%%/*}"; path=''
      [[ "$value" != */* ]] || path="/${value#*/}"
      authority="${authority##*@}"
      ;;
    *@*:*|[A-Za-z0-9]*:*)
      scheme=ssh; authority="${value%%:*}"; authority="${authority##*@}"
      path="/${value#*:}"
      ;;
    '') printf 'NO-REMOTE\n'; return ;;
    *) printf '[local or unrecognized remote]\n'; return ;;
  esac
  if [[ "$authority" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*(:[0-9]+)?$ && "$path" =~ ^/[A-Za-z0-9_./~%+-]*$ ]]; then
    printf '%s://%s%s\n' "$scheme" "$authority" "$path"
  else
    printf '[redacted remote]\n'
  fi
}
