#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -u

errors=0
warnings=0
seen_failures=""

info() {
  printf 'INFO: %s\n' "$1"
}

warn() {
  warnings=$((warnings + 1))
  printf 'WARN: %s\n' "$1"
}

fail() {
  errors=$((errors + 1))
  printf 'ERROR: %s\n' "$1"
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
    in_records {
      print
    }
  ' "$log"
}

gate_log_has_structured_event() {
  log="$1"
  event_type="$2"

  [ -f "$log" ] || return 1

  gate_log_records_section "$log" |
    grep -Eq "^[[:space:]]*event_type:[[:space:]]*${event_type}[[:space:]]*$"
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

  gate_log_records_section "$log" |
    awk '
      /^[[:space:]]*event_type:/ {
        if (in_gate_transition && gate_is_g6_plus && !has_executable_evidence) {
          missing = 1
        }
        in_gate_transition = ($0 ~ /^[[:space:]]*event_type:[[:space:]]*gate_transition[[:space:]]*$/)
        gate_is_g6_plus = 0
        has_executable_evidence = 0
        next
      }
      in_gate_transition && /^[[:space:]]*(to_gate|gate):[[:space:]]*G[6-9][[:space:]]*$/ {
        gate_is_g6_plus = 1
      }
      in_gate_transition && /^[[:space:]]*(executable_evidence|verification_evidence|verification):/ {
        has_executable_evidence = 1
      }
      END {
        if (in_gate_transition && gate_is_g6_plus && !has_executable_evidence) {
          missing = 1
        }
        exit !missing
      }
    '
}

gate_log_has_stale_gate_transition_evidence() {
  log="$1"

  [ -f "$log" ] || return 1

  gate_log_records_section "$log" |
    awk '
      /^[[:space:]]*event_type:/ {
        if (in_gate_transition && stale_evidence) {
          found = 1
        }
        in_gate_transition = ($0 ~ /^[[:space:]]*event_type:[[:space:]]*gate_transition[[:space:]]*$/)
        stale_evidence = 0
        next
      }
      in_gate_transition && /^[[:space:]]*status:[[:space:]]*(Stale|Superseded)[[:space:]]*$/ {
        stale_evidence = 1
      }
      END {
        if (in_gate_transition && stale_evidence) {
          found = 1
        }
        exit !found
      }
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
    in_block && /^[[:space:]]+revision:[[:space:]]*.+/ {
      sub("^[[:space:]]+revision:[[:space:]]*", "")
      revision = $0
      if (path != "") {
        print path "|" revision
      }
    }
  ' "$file"
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
  paths="README.md AGENTS.md docs/examples docs/methodology/agents"

  if [ -d "docs/project" ]; then
    paths="$paths docs/project"
  fi

  if grep -R "docs/sample-project" -n $paths 2>/dev/null; then
    fail "Found stale docs/sample-project reference."
  fi
}

check_accepted_doc_placeholders() {
  while IFS= read -r file; do
    if grep -Eq '^(Status|status):[[:space:]]*(Accepted|Complete|accepted|complete)[[:space:]]*$' "$file"; then
      if grep -Eq '\[[^][]+\]|TBD|Replace with' "$file"; then
        fail "Accepted/complete document still has placeholders: $file"
      fi
    fi

    if grep -Eq '^(Status|status):[[:space:]]*(Ready for Approval|ready_for_approval)[[:space:]]*$' "$file"; then
      if grep -Eq '\[[^][]+\]|TBD|Replace with' "$file"; then
        warn "Ready-for-approval document still has placeholders: $file"
      fi
    fi
  done < <(find docs/project -type f \( -name '*.md' -o -name '*.yaml' \) -print)
}

check_gate_log_record_format() {
  log="docs/project/approvals/gate-log.md"

  [ -f "$log" ] || return

  records="$(gate_log_records_section "$log")"

  if printf '%s\n' "$records" | grep -Eq '^[[:space:]]*event_type:[[:space:]]*gate_transition[[:space:]]*$'; then
    if ! printf '%s\n' "$records" | grep -Eq '^[[:space:]]*checked:[[:space:]]*.+'; then
      warn "Structured gate transition exists but no checked statement was found in gate-log.md."
    fi
    if ! printf '%s\n' "$records" | grep -Eq '^[[:space:]]*evidence:'; then
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
    elif gate_log_records_section "$log" |
      grep -Eq '^[[:space:]]*status:[[:space:]]*(Stale|Superseded)[[:space:]]*$'; then
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
      warn "Manifest attested enforcement is missing attestation cadence."
    fi
    if [ -z "$required_attester" ]; then
      warn "Manifest attested enforcement is missing required_attester field."
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

  if ! is_unknown "$next_gate" && ! valid_gate_value "$next_gate"; then
    fail "Manifest approvals.current_gate.next_gate is not a valid gate: $next_gate"
  fi
}

check_diff_gate_movement() {
  manifest="docs/project/project.yaml"
  log="docs/project/approvals/gate-log.md"

  [ -f "$manifest" ] || return
  [ -n "${GENDEV_BASE_REF:-}" ] || return
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return

  tmp_manifest="$(mktemp)"
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
    elif ! gate_log_has_structured_event "$log" "gate_transition"; then
      fail "project.current_gate changed from $base_gate to $current_gate without a structured gate transition."
    fi
  fi
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
    warn "Project current_gate ($project_gate) differs from approvals.current_gate.gate ($gate)."
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
    if is_unknown "$approved_by"; then
      fail "Gate is approved but approved_by is not set."
    fi
    if is_unknown "$approved_on"; then
      fail "Gate is approved but approved_on is not set."
    fi
    if [ -z "$evidence" ]; then
      fail "Gate is approved but evidence is missing."
    fi
    if [ -z "$risks" ] || printf '%s\n' "$risks" | grep -Eq '^TBD$|^$'; then
      fail "Gate is approved but risk disposition is still TBD."
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
        warn "Gate is approved in manifest but no approval record is visible in gate-log.md."
      fi
      if [ -f "$log" ] &&
        gate_log_has_legacy_approval "$log" &&
        ! gate_log_has_structured_event "$log" "gate_transition"; then
        warn "Gate is approved using a legacy prose record; structured gate event is recommended."
      fi
    fi
  fi
}

check_accepted_artifact_approval_records() {
  manifest="docs/project/project.yaml"
  log="docs/project/approvals/gate-log.md"
  accepted_count=0

  while IFS= read -r file; do
    if grep -Eq '^Status:[[:space:]]*Accepted[[:space:]]*$' "$file"; then
      accepted_count=$((accepted_count + 1))
    fi
  done < <(find docs/project -type f -name '*.md' -print)

  if [ "$accepted_count" -gt 0 ]; then
    gate_status="$(manifest_nested_value "$manifest" "approvals" "current_gate" "status")"
    if [ "$gate_status" != "approved" ] && { [ ! -f "$log" ] || ! grep -Eq 'Decision:[[:space:]]*(Approved|Accepted)' "$log"; }; then
      warn "Accepted artifact exists but no approved manifest state or gate-log decision was found."
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

check_baseline_files
check_sample_reference_drift

if [ ! -d "docs/project" ]; then
  info "docs/project is not initialized. Run: ./scripts/init-project.sh \"Project Name\""
else
  check_project_structure
  check_manifest_paths
  check_gate_log_record_format
  check_manifest_gate_values
  check_manifest_approval_state
  check_accepted_doc_placeholders
  check_accepted_artifact_approval_records
  check_artifact_provenance
  check_computed_staleness
  check_stale_evidence
  check_manifest_amendment_state
  check_manifest_enforcement_state
  check_diff_gate_movement
  check_changed_path_enforcement
  check_current_gate_artifact_status
  check_vision_success_criteria
  check_phase_plans
  check_traceability_evidence
  check_code_review_context_provenance
fi

if [ "$errors" -gt 0 ]; then
  printf '\nMethodology check failed: %d error(s), %d warning(s).\n' "$errors" "$warnings"
  exit 1
fi

printf '\nMethodology check passed: %d warning(s).\n' "$warnings"
