#!/usr/bin/env bash
# Interactive navigation only. Existing runners own all changes and gates.
# Sourced by bootstrap-day-one-mac.sh; compatible with macOS Bash 3.2.

centre_pause() {
  printf '\n'
  ui_text 'Press Enter to return to the setup centre.'
  IFS= read -r _
}

centre_command() {
  local status=0
  ui_title '▶' 'Selected action'
  printf '  day-one-mac'
  printf ' %q' "$@"
  printf '\n\n'
  /bin/bash "$HERE/day-one-mac" "$@" || status=$?
  CENTRE_COMMAND_STATUS="$status"
  if [[ "$status" != 0 ]]; then warn "Action stopped (exit $status). Review the message above before retrying."; fi
}

centre_guide() {
  if command -v less >/dev/null 2>&1; then less "$1"; else cat "$1"; fi
}

centre_required() {
  local phase action label
  while :; do
    SINGLE_VALUES=(); SINGLE_LABELS=()
    for phase in 01 02 03 04 05 06 07 08; do
      label='pending'
      [[ ! -s "$COMPLETED_DIR/$phase" ]] || label='recorded'
      SINGLE_VALUES+=("$phase")
      SINGLE_LABELS+=("$phase  $(phase_title "$phase") — $label")
    done
    SINGLE_VALUES+=(back); SINGLE_LABELS+=('Back to setup centre')
    select_one 'Required phases · recorded status is rechecked when run' 0
    phase="$SINGLE_RESULT"
    [[ "$phase" != back ]] || return 0
    SINGLE_VALUES=(plan check resume guide back)
    SINGLE_LABELS=('Preview changes' 'Check this phase' 'Run or revalidate using saved choices' 'Read the phase guide' 'Back to phase list')
    select_one "Required $phase · $(phase_title "$phase")" 0
    action="$SINGLE_RESULT"
    case "$action" in
      back) continue ;;
      guide) centre_guide "$(phase_doc "$phase")" ;;
      resume)
        load_saved_choices
        if ! has_saved_core_choices; then
          warn 'Choose Start or resume required setup first to save your setup choices.'
        elif [[ "$DRY_RUN" == 1 ]]; then centre_command setup --plan --phase "$phase"
        else centre_command setup --resume --phase "$phase"
        fi ;;
      *) centre_command setup "--$action" --phase "$phase" ;;
    esac
    centre_pause
  done
}

centre_module_selection() {
  local module="$1" value WIZARD_BACK_ENABLED=1
  CENTRE_SELECTION=()
  case "$module" in
    09)
      choose_database_services '' 'Select databases · Space to toggle, Enter to review' || return $?
      [[ -n "$MENU_RESULT" ]] || return 1
      CENTRE_SELECTION=(--services "$MENU_RESULT")
      choose_container_engine || return $?
      CENTRE_SELECTION+=(--container-runtime "$CONTAINER_RUNTIME") ;;
    10)
      choose_ai_clients '' 'Select AI clients · Space to toggle, Enter to review' || return $?
      [[ -n "$MENU_RESULT" ]] || return 1
      CENTRE_SELECTION=(--clients "$MENU_RESULT") ;;
    10A|11|12|15|16|17|18|19|20|22)
      ui_text 'Use a reviewed TSV manifest described in the module guide. Empty input cancels.'
      printf '  Manifest path: '; IFS= read -r value
      [[ -n "$value" && "$value" != :back ]] || return 1
      [[ "$value" != '~/'* ]] || value="$HOME/${value:2}"
      [[ -f "$value" && -r "$value" ]] || { warn 'The manifest must be a readable file.'; return 1; }
      CENTRE_SELECTION=(--manifest "$value") ;;
  esac
}

centre_module_command() {
  local layer="$1" module="$2"
  shift 2
  local args=("$layer" --module "$module" "$@")
  # Reuse ownership-aware per-app consent rather than silently accepting the
  # software runner's check-only default for an interactive install action.
  if [[ "$module" == 10 || "$module" == 16 ]]; then args+=(--app-install-policy prompt); fi
  centre_command "${args[@]}"
}

centre_modules() {
  local layer="$1" id layer_value mode prerequisite title guide action module module_title module_guide
  while :; do
    SINGLE_VALUES=(); SINGLE_LABELS=()
    while IFS=$'\t' read -r id layer_value mode prerequisite title guide; do
      [[ "$id" != \#* && "$layer_value" == "$layer" ]] || continue
      SINGLE_VALUES+=("$id"); SINGLE_LABELS+=("$id  $title")
    done < "$PROJECT_DIR/config/modules.tsv"
    SINGLE_VALUES+=(back); SINGLE_LABELS+=('Back to setup centre')
    select_one "$layer modules · apply requires completed Phase 8" 0
    module="$SINGLE_RESULT"
    [[ "$module" != back ]] || return 0
    module_title=''; module_guide=''
    while IFS=$'\t' read -r id layer_value mode prerequisite title guide; do
      [[ "$id" == "$module" ]] || continue
      module_title="$title"; module_guide="$PROJECT_DIR/$guide"; break
    done < "$PROJECT_DIR/config/modules.tsv"
    SINGLE_VALUES=(guide plan check configure resume back)
    SINGLE_LABELS=('Read the module guide' 'Preview saved selection' 'Check installed components' 'Choose and review a new selection' 'Run saved selection' 'Back to module list')
    select_one "$module · $module_title" 0
    action="$SINGLE_RESULT"
    case "$action" in
      back) continue ;;
      guide) centre_guide "$module_guide" ;;
      configure|resume)
        if [[ "$action" == resume && "$DRY_RUN" != 1 && ! -s "$COMPLETED_DIR/08" ]]; then
          warn 'Optional setup remains locked until required Phase 8 is complete.'
        elif [[ "$action" == configure && "$module" == 13 ]]; then
          if [[ "$DRY_RUN" == 1 || ! -s "$COMPLETED_DIR/08" ]]; then centre_command cli-tools --dry-run
          else centre_command cli-tools
          fi
        else
          CENTRE_SELECTION=()
          if [[ "$action" == configure ]] && ! centre_module_selection "$module"; then continue; fi
          centre_module_command "$layer" "$module" --plan ${CENTRE_SELECTION[@]+"${CENTRE_SELECTION[@]}"}
          if [[ "$DRY_RUN" != 1 && -s "$COMPLETED_DIR/08" ]]; then
            # A failed plan must never advance to apply.
            [[ "${CENTRE_COMMAND_STATUS:-0}" == 0 ]] || { centre_pause; continue; }
            ui_text 'Review this preview. Press Enter to choose whether to apply.'
            IFS= read -r _
            SINGLE_VALUES=(back run); SINGLE_LABELS=('Return without applying' 'Apply the reviewed selection')
            select_one 'Apply the selection you just reviewed?' 0
            if [[ "$SINGLE_RESULT" == run ]]; then
              if [[ "$action" == resume ]]; then centre_module_command "$layer" "$module" --resume
              else centre_module_command "$layer" "$module" --apply ${CENTRE_SELECTION[@]+"${CENTRE_SELECTION[@]}"}
              fi
            fi
          elif [[ ! -s "$COMPLETED_DIR/08" ]]; then
            warn 'Preview only: complete required Phase 8 before applying this selection.'
          fi
        fi ;;
      *) centre_module_command "$layer" "$module" "--$action" ;;
    esac
    centre_pause
  done
}

centre_docs() {
  local guide
  while :; do
    SINGLE_VALUES=(START-HERE.md PROCESS-OVERVIEW.md 20-reference/COMMAND-REFERENCE.md 02-optional/README.md 03-advanced/README.md back)
    SINGLE_LABELS=('Start here' 'Whole process overview' 'Command reference' 'Optional module index' 'Advanced module index' 'Back to other actions')
    select_one 'Documentation · choose a bundled guide' 0
    guide="$SINGLE_RESULT"
    [[ "$guide" != back ]] || return 0
    centre_guide "$DOC_DIR/$guide"
  done
}

centre_other_actions() {
  while :; do
    SINGLE_VALUES=(status modules shell runtime docs install macos cli raycast folders prepare rollback remove back)
    SINGLE_LABELS=(
      'Required phase status (recorded)'
      'Optional and advanced status · component breakdown'
      'Inspect shell, completion and suggestions'
      'Check runtime integrity and version'
      'Browse bundled documentation'
      'Required Installation Centre'
      'macOS preferences wizard'
      'CLI tools and optional aliases'
      'Raycast command setup'
      'Preview developer folder settings'
      'Prepare an existing Mac · Stage 0'
      'Preview recorded rollback'
      'Removal wizard · review before removing'
      'Back to setup centre'
    )
    select_one 'Other actions · inspect, configure or maintain' 0
    case "$SINGLE_RESULT" in
      back) return 0 ;;
      status) centre_command setup --status ;;
      modules) centre_command optional --status --details ;;
      shell) centre_command shell-status ;;
      runtime) centre_command runtime-status ;;
      docs) centre_docs ;;
      folders) centre_command folders --plan ;;
      rollback) centre_command rollback ;;
      install|macos|cli|raycast|prepare|remove)
        # The existing action-specific wizard owns selection and confirmation.
        case "$SINGLE_RESULT" in
          install) CENTRE_ARGS=(install) ;;
          macos) CENTRE_ARGS=(macos-settings --wizard) ;;
          cli)
            if [[ -s "$COMPLETED_DIR/08" ]]; then CENTRE_ARGS=(cli-tools)
            else CENTRE_ARGS=(cli-tools --dry-run); warn 'Preview only: complete required Phase 8 before installing CLI tools.'
            fi ;;
          raycast) CENTRE_ARGS=(raycast --wizard) ;;
          prepare) CENTRE_ARGS=(prepare-existing --guided) ;;
          remove) CENTRE_ARGS=(remove --guided) ;;
        esac
        if [[ "$DRY_RUN" == 1 ]]; then
          if [[ "$SINGLE_RESULT" == install ]]; then CENTRE_ARGS=(setup --plan)
          elif [[ "$SINGLE_RESULT" == remove ]]; then CENTRE_ARGS=(remove --guided)
          elif [[ "$SINGLE_RESULT" != cli || -s "$COMPLETED_DIR/08" ]]; then CENTRE_ARGS+=(--dry-run)
          fi
        fi
        centre_command "${CENTRE_ARGS[@]}" ;;
    esac
    centre_pause
  done
}

run_setup_centre() {
  day_one_require_apple_silicon || return 2
  [[ -t 0 && -t 1 ]] || die 'The setup wizard requires an interactive terminal. Use setup --plan or explicit setup options instead.'
  while :; do
    SINGLE_VALUES=(start required optional advanced actions exit)
    SINGLE_LABELS=('Start or resume required setup' 'Required phases · 01–08' 'Optional modules · 09–14' 'Advanced modules · 15–22' 'Other actions · status, settings and maintenance' 'Exit')
    select_one 'Setup centre · choose what to work on' 0
    case "$SINGLE_RESULT" in
      exit) return 0 ;;
      start)
        if [[ "$DRY_RUN" == 1 ]]; then /bin/bash "$0" --configure --dry-run || true
        else /bin/bash "$0" --configure || true
        fi
        centre_pause ;;
      required) centre_required ;;
      optional|advanced) centre_modules "$SINGLE_RESULT" ;;
      actions) centre_other_actions ;;
    esac
  done
}
