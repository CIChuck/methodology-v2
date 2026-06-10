#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -u

errors=0
warnings=0

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

require_file() {
  if [ ! -f "$1" ]; then
    fail "Missing required file: $1"
  fi
}

require_dir() {
  if [ ! -d "$1" ]; then
    fail "Missing required directory: $1"
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
  require_file "docs/methodology/guides/orchestration-validation.md"
  require_dir "docs/methodology/templates"
  require_dir "docs/methodology/dev-skills"
  require_dir "docs/methodology/agents/roles"
  require_file "scripts/init-project.sh"
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
      fail "Manifest path does not exist: $path"
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

  case "$gate_status" in
    pending | drafting | ready_for_review | ready_for_approval | approved | blocked | superseded)
      ;;
    "")
      warn "Manifest approval status is missing."
      ;;
    *)
      warn "Manifest approval status is not recognized: $gate_status"
      ;;
  esac

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

  artifact_status="$(sed -n 's/^Status:[[:space:]]*//p' "$artifact" | head -n 1)"

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

check_baseline_files
check_sample_reference_drift

if [ ! -d "docs/project" ]; then
  info "docs/project is not initialized. Run: ./scripts/init-project.sh \"Project Name\""
else
  check_project_structure
  check_manifest_paths
  check_gate_log_record_format
  check_manifest_approval_state
  check_accepted_doc_placeholders
  check_accepted_artifact_approval_records
  check_current_gate_artifact_status
  check_phase_plans
  check_traceability_evidence
fi

if [ "$errors" -gt 0 ]; then
  printf '\nMethodology check failed: %d error(s), %d warning(s).\n' "$errors" "$warnings"
  exit 1
fi

printf '\nMethodology check passed: %d warning(s).\n' "$warnings"
