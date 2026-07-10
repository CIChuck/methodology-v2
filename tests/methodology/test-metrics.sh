#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
helpers="$script_dir/lib/test-helpers.sh"

. "$helpers"

th_set_suite "metrics"
th_set_keep_on_failure "${TH_KEEP_ON_FAILURE:-0}"
th_require_compatible_bash
th_init_suite
trap th_cleanup EXIT

base_repo="$TH_WORKDIR/base"
th_temp_copy "$repo_root" "$base_repo"

th_run_case "ME-001" 0 "metrics reports uninitialized project" \
  "cd '$base_repo' && ./scripts/methodology-metrics.sh" \
  'not initialized'

init_target="$TH_WORKDIR/metrics-fixture"
th_temp_copy "$base_repo" "$init_target"
cd "$init_target"
./scripts/init-project.sh "Metrics Fixtures" > /dev/null

cat > docs/project/approvals/gate-log.md <<'EOF'
# Gate Log

## Gate Records

## Gate Event: G1 -> G2
```yaml
event_type: gate_transition
from_gate: G1
to_gate: G2
gate_started_on: 2026-13-01
decided_on: invalid-date
approval_requested_on: not-a-date
```
EOF

th_run_case "ME-002" 0 "metrics tolerates malformed timing data" \
  "cd '$init_target' && ./scripts/methodology-metrics.sh docs/project" \
  'missing timing fields'

cat > docs/project/approvals/gate-log.md <<'EOF'
# Gate Log

## Gate Records

## Gate Event: G1 -> G2
```yaml
event_type: gate_transition
from_gate: G1
to_gate: G2
decision: approved
decided_by: Test
gate_started_on: 2026-01-01
ready_for_approval_on: 2026-01-01
approval_requested_on: 2026-01-02
decided_on: 2026-01-03
result: passed
```
EOF

th_run_case "ME-003" 0 "metrics reports gate transition metrics" \
  "cd '$init_target' && ./scripts/methodology-metrics.sh docs/project" \
  'Average gate cycle days'

th_summary

exit $(( TH_CASE_FAIL > 0 ))
