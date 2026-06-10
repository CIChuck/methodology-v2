#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -eu

project_dir="${1:-docs/project}"

printf '# GenDev Metrics Report\n\n'
printf 'Project directory: `%s`\n\n' "$project_dir"

if [ ! -d "$project_dir" ]; then
  printf 'Status: project directory not initialized.\n'
  printf '\nRun `./scripts/init-project.sh "Project Name"` before collecting project metrics.\n'
  exit 0
fi

gate_log="$project_dir/approvals/gate-log.md"

printf '## Gate Log Metrics\n\n'

if [ ! -f "$gate_log" ]; then
  printf 'Gate log not found: `%s`\n\n' "$gate_log"
else
  awk '
    /^## Gate Records/ {
      in_records = 1
      next
    }
    in_records {
      print
    }
  ' "$gate_log" |
  awk '
    function trim(value) {
      gsub(/^[[:space:]]+/, "", value)
      gsub(/[[:space:]]+$/, "", value)
      gsub(/^"|"$/, "", value)
      return value
    }
    function line_value() {
      value = $0
      sub(/^[[:space:]]*[A-Za-z0-9_]+:[[:space:]]*/, "", value)
      return trim(value)
    }
    function days(date, parts, y, m, d) {
      if (date !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) {
        return ""
      }
      split(date, parts, "-")
      y = parts[1] + 0
      m = parts[2] + 0
      d = parts[3] + 0
      if (m < 3) {
        y -= 1
        m += 12
      }
      return int(365 * y + y / 4 - y / 100 + y / 400 + (153 * (m - 3) + 2) / 5 + d - 719469)
    }
    function finish_event(    start_days, approval_days, decided_days, delta) {
      if (event_type == "") {
        return
      }

      event_count[event_type]++

      if (event_type == "gate_transition") {
        gate_transitions++

        start_days = days(gate_started_on)
        decided_days = days(decided_on)
        if (start_days != "" && decided_days != "") {
          delta = decided_days - start_days
          if (delta >= 0) {
            gate_cycle_count++
            gate_cycle_total += delta
          }
        } else {
          gate_cycle_missing++
        }

        approval_days = days(approval_requested_on)
        if (approval_days != "" && decided_days != "") {
          delta = decided_days - approval_days
          if (delta >= 0) {
            approval_latency_count++
            approval_latency_total += delta
          }
        } else {
          approval_latency_missing++
        }
      }

      if (event_type == "amendment") {
        amendments++
        if (current_gate != "") {
          amendment_by_gate[current_gate]++
        }
      }

      if (event_type == "gate_regression") {
        regressions++
      }

      if (event_type == "reconciliation") {
        reconciliations++
      }

      if (event_type == "traceability_sample") {
        traceability_samples++
        if (result != "" && result != "passed") {
          traceability_sample_discrepancies++
        }
      }

      if (event_type == "enforcement_attestation") {
        enforcement_attestations++
      }

      if (event_type == "enforcement_override") {
        enforcement_overrides++
      }
    }
    function reset_event() {
      event_type = ""
      from_gate = ""
      to_gate = ""
      current_gate = ""
      gate_started_on = ""
      ready_for_approval_on = ""
      approval_requested_on = ""
      decided_on = ""
      result = ""
    }
    /^[[:space:]]*event_type:/ {
      finish_event()
      reset_event()
      event_type = line_value()
      next
    }
    /^[[:space:]]*from_gate:/ {
      from_gate = line_value()
      next
    }
    /^[[:space:]]*to_gate:/ {
      to_gate = line_value()
      next
    }
    /^[[:space:]]*current_gate:/ {
      current_gate = line_value()
      next
    }
    /^[[:space:]]*gate:/ {
      current_gate = line_value()
      next
    }
    /^[[:space:]]*gate_started_on:/ {
      gate_started_on = line_value()
      next
    }
    /^[[:space:]]*ready_for_approval_on:/ {
      ready_for_approval_on = line_value()
      next
    }
    /^[[:space:]]*approval_requested_on:/ {
      approval_requested_on = line_value()
      next
    }
    /^[[:space:]]*decided_on:/ {
      decided_on = line_value()
      next
    }
    /^[[:space:]]*result:/ {
      result = line_value()
      next
    }
    END {
      finish_event()

      printf "- Structured events: %d\n", gate_transitions + amendments + regressions + reconciliations + traceability_samples + enforcement_attestations + enforcement_overrides
      printf "- Gate transitions: %d\n", gate_transitions

      if (gate_cycle_count > 0) {
        printf "- Average gate cycle days: %.1f (%d measured; %d missing timing fields)\n", gate_cycle_total / gate_cycle_count, gate_cycle_count, gate_cycle_missing
      } else {
        printf "- Average gate cycle days: N/A (%d missing timing fields)\n", gate_cycle_missing
      }

      if (approval_latency_count > 0) {
        printf "- Average approval latency days: %.1f (%d measured; %d missing timing fields)\n", approval_latency_total / approval_latency_count, approval_latency_count, approval_latency_missing
      } else {
        printf "- Average approval latency days: N/A (%d missing timing fields)\n", approval_latency_missing
      }

      printf "- Amendments: %d\n", amendments
      for (gate in amendment_by_gate) {
        printf "  - %s: %d\n", gate, amendment_by_gate[gate]
      }
      printf "- Gate regressions: %d\n", regressions
      printf "- Reconciliations: %d\n", reconciliations
      printf "- Traceability samples: %d\n", traceability_samples
      printf "- Traceability sample discrepancies: %d\n", traceability_sample_discrepancies
      printf "- Enforcement attestations: %d\n", enforcement_attestations
      printf "- Enforcement overrides: %d\n", enforcement_overrides
    }
  '
  printf '\n'
fi

printf '## Traceability Coverage\n\n'

if ! find "$project_dir/traceability" -type f -name '*.md' -print -quit 2>/dev/null | grep -q .; then
  printf 'No traceability matrix files found.\n\n'
else
  find "$project_dir/traceability" -type f -name '*.md' -exec awk -F'|' '
    function trim(value) {
      gsub(/^[[:space:]]+/, "", value)
      gsub(/[[:space:]]+$/, "", value)
      return value
    }
    /^## Matrix/ {
      in_matrix = 1
      next
    }
    in_matrix && /^## / {
      in_matrix = 0
    }
    !in_matrix {
      next
    }
    /^\|/ {
      req = trim($2)
      status = tolower(trim($11))
      if (req == "" || req == "Req ID" || req ~ /^---$/) {
        next
      }
      rows++
      status_count[status]++
      if (status == "verified") {
        verified++
      }
    }
    END {
      printf "- Requirement rows: %d\n", rows
      printf "- Verified rows: %d\n", verified
      if (rows > 0) {
        printf "- Traceability coverage: %.1f%%\n", (verified / rows) * 100
      } else {
        printf "- Traceability coverage: N/A\n"
      }
      for (status in status_count) {
        printf "  - %s: %d\n", status, status_count[status]
      }
    }
  ' {} +
  printf '\n'
fi

printf '## Value Review\n\n'

if ! find "$project_dir/as-built" -type f -name '*value-review*.md' -print -quit 2>/dev/null | grep -q .; then
  printf 'No value review files found.\n\n'
else
  find "$project_dir/as-built" -type f -name '*value-review*.md' -exec awk -F'|' '
    function trim(value) {
      gsub(/^[[:space:]]+/, "", value)
      gsub(/[[:space:]]+$/, "", value)
      return value
    }
    /^## Success Criteria Actuals/ {
      in_actuals = 1
      next
    }
    in_actuals && /^## / {
      in_actuals = 0
    }
    !in_actuals {
      next
    }
    /^\|/ {
      criterion = trim($2)
      result = tolower(trim($6))
      if (criterion == "" || criterion == "Criterion" || criterion ~ /^---$/) {
        next
      }
      rows++
      if (result == "met" || result == "missed" || result == "unmeasurable") {
        result_count[result]++
      } else {
        result_count["not_recorded"]++
      }
    }
    END {
      printf "- Value review rows: %d\n", rows
      printf "- Met: %d\n", result_count["met"]
      printf "- Missed: %d\n", result_count["missed"]
      printf "- Unmeasurable: %d\n", result_count["unmeasurable"]
      printf "- Not recorded: %d\n", result_count["not_recorded"]
    }
  ' {} +
  printf '\n'
fi

cat <<'NOTE'
## Interpretation Note

Outcome metrics outrank activity metrics. A high finding count is not automatically good, and a low
finding count is not automatically good. Use escape rate, value review results, traceability
sampling, and missed criteria to discipline review quality.
NOTE
