#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -u

GENDEV_COMMON_DIR="$(cd "$(dirname "$0")/lib" && pwd)"
. "$GENDEV_COMMON_DIR/gendev-common.sh"
. "$GENDEV_COMMON_DIR/lifecycle-contract.sh"

errors=0
warnings=0
seen_failures=""
GENDEV_GATE_LOG_EVENTS_FILE=""
GENDEV_GATE_LOG_EVENTS_OUTPUT=""
GENDEV_GATE_LOG_EVENTS_RC=0

info() {
  printf 'INFO: %s\n' "$1"
}

diagnostic_quote() {
  printf '%s' "$1" | sed 's/"/'\''/g'
}

diagnostic_emit() {
  severity="$1"
  message="$2"
  code="GENDEV-CHECK-000"
  file="unknown"
  line="unknown"
  event_id="unknown"
  expected="methodology invariant holds"
  actual="$message"

  case "$message" in
    "Manifest declares methodology_version 1.0.0 but gate-log contains structured events without event_id and schema_version: 2."*)
      code="GENDEV-COMPAT-001"
      file="docs/project/approvals/gate-log.md"
      expected="all 1.0 structured events have event_id and schema_version 2"
      actual="one or more structured events are missing event_id or schema_version 2"
      ;;
    "Manifest legacy migration mode is active, but gate-log contains structured events without event_id and schema_version: 2."*)
      code="GENDEV-COMPAT-002"
      file="docs/project/approvals/gate-log.md"
      expected="legacy migration events have event_id and schema_version 2"
      actual="one or more structured events are missing event_id or schema_version 2"
      ;;
    "Manifest legacy migration mode requires migration.approved_by."*)
      code="GENDEV-COMPAT-003"
      file="docs/project/project.yaml"
      expected="migration.approved_by is a named human"
      actual="missing or unknown"
      ;;
    "Manifest legacy migration mode requires migration.approved_on."*)
      code="GENDEV-COMPAT-004"
      file="docs/project/project.yaml"
      expected="migration.approved_on is set"
      actual="missing or unknown"
      ;;
    "Manifest attested enforcement is missing attestation cadence."*)
      code="GENDEV-MANIFEST-ENFORCEMENT-001"
      file="docs/project/project.yaml"
      expected="enforcement.attested.cadence is set"
      actual="missing or unknown"
      ;;
    "Manifest attested enforcement is missing required_attester field."*)
      code="GENDEV-MANIFEST-ENFORCEMENT-002"
      file="docs/project/project.yaml"
      expected="enforcement.attested.required_attester is a named human"
      actual="missing or unknown"
      ;;
    "Project current_gate "*" differs from approvals.current_gate.gate "*)
      code="GENDEV-MANIFEST-APPROVAL-001"
      file="docs/project/project.yaml"
      expected="project.current_gate equals approvals.current_gate.gate"
      actual="$message"
      ;;
    "Gate is approved but approved_on is not an ISO date: "*)
      code="GENDEV-MANIFEST-APPROVAL-002"
      file="docs/project/project.yaml"
      expected="approvals.current_gate.approved_on is YYYY-MM-DD"
      actual="${message##*: }"
      ;;
    "Gate is approved but approved_by is not set."*)
      code="GENDEV-MANIFEST-APPROVAL-003"
      file="docs/project/project.yaml"
      expected="approvals.current_gate.approved_by is set"
      actual="missing or unknown"
      ;;
    "Gate is approved but evidence is missing."*)
      code="GENDEV-MANIFEST-APPROVAL-004"
      file="docs/project/project.yaml"
      expected="approvals.current_gate.evidence contains at least one path"
      actual="missing or unknown"
      ;;
    *" is a C1 PRD but contains no concrete observable acceptance criteria."*)
      code="GENDEV-G2-OBSERVABLE-001"
      file="${message%% *}"
      expected="C1 PRD has concrete observable acceptance criteria"
      actual="missing"
      ;;
    *" is a C2/C3 PRD but contains no concrete EARS-form acceptance criteria "*)
      code="GENDEV-G2-EARS-001"
      file="${message%% *}"
      expected="C2/C3 PRD has concrete EARS-form acceptance criteria"
      actual="missing"
      ;;
    *" has no concrete unwanted-behavior acceptance criteria."*)
      code="GENDEV-G2-UNWANTED-001"
      file="${message%% *}"
      expected="PRD includes all-class unwanted-behavior If/then criteria"
      actual="missing"
      ;;
    *" is missing the required Verification Specification section (G3)."*)
      code="GENDEV-G3-VERIFICATION-001"
      file="${message%% *}"
      expected="architecture contains Verification Specification section"
      actual="missing"
      ;;
    *" Verification Specification is not human-approved "*)
      code="GENDEV-G3-VERIFICATION-002"
      file="${message%% *}"
      expected="Verification Specification has non-placeholder Approved by and Approved on"
      actual="missing or unknown"
      ;;
    *" Verification Specification does not trace to G2 criteria."*)
      code="GENDEV-G3-TRACE-001"
      file="${message%% *}"
      expected="Verification Specification maps REQ IDs to Behavioral, Design, Implementation, and UAT checks"
      actual="missing"
      ;;
    *" is missing recorded design-verification interrogation answers."*)
      code="GENDEV-G3-INTERROGATION-001"
      file="${message%% *}"
      expected="architecture records design-verification interrogation answers"
      actual="missing"
      ;;
    "Gate-log evidence item "*" is missing required field: "*)
      code="GENDEV-EVIDENCE-ITEM-001"
      file="docs/project/approvals/gate-log.md"
      event_id="$(printf '%s\n' "$message" | sed -n 's/^Gate-log evidence item in \([^ ]*\) .*/\1/p')"
      expected="${message##*: }"
      actual="missing"
      ;;
    "Gate-log evidence item "*" has invalid evidence category: "*)
      code="GENDEV-EVIDENCE-ITEM-002"
      file="docs/project/approvals/gate-log.md"
      event_id="$(printf '%s\n' "$message" | sed -n 's/^Gate-log evidence item in \([^ ]*\) .*/\1/p')"
      expected="new_acceptance_status_only, complete_report_unchanged, or accepted_authority_unchanged"
      actual="${message##*: }"
      ;;
    "Gate-log evidence item "*" has invalid reviewed revision: "*)
      code="GENDEV-EVIDENCE-ITEM-003"
      file="docs/project/approvals/gate-log.md"
      event_id="$(printf '%s\n' "$message" | sed -n 's/^Gate-log evidence item in \([^ ]*\) .*/\1/p')"
      expected="non-placeholder Git revision token"
      actual="${message##*: }"
      ;;
    "Gate-log evidence item "*" has invalid blob OID in "*)
      code="GENDEV-EVIDENCE-ITEM-004"
      file="docs/project/approvals/gate-log.md"
      event_id="$(printf '%s\n' "$message" | sed -n 's/^Gate-log evidence item in \([^ ]*\) .*/\1/p')"
      expected="40- or 64-hex Git blob OID"
      actual="$message"
      ;;
    "Gate-log evidence item "*" has invalid sha256 digest in "*)
      code="GENDEV-EVIDENCE-ITEM-005"
      file="docs/project/approvals/gate-log.md"
      event_id="$(printf '%s\n' "$message" | sed -n 's/^Gate-log evidence item in \([^ ]*\) .*/\1/p')"
      expected="64-hex SHA-256 digest"
      actual="$message"
      ;;
    "Gate-log evidence item "*" category complete_report_unchanged requires reviewed and resulting blobs/digests to match."*)
      code="GENDEV-EVIDENCE-ITEM-006"
      file="docs/project/approvals/gate-log.md"
      event_id="$(printf '%s\n' "$message" | sed -n 's/^Gate-log evidence item in \([^ ]*\) .*/\1/p')"
      expected="reviewed/resulting blob OIDs and digests match"
      actual="mismatch"
      ;;
    "Gate-log evidence item "*" category accepted_authority_unchanged requires reviewed and resulting blobs/digests to match."*)
      code="GENDEV-EVIDENCE-ITEM-007"
      file="docs/project/approvals/gate-log.md"
      event_id="$(printf '%s\n' "$message" | sed -n 's/^Gate-log evidence item in \([^ ]*\) .*/\1/p')"
      expected="reviewed/resulting blob OIDs and digests match"
      actual="mismatch"
      ;;
    "Gate-log evidence item "*" category accepted_authority_unchanged requires originating_event_id."*)
      code="GENDEV-EVIDENCE-ITEM-008"
      file="docs/project/approvals/gate-log.md"
      event_id="$(printf '%s\n' "$message" | sed -n 's/^Gate-log evidence item in \([^ ]*\) .*/\1/p')"
      expected="originating_event_id"
      actual="missing"
      ;;
    "Late gate "*" requires artifact "*" with status "*)
      code="GENDEV-LATE-GATE-ARTIFACT-001"
      file="$(printf '%s\n' "$message" | sed -n "s/^Late gate [^ ]* requires artifact '\([^']*\)'.*/\1/p")"
      expected="$(printf '%s\n' "$message" | sed -n "s/.* with status \(.*\); actual:.*/\1/p")"
      actual="${message##*actual: }"
      ;;
    "G8 deployment readiness is Accepted but no structured deployment_approval event exists in gate-log.md."*)
      code="GENDEV-G8-DEPLOYMENT-001"
      file="docs/project/approvals/gate-log.md"
      expected="structured deployment_approval event"
      actual="missing"
      ;;
    "G9 close-out requires project.status closed."*)
      code="GENDEV-G9-TERMINAL-001"
      file="docs/project/project.yaml"
      expected="project.status closed"
      actual="not closed"
      ;;
    "G9 close-out requires active_role none."*)
      code="GENDEV-G9-TERMINAL-002"
      file="docs/project/project.yaml"
      expected="project.active_role none"
      actual="not none"
      ;;
    "G9 close-out requires a terminal G8 -> G9 gate_transition event."*)
      code="GENDEV-G9-TERMINAL-003"
      file="docs/project/approvals/gate-log.md"
      expected="terminal_closeout G8 -> G9 gate_transition"
      actual="missing"
      ;;
    "G9 close-out requires value-review disposition complete, not_due, or not_applicable."*)
      code="GENDEV-G9-VALUE-001"
      file="docs/project/as-built/value-review.md"
      expected="value_review.disposition complete, not_due, or not_applicable"
      actual="missing or invalid"
      ;;
    "Accepted artifact exists but no complete durable approval event is visible for gate "*)
      code="GENDEV-APPROVAL-EVENT-001"
      file="docs/project/approvals/gate-log.md"
      expected="complete durable approval event for accepted artifact gate"
      actual="missing"
      ;;
    "G6+ structured gate transition is missing executable or verification evidence."*)
      code="GENDEV-GATELOG-EVIDENCE-001"
      file="docs/project/approvals/gate-log.md"
      expected="G6+ gate_transition includes verification_evidence"
      actual="missing"
      ;;
    "Phase "*" is marked exited but no complete G5."*)
      code="GENDEV-PHASE-EXIT-001"
      file="docs/project/approvals/gate-log.md"
      expected="complete G5.<id>.4 phase_transition event"
      actual="missing"
      ;;
    "Project current_gate is G6 but not every declared phase has exited."* | \
    "Project current_gate is G7 but not every declared phase has exited."* | \
    "Project current_gate is G8 but not every declared phase has exited."* | \
    "Project current_gate is G9 but not every declared phase has exited."*)
      code="GENDEV-PHASE-EXIT-002"
      file="docs/project/project.yaml"
      expected="all declared phases have status exited before G6+"
      actual="$message"
      ;;
    "Manifest phase.phase_position is "*" but prior phase "*" has not exited."*)
      code="GENDEV-PHASE-ORDER-001"
      file="docs/project/project.yaml"
      expected="prior phase status exited before later phase checkpoint"
      actual="$message"
      ;;
    *"references undeclared tactical task ID: "*)
      code="GENDEV-TACTICAL-REF-001"
      file="${message%% *}"
      expected="referenced tactical task ID is declared in the Accepted tactical plan"
      actual="${message##*: }"
      ;;
    *"references tactical task ID not declared in an Accepted tactical plan: "*)
      code="GENDEV-TRACE-TASK-001"
      file="${message%%:*}"
      line="${message#*:}"
      line="${line%% *}"
      expected="traceability tactical task resolves to an Accepted tactical plan task"
      actual="${message##*: }"
      ;;
    "Accepted/complete document still has placeholders: "*)
      code="GENDEV-PLACEHOLDER-001"
      file="${message##*: }"
      expected="Accepted or Complete document contains no template placeholders"
      actual="placeholder token present"
      ;;
    "Malformed structured"*gate-log* | "Malformed structured event record in "*)
      code="GENDEV-GATELOG-PARSE-001"
      file="docs/project/approvals/gate-log.md"
      expected="restricted schema-2 structured event block"
      actual="parse failure"
      ;;
  esac

  printf '%s [%s] file=%s line=%s event_id=%s expected="%s" actual="%s" message="%s"\n' \
    "$severity" \
    "$code" \
    "$file" \
    "$line" \
    "$event_id" \
    "$(diagnostic_quote "$expected")" \
    "$(diagnostic_quote "$actual")" \
    "$(diagnostic_quote "$message")"
}

warn() {
  warnings=$((warnings + 1))
  diagnostic_emit "WARN:" "$1"
}

fail() {
  errors=$((errors + 1))
  diagnostic_emit "ERROR:" "$1"
}

fail_once() {
  message="$1"

  if printf '%s\n' "$seen_failures" | grep -Fxq "$message"; then
    return
  fi

  seen_failures="${seen_failures}${message}
"
  fail "$message"
}

require_file() {
  if [ ! -f "$1" ]; then
    fail_once "Missing required file: $1"
  fi
}

require_dir() {
  if [ ! -d "$1" ]; then
    fail_once "Missing required directory: $1"
  fi
}

is_unknown() {
  case "$1" in
    "" | "TBD" | "\"TBD\"" | "[]" | "[TBD]" | "[Project Name]" | "[project-slug]")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

valid_gate_value() {
  case "$1" in
    G0 | G1 | G2 | G3 | G4 | G5 | G6 | G7 | G8 | G9)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

gate_number() {
  printf '%s\n' "$1" | sed 's/^G//'
}

valid_gate_status() {
  case "$1" in
    pending | drafting | ready_for_review | ready_for_approval | approved | blocked | superseded)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

valid_blast_radius_class() {
  case "$1" in
    C1 | C2 | C3)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

manifest_section_value() {
  manifest="$1"
  section="$2"
  key="$3"

  awk -v section="$section" -v key="$key" '
    /^[^[:space:]][^:]*:/ {
      current = $1
      sub(":", "", current)
      in_section = (current == section)
      next
    }
    in_section && $0 ~ "^[[:space:]]+" key ":" {
      sub("^[[:space:]]*" key ":[[:space:]]*", "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$manifest"
}

manifest_nested_value() {
  manifest="$1"
  section="$2"
  nested="$3"
  key="$4"

  awk -v section="$section" -v nested="$nested" -v key="$key" '
    /^[^[:space:]][^:]*:/ {
      current = $1
      sub(":", "", current)
      in_section = (current == section)
      in_nested = 0
      next
    }
    in_section && $0 ~ "^[[:space:]]{2}" nested ":" {
      in_nested = 1
      next
    }
    in_nested && $0 ~ "^[[:space:]]{2}[A-Za-z0-9_]+:" {
      in_nested = 0
    }
    in_nested && $0 ~ "^[[:space:]]{4}" key ":" {
      sub("^[[:space:]]*" key ":[[:space:]]*", "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$manifest"
}

manifest_section_list_values() {
  manifest="$1"
  section="$2"
  list_key="$3"

  awk -v section="$section" -v list_key="$list_key" '
    /^[^[:space:]][^:]*:/ {
      current = $1
      sub(":", "", current)
      in_section = (current == section)
      in_list = 0
      next
    }
    in_section && $0 ~ "^[[:space:]]{2}" list_key ":" {
      in_list = 1
      next
    }
    in_section && in_list && /^[[:space:]]{2}[A-Za-z0-9_]+:/ {
      exit
    }
    in_section && in_list && /^[[:space:]]{4}- / {
      sub("^[[:space:]]*-[[:space:]]*", "")
      gsub(/^"|"$/, "")
      print
    }
  ' "$manifest"
}

manifest_current_gate_block() {
  manifest="$1"

  awk '
    /^approvals:/ {
      in_approvals = 1
      next
    }
    /^[^[:space:]][^:]*:/ && in_approvals {
      exit
    }
    in_approvals && /^  current_gate:/ {
      in_gate = 1
      next
    }
    in_gate && /^  [A-Za-z0-9_]+:/ {
      exit
    }
    in_gate {
      print
    }
  ' "$manifest"
}

manifest_current_gate_list_values() {
  manifest="$1"
  list_key="$2"

  awk -v list_key="$list_key" '
    /^approvals:/ {
      in_approvals = 1
      next
    }
    /^[^[:space:]][^:]*:/ && in_approvals {
      exit
    }
    in_approvals && /^  current_gate:/ {
      in_gate = 1
      next
    }
    in_gate && /^  [A-Za-z0-9_]+:/ {
      exit
    }
    in_gate && $0 ~ "^[[:space:]]{4}" list_key ":" {
      in_list = 1
      next
    }
    in_list && /^    [A-Za-z0-9_]+:/ {
      exit
    }
    in_list && /^      - / {
      sub("^[[:space:]]*-[[:space:]]*", "")
      gsub(/^"|"$/, "")
      print
    }
  ' "$manifest"
}

manifest_section_block() {
  manifest="$1"
  section="$2"

  awk -v section="$section" '
    /^[^[:space:]][^:]*:/ {
      current = $1
      sub(":", "", current)
      in_section = (current == section)
      if (in_section) {
        next
      }
    }
    /^[^[:space:]][^:]*:/ && !in_section {
      next
    }
    in_section && /^[^[:space:]][^:]*:/ {
      exit
    }
    in_section {
      print
    }
  ' "$manifest"
}

gate_log_records_section() {
  log="$1"

  awk '
    /^## Gate Records/ {
      in_records = 1
      next
    }
    in_records && /^## / {
      exit
    }
    in_records {
      print
    }
  ' "$log"
}

gate_log_load_events() {
  log="$1"

  if [ "$GENDEV_GATE_LOG_EVENTS_FILE" != "$log" ] || [ -z "${GENDEV_GATE_LOG_EVENTS_OUTPUT+x}" ]; then
    GENDEV_GATE_LOG_EVENTS_FILE="$log"
    GENDEV_GATE_LOG_EVENTS_OUTPUT="$(awk -f scripts/lib/gate-log.awk "$log" 2>/tmp/gate-log.err.$$)"
    GENDEV_GATE_LOG_EVENTS_RC=$?
    cat "/tmp/gate-log.err.$$" 2>/dev/null
    rm -f "/tmp/gate-log.err.$$"
  fi

  return "$GENDEV_GATE_LOG_EVENTS_RC"
}

gate_log_events() {
  log="$1"

  [ -f "$log" ] || return 1

  if ! gate_log_load_events "$log"; then
    return 1
  fi

  printf '%s\n' "$GENDEV_GATE_LOG_EVENTS_OUTPUT"
}

gate_log_has_structured_event() {
  log="$1"
  event_type="$2"

  if ! parsed_gate_events="$(
    gate_log_events "$log"
  )"; then
    fail "Malformed structured event record in $log."
    return 1
  fi

  printf '%s\n' "$parsed_gate_events" |
    awk -F'\t' -v event_type="$event_type" '{
      if ($2 == event_type) {
        exit_found = 1
      }
    }
    END { exit !exit_found }'
}

gate_log_has_legacy_approval() {
  log="$1"

  [ -f "$log" ] || return 1

  gate_log_records_section "$log" |
    grep -Eq '^## .+ Approval|Decision:[[:space:]]*(Approved|Accepted|approved|accepted)'
}

gate_log_missing_executable_evidence_for_g6_plus() {
  log="$1"

  [ -f "$log" ] || return 0

  if ! parsed_gate_events="$(
    gate_log_events "$log"
  )"; then
    fail "Malformed structured event record in $log."
    return 1
  fi

  printf '%s\n' "$parsed_gate_events" |
    awk -F'\t' '
      {
        if ($2 != "gate_transition") {
          next
        }
        if ($4 !~ /^G[6-9]([.-]|$)/ && $5 !~ /^G[6-9]([.-]|$)/) {
          next
        }
        if ($9 == 0) {
          missing = 1
        }
      }
      END { exit !missing }
    '
}

gate_log_has_stale_gate_transition_evidence() {
  log="$1"

  [ -f "$log" ] || return 1

  if ! parsed_gate_events="$(
    gate_log_events "$log"
  )"; then
    fail "Malformed structured event record in $log."
    return 1
  fi

  printf '%s\n' "$parsed_gate_events" |
    awk -F'\t' '
      $2 == "gate_transition" && $10 == 1 { found = 1 }
      END { exit !found }
    '
}

changed_paths() {
  if [ -n "${GENDEV_CHANGED_PATHS_FILE:-}" ] && [ -f "$GENDEV_CHANGED_PATHS_FILE" ]; then
    sed '/^[[:space:]]*$/d' "$GENDEV_CHANGED_PATHS_FILE"
  fi
}

path_matches_prefix() {
  path="$1"
  prefix="$2"

  prefix="${prefix%/}"
  case "$path" in
    "$prefix" | "$prefix"/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

list_has_known_value() {
  values="$1"

  while IFS= read -r value; do
    [ -n "$value" ] || continue
    if ! is_unknown "$value"; then
      return 0
    fi
  done <<EOF
$values
EOF

  return 1
}

path_is_excluded() {
  path="$1"
  excluded_paths="$2"

  while IFS= read -r excluded_path; do
    [ -n "$excluded_path" ] || continue
    is_unknown "$excluded_path" && continue
    if path_matches_prefix "$path" "$excluded_path"; then
      return 0
    fi
  done <<EOF
$excluded_paths
EOF

  return 1
}

path_is_implementation_path() {
  path="$1"
  implementation_paths="$2"
  excluded_paths="$3"

  if path_is_excluded "$path" "$excluded_paths"; then
    return 1
  fi

  while IFS= read -r implementation_path; do
    [ -n "$implementation_path" ] || continue
    is_unknown "$implementation_path" && continue
    if path_matches_prefix "$path" "$implementation_path"; then
      return 0
    fi
  done <<EOF
$implementation_paths
EOF

  return 1
}

trace_context_has_task_id() {
  [ -n "${GENDEV_TRACE_CONTEXT_FILE:-}" ] || return 1
  [ -f "$GENDEV_TRACE_CONTEXT_FILE" ] || return 1

  grep -Eiq '(^|[^A-Za-z0-9_])(TASK|WS|WORKSTREAM|REQ|AC|PHASE)[-_:# ]+[A-Za-z0-9][A-Za-z0-9._-]*([^A-Za-z0-9_]|$)' \
    "$GENDEV_TRACE_CONTEXT_FILE"
}

valid_task_id() {
  printf '%s\n' "$1" | grep -Eq "$GENDEV_TASK_ID_PATTERN"
}

valid_workstream_id() {
  printf '%s\n' "$1" | grep -Eq "$GENDEV_WORKSTREAM_ID_PATTERN"
}

accepted_tactical_plans() {
  for file in docs/project/build-plan/phases/*tactical*.md; do
    [ -e "$file" ] || continue
    if [ "$(artifact_status "$file")" = "Accepted" ]; then
      printf '%s\n' "$file"
    fi
  done
}

tactical_declared_task_ids() {
  file="$1"

  awk '
    function trim(value) {
      gsub(/^[[:space:]]+/, "", value)
      gsub(/[[:space:]]+$/, "", value)
      return value
    }
    /^## Workstreams/ { in_workstreams = 1; next }
    in_workstreams && /^## / { exit }
    in_workstreams && /^###[[:space:]]/ {
      line = $0
      while (match(line, /PH-[A-Za-z0-9]+(-[A-Za-z0-9]+)*-T[0-9]+/)) {
        print substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART + RLENGTH)
      }
      next
    }
    in_workstreams && /^\|/ {
      split($0, cells, "|")
      first = trim(cells[2])
      if (first ~ /^PH-[A-Za-z0-9]+(-[A-Za-z0-9]+)*-T[0-9]+$/) {
        print first
      }
    }
  ' "$file" | sort -u
}

tactical_declared_workstream_ids() {
  file="$1"

  awk '
    function trim(value) {
      gsub(/^[[:space:]]+/, "", value)
      gsub(/[[:space:]]+$/, "", value)
      return value
    }
    /^## Workstreams/ { in_workstreams = 1; next }
    in_workstreams && /^## / { exit }
    in_workstreams && /^###[[:space:]]/ {
      line = $0
      while (match(line, /PH-[A-Za-z0-9]+(-[A-Za-z0-9]+)*-WS[0-9]+/)) {
        print substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART + RLENGTH)
      }
      next
    }
    in_workstreams && /^\|/ {
      split($0, cells, "|")
      first = trim(cells[2])
      if (first ~ /^PH-[A-Za-z0-9]+(-[A-Za-z0-9]+)*-WS[0-9]+$/) {
        print first
      }
    }
  ' "$file" | sort -u
}

file_task_id_tokens() {
  file="$1"
  grep -Eo 'PH-[A-Za-z0-9]+(-[A-Za-z0-9]+)*-T[0-9]+' "$file" 2>/dev/null | sort -u
}

file_workstream_id_tokens() {
  file="$1"
  grep -Eo 'PH-[A-Za-z0-9]+(-[A-Za-z0-9]+)*-WS[0-9]+' "$file" 2>/dev/null | sort -u
}

known_tactical_task_ids() {
  accepted_tactical_plans |
    while IFS= read -r file; do
      tactical_declared_task_ids "$file"
    done |
    sort -u
}

artifact_status() {
  file="$1"

  sed -n 's/^Status:[[:space:]]*//p' "$file" | head -n 1
}

artifact_derived_revisions() {
  file="$1"

  awk '
    /^Derived from:/ {
      in_block = 1
      path = ""
      next
    }
    in_block && /^[^[:space:]][^:]*:/ {
      exit
    }
    in_block && /^[[:space:]]*- path:[[:space:]]*.+/ {
      sub("^[[:space:]]*- path:[[:space:]]*", "")
      path = $0
      gsub(/`/, "", path)
      next
    }
    in_block && /^[[:space:]]+revision:[[:space:]]*/ {
      sub("^[[:space:]]+revision:[[:space:]]*", "")
      revision = $0
      if (path != "") {
        print path "|" revision
      }
    }
  ' "$file"
}

gate_log_has_strict_approval_event() {
  log="$1"
  expected_to_gate="$2"

  [ -f "$log" ] || return 1

  if ! parsed_gate_events="$(
    gate_log_events "$log"
  )"; then
    return 1
  fi

  if [ -n "$expected_to_gate" ]; then
    printf '%s\n' "$parsed_gate_events" |
      awk -F'\t' -v expected_to_gate="$expected_to_gate" '
        $2 == "gate_transition" &&
        $3 != "" &&
        $4 != "" &&
        $4 == expected_to_gate &&
        ($6 == "approved" || $6 == "accepted" || $6 == "Approved" || $6 == "Accepted") &&
        $7 == 1 &&
        $8 == 1 &&
        $10 == 0 {
          found = 1
          exit
        }
        END { exit !found }
      '
  else
    printf '%s\n' "$parsed_gate_events" |
      awk -F'\t' '
        $2 == "gate_transition" &&
        $3 != "" &&
        $4 != "" &&
        ($6 == "approved" || $6 == "accepted" || $6 == "Approved" || $6 == "Accepted") &&
        $7 == 1 &&
        $8 == 1 &&
        $10 == 0 {
          found = 1
          exit
        }
        END { exit !found }
      '
  fi
}

gate_log_transition_event_count() {
  log="$1"
  from_gate="$2"
  to_gate="$3"

  [ -f "$log" ] || return 0

  if ! parsed_gate_events="$(gate_log_events "$log")"; then
    return 1
  fi

  printf '%s\n' "$parsed_gate_events" |
    awk -F'\t' -v from_gate="$from_gate" -v to_gate="$to_gate" '
      $2 == "gate_transition" && $3 == from_gate && $4 == to_gate {count++}
      END { print count + 0 }
    '
}

gate_log_transition_event_count_with_combined_fields() {
  log="$1"
  from_gate="$2"
  to_gate="$3"
  combined_span="$4"

  [ -f "$log" ] || return 0

  if ! parsed_gate_events="$(gate_log_events "$log")"; then
    return 1
  fi

  printf '%s\n' "$parsed_gate_events" |
    awk -F'\t' -v from_gate="$from_gate" -v to_gate="$to_gate" -v combined_span="$combined_span" '
      function strip(value,    v) {
        v = value
        sub(/^[[:space:]]+/, "", v)
        sub(/[[:space:]]+$/, "", v)
        gsub(/^"|"$/, "", v)
        return v
      }

      function is_unknown(value,    v) {
        v = strip(value)
        return (v == "" || v == "TBD" || v == "[TBD]" || v == "[]")
      }

      $2 == "gate_transition" &&
      $3 == from_gate &&
      $4 == to_gate &&
      strip($12) == combined_span &&
      !is_unknown($11) &&
      !is_unknown($13) {
        count++
      }
      END { print count + 0 }
    '
}

gate_log_phase_exit_event_count() {
  log="$1"
  phase_id="$2"

  [ -f "$log" ] || return 0

  if ! parsed_gate_events="$(gate_log_events "$log")"; then
    return 1
  fi

  printf '%s\n' "$parsed_gate_events" |
    awk -F'\t' -v phase_id="$phase_id" '
      $2 == "phase_transition" &&
      $14 == "G5." phase_id ".4" &&
      $15 == phase_id &&
      ($6 == "exited" || $6 == "approved" || $6 == "accepted") &&
      $7 == 1 &&
      $16 == 1 &&
      $17 == 1 &&
      $18 == 1 {
        count++
      }
      END { print count + 0 }
    '
}

gate_log_has_non_schema2_event() {
  log="$1"

  [ -f "$log" ] || return 1

  if ! parsed_gate_events="$(gate_log_events "$log")"; then
    return 1
  fi

  printf '%s\n' "$parsed_gate_events" |
    awk -F'\t' '
      NF && ($19 == "" || $20 != "2") {
        found = 1
      }
      END { exit !found }
    '
}

manifest_scaling_combined_gates() {
  manifest="$1"

  awk '
    function trim(value) {
      gsub(/^[[:space:]]+/, "", value)
      gsub(/[[:space:]]+$/, "", value)
      gsub(/^"|"$/, "", value)
      return value
    }

    function emit_entry() {
      if (!in_entry) {
        return
      }
      print span "|" mode "|" justification "|" approver "|" approved_on
      span = ""
      mode = ""
      justification = ""
      approver = ""
      approved_on = ""
      in_entry = 0
    }

    /^scaling:/ {
      in_scaling = 1
      next
    }

    in_scaling && /^[^[:space:]][^:]*:/ {
      emit_entry()
      exit
    }

    in_scaling && $0 ~ /^  combined_gates:/ {
      in_entry = 0
      line_value = $0
      sub(/^[[:space:]]*combined_gates:[[:space:]]*/, "", line_value)
      line_value = trim(line_value)
      if (line_value == "[]" || line_value == "N/A") {
        in_combined = 0
        next
      }
      in_combined = 1
      next
    }

    in_scaling && in_combined && /^    - / {
      emit_entry()
      span = ""
      mode = ""
      justification = ""
      approver = ""
      approved_on = ""
      in_entry = 1
      line = $0
      sub(/^    -[[:space:]]*/, "", line)
      if (line ~ /^[A-Za-z0-9_]+:/) {
        key = line
        sub(/:.*/, "", key)
        value = line
        sub(/^[A-Za-z0-9_]+:[[:space:]]*/, "", value)
        value = trim(value)
        if (key == "gates" || key == "span") {
          span = value
        } else if (key == "mode") {
          mode = value
        } else if (key == "justification") {
          justification = value
        } else if (key == "approved_by" || key == "approver") {
          if (approver == "") {
            approver = value
          }
        } else if (key == "approved_on") {
          approved_on = value
        }
      }
      next
    }

    in_scaling && in_combined && in_entry && $0 ~ /^      - / {
      next
    }

    in_scaling && in_combined && in_entry && $0 ~ /^      [A-Za-z0-9_]+:/ {
      line = $0
      sub(/^[[:space:]]*/, "", line)
      key = line
      sub(/:.*/, "", key)
      value = line
      sub(/^[A-Za-z0-9_]+:[[:space:]]*/, "", value)
      value = trim(value)

      if (key == "gates" || key == "span") {
        span = value
      } else if (key == "mode") {
        mode = value
      } else if (key == "justification") {
        justification = value
      } else if (key == "approved_by" || key == "approver") {
        if (approver == "") {
          approver = value
        }
      } else if (key == "approved_on") {
        approved_on = value
      }
      next
    }

    in_scaling && in_combined && /^  [A-Za-z0-9_]+:/ {
      emit_entry()
      in_combined = 0
    }

    END { emit_entry() }
  ' "$manifest"
}

manifest_scaling_combined_gate_entry() {
  manifest="$1"
  target_span="$2"

  manifest_scaling_combined_gates "$manifest" |
    awk -F'|' -v target_span="$target_span" '$1 == target_span { print; exit }'
}

manifest_phase_entries() {
  manifest="$1"

  awk '
    function trim(value) {
      gsub(/^[[:space:]]+/, "", value)
      gsub(/[[:space:]]+$/, "", value)
      gsub(/^"|"$/, "", value)
      return value
    }

    function emit_entry() {
      if (id != "") {
        print id "|" status
      }
      id = ""
      status = ""
    }

    /^phase:/ {
      in_phase = 1
      next
    }

    in_phase && /^[^[:space:]][^:]*:/ {
      emit_entry()
      exit
    }

    in_phase && /^[[:space:]]{2}phases:[[:space:]]*\[\]/ {
      exit
    }

    in_phase && /^[[:space:]]{2}phases:/ {
      in_phases = 1
      next
    }

    in_phase && in_phases && /^[[:space:]]{2}[A-Za-z0-9_]+:/ {
      emit_entry()
      exit
    }

    in_phase && in_phases && /^[[:space:]]{4}-[[:space:]]+id:/ {
      emit_entry()
      line = $0
      sub(/^.*id:[[:space:]]*/, "", line)
      id = trim(line)
      next
    }

    in_phase && in_phases && id != "" && /^[[:space:]]{6}status:/ {
      line = $0
      sub(/^.*status:[[:space:]]*/, "", line)
      status = trim(line)
      next
    }

    END { emit_entry() }
  ' "$manifest"
}

phase_artifact_path() {
  artifact_id="$1"
  phase_id="$2"

  path="$(gendev_artifact_path "$artifact_id" 2>/dev/null || true)"
  [ -n "$path" ] || return 1
  printf '%s\n' "$path" | sed "s/<id>/${phase_id}/g"
}

valid_sha256_digest_ref() {
  printf '%s\n' "$1" | grep -Eq '^sha256:[0-9a-fA-F]{64}$'
}

valid_sha256_hex() {
  printf '%s\n' "$1" | grep -Eq '^[0-9a-fA-F]{64}$'
}

valid_git_oid() {
  printf '%s\n' "$1" | grep -Eq '^([0-9a-fA-F]{40}|[0-9a-fA-F]{64})$'
}

valid_git_revision_token() {
  value="$1"
  ! is_unknown "$value" && printf '%s\n' "$value" | grep -Eq '^[A-Za-z0-9._/-]+$'
}

check_version_compatibility_state() {
  manifest="docs/project/project.yaml"
  log="docs/project/approvals/gate-log.md"

  [ -f "$manifest" ] || return

  methodology_version="$(manifest_section_value "$manifest" "project" "methodology_version")"
  migration_mode="$(manifest_section_value "$manifest" "migration" "mode")"
  migration_source="$(manifest_section_value "$manifest" "migration" "source_methodology_version")"
  migration_target="$(manifest_section_value "$manifest" "migration" "target_methodology_version")"
  migration_digest="$(manifest_section_value "$manifest" "migration" "assessment_digest")"
  migration_approved_by="$(manifest_section_value "$manifest" "migration" "approved_by")"
  migration_approved_on="$(manifest_section_value "$manifest" "migration" "approved_on")"

  case "$methodology_version" in
    "")
      warn "Manifest project.methodology_version is missing; compatibility mode cannot be determined."
      return
      ;;
    1.0.0)
      if [ -f "$log" ] && gate_log_has_non_schema2_event "$log"; then
        fail "Manifest declares methodology_version 1.0.0 but gate-log contains structured events without event_id and schema_version: 2."
      fi
      return
      ;;
  esac

  if [ -z "$migration_mode" ]; then
    warn "Manifest project.methodology_version is older-version/pinned ($methodology_version); strict 1.0 schema checks require explicit onboarding mode."
    return
  fi

  if [ "$migration_mode" != "$GENDEV_COMPATIBILITY_LEGACY_MODE" ]; then
    fail "Manifest migration.mode must be $GENDEV_COMPATIBILITY_LEGACY_MODE for legacy migration; found: $migration_mode"
  fi

  if [ "$migration_source" != "$methodology_version" ]; then
    fail "Manifest migration.source_methodology_version must match project.methodology_version ($methodology_version)."
  fi

  if [ "$migration_target" != "1.0.0" ]; then
    fail "Manifest migration.target_methodology_version must be 1.0.0."
  fi

  if ! valid_sha256_digest_ref "$migration_digest"; then
    fail "Manifest migration.assessment_digest must be a sha256:<64 hex> digest."
  fi

  if is_unknown "$migration_approved_by"; then
    fail "Manifest legacy migration mode requires migration.approved_by."
  fi

  if is_unknown "$migration_approved_on"; then
    fail "Manifest legacy migration mode requires migration.approved_on."
  fi

  if [ -f "$log" ] && gate_log_has_non_schema2_event "$log"; then
    fail "Manifest legacy migration mode is active, but gate-log contains structured events without event_id and schema_version: 2."
  fi
}

status_in_list() {
  status="$1"
  allowed="$2"

  printf '%s\n' "$allowed" |
    tr ' ' '\n' |
    grep -Fxq "$status"
}

artifact_has_derived_revision() {
  file="$1"

  awk '
    /^Derived from:/ {
      in_block = 1
      next
    }
    in_block && /^[^[:space:]][^:]*:/ {
      exit
    }
    in_block && /^[[:space:]]*- path:[[:space:]]*.+/ {
      path_found = 1
    }
    in_block && /^[[:space:]]+revision:[[:space:]]*.+/ {
      revision_found = 1
    }
    END {
      exit !(path_found && revision_found)
    }
  ' "$file"
}

project_provenance_artifacts() {
  for dir in \
    docs/project/vision \
    docs/project/prd \
    docs/project/architecture \
    docs/project/security-governance \
    docs/project/decisions \
    docs/project/testing \
    docs/project/traceability \
    docs/project/as-built; do
    [ -d "$dir" ] || continue
    find "$dir" -type f -name '*.md' -print
  done

  if [ -d "docs/project/build-plan" ]; then
    find docs/project/build-plan -type f -name '*.md' ! -name 'README.md' -print
  fi
}

check_heading() {
  file="$1"
  heading="$2"

  if ! grep -Eq "^## ${heading}([[:space:]]|$)" "$file"; then
    fail "$file is missing section: ## $heading"
  fi
}

check_baseline_files() {
  require_file "AGENTS.md"
  require_file "README.md"
  require_file "docs/methodology/constitution/gendev.md"
  require_file "docs/methodology/guides/agentic-development-workflow.md"
  require_file "docs/methodology/guides/gates.md"
  require_file "docs/methodology/guides/amendment-and-regression-protocol.md"
  require_file "docs/methodology/guides/enforcement-contract.md"
  require_file "docs/methodology/guides/orchestration-validation.md"
  require_dir "docs/methodology/templates"
  require_dir "docs/methodology/dev-skills"
  require_dir "docs/methodology/agents/roles"
  require_file "scripts/init-project.sh"
  require_file "scripts/check-methodology.sh"
  require_file "scripts/methodology-guard.sh"
  require_file "scripts/install-hooks.sh"
  require_file "scripts/methodology-metrics.sh"
  require_file ".github/workflows/methodology.yml"
  require_file "docs/methodology/templates/value-review-template.md"
}

check_manifest_paths() {
  manifest="docs/project/project.yaml"

  require_file "$manifest"
  if [ ! -f "$manifest" ]; then
    return
  fi

  while IFS= read -r line; do
    path="$(
      printf '%s\n' "$line" |
        sed -n \
          -e 's/^[[:space:]]*[A-Za-z0-9_]*:[[:space:]]*\(docs\/[^ #]*\).*$/\1/p' \
          -e 's/^[[:space:]]*-[[:space:]]*\(docs\/[^ #]*\).*$/\1/p'
    )"

    if [ -n "$path" ] && [ ! -e "$path" ]; then
      fail_once "Manifest path does not exist: $path"
    fi
  done < "$manifest"
}

check_project_structure() {
  require_dir "docs/project/approvals"
  require_file "docs/project/approvals/gate-log.md"
  require_dir "docs/project/vision"
  require_dir "docs/project/prd"
  require_dir "docs/project/architecture"
  require_dir "docs/project/security-governance"
  require_dir "docs/project/decisions"
  require_dir "docs/project/build-plan"
  require_dir "docs/project/build-plan/phases"
  require_dir "docs/project/testing"
  require_dir "docs/project/traceability"
  require_dir "docs/project/as-built"
}

check_sample_reference_drift() {
  paths="README.md AGENTS.md docs/resources/examples docs/methodology/agents"

  if [ -d "docs/project" ]; then
    paths="$paths docs/project"
  fi

  if grep -R "docs/sample-project" -n $paths 2>/dev/null; then
    fail "Found stale docs/sample-project reference."
  fi
}

# Returns 0 (true) if the file contains a genuine template placeholder. Markdown
# links, images, reference labels, escaped brackets, checkboxes, and named rule
# markers are content syntax, not placeholders.
has_real_placeholder() {
  file="$1"

  awk '
    function trim(s) {
      sub(/^[[:space:]]+/, "", s)
      sub(/[[:space:]]+$/, "", s)
      return s
    }

    function strip_markdown_links(line,    tmp) {
      # Ignore image links, inline links, reference links, and reference definitions.
      gsub(/!\[[^][]*\]\([^)]*\)/, "", line)
      gsub(/\[[^][]*\]\[[^][]*\]/, "", line)
      gsub(/\[[^][]*\]\([^)]*\)/, "", line)
      if (line ~ /^[[:space:]]*\[[^]]+\]:/) {
        return ""
      }

      # Ignore escaped bracket literals: \[like this\]
      gsub(/\\\[/, "", line)
      gsub(/\\\]/, "", line)

      # Ignore standalone markdown checkboxes first.
      gsub(/\[[ xX]\]/, "", line)
      return line
    }

    function lower(value) {
      return tolower(value)
    }

    function is_placeholder_phrase(value,    v) {
      v = lower(trim(value))

      if (v == "" || v == "n/a" || v == "none") {
        return 0
      }

      if (v == "tbd" || v == "todo" || v == "replace with") {
        return 1
      }

      if (v ~ /(^|[^a-z0-9_])(tbd|todo)([^a-z0-9_]|$)/ ||
          v ~ /(^|[^a-z0-9_])replace with([^a-z0-9_]|$)/) {
        return 1
      }

      if (v == "project name" || v == "project-slug" || v == "yyyy-mm-dd" ||
          v == "phase name" || v == "path" || v == "revision") {
        return 1
      }

      if (v ~ /^(fill in|replace with|insert|enter|provide|describe|specify|add)($|[[:space:]:-])/) {
        return 1
      }

      if (v ~ /(^|[[:space:]:-])(placeholder|template value|example value)($|[[:space:]:-])/) {
        return 1
      }

      return 0
    }

    function is_placeholder_token(token) {
      token = trim(token)
      if (length(token) < 3) {
        return 0
      }

      sub(/^\[/, "", token)
      sub(/\]$/, "", token)

      if (token ~ /^(YAGNI|KISS|DRY|SRP|LA|NAA|GOV|INT)$/) {
        return 0
      }

      return is_placeholder_phrase(token)
    }

    {
      line = $0
      line = strip_markdown_links(line)
      if (is_placeholder_phrase(line)) {
        found = 1
        exit
      }
      while (match(line, /\[[^][]+\]/)) {
        token = substr(line, RSTART, RLENGTH)
        if (is_placeholder_token(token)) {
          found = 1
          exit
        }
        line = substr(line, RSTART + RLENGTH)
      }
    }

    END { exit !found }
  ' "$file"
}

check_accepted_doc_placeholders() {
  while IFS= read -r file; do
    if grep -Eq '^(Status|status):[[:space:]]*(Accepted|Complete|accepted|complete)[[:space:]]*$' "$file"; then
      if has_real_placeholder "$file"; then
        fail "Accepted/complete document still has placeholders: $file"
      fi
    fi

    if grep -Eq '^(Status|status):[[:space:]]*(Ready for Approval|ready_for_approval)[[:space:]]*$' "$file"; then
      if has_real_placeholder "$file"; then
        warn "Ready-for-approval document still has placeholders: $file"
      fi
    fi
  done < <(find docs/project -type f \( -name '*.md' -o -name '*.yaml' \) -print)
}

check_gate_log_record_format() {
  log="docs/project/approvals/gate-log.md"

  [ -f "$log" ] || return

  if ! parsed_gate_events="$(gate_log_events "$log")"; then
    fail "Malformed structured gate-log record section in $log."
    return
  fi

  if printf '%s\n' "$parsed_gate_events" | awk -F'\t' '$2=="gate_transition" {exit 0} END {exit 1}'; then
    if ! printf '%s\n' "$parsed_gate_events" | awk -F'\t' '$2=="gate_transition" && $7=="1" {exit 0} END {exit 1}'; then
      warn "Structured gate transition exists but no checked statement was found in gate-log.md."
    fi
    if ! printf '%s\n' "$parsed_gate_events" | awk -F'\t' '$2=="gate_transition" && $8=="1" {exit 0} END {exit 1}'; then
      warn "Structured gate transition exists but no evidence block was found in gate-log.md."
    fi
  fi

  if gate_log_has_legacy_approval "$log" && ! gate_log_has_structured_event "$log" "gate_transition"; then
    warn "Legacy prose approval record found; new gate approvals should use structured gate events."
  fi

  if gate_log_missing_executable_evidence_for_g6_plus "$log"; then
    fail "G6+ structured gate transition is missing executable or verification evidence."
  fi
}

gate_log_evidence_items() {
  log="$1"

  awk '
    function trim(value) {
      gsub(/^[[:space:]]+/, "", value)
      gsub(/[[:space:]]+$/, "", value)
      gsub(/^"|"$/, "", value)
      return value
    }
    function reset_item() {
      artifact_id = ""
      artifact_path = ""
      category = ""
      reviewed_revision = ""
      reviewed_blob_oid = ""
      reviewed_digest = ""
      resulting_blob_oid = ""
      resulting_digest = ""
      status = ""
      originating_event_id = ""
      item_seen = 0
    }
    function emit_item() {
      if (!item_seen) {
        return
      }
      print event_id "|" artifact_id "|" artifact_path "|" category "|" reviewed_revision "|" reviewed_blob_oid "|" reviewed_digest "|" resulting_blob_oid "|" resulting_digest "|" status "|" originating_event_id
      reset_item()
    }
    /^## Gate Records/ { in_records = 1; next }
    in_records && /^## / { exit }
    in_records && /^```[[:space:]]*yaml/ {
      in_yaml = 1
      in_evidence = 0
      event_id = ""
      reset_item()
      next
    }
    in_records && in_yaml && /^```[[:space:]]*$/ {
      emit_item()
      in_yaml = 0
      in_evidence = 0
      next
    }
    !in_records || !in_yaml { next }
    /^[A-Za-z_][A-Za-z0-9_]*:/ {
      if ($0 !~ /^evidence:/) {
        emit_item()
        in_evidence = 0
      }
    }
    /^event_id:/ {
      value = $0
      sub(/^event_id:[[:space:]]*/, "", value)
      event_id = trim(value)
      next
    }
    /^evidence:/ {
      in_evidence = 1
      next
    }
    in_evidence && /^  - / {
      emit_item()
      item_seen = 1
      line = $0
      sub(/^  -[[:space:]]*/, "", line)
      key = line
      sub(/:.*/, "", key)
      value = line
      sub(/^[A-Za-z0-9_]+:[[:space:]]*/, "", value)
      if (key == "artifact_id") artifact_id = trim(value)
      else if (key == "artifact_path") artifact_path = trim(value)
      else if (key == "category") category = trim(value)
      else if (key == "reviewed_revision") reviewed_revision = trim(value)
      else if (key == "reviewed_blob_oid") reviewed_blob_oid = trim(value)
      else if (key == "reviewed_digest") reviewed_digest = trim(value)
      else if (key == "resulting_blob_oid") resulting_blob_oid = trim(value)
      else if (key == "resulting_digest") resulting_digest = trim(value)
      else if (key == "status") status = trim(value)
      else if (key == "originating_event_id") originating_event_id = trim(value)
      next
    }
    in_evidence && item_seen && /^    [A-Za-z_][A-Za-z0-9_]*:/ {
      line = $0
      sub(/^    /, "", line)
      key = line
      sub(/:.*/, "", key)
      value = line
      sub(/^[A-Za-z0-9_]+:[[:space:]]*/, "", value)
      if (key == "artifact_id") artifact_id = trim(value)
      else if (key == "artifact_path") artifact_path = trim(value)
      else if (key == "category") category = trim(value)
      else if (key == "reviewed_revision") reviewed_revision = trim(value)
      else if (key == "reviewed_blob_oid") reviewed_blob_oid = trim(value)
      else if (key == "reviewed_digest") reviewed_digest = trim(value)
      else if (key == "resulting_blob_oid") resulting_blob_oid = trim(value)
      else if (key == "resulting_digest") resulting_digest = trim(value)
      else if (key == "status") status = trim(value)
      else if (key == "originating_event_id") originating_event_id = trim(value)
      next
    }
    END { emit_item() }
  ' "$log"
}

check_gate_log_evidence_item_bindings() {
  log="docs/project/approvals/gate-log.md"
  [ -f "$log" ] || return

  gate_log_evidence_items "$log" |
    while IFS='|' read -r event_id artifact_id artifact_path category reviewed_revision reviewed_blob_oid reviewed_digest resulting_blob_oid resulting_digest status originating_event_id; do
      [ -n "$event_id$artifact_id$artifact_path$category" ] || continue
      item_label="in $event_id for ${artifact_path:-unknown}"

      for field in artifact_id artifact_path category reviewed_revision reviewed_blob_oid reviewed_digest resulting_blob_oid resulting_digest status; do
        eval "field_value=\${$field}"
        if is_unknown "$field_value"; then
          fail "Gate-log evidence item $item_label is missing required field: $field"
        fi
      done

      case "$category" in
        new_acceptance_status_only | complete_report_unchanged | accepted_authority_unchanged)
          ;;
        *)
          fail "Gate-log evidence item $item_label has invalid evidence category: $category"
          ;;
      esac

      if ! valid_git_revision_token "$reviewed_revision"; then
        fail "Gate-log evidence item $item_label has invalid reviewed revision: $reviewed_revision"
      fi
      for oid_field in reviewed_blob_oid resulting_blob_oid; do
        eval "oid_value=\${$oid_field}"
        if ! valid_git_oid "$oid_value"; then
          fail "Gate-log evidence item $item_label has invalid blob OID in $oid_field: $oid_value"
        fi
      done
      for digest_field in reviewed_digest resulting_digest; do
        eval "digest_value=\${$digest_field}"
        if ! valid_sha256_hex "$digest_value"; then
          fail "Gate-log evidence item $item_label has invalid sha256 digest in $digest_field: $digest_value"
        fi
      done

      case "$category" in
        complete_report_unchanged)
          if [ "$reviewed_blob_oid" != "$resulting_blob_oid" ] || [ "$reviewed_digest" != "$resulting_digest" ]; then
            fail "Gate-log evidence item $item_label category complete_report_unchanged requires reviewed and resulting blobs/digests to match."
          fi
          ;;
        accepted_authority_unchanged)
          if [ "$reviewed_blob_oid" != "$resulting_blob_oid" ] || [ "$reviewed_digest" != "$resulting_digest" ]; then
            fail "Gate-log evidence item $item_label category accepted_authority_unchanged requires reviewed and resulting blobs/digests to match."
          fi
          if is_unknown "$originating_event_id"; then
            fail "Gate-log evidence item $item_label category accepted_authority_unchanged requires originating_event_id."
          fi
          ;;
      esac
    done
}

late_gate_requires_artifact_status() {
  gate="$1"
  path="$2"
  allowed="$3"

  if [ ! -f "$path" ]; then
    fail "Late gate $gate requires artifact '$path' with status $allowed; actual: missing"
    return
  fi

  status="$(artifact_status "$path")"
  if ! status_in_list "$status" "$allowed"; then
    fail "Late gate $gate requires artifact '$path' with status $allowed; actual: ${status:-missing}"
  fi
}

gate_log_has_terminal_g9_closeout() {
  log="$1"
  [ -f "$log" ] || return 1

  awk '
    /^## Gate Records/ { in_records = 1; next }
    in_records && /^## / { exit }
    in_records && /^```[[:space:]]*yaml/ {
      in_yaml = 1
      event_type = ""
      from_gate = ""
      to_gate = ""
      terminal = ""
      next
    }
    in_records && in_yaml && /^```[[:space:]]*$/ {
      if (event_type == "gate_transition" && from_gate == "G8" && to_gate == "G9" && terminal == "true") {
        found = 1
      }
      in_yaml = 0
      next
    }
    in_yaml && /^event_type:/ {
      event_type = $0
      sub(/^event_type:[[:space:]]*/, "", event_type)
      next
    }
    in_yaml && /^from_gate:/ {
      from_gate = $0
      sub(/^from_gate:[[:space:]]*/, "", from_gate)
      next
    }
    in_yaml && /^to_gate:/ {
      to_gate = $0
      sub(/^to_gate:[[:space:]]*/, "", to_gate)
      next
    }
    in_yaml && /^terminal_closeout:/ {
      terminal = $0
      sub(/^terminal_closeout:[[:space:]]*/, "", terminal)
      next
    }
    END { exit !found }
  ' "$log"
}

value_review_has_valid_disposition() {
  file="$1"
  [ -f "$file" ] || return 1

  disposition="$(
    sed -n \
      -e 's/^[[:space:]]*value_review\.disposition:[[:space:]]*//p' \
      -e 's/^[[:space:]]*Disposition:[[:space:]]*//p' \
      "$file" | head -n 1
  )"

  case "$disposition" in
    complete | not_due | not_applicable)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

check_late_gate_lifecycle_state() {
  manifest="docs/project/project.yaml"
  log="docs/project/approvals/gate-log.md"
  [ -f "$manifest" ] || return

  project_gate="$(manifest_section_value "$manifest" "project" "current_gate")"
  project_status="$(manifest_section_value "$manifest" "project" "status")"
  active_role="$(manifest_section_value "$manifest" "collaboration" "active_role")"

  case "$project_gate" in
    G7 | G8 | G9)
      late_gate_requires_artifact_status "$project_gate" "docs/project/build-plan/implementation-summary.md" "Complete"
      ;;
  esac

  case "$project_gate" in
    G8 | G9)
      late_gate_requires_artifact_status "$project_gate" "docs/project/review/code-review.md" "Complete"
      late_gate_requires_artifact_status "$project_gate" "docs/project/review/remediation.md" "Complete not_required"
      late_gate_requires_artifact_status "$project_gate" "docs/project/testing/final-test-uat-report.md" "Complete"
      late_gate_requires_artifact_status "$project_gate" "docs/project/traceability/traceability-matrix.md" "Complete"
      late_gate_requires_artifact_status "$project_gate" "docs/project/deployment/deployment-readiness.md" "Ready for Approval Accepted"
      late_gate_requires_artifact_status "$project_gate" "docs/project/deployment/production-runbook.md" "Complete"

      deployment_readiness_status=""
      if [ -f "docs/project/deployment/deployment-readiness.md" ]; then
        deployment_readiness_status="$(artifact_status "docs/project/deployment/deployment-readiness.md")"
      fi
      if [ "$deployment_readiness_status" = "Accepted" ] &&
        ! gate_log_has_structured_event "$log" "deployment_approval"; then
        fail "G8 deployment readiness is Accepted but no structured deployment_approval event exists in gate-log.md."
      fi
      ;;
  esac

  if [ "$project_gate" = "G9" ]; then
    late_gate_requires_artifact_status "$project_gate" "docs/project/deployment/deployment-record.md" "Complete"
    late_gate_requires_artifact_status "$project_gate" "docs/project/as-built/value-review.md" "Complete"
    late_gate_requires_artifact_status "$project_gate" "docs/project/as-built/as-built-closeout.md" "Complete"

    if [ "$project_status" != "closed" ]; then
      fail "G9 close-out requires project.status closed."
    fi
    if [ "$active_role" != "none" ]; then
      fail "G9 close-out requires active_role none."
    fi
    if ! gate_log_has_terminal_g9_closeout "$log"; then
      fail "G9 close-out requires a terminal G8 -> G9 gate_transition event."
    fi
    if ! value_review_has_valid_disposition "docs/project/as-built/value-review.md"; then
      fail "G9 close-out requires value-review disposition complete, not_due, or not_applicable."
    fi
  fi
}

check_artifact_provenance() {
  while IFS= read -r file; do
    missing=""

    for field in "Produced by" "Produced on" "Produced with" "Agent identity"; do
      if ! grep -Eq "^${field}:[[:space:]]*.+" "$file"; then
        missing="${missing} ${field}"
      fi
    done

    if ! grep -Eq '^Derived from:' "$file" || ! artifact_has_derived_revision "$file"; then
      missing="${missing} Derived from path/revision"
    fi

    if [ -n "$missing" ]; then
      warn "$file is missing provenance field(s):$missing"
    fi
  done < <(project_provenance_artifacts)
}

check_project_identity_field() {
  manifest="docs/project/project.yaml"
  [ -f "$manifest" ] || return 0

  # Extract the slug value from project.yaml (slug: "value")
  manifest_slug=$(grep -E '^[[:space:]]*slug:' "$manifest" | head -1 | sed -E 's/^[[:space:]]*slug:[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/')
  if [ -z "$manifest_slug" ] || [ "$manifest_slug" = "[project-slug]" ]; then
    return 0
  fi

  while IFS= read -r file; do
    field_line=$(grep -E '^project:[[:space:]]*.+' "$file" | head -1)
    if [ -z "$field_line" ]; then
      fail "$file is missing the required project front-matter field (Rule 14)."
      continue
    fi
    field_value=$(printf '%s' "$field_line" | sed -E 's/^project:[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/')
    if [ "$field_value" != "$manifest_slug" ]; then
      fail "$file project field '$field_value' does not match project.yaml slug '$manifest_slug' (Rule 14)."
    fi
  done < <(project_provenance_artifacts)

  # The gate log is an authority artifact and also requires the field.
  gate_log="docs/project/approvals/gate-log.md"
  if [ -f "$gate_log" ]; then
    gl_line=$(grep -E '^project:[[:space:]]*.+' "$gate_log" | head -1)
    if [ -z "$gl_line" ]; then
      fail "$gate_log is missing the required project front-matter field (Rule 14)."
    else
      gl_value=$(printf '%s' "$gl_line" | sed -E 's/^project:[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/')
      if [ "$gl_value" != "$manifest_slug" ]; then
        fail "$gate_log project field '$gl_value' does not match project.yaml slug '$manifest_slug' (Rule 14)."
      fi
    fi
  fi

  # Supporting-artifact form (Rule 13): when supporting artifacts exist under a
  # design directory, each must have a valid kebab-case filename and the project
  # field. Graph properties (cycles, typed coherence) are the linter's job, not
  # the checker's.
  for sdir in docs/project/design docs/project/supporting; do
    [ -d "$sdir" ] || continue
    while IFS= read -r sfile; do
      base=$(basename "$sfile" .md)
      if ! printf '%s' "$base" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; then
        fail "$sfile supporting-artifact filename is not a valid kebab-case identifier (Rule 13)."
      fi
      if ! grep -Eq '^project:[[:space:]]*.+' "$sfile"; then
        fail "$sfile supporting artifact is missing the required project front-matter field (Rule 13)."
      else
        sfield=$(grep -E '^project:[[:space:]]*.+' "$sfile" | head -1 | sed -E 's/^project:[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/')
        if [ "$sfield" != "$manifest_slug" ]; then
          fail "$sfile supporting-artifact project field '$sfield' does not match project.yaml slug '$manifest_slug' (Rule 13)."
        fi
      fi
    done < <(find "$sdir" -type f -name '*.md' ! -name 'README.md' -print)
  done
}

check_stale_evidence() {
  manifest="docs/project/project.yaml"
  log="docs/project/approvals/gate-log.md"

  if [ -f "$manifest" ]; then
    while IFS= read -r evidence_path; do
      [ -f "$evidence_path" ] || continue
      status="$(artifact_status "$evidence_path")"
      case "$status" in
        Stale | Superseded)
          warn "Manifest gate evidence is $status and needs reconciliation: $evidence_path"
          ;;
      esac
    done < <(manifest_current_gate_list_values "$manifest" "evidence")
  fi

  if [ -f "$log" ]; then
    if gate_log_has_stale_gate_transition_evidence "$log"; then
      fail "Gate transition cites stale or superseded evidence in gate-log.md."
    elif parsed_gate_events="$(gate_log_events "$log")" \
      && printf '%s\n' "$parsed_gate_events" | awk -F'\t' '$2 != "gate_transition" && $10 == 1 {found = 1} END {exit !found}'; then
      warn "Gate-log records cite stale or superseded evidence outside a gate transition; review reconciliation state."
    fi
  fi
}

check_computed_staleness() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return
  fi

  while IFS= read -r file; do
    while IFS='|' read -r source_path pinned_revision; do
      case "$pinned_revision" in
        "" | "TBD" | "\"TBD\"" | "N/A" | "\"N/A\"")
          continue
          ;;
      esac

      if ! printf '%s\n' "$pinned_revision" | grep -Eq '^[0-9a-fA-F]{7,40}$'; then
        continue
      fi

      [ -f "$source_path" ] || continue

      current_revision="$(git log -n 1 --format=%H -- "$source_path" 2>/dev/null)"
      [ -n "$current_revision" ] || continue

      case "$current_revision" in
        "$pinned_revision"*)
          ;;
        *)
          warn "$file may be stale: $source_path is at $current_revision but Derived from pins $pinned_revision."
          ;;
      esac
    done < <(artifact_derived_revisions "$file")
  done < <(project_provenance_artifacts)
}

check_manifest_amendment_state() {
  manifest="docs/project/project.yaml"
  log="docs/project/approvals/gate-log.md"

  [ -f "$manifest" ] || return

  active_count="$(manifest_section_value "$manifest" "amendments" "active_count")"

  if [ -z "$active_count" ]; then
    warn "Manifest is missing amendments.active_count."
    return
  fi

  if ! printf '%s\n' "$active_count" | grep -Eq '^[0-9]+$'; then
    warn "Manifest amendments.active_count is not numeric: $active_count"
    return
  fi

  if [ "$active_count" -gt 0 ]; then
    if [ -f "$log" ] && ! gate_log_has_structured_event "$log" "amendment"; then
      warn "Manifest has active amendments but no amendment event is visible in gate-log.md."
    fi
  fi
}

check_manifest_scaling_state() {
  manifest="docs/project/project.yaml"

  require_file "$manifest"
  if [ ! -f "$manifest" ]; then
    return
  fi

  if ! grep -Eq '^scaling:' "$manifest"; then
    warn "Manifest is missing scaling block."
    return
  fi

  blast_radius_class="$(manifest_section_value "$manifest" "scaling" "blast_radius_class")"
  classification_reason="$(manifest_section_value "$manifest" "scaling" "classification_reason")"
  gate_combination_policy="$(manifest_section_value "$manifest" "scaling" "gate_combination_policy")"

  if ! valid_blast_radius_class "$blast_radius_class"; then
    fail "Manifest scaling.blast_radius_class must be C1, C2, or C3."
  fi

  if is_unknown "$classification_reason"; then
    warn "Manifest scaling.classification_reason is missing."
  fi

  if is_unknown "$gate_combination_policy"; then
    warn "Manifest scaling.gate_combination_policy is missing."
  fi

  combined_gate_entries="$(manifest_scaling_combined_gates "$manifest")"
  combined_gate_count="$(printf '%s\n' "$combined_gate_entries" | awk 'NF > 0 {count++} END { print count + 0 }')"

  if [ "$combined_gate_count" -gt 0 ]; then
    while IFS='|' read -r declared_span declared_mode declared_justification declared_approver declared_approved_on; do
      if [ -z "$declared_span" ]; then
        fail "Manifest scaling.combined_gates entry is missing a required span value."
        continue
      fi

      if ! printf '%s\n' "$declared_span" | grep -Eq '^G[0-9]+-G[0-9]+$'; then
        fail "Manifest scaling.combined_gates has an invalid span: $declared_span"
        continue
      fi

      if is_unknown "$declared_justification"; then
        fail "Manifest scaling.combined_gates entry $declared_span is missing justification."
      fi

      if is_unknown "$declared_approver"; then
        fail "Manifest scaling.combined_gates entry $declared_span is missing approved_by/approver."
      fi

      if is_unknown "$declared_approved_on"; then
        fail "Manifest scaling.combined_gates entry $declared_span is missing approved_on."
      fi

      if is_unknown "$declared_mode"; then
        fail "Manifest scaling.combined_gates entry $declared_span is missing mode."
      fi
    done <<EOF
$combined_gate_entries
EOF
  fi

  if [ "$blast_radius_class" = "C3" ] && [ "$combined_gate_count" -gt 0 ]; then
    fail "Manifest class is C3 but combined gates are recorded; C3 projects should not combine gates."
  fi
}

check_manifest_enforcement_state() {
  manifest="docs/project/project.yaml"

  require_file "$manifest"
  if [ ! -f "$manifest" ]; then
    return
  fi

  if ! grep -Eq '^enforcement:' "$manifest"; then
    warn "Manifest is missing enforcement block."
    return
  fi

  contract_version="$(manifest_section_value "$manifest" "enforcement" "contract_version")"
  enforcement_class="$(manifest_section_value "$manifest" "enforcement" "class")"
  protected_branch="$(manifest_section_value "$manifest" "enforcement" "protected_branch")"
  cadence="$(manifest_nested_value "$manifest" "enforcement" "attestation" "cadence")"
  required_attester="$(manifest_nested_value "$manifest" "enforcement" "attestation" "required_attester")"
  pre_commit_hook="$(manifest_nested_value "$manifest" "enforcement" "binding_paths" "pre_commit_hook")"
  ci_workflow="$(manifest_nested_value "$manifest" "enforcement" "binding_paths" "ci_workflow")"
  override_approvers="$(manifest_nested_value "$manifest" "enforcement" "override_policy" "required_approvers")"
  override_record="$(manifest_nested_value "$manifest" "enforcement" "override_policy" "record_path")"
  block="$(manifest_section_block "$manifest" "enforcement")"

  if is_unknown "$contract_version"; then
    warn "Manifest enforcement.contract_version is missing."
  fi

  case "$enforcement_class" in
    attested | enforced)
      ;;
    "")
      warn "Manifest enforcement.class is missing."
      ;;
    *)
      warn "Manifest enforcement.class is not recognized: $enforcement_class"
      ;;
  esac

  if is_unknown "$protected_branch"; then
    warn "Manifest enforcement.protected_branch is missing."
  fi

  if ! printf '%s\n' "$block" | grep -Eq '^[[:space:]]{2}implementation_paths:'; then
    warn "Manifest enforcement.implementation_paths is missing."
  fi

  if ! printf '%s\n' "$block" | grep -Eq '^[[:space:]]{2}excluded_paths:'; then
    warn "Manifest enforcement.excluded_paths is missing."
  fi

  if [ "$enforcement_class" = "attested" ]; then
    if is_unknown "$cadence"; then
      fail "Manifest attested enforcement is missing attestation cadence."
    fi
    if is_unknown "$required_attester"; then
      fail "Manifest attested enforcement is missing required_attester field."
    fi
  fi

  if [ "$enforcement_class" = "enforced" ]; then
    if is_unknown "$pre_commit_hook" && is_unknown "$ci_workflow"; then
      warn "Manifest enforced class should declare at least one binding path."
    fi
  fi

  if ! is_unknown "$pre_commit_hook" && [ ! -e "$pre_commit_hook" ]; then
    warn "Manifest enforcement binding path does not exist: $pre_commit_hook"
  fi

  if ! is_unknown "$ci_workflow" && [ ! -e "$ci_workflow" ]; then
    warn "Manifest enforcement binding path does not exist: $ci_workflow"
  fi

  if is_unknown "$override_approvers"; then
    warn "Manifest enforcement override_policy.required_approvers is missing."
  fi

  if is_unknown "$override_record"; then
    warn "Manifest enforcement override_policy.record_path is missing."
  elif [ ! -e "$override_record" ]; then
    warn "Manifest enforcement override record path does not exist: $override_record"
  fi
}

check_manifest_gate_values() {
  manifest="docs/project/project.yaml"

  require_file "$manifest"
  if [ ! -f "$manifest" ]; then
    return
  fi

  project_gate="$(manifest_section_value "$manifest" "project" "current_gate")"
  approval_gate="$(manifest_nested_value "$manifest" "approvals" "current_gate" "gate")"
  next_gate="$(manifest_nested_value "$manifest" "approvals" "current_gate" "next_gate")"

  if ! valid_gate_value "$project_gate"; then
    fail "Manifest project.current_gate is not a valid gate: $project_gate"
  fi

  if ! valid_gate_value "$approval_gate"; then
    fail "Manifest approvals.current_gate.gate is not a valid gate: $approval_gate"
  fi

  if [ "$next_gate" = "none" ] && [ "$project_gate" = "G9" ] && [ "$approval_gate" = "G9" ]; then
    :
  elif ! is_unknown "$next_gate" && ! valid_gate_value "$next_gate"; then
    fail "Manifest approvals.current_gate.next_gate is not a valid gate: $next_gate"
  fi
}

check_diff_gate_movement() {
  manifest="docs/project/project.yaml"
  log="docs/project/approvals/gate-log.md"

  [ -f "$manifest" ] || return
  [ -n "${GENDEV_BASE_REF:-}" ] || return
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return

  tmp_manifest="$(gendev_mktemp_file)"
  if ! git show "${GENDEV_BASE_REF}:$manifest" > "$tmp_manifest" 2>/dev/null; then
    rm -f "$tmp_manifest"
    return
  fi

  base_gate="$(manifest_section_value "$tmp_manifest" "project" "current_gate")"
  current_gate="$(manifest_section_value "$manifest" "project" "current_gate")"
  rm -f "$tmp_manifest"

  if [ -n "$base_gate" ] && [ -n "$current_gate" ] && [ "$base_gate" != "$current_gate" ]; then
    if ! changed_paths | grep -Fxq "$log"; then
      fail "project.current_gate changed from $base_gate to $current_gate without a gate-log update in the same diff."
      return
    fi

    if ! gate_log_has_structured_event "$log" "gate_transition"; then
      fail "project.current_gate changed from $base_gate to $current_gate without a structured gate transition."
      return
    fi

    tmp_base_log="$(gendev_mktemp_file)"
    base_transition_count=0
    if git show "${GENDEV_BASE_REF}:$log" > "$tmp_base_log" 2>/dev/null; then
      if ! base_transition_count="$(gate_log_transition_event_count "$tmp_base_log" "$base_gate" "$current_gate")"; then
        fail "Malformed structured gate-log record in base ${GENDEV_BASE_REF}:$log."
        rm -f "$tmp_base_log"
        return
      fi
    fi
    if ! current_transition_count="$(gate_log_transition_event_count "$log" "$base_gate" "$current_gate")"; then
      fail "Malformed structured gate-log record in $log."
      return
    fi

    base_gate_index="$(gate_number "$base_gate")"
    current_gate_index="$(gate_number "$current_gate")"

    if [ "$base_gate_index" -lt "$current_gate_index" ]; then
      gate_span_distance=$((current_gate_index - base_gate_index))
    else
      gate_span_distance=$((base_gate_index - current_gate_index))
    fi

    if [ "$gate_span_distance" -eq 1 ]; then
      if [ "$current_transition_count" -eq 0 ]; then
        fail "project.current_gate changed from $base_gate to $current_gate without a matching gate transition ($base_gate -> $current_gate) in gate-log.md."
        return
      fi

      if [ "$current_transition_count" -le "$base_transition_count" ]; then
        fail "project.current_gate changed from $base_gate to $current_gate without a newly added $base_gate -> $current_gate transition in gate-log.md."
        return
      fi
    else
      combined_span="${base_gate}-${current_gate}"

      if [ "$current_transition_count" -eq 0 ]; then
        fail "project.current_gate changed from $base_gate to $current_gate without a matching gate transition ($base_gate -> $current_gate) in gate-log.md."
        return
      fi

      if [ -z "$(manifest_scaling_combined_gate_entry "$manifest" "$combined_span")" ]; then
        fail "project.current_gate changed from $base_gate to $current_gate without a matching manifest scaling.combined_gates declaration for span $combined_span."
        return
      fi

      blast_radius_class="$(manifest_section_value "$manifest" "scaling" "blast_radius_class")"
      if [ "$blast_radius_class" = "C3" ]; then
        fail "project.current_gate changed from $base_gate to $current_gate using a combined transition, but blast_radius_class C3 does not allow combined transitions."
        return
      fi

      if ! base_combined_transition_count="$(gate_log_transition_event_count_with_combined_fields "$tmp_base_log" "$base_gate" "$current_gate" "$combined_span")"; then
        fail "Malformed structured gate-log record in base ${GENDEV_BASE_REF}:$log."
        return
      fi

      if ! current_combined_transition_count="$(gate_log_transition_event_count_with_combined_fields "$log" "$base_gate" "$current_gate" "$combined_span")"; then
        fail "Malformed structured gate-log record in $log."
        return
      fi

      if [ "$current_combined_transition_count" -eq 0 ]; then
        fail "project.current_gate changed from $base_gate to $current_gate without a matching gate transition ($base_gate -> $current_gate) with combined_gates: $combined_span in gate-log.md."
        return
      fi

      if [ "$current_combined_transition_count" -le "$base_combined_transition_count" ]; then
        fail "project.current_gate changed from $base_gate to $current_gate without a newly added combined gate transition ($base_gate -> $current_gate) with combined_gates: $combined_span in gate-log.md."
        return
      fi
    fi
    rm -f "$tmp_base_log"
  fi
}

check_gate_log_append_only_history() {
  log="docs/project/approvals/gate-log.md"

  [ -f "$log" ] || return
  [ -n "${GENDEV_BASE_REF:-}" ] || return
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return

  base_log="$(gendev_mktemp_file)"
  if ! git show "${GENDEV_BASE_REF}:$log" > "$base_log" 2>/dev/null; then
    rm -f "$base_log"
    return
  fi

  base_line_count="$(awk 'END { print NR }' "$base_log")"
  base_line_count="${base_line_count:-0}"
  current_line_count="$(awk 'END { print NR }' "$log")"
  current_line_count="${current_line_count:-0}"

  if [ "$current_line_count" -lt "$base_line_count" ]; then
    fail "gate-log history in $log appears shortened versus ${GENDEV_BASE_REF}; existing historical entries were deleted."
    rm -f "$base_log"
    return
  fi

  if [ "$base_line_count" -gt 0 ] &&
    ! awk -v base_count="$base_line_count" '
      NR == FNR { base_lines[NR] = $0; next }
      FNR <= base_count && $0 != base_lines[FNR] { bad = 1; exit 1 }
      END {
        if (bad) {
          exit 1
        }
      }
    ' "$base_log" "$log"; then
    fail "gate-log history in $log does not preserve historical entries from ${GENDEV_BASE_REF}; prior log content was edited or inserted before append position."
    rm -f "$base_log"
    return
  fi

  base_events="$(gendev_mktemp_file)"
  current_events="$(gendev_mktemp_file)"

  if ! gate_log_events "$base_log" > "$base_events"; then
    fail "Malformed structured gate-log record in base ${GENDEV_BASE_REF}:$log."
    rm -f "$base_log" "$base_events" "$current_events"
    return
  fi

  if ! gate_log_events "$log" > "$current_events"; then
    fail "Malformed structured gate-log record in $log."
    rm -f "$base_log" "$base_events" "$current_events"
    return
  fi

  base_count="$(awk 'END { print NR }' "$base_events")"
  current_count="$(awk 'END { print NR }' "$current_events")"
  base_count="${base_count:-0}"
  current_count="${current_count:-0}"

  if [ "$current_count" -lt "$base_count" ]; then
    fail "gate-log history in $log appears shortened versus ${GENDEV_BASE_REF}; existing historical entries were deleted."
    rm -f "$base_log" "$base_events" "$current_events"
    return
  fi

  if [ "$base_count" -gt 0 ] &&
    ! awk -v base_count="$base_count" '
      NR == FNR { base_events[NR] = $0; next }
      FNR <= base_count && $0 != base_events[FNR] { bad = 1; exit 1 }
      END {
        if (bad) {
          exit 1
        }
      }
    ' "$base_events" "$current_events"; then
    fail "gate-log history in $log does not preserve historical event records from ${GENDEV_BASE_REF}; prior entries were edited."
    rm -f "$base_log" "$base_events" "$current_events"
    return
  fi

  rm -f "$base_log" "$base_events" "$current_events"
}

check_changed_path_enforcement() {
  manifest="docs/project/project.yaml"

  [ -f "$manifest" ] || return

  paths="$(changed_paths)"
  [ -n "$paths" ] || return

  current_gate="$(manifest_section_value "$manifest" "project" "current_gate")"
  valid_gate_value "$current_gate" || return
  gate_index="$(gate_number "$current_gate")"

  implementation_paths="$(manifest_section_list_values "$manifest" "enforcement" "implementation_paths")"
  excluded_paths="$(manifest_section_list_values "$manifest" "enforcement" "excluded_paths")"

  if ! list_has_known_value "$implementation_paths"; then
    if [ "$gate_index" -ge 5 ]; then
      fail "Manifest enforcement.implementation_paths must be set at G5 or later."
    else
      warn "Implementation path enforcement skipped because enforcement.implementation_paths is not set."
    fi
    return
  fi

  implementation_change_found=0

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if path_is_implementation_path "$path" "$implementation_paths" "$excluded_paths"; then
      implementation_change_found=1
      if [ "$gate_index" -lt 5 ]; then
        fail "Implementation path changed before G5: $path"
      fi
    fi
  done <<EOF
$paths
EOF

  if [ "$implementation_change_found" -eq 1 ] &&
    [ "$gate_index" -ge 5 ] &&
    [ "${GENDEV_REQUIRE_TASK_ID:-}" = "1" ] &&
    ! trace_context_has_task_id; then
    fail "Implementation changes at G5+ require a tactical task, workstream, or requirement ID in the review context."
  fi
}

check_manifest_approval_state() {
  manifest="docs/project/project.yaml"
  log="docs/project/approvals/gate-log.md"

  require_file "$manifest"
  if [ ! -f "$manifest" ]; then
    return
  fi

  project_gate="$(manifest_section_value "$manifest" "project" "current_gate")"
  owner="$(manifest_section_value "$manifest" "human_control" "owner")"
  approver="$(manifest_section_value "$manifest" "human_control" "approver")"
  gate="$(manifest_nested_value "$manifest" "approvals" "current_gate" "gate")"
  gate_status="$(manifest_nested_value "$manifest" "approvals" "current_gate" "status")"
  required_approver="$(manifest_nested_value "$manifest" "approvals" "current_gate" "required_approver")"
  approved_by="$(manifest_nested_value "$manifest" "approvals" "current_gate" "approved_by")"
  approved_on="$(manifest_nested_value "$manifest" "approvals" "current_gate" "approved_on")"
  next_gate="$(manifest_nested_value "$manifest" "approvals" "current_gate" "next_gate")"
  next_role="$(manifest_nested_value "$manifest" "approvals" "current_gate" "next_role")"
  next_artifact="$(manifest_nested_value "$manifest" "approvals" "current_gate" "next_artifact")"
  risks="$(manifest_current_gate_list_values "$manifest" "risks_accepted")"
  blockers="$(manifest_current_gate_list_values "$manifest" "blocking_open_questions")"
  evidence="$(manifest_current_gate_list_values "$manifest" "evidence")"

  if ! valid_gate_status "$gate_status"; then
    fail "Manifest approval status is not recognized: $gate_status"
  fi

  if [ -n "$project_gate" ] && [ -n "$gate" ] && [ "$project_gate" != "$gate" ]; then
    fail "Project current_gate ($project_gate) differs from approvals.current_gate.gate ($gate)."
  fi

  if [ "$gate_status" = "ready_for_approval" ]; then
    if is_unknown "$owner"; then
      warn "Gate is ready_for_approval but human_control.owner is not set."
    fi
    if is_unknown "$approver" && is_unknown "$required_approver"; then
      warn "Gate is ready_for_approval but no approver is set."
    fi
    if [ -z "$evidence" ]; then
      warn "Gate is ready_for_approval but evidence is missing."
    fi
    if [ -z "$risks" ] || printf '%s\n' "$risks" | grep -Eq '^TBD$|^$'; then
      warn "Gate is ready_for_approval but risk disposition is still TBD."
    fi
    if printf '%s\n' "$blockers" | grep -Eq '^TBD$'; then
      warn "Gate is ready_for_approval but blocking_open_questions is still TBD."
    fi
    if is_unknown "$next_gate" || is_unknown "$next_role" || is_unknown "$next_artifact"; then
      warn "Gate is ready_for_approval but next gate, role, or artifact is missing."
    fi
  fi

  if [ "$gate_status" = "approved" ]; then
    if ! valid_gate_value "$gate"; then
      fail "Gate is approved but approvals.current_gate.gate is not valid: $gate"
    fi
    if is_unknown "$approved_by"; then
      fail "Gate is approved but approved_by is not set."
    fi
    if is_unknown "$approved_on"; then
      fail "Gate is approved but approved_on is not set."
    elif ! printf '%s\n' "$approved_on" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
      fail "Gate is approved but approved_on is not an ISO date: $approved_on"
    fi
    if [ -z "$evidence" ]; then
      fail "Gate is approved but evidence is missing."
    elif ! list_has_known_value "$evidence"; then
      fail "Gate is approved but evidence contains no concrete path."
    fi
    if [ -z "$risks" ] || printf '%s\n' "$risks" | grep -Eq '^TBD$|^$'; then
      fail "Gate is approved but risk disposition is still TBD."
    fi
    if printf '%s\n' "$blockers" | grep -Eq '^TBD$'; then
      fail "Gate is approved but blocking_open_questions is still TBD."
    fi
    if is_unknown "$next_gate" || is_unknown "$next_role" || is_unknown "$next_artifact"; then
      fail "Gate is approved but next gate, role, or artifact is missing."
    fi
    record_format="$(manifest_section_value "$manifest" "approvals" "record_format")"
    if [ "$record_format" = "structured_markdown_yaml" ]; then
      if [ -f "$log" ] && ! gate_log_has_structured_event "$log" "gate_transition"; then
        fail "Gate is approved in structured mode but no structured gate transition exists in gate-log.md."
      fi
    else
      if [ -f "$log" ] &&
        ! gate_log_has_structured_event "$log" "gate_transition" &&
        ! gate_log_has_legacy_approval "$log"; then
        fail "Gate is approved in manifest but no approval record is visible in gate-log.md."
      fi
      if [ -f "$log" ] &&
        gate_log_has_legacy_approval "$log" &&
        ! gate_log_has_structured_event "$log" "gate_transition"; then
        fail "Gate is approved using a legacy prose record; structured gate event is required."
      fi
    fi
  fi
}

check_accepted_artifact_approval_records() {
  manifest="docs/project/project.yaml"
  accepted_count=0
  strict_approval_mode=0
  log="docs/project/approvals/gate-log.md"

  while IFS= read -r file; do
    if grep -Eq '^Status:[[:space:]]*Accepted[[:space:]]*$' "$file"; then
      accepted_count=$((accepted_count + 1))
    fi
  done < <(find docs/project -type f -name '*.md' -print)

  if [ "$accepted_count" -gt 0 ]; then
    # Strict mode requires a complete structured transition event before any Accepted
    # artifact can pass. `approvals.latest_decision` is a summary record and never
    # substitutes for a real transition event.
    gate_status="$(manifest_nested_value "$manifest" "approvals" "current_gate" "status")"
    record_format="$(manifest_section_value "$manifest" "approvals" "record_format")"
    target_gate="$(manifest_nested_value "$manifest" "approvals" "current_gate" "gate")"
    if [ -z "$target_gate" ]; then
      target_gate="$(manifest_section_value "$manifest" "project" "current_gate")"
    fi

    case "$record_format" in
      structured_markdown_yaml)
        strict_approval_mode=1
        ;;
    esac

    if [ "$strict_approval_mode" -eq 1 ]; then
      if [ -f "$log" ] && gate_log_has_strict_approval_event "$log" "$target_gate"; then
        return
      fi
      fail "Accepted artifact exists but no complete durable approval event is visible for gate $target_gate in $log. approvals.latest_decision cannot substitute."
      return
    fi

    # In legacy mode, manifest signals are treated as a summary plus evidence,
    # not as replacement for structured event evidence.
    latest_decision="$(manifest_nested_value "$manifest" "approvals" "latest_decision" "decision")"
    latest_decided_by="$(manifest_nested_value "$manifest" "approvals" "latest_decision" "decided_by")"

    approved=1
    case "$gate_status" in
      approved) approved=0 ;;
    esac
    case "$latest_decision" in
      approved | accepted | Approved | Accepted)
        # Require a real decider, not the fresh-init/template placeholder.
        case "$latest_decided_by" in
          "" | TBD | tbd) : ;;
          *) approved=0 ;;
        esac
        ;;
    esac

    if [ "$approved" -ne 0 ]; then
      warn "Accepted artifact exists but the manifest records no real approval (approvals.current_gate.status is not approved and approvals.latest_decision is unset or TBD)."
    fi
  fi
}

check_current_gate_artifact_status() {
  manifest="docs/project/project.yaml"

  [ -f "$manifest" ] || return

  project_gate="$(manifest_section_value "$manifest" "project" "current_gate")"
  gate_status="$(manifest_nested_value "$manifest" "approvals" "current_gate" "status")"
  artifact=""

  case "$project_gate" in
    G1)
      artifact="$(find docs/project/vision -maxdepth 1 -type f -name '*.md' | sort | head -n 1)"
      ;;
    G2)
      artifact="$(find docs/project/prd -maxdepth 1 -type f -name '*.md' | sort | head -n 1)"
      ;;
    G3)
      artifact="$(find docs/project/architecture -maxdepth 1 -type f -name '*.md' | sort | head -n 1)"
      ;;
    G4)
      artifact="$(find docs/project/security-governance -maxdepth 1 -type f -name '*.md' | sort | head -n 1)"
      ;;
  esac

  [ -n "$artifact" ] || return

  artifact_status="$(artifact_status "$artifact")"

  case "$artifact_status" in
    Stale | Superseded)
      warn "$project_gate current artifact is $artifact_status and needs reconciliation: $artifact"
      ;;
  esac

  if [ "$gate_status" = "ready_for_approval" ]; then
    case "$artifact_status" in
      "Ready for Approval" | "Accepted")
        ;;
      *)
        warn "$project_gate is ready_for_approval but $artifact status is '$artifact_status'."
        ;;
    esac
  fi

  if [ "$gate_status" = "approved" ]; then
    case "$artifact_status" in
      "Accepted" | "Complete")
        ;;
      *)
        warn "$project_gate is approved but $artifact status is '$artifact_status'."
        ;;
    esac
  fi
}

check_vision_success_criteria() {
  for file in docs/project/vision/*.md; do
    [ -e "$file" ] || continue

    status="$(artifact_status "$file")"
    case "$status" in
      "Ready for Approval" | "Accepted")
        ;;
      *)
        continue
        ;;
    esac

    criteria_block="$(
      awk '
        /^## Success Criteria/ {
          in_section = 1
          next
        }
        in_section && /^## / {
          exit
        }
        in_section {
          print
        }
      ' "$file"
    )"

    if ! printf '%s\n' "$criteria_block" |
      grep -Eq '\|[[:space:]]*Criterion[[:space:]]*\|[[:space:]]*Measure[[:space:]]*\|[[:space:]]*Target[[:space:]]*\|[[:space:]]*Read Timing[[:space:]]*\|[[:space:]]*Owner[[:space:]]*\|[[:space:]]*Evidence Source[[:space:]]*\|'; then
      fail "$file has ready/accepted status but success criteria do not include measurement fields."
      continue
    fi

    if ! printf '%s\n' "$criteria_block" |
      awk -F'|' '
        function trim(value) {
          gsub(/^[[:space:]]+/, "", value)
          gsub(/[[:space:]]+$/, "", value)
          return value
        }
        function complete(value) {
          value = trim(value)
          return value != "" && value != "TBD" && value !~ /^-+$/
        }
        /^\|/ {
          criterion = trim($2)
          if (criterion == "" || criterion == "Criterion" || criterion ~ /^---$/) {
            next
          }
          if (complete($2) && complete($3) && complete($4) && complete($5) && complete($6) && complete($7)) {
            found = 1
          }
        }
        END {
          exit !found
        }
      '; then
      fail "$file has ready/accepted status but no complete measurable success criterion."
    fi
  done
}

prd_body_without_ears_instruction() {
  file="$1"

  awk '
    /^### Acceptance Criteria in EARS Form/ { in_instr = 1; next }
    in_instr && /^(##|---)/ { in_instr = 0 }
    in_instr { next }
    { print }
  ' "$file"
}

has_ears_acceptance_criteria() {
  file="$1"

  prd_body_without_ears_instruction "$file" |
    grep -E '(When|While|If|Where)[^|<>]*shall|\bThe system shall\b' |
    grep -vq '<[a-z]'
}

has_unwanted_acceptance_criteria() {
  file="$1"

  prd_body_without_ears_instruction "$file" |
    grep -Ei '(^|[^A-Za-z])If[^|<>]*((then)|(the system shall))' |
    grep -vq '<[a-z]'
}

has_observable_acceptance_criteria() {
  file="$1"

  prd_body_without_ears_instruction "$file" |
    awk -F'|' '
      function trim(value) {
        gsub(/^[[:space:]]+/, "", value)
        gsub(/[[:space:]]+$/, "", value)
        return value
      }
      function complete(value) {
        value = trim(value)
        return value != "" &&
          value != "TBD" &&
          value !~ /^-+$/ &&
          value !~ /^\[[^][]+\]$/ &&
          value !~ /<[^>]+>/
      }
      /^\|/ {
        if ($0 ~ /^[[:space:]]*\|[[:space:]-]+\|/) {
          next
        }
        if ($0 ~ /Acceptance Criteria/) {
          ac_idx = 0
          for (i = 1; i <= NF; i++) {
            if (trim($i) == "Acceptance Criteria") {
              ac_idx = i
            }
          }
          next
        }
        id = trim($2)
        if (ac_idx > 0 && id ~ /^REQ-/ && complete($ac_idx)) {
          found = 1
        }
      }
      END { exit !found }
    '
}

check_ears_acceptance_criteria() {
  # Validate that ready/accepted PRDs meet their class-specific G2 criteria:
  # C2/C3 require concrete EARS form, C1 may use concrete observable criteria,
  # and every class must carry unwanted-behavior criteria.
  manifest="docs/project/project.yaml"
  blast=""
  [ -f "$manifest" ] && blast="$(manifest_section_value "$manifest" "scaling" "blast_radius_class" 2>/dev/null || true)"

  for file in docs/project/prd/*.md; do
    [ -e "$file" ] || continue

    status="$(artifact_status "$file")"
    case "$status" in
      "Ready for Approval" | "Accepted") ;;
      *) continue ;;
    esac

    case "$blast" in
      C1)
        if ! has_ears_acceptance_criteria "$file" &&
          ! has_observable_acceptance_criteria "$file"; then
          fail "$file ($status) is a C1 PRD but contains no concrete observable acceptance criteria."
        fi
        ;;
      *)
        if ! has_ears_acceptance_criteria "$file"; then
          fail "$file ($status) is a C2/C3 PRD but contains no concrete EARS-form acceptance criteria (When/While/If/Where ... shall, or The system shall), excluding the template's instructional examples. See constitution Verification-First Principle."
        fi
        ;;
    esac

    if ! has_unwanted_acceptance_criteria "$file"; then
      fail "$file ($status) has no concrete unwanted-behavior acceptance criteria."
    fi
  done
}

verification_spec_has_trace() {
  spec="$1"

  printf '%s\n' "$spec" | grep -Eq '^Requirement:[[:space:]]*REQ-' &&
    printf '%s\n' "$spec" | grep -Eq '^Behavioral:[[:space:]]*.+' &&
    printf '%s\n' "$spec" | grep -Eq '^Design:[[:space:]]*.+' &&
    printf '%s\n' "$spec" | grep -Eq '^Implementation:[[:space:]]*.+' &&
    printf '%s\n' "$spec" | grep -Eq '^UAT:[[:space:]]*.+'
}

verification_spec_has_interrogation_answer() {
  spec="$1"

  printf '%s\n' "$spec" |
    grep -Eiq '^(Interrogation|Design interrogation|Failure modes|Scale limits|Evolution risk|Security boundary):[[:space:]]*[A-Za-z0-9]'
}

verification_spec_is_human_approved() {
  spec="$1"

  approved_by="$(printf '%s\n' "$spec" | grep -E '^Approved by:' | head -1 | sed -E 's/^Approved by:[[:space:]]*//')"
  approved_on="$(printf '%s\n' "$spec" | grep -E '^Approved on:' | head -1 | sed -E 's/^Approved on:[[:space:]]*//')"

  if is_unknown "$approved_by"; then
    return 1
  fi
  if is_unknown "$approved_on" || ! printf '%s\n' "$approved_on" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
    return 1
  fi

  return 0
}

check_verification_specification() {
  # Validate that a ready/accepted architecture carries a human-approved
  # Verification Specification (constitution Verification-First Principle; G3).
  for file in docs/project/architecture/*.md; do
    [ -e "$file" ] || continue

    status="$(artifact_status "$file")"
    case "$status" in
      "Ready for Approval" | "Accepted") ;;
      *) continue ;;
    esac

    if ! grep -Eq '^## Verification Specification' "$file"; then
      fail "$file ($status) is missing the required Verification Specification section (G3)."
      continue
    fi

    spec_block="$(
      awk '
        /^## Verification Specification/ { in_section = 1; next }
        in_section && /^## / { exit }
        in_section { print }
      ' "$file"
    )"

    if ! verification_spec_is_human_approved "$spec_block"; then
      fail "$file Verification Specification is not human-approved (Approved by/on is empty, TBD, or malformed)."
    fi
    if ! verification_spec_has_trace "$spec_block"; then
      fail "$file Verification Specification does not trace to G2 criteria."
    fi
    if ! verification_spec_has_interrogation_answer "$spec_block"; then
      fail "$file is missing recorded design-verification interrogation answers."
    fi
  done
}

check_phase_position() {
  manifest="docs/project/project.yaml"
  [ -f "$manifest" ] || return

  # Phase-loop fields are optional. A manifest without phase_position or a
  # null/empty value is valid (backward compatibility with pre-phase-loop
  # projects). Validation only runs when phase_position carries a value.
  position="$(manifest_section_value "$manifest" "phase" "phase_position")"
  case "$position" in
    ""|null|NULL|"~"|TBD) return ;;
  esac

  phase_entries="$(manifest_phase_entries "$manifest")"

  # Position grammar: G5.<phase-id>.<checkpoint>, checkpoint in 0-4.
  # G5.0 is the loop-start address and carries no phase id.
  if [ "$position" = "G5.0" ]; then
    if [ -z "$phase_entries" ]; then
      fail "Manifest phase.phase_position is G5.0 but phase.phases declares no phase partition."
    fi
    return
  fi
  if ! printf '%s' "$position" | grep -Eq '^G5\.[A-Za-z0-9-]+\.[1-4]$'; then
    fail "Manifest phase.phase_position is not a valid checkpoint address: $position"
    return
  fi

  # The phase id embedded in the position must be declared in phases[].
  pos_phase_id="$(printf '%s' "$position" | sed -E 's/^G5\.([A-Za-z0-9-]+)\.[1-4]$/\1/')"
  declared_ids="$(printf '%s\n' "$phase_entries" | awk -F'|' 'NF { print $1 }')"

  if [ -n "$declared_ids" ]; then
    if ! printf '%s\n' "$declared_ids" | grep -Fxq "$pos_phase_id"; then
      fail "Manifest phase.phase_position references phase id '$pos_phase_id' not declared in phase.phases."
    fi
  else
    # A populated phase_position requires a declared phases list. An empty or
    # missing phases[] with an active interior checkpoint is invalid: the phase
    # id has no authoritative declaration to order against.
    fail "Manifest phase.phase_position is set ($position) but phase.phases declares no phases."
  fi
}

check_phase_exit_evidence() {
  phase_id="$1"
  log="docs/project/approvals/gate-log.md"

  if ! exit_event_count="$(gate_log_phase_exit_event_count "$log" "$phase_id")"; then
    fail "Malformed structured phase transition record in $log."
    return
  fi

  if [ "$exit_event_count" -eq 0 ]; then
    fail "Phase $phase_id is marked exited but no complete G5.$phase_id.4 phase_transition event is visible in gate-log.md."
  fi

  for artifact_id in \
    implementation_evidence \
    phase_test_uat \
    phase_code_review \
    phase_remediation \
    traceability \
    phase_as_built \
    phase_learnings; do
    path="$(phase_artifact_path "$artifact_id" "$phase_id")"
    expected="$(gendev_checkpoint_artifact_resulting_statuses 'G5.<id>.4' "$artifact_id" 2>/dev/null || true)"

    if [ ! -f "$path" ]; then
      fail "Phase $phase_id is exited but required phase-exit artifact is missing: $path"
      continue
    fi

    status="$(artifact_status "$path")"
    if ! status_in_list "$status" "$expected"; then
      fail "Phase $phase_id exit artifact $path has status '$status'; expected one of: $expected"
    fi
  done
}

check_phase_lifecycle_state() {
  manifest="docs/project/project.yaml"
  [ -f "$manifest" ] || return

  phase_entries="$(manifest_phase_entries "$manifest")"
  [ -n "$phase_entries" ] || return

  position="$(manifest_section_value "$manifest" "phase" "phase_position")"
  project_gate="$(manifest_section_value "$manifest" "project" "current_gate")"
  pos_phase_id=""
  pos_checkpoint=""
  if printf '%s\n' "$position" | grep -Eq '^G5\.[A-Za-z0-9-]+\.[1-4]$'; then
    pos_phase_id="$(printf '%s' "$position" | sed -E 's/^G5\.([A-Za-z0-9-]+)\.[1-4]$/\1/')"
    pos_checkpoint="$(printf '%s' "$position" | sed -E 's/^G5\.[A-Za-z0-9-]+\.([1-4])$/\1/')"
  fi

  prior_to_position=1
  last_phase_id=""
  exited_count=0
  phase_count=0

  while IFS='|' read -r phase_id phase_status; do
    [ -n "$phase_id" ] || continue
    phase_count=$((phase_count + 1))
    last_phase_id="$phase_id"

    case "$phase_status" in
      pending | in_progress | exited)
        ;;
      "")
        fail "Manifest phase.phases entry $phase_id is missing status."
        ;;
      *)
        fail "Manifest phase.phases entry $phase_id has invalid status: $phase_status"
        ;;
    esac

    if [ -n "$pos_phase_id" ]; then
      if [ "$phase_id" = "$pos_phase_id" ]; then
        prior_to_position=0
        if [ "$pos_checkpoint" = "4" ] && [ "$phase_status" != "exited" ]; then
          fail "Manifest phase.phase_position is G5.$phase_id.4 but phase $phase_id status is not exited."
        fi
        if [ "$pos_checkpoint" != "4" ] && [ "$phase_status" = "exited" ]; then
          fail "Manifest phase $phase_id is exited but phase.phase_position has not reached G5.$phase_id.4."
        fi
      elif [ "$prior_to_position" -eq 1 ] && [ "$phase_status" != "exited" ]; then
        fail "Manifest phase.phase_position is $position but prior phase $phase_id has not exited."
      fi
    fi

    if [ "$phase_status" = "exited" ]; then
      exited_count=$((exited_count + 1))
      check_phase_exit_evidence "$phase_id"
    fi
  done <<EOF
$phase_entries
EOF

  case "$project_gate" in
    G6 | G7 | G8 | G9)
      if [ "$phase_count" -eq 0 ]; then
        fail "Project current_gate is $project_gate but phase.phases declares no phases."
      elif [ "$exited_count" -ne "$phase_count" ]; then
        fail "Project current_gate is $project_gate but not every declared phase has exited."
      fi

      if [ -n "$last_phase_id" ] && [ "$position" != "G5.$last_phase_id.4" ]; then
        fail "Project current_gate is $project_gate but phase.phase_position is '$position'; expected final phase exit G5.$last_phase_id.4."
      fi
      ;;
  esac
}

check_tactical_task_model() {
  while IFS= read -r file; do
    [ -n "$file" ] || continue

    declared_tasks="$(tactical_declared_task_ids "$file")"
    declared_workstreams="$(tactical_declared_workstream_ids "$file")"

    if [ -z "$declared_tasks" ]; then
      fail "$file is Accepted but declares no tactical task IDs under ## Workstreams."
    fi

    while IFS= read -r task_id; do
      [ -n "$task_id" ] || continue
      if ! valid_task_id "$task_id"; then
        fail "$file declares malformed tactical task ID: $task_id"
      fi
    done <<EOF
$declared_tasks
EOF

    while IFS= read -r task_id; do
      [ -n "$task_id" ] || continue
      if ! valid_task_id "$task_id"; then
        fail "$file references malformed tactical task ID: $task_id"
        continue
      fi
      if ! printf '%s\n' "$declared_tasks" | grep -Fxq "$task_id"; then
        fail "$file references undeclared tactical task ID: $task_id"
      fi
    done <<EOF
$(file_task_id_tokens "$file")
EOF

    while IFS= read -r workstream_id; do
      [ -n "$workstream_id" ] || continue
      if ! valid_workstream_id "$workstream_id"; then
        fail "$file references malformed workstream ID: $workstream_id"
        continue
      fi
      if [ -n "$declared_workstreams" ] &&
        ! printf '%s\n' "$declared_workstreams" | grep -Fxq "$workstream_id"; then
        fail "$file references undeclared workstream ID: $workstream_id"
      fi
    done <<EOF
$(file_workstream_id_tokens "$file")
EOF
  done <<EOF
$(accepted_tactical_plans)
EOF
}

check_phase_plans() {
  for file in docs/project/build-plan/phases/*build-plan*.md; do
    [ -e "$file" ] || continue
    check_heading "$file" "Acceptance Criteria"
    check_heading "$file" "Test Strategy"
    if ! grep -Eq '^## Documentation Close-Out' "$file"; then
      fail "$file is missing documentation close-out section"
    fi
  done

  for file in docs/project/build-plan/phases/*tactical*.md; do
    [ -e "$file" ] || continue
    check_heading "$file" "Workstreams"
    check_heading "$file" "Accuracy Pass"
    if ! grep -Eq 'Verification Commands' "$file"; then
      fail "$file is missing verification command guidance"
    fi
  done
}

check_traceability_evidence() {
  known_tasks="$(known_tactical_task_ids)"

  for file in docs/project/traceability/*.md; do
    [ -e "$file" ] || continue
    awk -F'|' '
      NR > 2 {
        status = tolower($11)
        evidence = $9
        review = $10
        gsub(/[[:space:]]/, "", status)
        gsub(/[[:space:]]/, "", evidence)
        gsub(/[[:space:]]/, "", review)
        if (status == "verified" && (evidence == "" || review == "")) {
          printf "%s:%d\n", FILENAME, FNR
        }
      }
    ' "$file" |
      while IFS= read -r location; do
        printf 'ERROR: Traceability row marked verified without evidence/review: %s\n' "$location"
        exit 1
      done

    if [ "$?" -ne 0 ]; then
      errors=$((errors + 1))
    fi

    [ -n "$known_tasks" ] || continue

    while IFS='|' read -r line_no task_cell row_status; do
      task_cell="$(printf '%s\n' "$task_cell" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      row_status="$(printf '%s\n' "$row_status" | tr '[:upper:]' '[:lower:]' | sed 's/[[:space:]]//g')"

      case "$task_cell" in
        "" | "TBD" | "N/A" | "n/a" | "-")
          case "$row_status" in
            deferred | rejected | blocked)
              continue
              ;;
            *)
              fail "$file:$line_no has an active traceability row without a tactical task ID."
              continue
              ;;
          esac
          ;;
      esac

      task_tokens="$(printf '%s\n' "$task_cell" | grep -Eo 'PH-[A-Za-z0-9]+(-[A-Za-z0-9]+)*-T[0-9]+' || true)"
      if [ -z "$task_tokens" ]; then
        fail "$file:$line_no tactical task cell does not contain a valid task ID token: $task_cell"
        continue
      fi

      while IFS= read -r task_id; do
        [ -n "$task_id" ] || continue
        if ! valid_task_id "$task_id"; then
          fail "$file:$line_no references malformed tactical task ID: $task_id"
          continue
        fi
        if [ -n "$known_tasks" ] &&
          ! printf '%s\n' "$known_tasks" | grep -Fxq "$task_id"; then
          fail "$file:$line_no references tactical task ID not declared in an Accepted tactical plan: $task_id"
        fi
      done <<EOF
$task_tokens
EOF
    done <<EOF
$(awk -F'|' '
  NR > 2 && /^\|/ {
    status = $11
    task = $7
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", task)
    if (tolower($2) ~ /^[[:space:]]*-+[[:space:]]*$/ || tolower($2) ~ /^[[:space:]]*req id[[:space:]]*$/) {
      next
    }
    print FNR "|" task "|" status
  }
' "$file")
EOF
  done
}

check_code_review_context_provenance() {
  for file in docs/project/build-plan/phases/*code-review*.md; do
    [ -e "$file" ] || continue

    if ! grep -Eq '^## Context Provenance([[:space:]]|$)' "$file"; then
      warn "$file is missing context provenance section."
      continue
    fi

    for field in \
      "Reviewing agent:" \
      "Model/version:" \
      "Review context created on:" \
      "Inputs provided:" \
      "Authority document revisions used:" \
      "Implementation diff or commit reviewed:" \
      "Implementer session shared with reviewer:" \
      "Exceptions:"; do
      if ! grep -Fq "$field" "$file"; then
        warn "$file context provenance is missing field: $field"
      fi
    done
  done
}

# Shared helper aliases from scripts/lib/gendev-common.sh.
is_unknown() {
  gendev_is_unknown "$@"
}

manifest_section_value() {
  gendev_manifest_section_value "$@"
}

manifest_nested_value() {
  gendev_manifest_nested_value "$@"
}

manifest_section_list_values() {
  gendev_manifest_section_list_values "$@"
}

manifest_current_gate_block() {
  gendev_manifest_current_gate_block "$@"
}

manifest_current_gate_list_values() {
  gendev_manifest_current_gate_list_values "$@"
}

manifest_section_block() {
  gendev_manifest_section_block "$@"
}

gate_log_records_section() {
  gendev_gate_log_records_section "$@"
}

gate_log_load_events() {
  gendev_gate_log_load_events "$@"
}

gate_log_events() {
  gendev_gate_log_events "$@"
}

gate_log_has_structured_event() {
  gendev_gate_log_has_structured_event "$@"
}

gate_log_has_legacy_approval() {
  gendev_gate_log_has_legacy_approval "$@"
}

gate_log_missing_executable_evidence_for_g6_plus() {
  gendev_gate_log_missing_executable_evidence_for_g6_plus "$@"
}

gate_log_has_stale_gate_transition_evidence() {
  gendev_gate_log_has_stale_gate_transition_evidence "$@"
}

check_baseline_files
check_sample_reference_drift

if [ ! -d "docs/project" ]; then
  info "docs/project is not initialized. Run: ./scripts/init-project.sh \"Project Name\""
else
  check_project_structure
  check_manifest_paths
  check_gate_log_record_format
  check_gate_log_evidence_item_bindings
  check_version_compatibility_state
  check_manifest_gate_values
  check_manifest_approval_state
  check_accepted_doc_placeholders
  check_accepted_artifact_approval_records
  check_artifact_provenance
  check_project_identity_field
  check_computed_staleness
  check_stale_evidence
  check_manifest_amendment_state
  check_manifest_scaling_state
  check_manifest_enforcement_state
  check_diff_gate_movement
  check_gate_log_append_only_history
  check_changed_path_enforcement
  check_current_gate_artifact_status
  check_vision_success_criteria
  check_ears_acceptance_criteria
  check_verification_specification
  check_phase_plans
  check_phase_position
  check_phase_lifecycle_state
  check_late_gate_lifecycle_state
  check_tactical_task_model
  check_traceability_evidence
  check_code_review_context_provenance
fi

if [ "$errors" -gt 0 ]; then
  printf '\nMethodology check failed: %d error(s), %d warning(s).\n' "$errors" "$warnings"
  exit 1
fi

printf '\nMethodology check passed: %d warning(s).\n' "$warnings"
