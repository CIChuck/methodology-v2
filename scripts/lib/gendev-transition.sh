#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

# Portable transition helpers for installed GenDev lifecycle commands.

_GENDEV_TRANSITION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$_GENDEV_TRANSITION_DIR/gendev-common.sh"
. "$_GENDEV_TRANSITION_DIR/lifecycle-contract.sh"

GENDEV_TRANSITION_LOCK="docs/project/.gendev-transition.lock"
GENDEV_TRANSITION_JOURNAL=""

gendev_transition_usage_error() {
  printf '%s\n' "$1" >&2
  return 2
}

gendev_transition_require_project() {
  for required in \
    docs/project/project.yaml \
    docs/project/approvals/gate-log.md \
    scripts/check-methodology.sh; do
    if [ ! -f "$required" ]; then
      printf 'Required file missing: %s\n' "$required" >&2
      printf 'Run this from an initialized project root.\n' >&2
      return 1
    fi
  done
}

gendev_transition_gate_profile() {
  gate="$1"
  next_gate=""
  next_artifact=""

  case "$gate" in
    G1) next_gate="G2"; next_artifact="docs/project/prd/prd.md" ;;
    G2) next_gate="G3"; next_artifact="docs/project/architecture/architecture.md" ;;
    G3) next_gate="G4"; next_artifact="docs/project/security-governance/governance-security-spec.md" ;;
    G4) next_gate="G5"; next_artifact="docs/project/build-plan/phase-plan.md" ;;
    G5) next_gate="G6"; next_artifact="docs/project/build-plan/implementation-summary.md" ;;
    G6) next_gate="G7"; next_artifact="docs/project/review/code-review.md" ;;
    G7) next_gate="G8"; next_artifact="docs/project/deployment/deployment-readiness.md" ;;
    G8) next_gate="G9"; next_artifact="none" ;;
    G9)
      printf 'close-gate.sh handles declared outgoing transitions G1 through G8 only; G9 is terminal.\n' >&2
      return 2
      ;;
    *)
      printf 'Unsupported gate: %s\n' "$gate" >&2
      return 2
      ;;
  esac

  expected_command="$(gendev_transition_command "$gate" "$next_gate" 2>/dev/null || true)"
  if [ "$expected_command" != "scripts/close-gate.sh $gate" ]; then
    printf 'Lifecycle contract does not define close-gate transition %s -> %s.\n' "$gate" "$next_gate" >&2
    return 2
  fi

  source_artifact_id="$(gendev_transition_required_artifacts "$gate" "$next_gate" 2>/dev/null | awk '{print $1}')"
  artifact="$(gendev_artifact_path "$source_artifact_id" 2>/dev/null || true)"
  if [ -z "$artifact" ]; then
    printf 'Lifecycle contract does not define a source artifact path for %s -> %s.\n' "$gate" "$next_gate" >&2
    return 2
  fi

  next_role="$(gendev_transition_resulting_role "$gate" "$next_gate" 2>/dev/null || true)"
  if [ -z "$next_role" ]; then
    printf 'Lifecycle contract does not define resulting role for %s -> %s.\n' "$gate" "$next_gate" >&2
    return 2
  fi

  printf '%s|%s|%s|%s\n' "$next_gate" "$artifact" "$next_role" "$next_artifact"
}

gendev_transition_manifest_value() {
  gendev_manifest_section_value docs/project/project.yaml "$1" "$2"
}

gendev_transition_nested_manifest_value() {
  gendev_manifest_nested_value docs/project/project.yaml "$1" "$2" "$3"
}

gendev_transition_load_answers() {
  answers_file="$1"
  decided_by=""
  decided_on="$(gendev_utc_date)"
  checked_statement=""
  risk_disposition="none"
  open_questions="none"
  reviewed_revision=""

  if [ -n "$answers_file" ]; then
    if [ ! -f "$answers_file" ]; then
      printf 'Answers file missing: %s\n' "$answers_file" >&2
      return 1
    fi
    while IFS='=' read -r key value; do
      case "$key" in
        decided_by) decided_by="$value" ;;
        decided_on) decided_on="$value" ;;
        checked_statement) checked_statement="$value" ;;
        risk_disposition) risk_disposition="$value" ;;
        open_questions) open_questions="$value" ;;
        reviewed_revision) reviewed_revision="$value" ;;
      esac
    done < "$answers_file"
  elif [ -t 0 ]; then
    printf 'Approver name: '
    read -r decided_by
    printf 'Decision date [%s]: ' "$decided_on"
    read -r input_decided_on
    [ -z "$input_decided_on" ] || decided_on="$input_decided_on"
    printf 'Checked statement: '
    read -r checked_statement
    printf 'Reviewed revision: '
    read -r reviewed_revision
    printf 'Risk disposition [none]: '
    read -r input_risk
    [ -z "$input_risk" ] || risk_disposition="$input_risk"
    printf 'Open questions [none]: '
    read -r input_questions
    [ -z "$input_questions" ] || open_questions="$input_questions"
  else
    printf 'Noninteractive close requires --answers-file.\n' >&2
    return 1
  fi

  if gendev_is_unknown "$decided_by" || gendev_is_unknown "$checked_statement"; then
    printf 'Approver and checked_statement are required.\n' >&2
    return 1
  fi
  if gendev_is_unknown "$reviewed_revision"; then
    printf 'reviewed_revision is required.\n' >&2
    return 1
  fi
  if ! printf '%s\n' "$decided_on" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
    printf 'Decision date must be YYYY-MM-DD: %s\n' "$decided_on" >&2
    return 1
  fi

  GENDEV_DECIDED_BY="$decided_by"
  GENDEV_DECIDED_ON="$decided_on"
  GENDEV_CHECKED_STATEMENT="$checked_statement"
  GENDEV_RISK_DISPOSITION="$risk_disposition"
  GENDEV_OPEN_QUESTIONS="$open_questions"
  GENDEV_REVIEWED_REVISION="$reviewed_revision"
}

gendev_transition_validate_reviewed_revision() {
  artifact="${1:-}"
  revision="$GENDEV_REVIEWED_REVISION"

  if ! gendev_transition_has_project_git; then
    if [ "$revision" = "WORKTREE" ]; then
      return 0
    fi
    printf 'reviewed_revision requires a Git worktree unless set to WORKTREE for non-Git fixtures.\n' >&2
    return 1
  fi

  if [ "$revision" = "WORKTREE" ]; then
    printf 'reviewed_revision must be a committed Git revision in a Git worktree.\n' >&2
    return 1
  fi

  if ! git rev-parse --verify -q "${revision}^{commit}" >/dev/null 2>&1; then
    printf 'reviewed_revision does not resolve to a commit: %s\n' "$revision" >&2
    return 1
  fi

  if [ -n "$artifact" ]; then
    if ! git cat-file -e "${revision}:${artifact}" 2>/dev/null; then
      printf 'reviewed_revision does not contain artifact path: %s\n' "$artifact" >&2
      return 1
    fi

    reviewed_blob="$(git rev-parse "${revision}:${artifact}")"
    current_blob="$(git hash-object "$artifact")"
    if [ "$reviewed_blob" != "$current_blob" ]; then
      printf 'reviewed_revision blob for %s does not match current pre-transition artifact.\n' "$artifact" >&2
      return 1
    fi
  fi
}

gendev_transition_file_digest() {
  target="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$target" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$target" | awk '{print $1}'
  else
    python3 - "$target" <<'PY'
import hashlib
import sys
with open(sys.argv[1], "rb") as handle:
    print(hashlib.sha256(handle.read()).hexdigest())
PY
  fi
}

gendev_transition_blob_oid() {
  target="$1"
  if gendev_transition_has_project_git; then
    git hash-object "$target"
  else
    gendev_transition_file_digest "$target"
  fi
}

gendev_transition_has_project_git() {
  top_level="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$top_level" ] || return 1
  [ "$(cd "$top_level" && pwd -P)" = "$(pwd -P)" ]
}

gendev_transition_status() {
  sed -n 's/^Status:[[:space:]]*//p' "$1" | head -n 1
}

gendev_transition_expected_source_status() {
  gate="$1"
  case "$gate" in
    G1 | G2 | G3 | G4)
      printf 'Ready for Approval\n'
      ;;
    G5)
      printf 'Accepted\n'
      ;;
    G6 | G7 | G8)
      printf 'Complete\n'
      ;;
    *)
      printf 'Ready for Approval\n'
      ;;
  esac
}

gendev_transition_render_status_acceptance() {
  source="$1"
  destination="$2"
  awk '
    BEGIN { replaced = 0 }
    /^Status:[[:space:]]*/ && replaced == 0 {
      print "Status: Accepted"
      replaced = 1
      next
    }
    { print }
    END { if (replaced == 0) exit 1 }
  ' "$source" > "$destination"
}

gendev_transition_render_manifest() {
  source="$1"
  destination="$2"
  from_gate="$3"
  to_gate="$4"
  next_role="$5"
  next_artifact="$6"
  event_id="$7"

  awk -v from_gate="$from_gate" -v to_gate="$to_gate" -v next_role="$next_role" \
    -v next_artifact="$next_artifact" -v event_id="$event_id" \
    -v decided_by="$GENDEV_DECIDED_BY" -v decided_on="$GENDEV_DECIDED_ON" '
    /^project:/ { in_project = 1; in_collab = 0; in_current_gate = 0; in_latest = 0; print; next }
    /^collaboration:/ { in_project = 0; in_collab = 1; in_current_gate = 0; in_latest = 0; print; next }
    /^approvals:/ { in_project = 0; in_collab = 0; in_approvals = 1; in_current_gate = 0; in_latest = 0; print; next }
    /^[^[:space:]][^:]*:/ && $0 !~ /^project:/ && $0 !~ /^collaboration:/ && $0 !~ /^approvals:/ {
      in_project = 0; in_collab = 0; in_approvals = 0; in_current_gate = 0; in_latest = 0
    }
    in_project && /^  current_gate:/ { print "  current_gate: " to_gate; next }
    in_project && /^  status:/ && to_gate == "G9" { print "  status: closed"; next }
    in_collab && /^  active_role:/ { print "  active_role: " next_role; next }
    in_approvals && /^  current_gate:/ { in_current_gate = 1; in_latest = 0; print; next }
    in_approvals && /^  latest_decision:/ { in_current_gate = 0; in_latest = 1; print; next }
    in_current_gate && /^    gate:/ { print "    gate: " to_gate; next }
    in_current_gate && /^    status:/ { print "    status: pending"; next }
    in_current_gate && /^    approved_by:/ { print "    approved_by: TBD"; next }
    in_current_gate && /^    approved_on:/ { print "    approved_on: TBD"; next }
    in_current_gate && /^    next_gate:/ {
      if (to_gate == "G9") print "    next_gate: none"
      else print "    next_gate: " next_successor(to_gate)
      next
    }
    in_current_gate && /^    next_role:/ { print "    next_role: " next_role; next }
    in_current_gate && /^    next_artifact:/ { print "    next_artifact: " next_artifact; next }
    in_latest && /^    decision:/ { print "    decision: approved"; next }
    in_latest && /^    decided_by:/ { print "    decided_by: " decided_by; next }
    in_latest && /^    decided_on:/ { print "    decided_on: " decided_on; next }
    in_latest && /^    record:/ { print "    record: docs/project/approvals/gate-log.md#" event_id; next }
    { print }
    function next_successor(gate) {
      if (gate == "G1") return "G2"
      if (gate == "G2") return "G3"
      if (gate == "G3") return "G4"
      if (gate == "G4") return "G5"
      if (gate == "G5") return "G6"
      if (gate == "G6") return "G7"
      if (gate == "G7") return "G8"
      if (gate == "G8") return "G9"
      return "none"
    }
  ' "$source" > "$destination"
}

gendev_transition_remove_sentinel() {
  source="$1"
  destination="$2"
  sed '/^No gate approvals recorded yet\.$/d' "$source" > "$destination"
}

gendev_transition_append_gate_event() {
  log="$1"
  from_gate="$2"
  to_gate="$3"
  artifact="$4"
  event_id="$5"
  reviewed_revision="$6"
  reviewed_blob="$7"
  reviewed_digest="$8"
  resulting_blob="$9"
  resulting_digest="${10}"
  category="${11}"
  evidence_status="Accepted"
  if [ "$category" = "complete_report_unchanged" ]; then
    evidence_status="Complete"
  fi

  {
    printf '\n### Gate Event: %s -> %s\n\n' "$from_gate" "$to_gate"
    printf '```yaml\n'
    printf 'event_id: %s\n' "$event_id"
    printf 'schema_version: 2\n'
    printf 'event_type: gate_transition\n'
    printf 'from_gate: %s\n' "$from_gate"
    printf 'to_gate: %s\n' "$to_gate"
    printf 'decision: approved\n'
    printf 'decided_by: %s\n' "$(gendev_yaml_scalar_escape "$GENDEV_DECIDED_BY")"
    printf 'decided_on: %s\n' "$GENDEV_DECIDED_ON"
    printf 'status: approved\n'
    printf 'checked: "%s"\n' "$(gendev_yaml_scalar_escape "$GENDEV_CHECKED_STATEMENT")"
    if [ "$to_gate" = "G9" ]; then
      printf 'terminal_closeout: true\n'
    fi
    printf 'risk_disposition: "%s"\n' "$(gendev_yaml_scalar_escape "$GENDEV_RISK_DISPOSITION")"
    printf 'open_questions: "%s"\n' "$(gendev_yaml_scalar_escape "$GENDEV_OPEN_QUESTIONS")"
    printf 'evidence:\n'
    printf '  - artifact_id: %s\n' "$(basename "$artifact" .md | sed 's/-/_/g')"
    printf '    artifact_path: %s\n' "$artifact"
    printf '    category: %s\n' "$category"
    printf '    reviewed_revision: %s\n' "$reviewed_revision"
    printf '    reviewed_blob_oid: %s\n' "$reviewed_blob"
    printf '    reviewed_digest: %s\n' "$reviewed_digest"
    printf '    resulting_blob_oid: %s\n' "$resulting_blob"
    printf '    resulting_digest: %s\n' "$resulting_digest"
    printf '    status: %s\n' "$evidence_status"
    if [ "$category" = "accepted_authority_unchanged" ]; then
      printf '    originating_event_id: ORIGIN-%s\n' "$event_id"
    fi
    printf 'verification_evidence:\n'
    printf '  - command: ./scripts/check-methodology.sh\n'
    printf '    result: pending_postwrite\n'
    printf '```\n'
  } >> "$log"
}

gendev_transition_acquire_lock() {
  if ! mkdir "$GENDEV_TRANSITION_LOCK" 2>/dev/null; then
    printf 'Transition lock already exists: %s\n' "$GENDEV_TRANSITION_LOCK" >&2
    return 1
  fi
  GENDEV_TRANSITION_JOURNAL="$GENDEV_TRANSITION_LOCK/recovery-journal.txt"
  : > "$GENDEV_TRANSITION_JOURNAL"
}

gendev_transition_release_lock() {
  if [ -n "$GENDEV_TRANSITION_LOCK" ] && [ -d "$GENDEV_TRANSITION_LOCK" ]; then
    rm -rf "$GENDEV_TRANSITION_LOCK"
  fi
}

gendev_transition_backup_file() {
  source="$1"
  backup="$GENDEV_TRANSITION_LOCK/$(printf '%s' "$source" | sed 's#[/.]#_#g').bak"
  cp "$source" "$backup"
  printf '%s|%s\n' "$source" "$backup" >> "$GENDEV_TRANSITION_JOURNAL"
}

gendev_transition_rollback() {
  if [ -f "$GENDEV_TRANSITION_JOURNAL" ]; then
    while IFS='|' read -r target backup; do
      [ -n "$target" ] || continue
      if [ -f "$backup" ]; then
        cp "$backup" "$target"
      fi
    done < "$GENDEV_TRANSITION_JOURNAL"
  fi
  gendev_transition_release_lock
}

gendev_transition_install() {
  artifact="$1"
  artifact_candidate="$2"
  manifest_candidate="$3"
  log_candidate="$4"

  gendev_transition_acquire_lock || return 1
  trap 'gendev_transition_rollback' INT TERM HUP
  gendev_transition_backup_file "$artifact"
  gendev_transition_backup_file "docs/project/project.yaml"
  gendev_transition_backup_file "docs/project/approvals/gate-log.md"

  cp "$artifact_candidate" "$artifact" &&
    cp "$manifest_candidate" docs/project/project.yaml &&
    cp "$log_candidate" docs/project/approvals/gate-log.md || {
      gendev_transition_rollback
      return 1
    }

  if ! ./scripts/check-methodology.sh >/tmp/gendev-close-gate-check.$$ 2>&1; then
    cat /tmp/gendev-close-gate-check.$$ >&2
    rm -f /tmp/gendev-close-gate-check.$$
    gendev_transition_rollback
    return 1
  fi
  rm -f /tmp/gendev-close-gate-check.$$

  trap - INT TERM HUP
  gendev_transition_release_lock
}

gendev_transition_install_from_map() {
  map_file="$1"

  gendev_transition_acquire_lock || return 1
  trap 'gendev_transition_rollback' INT TERM HUP

  while IFS='|' read -r target candidate; do
    [ -n "$target" ] || continue
    if [ ! -f "$target" ] || [ ! -f "$candidate" ]; then
      printf 'Transition candidate is missing target or candidate: %s\n' "$target" >&2
      gendev_transition_rollback
      return 1
    fi
    gendev_transition_backup_file "$target"
  done < "$map_file"

  while IFS='|' read -r target candidate; do
    [ -n "$target" ] || continue
    cp "$candidate" "$target" || {
      gendev_transition_rollback
      return 1
    }
  done < "$map_file"

  if ! ./scripts/check-methodology.sh >/tmp/gendev-transition-check.$$ 2>&1; then
    cat /tmp/gendev-transition-check.$$ >&2
    rm -f /tmp/gendev-transition-check.$$
    gendev_transition_rollback
    return 1
  fi
  rm -f /tmp/gendev-transition-check.$$

  trap - INT TERM HUP
  gendev_transition_release_lock
}

gendev_transition_render_phase_manifest() {
  source="$1"
  destination="$2"
  position="$3"
  phase_id="$4"
  phase_status="$5"

  awk -v position="$position" -v phase_id="$phase_id" -v phase_status="$phase_status" '
    function trim(value) {
      gsub(/^[[:space:]]+/, "", value)
      gsub(/[[:space:]]+$/, "", value)
      gsub(/^"|"$/, "", value)
      return value
    }
    /^phase:/ { in_phase = 1; print; next }
    in_phase && /^[^[:space:]][^:]*:/ { in_phase = 0; current_phase = ""; print; next }
    in_phase && /^  phase_position:/ {
      print "  phase_position: " position
      next
    }
    in_phase && /^  current_phase_id:/ {
      if (phase_id == "") print "  current_phase_id: null"
      else print "  current_phase_id: " phase_id
      next
    }
    in_phase && /^[[:space:]]{4}-[[:space:]]+id:/ {
      line = $0
      sub(/^.*id:[[:space:]]*/, "", line)
      current_phase = trim(line)
      print
      next
    }
    in_phase && current_phase == phase_id && /^[[:space:]]{6}status:/ && phase_status != "" {
      print "      status: " phase_status
      next
    }
    { print }
  ' "$source" > "$destination"
}

gendev_transition_append_phase_checkpoint_event() {
  log="$1"
  position="$2"
  phase_id="$3"
  event_id="$4"

  {
    printf '\n### Phase Checkpoint: %s\n\n' "$position"
    printf '```yaml\n'
    printf 'event_id: %s\n' "$event_id"
    printf 'schema_version: 2\n'
    printf 'event_type: phase_checkpoint\n'
    printf 'position: %s\n' "$position"
    if [ -n "$phase_id" ]; then
      printf 'phase_id: "%s"\n' "$phase_id"
    fi
    printf 'decision: accepted\n'
    printf 'decided_by: %s\n' "$(gendev_yaml_scalar_escape "$GENDEV_DECIDED_BY")"
    printf 'decided_on: %s\n' "$GENDEV_DECIDED_ON"
    printf 'checked: "%s"\n' "$(gendev_yaml_scalar_escape "$GENDEV_CHECKED_STATEMENT")"
    printf '```\n'
  } >> "$log"
}

gendev_transition_append_phase_exit_event() {
  log="$1"
  phase_id="$2"
  event_id="$3"

  {
    printf '\n### Phase Transition: G5.%s.4\n\n' "$phase_id"
    printf '```yaml\n'
    printf 'event_id: %s\n' "$event_id"
    printf 'schema_version: 2\n'
    printf 'event_type: phase_transition\n'
    printf 'position: G5.%s.4\n' "$phase_id"
    printf 'phase_id: "%s"\n' "$phase_id"
    printf 'decision: exited\n'
    printf 'decided_by: %s\n' "$(gendev_yaml_scalar_escape "$GENDEV_DECIDED_BY")"
    printf 'decided_on: %s\n' "$GENDEV_DECIDED_ON"
    printf 'status: exited\n'
    printf 'checked: "%s"\n' "$(gendev_yaml_scalar_escape "$GENDEV_CHECKED_STATEMENT")"
    printf 'exit_test:\n'
    printf '  path: docs/project/testing/phase-%s-test-uat-plan.md\n' "$phase_id"
    printf '  result: passed\n'
    printf 'regression_suite:\n'
    printf '  result: green\n'
    printf 'learnings: docs/project/build-plan/phases/phase-%s-learnings.md\n' "$phase_id"
    printf '```\n'
  } >> "$log"
}

gendev_transition_append_deployment_approval_event() {
  log="$1"
  event_id="$2"
  artifact="$3"
  reviewed_revision="$4"
  reviewed_blob="$5"
  reviewed_digest="$6"
  resulting_blob="$7"
  resulting_digest="$8"

  {
    printf '\n### Deployment Approval: G8\n\n'
    printf '```yaml\n'
    printf 'event_id: %s\n' "$event_id"
    printf 'schema_version: 2\n'
    printf 'event_type: deployment_approval\n'
    printf 'gate: G8\n'
    printf 'decision: approved\n'
    printf 'approved_by: %s\n' "$(gendev_yaml_scalar_escape "$GENDEV_DECIDED_BY")"
    printf 'approved_on: %s\n' "$GENDEV_DECIDED_ON"
    printf 'status: approved\n'
    printf 'checked: "%s"\n' "$(gendev_yaml_scalar_escape "$GENDEV_CHECKED_STATEMENT")"
    printf 'deployment_disposition: approved\n'
    printf 'production_action_performed: false\n'
    printf 'evidence:\n'
    printf '  - artifact_id: deployment_readiness\n'
    printf '    artifact_path: %s\n' "$artifact"
    printf '    category: new_acceptance_status_only\n'
    printf '    reviewed_revision: %s\n' "$reviewed_revision"
    printf '    reviewed_blob_oid: %s\n' "$reviewed_blob"
    printf '    reviewed_digest: %s\n' "$reviewed_digest"
    printf '    resulting_blob_oid: %s\n' "$resulting_blob"
    printf '    resulting_digest: %s\n' "$resulting_digest"
    printf '    status: Accepted\n'
    printf '```\n'
  } >> "$log"
}

gendev_transition_phase_id_from_position() {
  position="$1"
  case "$position" in
    G5.0) printf '\n' ;;
    G5.*.[123])
      value="${position#G5.}"
      printf '%s\n' "${value%.*}"
      ;;
    *) return 1 ;;
  esac
}

gendev_record_phase_checkpoint() {
  position="$1"
  dry_run="$2"
  answers_file="$3"

  gendev_transition_require_project || return 1
  project_gate="$(gendev_transition_manifest_value project current_gate)"
  if [ "$project_gate" != "G5" ]; then
    printf 'Phase checkpoints require project.current_gate G5; actual: %s\n' "$project_gate" >&2
    return 1
  fi
  phase_id="$(gendev_transition_phase_id_from_position "$position")" || {
    printf 'Unsupported phase checkpoint: %s\n' "$position" >&2
    return 2
  }
  gendev_transition_load_answers "$answers_file" || return 1
  gendev_transition_validate_reviewed_revision || return 1

  event_id="EV-$(date -u +%Y%m%dT%H%M%SZ)-${position}"
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/gendev-phase-checkpoint.XXXXXX")"
  manifest_candidate="$tmp_dir/project.yaml"
  log_candidate="$tmp_dir/gate-log.md"
  map_file="$tmp_dir/map"
  phase_status=""
  [ -n "$phase_id" ] && phase_status="in_progress"

  gendev_transition_render_phase_manifest docs/project/project.yaml "$manifest_candidate" "$position" "$phase_id" "$phase_status"
  gendev_transition_remove_sentinel docs/project/approvals/gate-log.md "$log_candidate"
  gendev_transition_append_phase_checkpoint_event "$log_candidate" "$position" "$phase_id" "$event_id"

  if [ "$dry_run" -eq 1 ]; then
    printf 'DRY RUN: would record phase checkpoint %s\n' "$position"
    rm -rf "$tmp_dir"
    return 0
  fi

  {
    printf 'docs/project/project.yaml|%s\n' "$manifest_candidate"
    printf 'docs/project/approvals/gate-log.md|%s\n' "$log_candidate"
  } > "$map_file"

  if gendev_transition_install_from_map "$map_file"; then
    printf 'Recorded phase checkpoint %s.\n' "$position"
    printf 'event_id: %s\n' "$event_id"
    rm -rf "$tmp_dir"
    return 0
  fi
  rm -rf "$tmp_dir"
  return 1
}

gendev_close_phase() {
  phase_id="$1"
  dry_run="$2"
  answers_file="$3"

  gendev_transition_require_project || return 1
  project_gate="$(gendev_transition_manifest_value project current_gate)"
  if [ "$project_gate" != "G5" ]; then
    printf 'Phase close requires project.current_gate G5; actual: %s\n' "$project_gate" >&2
    return 1
  fi
  gendev_transition_load_answers "$answers_file" || return 1
  gendev_transition_validate_reviewed_revision || return 1

  event_id="EV-$(date -u +%Y%m%dT%H%M%SZ)-G5-${phase_id}-4"
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/gendev-close-phase.XXXXXX")"
  manifest_candidate="$tmp_dir/project.yaml"
  log_candidate="$tmp_dir/gate-log.md"
  map_file="$tmp_dir/map"

  gendev_transition_render_phase_manifest docs/project/project.yaml "$manifest_candidate" "G5.${phase_id}.4" "$phase_id" "exited"
  gendev_transition_remove_sentinel docs/project/approvals/gate-log.md "$log_candidate"
  gendev_transition_append_phase_exit_event "$log_candidate" "$phase_id" "$event_id"

  if [ "$dry_run" -eq 1 ]; then
    printf 'DRY RUN: would close phase %s at G5.%s.4\n' "$phase_id" "$phase_id"
    rm -rf "$tmp_dir"
    return 0
  fi

  {
    printf 'docs/project/project.yaml|%s\n' "$manifest_candidate"
    printf 'docs/project/approvals/gate-log.md|%s\n' "$log_candidate"
  } > "$map_file"

  if gendev_transition_install_from_map "$map_file"; then
    printf 'Closed phase %s at G5.%s.4.\n' "$phase_id" "$phase_id"
    printf 'event_id: %s\n' "$event_id"
    rm -rf "$tmp_dir"
    return 0
  fi
  rm -rf "$tmp_dir"
  return 1
}

gendev_record_deployment_approval() {
  dry_run="$1"
  answers_file="$2"
  artifact="docs/project/deployment/deployment-readiness.md"

  gendev_transition_require_project || return 1
  project_gate="$(gendev_transition_manifest_value project current_gate)"
  if [ "$project_gate" != "G8" ]; then
    printf 'Deployment approval requires project.current_gate G8; actual: %s\n' "$project_gate" >&2
    return 1
  fi
  [ -f "$artifact" ] || {
    printf 'Required file missing: %s\n' "$artifact" >&2
    return 1
  }
  status="$(gendev_transition_status "$artifact")"
  if [ "$status" != "Ready for Approval" ]; then
    printf 'Deployment readiness must be Ready for Approval; actual: %s\n' "${status:-missing}" >&2
    return 1
  fi
  gendev_transition_load_answers "$answers_file" || return 1
  gendev_transition_validate_reviewed_revision "$artifact" || return 1

  reviewed_revision="$GENDEV_REVIEWED_REVISION"
  event_id="EV-$(date -u +%Y%m%dT%H%M%SZ)-G8-deployment-approval"
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/gendev-deployment-approval.XXXXXX")"
  readiness_candidate="$tmp_dir/deployment-readiness.md"
  log_candidate="$tmp_dir/gate-log.md"
  map_file="$tmp_dir/map"

  reviewed_blob="$(gendev_transition_blob_oid "$artifact")"
  reviewed_digest="$(gendev_transition_file_digest "$artifact")"
  gendev_transition_render_status_acceptance "$artifact" "$readiness_candidate" || {
    rm -rf "$tmp_dir"
    printf 'Could not render Accepted deployment readiness candidate.\n' >&2
    return 1
  }
  resulting_blob="$(gendev_transition_blob_oid "$readiness_candidate")"
  resulting_digest="$(gendev_transition_file_digest "$readiness_candidate")"
  gendev_transition_remove_sentinel docs/project/approvals/gate-log.md "$log_candidate"
  gendev_transition_append_deployment_approval_event "$log_candidate" "$event_id" "$artifact" \
    "$reviewed_revision" "$reviewed_blob" "$reviewed_digest" "$resulting_blob" "$resulting_digest"

  if [ "$dry_run" -eq 1 ]; then
    printf 'DRY RUN: would record deployment_approval at G8 without changing project.current_gate.\n'
    rm -rf "$tmp_dir"
    return 0
  fi

  {
    printf '%s|%s\n' "$artifact" "$readiness_candidate"
    printf 'docs/project/approvals/gate-log.md|%s\n' "$log_candidate"
  } > "$map_file"

  if gendev_transition_install_from_map "$map_file"; then
    printf 'Recorded deployment_approval at G8.\n'
    printf 'event_id: %s\n' "$event_id"
    rm -rf "$tmp_dir"
    return 0
  fi
  rm -rf "$tmp_dir"
  return 1
}

gendev_close_major_gate() {
  gate="$1"
  dry_run="$2"
  answers_file="$3"

  gendev_transition_require_project || return 1

  profile="$(gendev_transition_gate_profile "$gate")" || return $?
  next_gate="$(printf '%s\n' "$profile" | awk -F'|' '{print $1}')"
  artifact="$(printf '%s\n' "$profile" | awk -F'|' '{print $2}')"
  next_role="$(printf '%s\n' "$profile" | awk -F'|' '{print $3}')"
  next_artifact="$(printf '%s\n' "$profile" | awk -F'|' '{print $4}')"

  [ -f "$artifact" ] || {
    printf 'Required file missing: %s\n' "$artifact" >&2
    return 1
  }

  project_gate="$(gendev_transition_manifest_value project current_gate)"
  approval_gate="$(gendev_transition_nested_manifest_value approvals current_gate gate)"
  if [ "$project_gate" != "$gate" ] || [ "$approval_gate" != "$gate" ]; then
    printf 'Manifest is positioned at project.current_gate=%s approvals.current_gate.gate=%s, not %s.\n' \
      "$project_gate" "$approval_gate" "$gate" >&2
    return 1
  fi

  artifact_status="$(gendev_transition_status "$artifact")"
  expected_status="$(gendev_transition_expected_source_status "$gate")"
  if [ "$artifact_status" != "$expected_status" ]; then
    printf 'Artifact %s must be %s before closing %s; actual: %s\n' \
      "$artifact" "$expected_status" "$gate" "${artifact_status:-missing}" >&2
    return 1
  fi

  gendev_transition_load_answers "$answers_file" || return 1
  gendev_transition_validate_reviewed_revision "$artifact" || return 1

  reviewed_revision="$GENDEV_REVIEWED_REVISION"

  event_id="EV-$(date -u +%Y%m%dT%H%M%SZ)-${gate}-${next_gate}"
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/gendev-close-gate.XXXXXX")"
  artifact_candidate="$tmp_dir/artifact"
  manifest_candidate="$tmp_dir/project.yaml"
  log_candidate="$tmp_dir/gate-log.md"

  reviewed_blob="$(gendev_transition_blob_oid "$artifact")"
  reviewed_digest="$(gendev_transition_file_digest "$artifact")"

  case "$artifact_status" in
    "Ready for Approval")
      gendev_transition_render_status_acceptance "$artifact" "$artifact_candidate" || {
        rm -rf "$tmp_dir"
        printf 'Could not render accepted artifact candidate for %s.\n' "$artifact" >&2
        return 1
      }
      category="new_acceptance_status_only"
      ;;
    "Complete")
      cp "$artifact" "$artifact_candidate"
      category="complete_report_unchanged"
      ;;
    *)
      cp "$artifact" "$artifact_candidate"
      category="accepted_authority_unchanged"
      ;;
  esac

  resulting_blob="$(gendev_transition_blob_oid "$artifact_candidate")"
  resulting_digest="$(gendev_transition_file_digest "$artifact_candidate")"
  gendev_transition_render_manifest docs/project/project.yaml "$manifest_candidate" \
    "$gate" "$next_gate" "$next_role" "$next_artifact" "$event_id"
  gendev_transition_remove_sentinel docs/project/approvals/gate-log.md "$log_candidate"
  gendev_transition_append_gate_event "$log_candidate" "$gate" "$next_gate" "$artifact" \
    "$event_id" "$reviewed_revision" "$reviewed_blob" "$reviewed_digest" \
    "$resulting_blob" "$resulting_digest" "$category"

  if [ "$dry_run" -eq 1 ]; then
    printf 'DRY RUN: would close %s -> %s\n' "$gate" "$next_gate"
    printf 'event_id: %s\n' "$event_id"
    printf 'artifact: %s\n' "$artifact"
    rm -rf "$tmp_dir"
    return 0
  fi

  if gendev_transition_install "$artifact" "$artifact_candidate" "$manifest_candidate" "$log_candidate"; then
    printf '%s closed to %s.\n' "$gate" "$next_gate"
    printf 'event_id: %s\n' "$event_id"
    printf 'changed: %s docs/project/project.yaml docs/project/approvals/gate-log.md\n' "$artifact"
    rm -rf "$tmp_dir"
    return 0
  fi

  rm -rf "$tmp_dir"
  return 1
}
