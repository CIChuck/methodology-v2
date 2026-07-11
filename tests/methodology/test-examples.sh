#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
helpers="$script_dir/lib/test-helpers.sh"

. "$helpers"

th_set_suite "examples"
th_set_keep_on_failure "${TH_KEEP_ON_FAILURE:-0}"
th_require_compatible_bash
th_init_suite
trap th_cleanup EXIT

current_root="$repo_root/docs/resources/examples/current"
legacy_root="$repo_root/docs/resources/examples/legacy/0.1.0-pre-phase-loop"

th_run_case "EX-001" 0 "current and legacy example directories exist" \
  "test -d '$current_root/c1-csv-cleanup' && test -d '$current_root/c2-standard-planning' && \
   test -d '$legacy_root/gendev-lite-contained-tool' && test -d '$legacy_root/minimal-saas-product'" \
  ''

th_run_case "EX-002" 0 "C1 current example positive and negative CLI checks pass" \
  "cd '$repo_root' && ./docs/resources/examples/current/c1-csv-cleanup/tests/run.sh" \
  ''

th_run_case "EX-003" 0 "current examples expose metadata and no phase-loop exemption language" \
  "test -f '$current_root/c1-csv-cleanup/example.json' && \
   test -f '$current_root/c2-standard-planning/example.json' && \
   ! rg -n 'Phase-loop exemption|predates the G5' '$current_root'" \
  ''

th_run_case "EX-004" 0 "legacy examples are explicitly non-authoritative" \
  "test -f '$legacy_root/README.md' && rg -n 'historical, non-authoritative|pre-phase-loop' '$legacy_root/README.md'" \
  'non-authoritative'

th_run_case "EX-005" 0 "C2 current example does not claim real implementation evidence" \
  "rg -n 'real_code: false|no implemented product code|must not claim' '$current_root/c2-standard-planning/README.md' && \
   ! rg -n '\\|[^|]*verified[^|]*\\|' '$current_root/c2-standard-planning/traceability/traceability-matrix.md'" \
  'real_code: false'

th_run_case "EX-006" 0 "C1 current example contains full current lifecycle evidence trail" \
  "test -f '$current_root/c1-csv-cleanup/project.yaml' && \
   test -f '$current_root/c1-csv-cleanup/framing.md' && \
   test -f '$current_root/c1-csv-cleanup/approvals/gate-log.md' && \
   test -f '$current_root/c1-csv-cleanup/build-plan/phase-plan.md' && \
   test -f '$current_root/c1-csv-cleanup/build-plan/phases/phase-1-build-plan.md' && \
   test -f '$current_root/c1-csv-cleanup/build-plan/phases/phase-1-tactical-plan.md' && \
   test -f '$current_root/c1-csv-cleanup/build-plan/phases/phase-1-construction-directive.md' && \
   test -f '$current_root/c1-csv-cleanup/testing/phase-1-test-uat-plan.md' && \
   test -f '$current_root/c1-csv-cleanup/evidence/implementation-evidence.md' && \
   test -f '$current_root/c1-csv-cleanup/review/code-review.md' && \
   test -f '$current_root/c1-csv-cleanup/review/remediation.md' && \
   test -f '$current_root/c1-csv-cleanup/as-built/as-built-closeout.md' && \
   test -f '$current_root/c1-csv-cleanup/traceability/traceability-matrix.md' && \
   rg -n 'G5\\.1\\.1|G5\\.1\\.2|G5\\.1\\.3|G8 -> G9|non_deployment_approved' '$current_root/c1-csv-cleanup/approvals/gate-log.md'" \
  'G8 -> G9'

th_run_case "EX-007" 0 "C2 current example contains separate authority and planning stop" \
  "test -f '$current_root/c2-standard-planning/vision/vision.md' && \
   test -f '$current_root/c2-standard-planning/prd/prd.md' && \
   test -f '$current_root/c2-standard-planning/architecture/architecture.md' && \
   test -f '$current_root/c2-standard-planning/security-governance/governance-security-spec.md' && \
   test -f '$current_root/c2-standard-planning/build-plan/phase-plan.md' && \
   test -f '$current_root/c2-standard-planning/build-plan/phases/phase-1-tactical-plan.md' && \
   test -f '$current_root/c2-standard-planning/build-plan/phases/phase-1-construction-directive.md' && \
   rg -n 'EARS acceptance criterion|Unwanted behavior' '$current_root/c2-standard-planning/prd/prd.md' && \
   rg -n 'VER-C2-001|VER-C2-002|VER-C2-003' '$current_root/c2-standard-planning/architecture/architecture.md' && \
   rg -n 'C2-P1-WS1-T001|C2-P1-WS3-T001' '$current_root/c2-standard-planning/build-plan/phases/phase-1-tactical-plan.md'" \
  'C2-P1-WS1-T001'

th_summary

exit $(( TH_CASE_FAIL > 0 ))
