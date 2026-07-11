#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -eu

project_dir="${1:-docs/project}"

printf '# GenDev Metrics Report\n\n'
printf 'Project directory: `%s`\n\n' "$project_dir"

if [ ! -d "$project_dir" ]; then
  printf 'Status: project directory not initialized.\n\n'
  printf 'Run `./scripts/init-project.sh "Project Name"` before collecting project metrics.\n'
  exit 0
fi

gate_log="$project_dir/approvals/gate-log.md"

printf '## Gate Log Metrics\n\n'

if [ ! -f "$gate_log" ]; then
  printf 'Gate log not found: `%s`\n\n' "$gate_log"
else
  parser_output="$(awk -f scripts/lib/gate-log.awk "$gate_log" 2>/tmp/gendev-metrics-gatelog.$$ || true)"
  parser_errors="$(cat /tmp/gendev-metrics-gatelog.$$ 2>/dev/null || true)"
  rm -f /tmp/gendev-metrics-gatelog.$$
  if [ -n "$parser_errors" ]; then
    printf -- '- Gate log parse errors: present\n'
  else
    printf -- '- Gate log parse errors: none\n'
  fi
  printf '%s\n' "$parser_output" | awk -F'\t' '
    NF >= 2 && $2 != "" { event_count[$2]++; total++ }
    END {
      printf "- Canonical events: %d\n", total + 0
      printf "- Gate transitions: %d\n", event_count["gate_transition"] + 0
      printf "- Phase checkpoints: %d\n", event_count["phase_checkpoint"] + 0
      printf "- Phase transitions: %d\n", event_count["phase_transition"] + 0
      printf "- Deployment approvals: %d\n", event_count["deployment_approval"] + 0
      printf "- Amendments: %d\n", event_count["amendment"] + 0
    }
  '

  awk '
    function trim(value) { gsub(/^[[:space:]]+/, "", value); gsub(/[[:space:]]+$/, "", value); gsub(/^"|"$/, "", value); return value }
    function value() { line = $0; sub(/^[[:space:]]*[A-Za-z0-9_]+:[[:space:]]*/, "", line); return trim(line) }
    function leap(y) { return (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0) }
    function valid_date(date, parts, y, m, d, maxd) {
      if (date !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) return 0
      split(date, parts, "-"); y = parts[1] + 0; m = parts[2] + 0; d = parts[3] + 0
      if (m < 1 || m > 12 || d < 1) return 0
      maxd = 31
      if (m == 4 || m == 6 || m == 9 || m == 11) maxd = 30
      if (m == 2) maxd = leap(y) ? 29 : 28
      return d <= maxd
    }
    function days(date, parts, y, m, d) {
      split(date, parts, "-"); y = parts[1] + 0; m = parts[2] + 0; d = parts[3] + 0
      if (m < 3) { y -= 1; m += 12 }
      return int(365 * y + y / 4 - y / 100 + y / 400 + (153 * (m - 3) + 2) / 5 + d - 719469)
    }
    function finish(    sd, ad, dd, delta) {
      if (event_type == "") return
      if (event_type == "gate_transition") {
        if (gate_started_on == "" || decided_on == "") cycle_missing++
        else if (!valid_date(gate_started_on) || !valid_date(decided_on)) cycle_invalid++
        else { sd = days(gate_started_on); dd = days(decided_on); delta = dd - sd; if (delta < 0) cycle_reversed++; else { cycle_count++; cycle_total += delta } }
        if (approval_requested_on == "" || decided_on == "") approval_missing++
        else if (!valid_date(approval_requested_on) || !valid_date(decided_on)) approval_invalid++
        else { ad = days(approval_requested_on); dd = days(decided_on); delta = dd - ad; if (delta < 0) approval_reversed++; else { approval_count++; approval_total += delta } }
      }
    }
    function reset() { event_type = gate_started_on = approval_requested_on = decided_on = "" }
    /^## Gate Records/ { in_records = 1; next }
    in_records && /^## / { next }
    in_records && /^```[[:space:]]*yaml/ { finish(); reset(); in_yaml = 1; next }
    in_records && /^```[[:space:]]*$/ && in_yaml { finish(); reset(); in_yaml = 0; next }
    in_records && in_yaml && /^[[:space:]]*event_type:/ { event_type = value(); next }
    in_records && in_yaml && /^[[:space:]]*gate_started_on:/ { gate_started_on = value(); next }
    in_records && in_yaml && /^[[:space:]]*approval_requested_on:/ { approval_requested_on = value(); next }
    in_records && in_yaml && /^[[:space:]]*decided_on:/ { decided_on = value(); next }
    END {
      finish()
      if (cycle_count > 0) printf "- Average gate cycle days: %.1f (%d measured)\n", cycle_total / cycle_count, cycle_count
      else printf "- Average gate cycle days: N/A\n"
      printf "- Gate cycle timing missing: %d\n", cycle_missing + 0
      printf "- Gate cycle timing invalid: %d\n", cycle_invalid + 0
      printf "- Gate cycle timing reversed: %d\n", cycle_reversed + 0
      if (approval_count > 0) printf "- Average approval latency days: %.1f (%d measured)\n", approval_total / approval_count, approval_count
      else printf "- Average approval latency days: N/A\n"
      printf "- Approval timing missing: %d\n", approval_missing + 0
      printf "- Approval timing invalid: %d\n", approval_invalid + 0
      printf "- Approval timing reversed: %d\n", approval_reversed + 0
    }
  ' "$gate_log"
  printf '\n'
fi

printf '## Traceability Coverage\n\n'
if ! find "$project_dir/traceability" -type f -name '*.md' -print -quit 2>/dev/null | grep -q .; then
  printf 'No traceability matrix files found.\n\n'
else
  find "$project_dir/traceability" -type f -name '*.md' -exec awk -F'|' '
    function trim(value) { gsub(/^[[:space:]]+/, "", value); gsub(/[[:space:]]+$/, "", value); return value }
    /^## Matrix/ { in_matrix = 1; next }
    in_matrix && /^## / { in_matrix = 0 }
    !in_matrix { next }
    /^\|/ {
      if (NF < 11) { malformed++; next }
      req = trim($2); status = tolower(trim($11))
      if (req == "" || req == "Req ID" || req ~ /^---$/) next
      rows++; status_count[status]++; if (status == "verified") verified++
    }
    END {
      printf "- Requirement rows: %d\n", rows + 0
      printf "- Verified rows: %d\n", verified + 0
      if (rows > 0) printf "- Traceability coverage: %.1f%%\n", (verified / rows) * 100
      else printf "- Traceability coverage: N/A\n"
      printf "- Malformed traceability rows: %d\n", malformed + 0
      split("verified partial missing deferred", order, " ")
      for (i = 1; i <= 4; i++) printf "  - %s: %d\n", order[i], status_count[order[i]] + 0
    }
  ' {} +
  printf '\n'
fi

printf '## Value Review\n\n'
if ! find "$project_dir/as-built" -type f -name '*value-review*.md' -print -quit 2>/dev/null | grep -q .; then
  printf 'No value review files found.\n\n'
else
  find "$project_dir/as-built" -type f -name '*value-review*.md' -exec awk -F'|' '
    function trim(value) { gsub(/^[[:space:]]+/, "", value); gsub(/[[:space:]]+$/, "", value); gsub(/^"|"$/, "", value); return value }
    /^Status:/ { status = trim(substr($0, 8)); artifact_status[status]++ }
    /^[[:space:]]*value_review\.disposition:/ { disposition = trim($0); sub(/^[[:space:]]*value_review\.disposition:[[:space:]]*/, "", disposition); disposition_count[disposition]++; saw_disposition = 1 }
    /^[[:space:]]*Disposition:/ { disposition = trim($0); sub(/^[[:space:]]*Disposition:[[:space:]]*/, "", disposition); disposition_count[disposition]++; saw_disposition = 1 }
    /^## Success Criteria Actuals/ { in_actuals = 1; next }
    in_actuals && /^## / { in_actuals = 0 }
    in_actuals && /^\|/ {
      criterion = trim($2); result = tolower(trim($6))
      if (criterion == "" || criterion == "Criterion" || criterion ~ /^---$/) next
      rows++; if (result == "met" || result == "missed" || result == "unmeasurable") result_count[result]++; else result_count["not_recorded"]++
    }
    END {
      printf "- Value review files: %d\n", ARGC - 1
      printf "- Value review rows: %d\n", rows + 0
      printf "- Met: %d\n", result_count["met"] + 0
      printf "- Missed: %d\n", result_count["missed"] + 0
      printf "- Unmeasurable: %d\n", result_count["unmeasurable"] + 0
      printf "- Not recorded: %d\n", result_count["not_recorded"] + 0
      printf "- Artifact Status Complete: %d\n", artifact_status["Complete"] + 0
      printf "- Disposition complete: %d\n", disposition_count["complete"] + 0
      printf "- Disposition not_due: %d\n", disposition_count["not_due"] + 0
      printf "- Disposition not_applicable: %d\n", disposition_count["not_applicable"] + 0
      invalid = 0
      for (d in disposition_count) if (d != "complete" && d != "not_due" && d != "not_applicable") invalid += disposition_count[d]
      printf "- Disposition invalid: %d\n", invalid + 0
      printf "- Disposition missing: %d\n", saw_disposition ? 0 : (ARGC - 1)
    }
  ' {} +
  printf '\n'
fi

cat <<'NOTE'
## Interpretation Note

Outcome metrics outrank activity metrics. A high finding count is not automatically good, and a low
finding count is not automatically good. GenDev reports value review results, traceability sampling,
and missed criteria from current records. Escape rate is not computed until a future structured
incident event and denominator are defined.
NOTE
