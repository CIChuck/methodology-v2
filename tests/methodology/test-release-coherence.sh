#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
helpers="$script_dir/lib/test-helpers.sh"

. "$helpers"

th_set_suite "release-coherence"
th_set_keep_on_failure "${TH_KEEP_ON_FAILURE:-0}"
th_require_compatible_bash
th_init_suite
trap th_cleanup EXIT

th_run_case "RC-001" 0 "lifecycle registry and active docs are coherent" \
  "cd '$repo_root' && ./scripts/check-lifecycle-coherence.py --mode release" \
  'Lifecycle coherence: clean \(release mode\)'

th_run_case "RC-002" 1 "active docs contain no raw refinement notes" \
  "cd '$repo_root' && rg -n '^\\s*refinement:' docs/resources/practitioner-guide" \
  ''

th_run_case "RC-003" 1 "active docs contain no retired phase roadmap references" \
  "cd '$repo_root' && rg -n 'phase-roadmap\\.md|^## Phase Roadmap' README.md AGENTS.md docs/methodology docs/project-template docs/resources/practitioner-guide scripts" \
  ''

th_run_case "RC-004" 1 "active docs contain no canonical placeholder document paths" \
  "cd '$repo_root' && rg -n 'docs/project/(vision|prd|architecture|security-governance)/\\[[^]]+\\]\\.md' README.md AGENTS.md docs/methodology docs/project-template docs/resources/practitioner-guide scripts" \
  ''

th_run_case "RC-005" 0 "distribution manifest names required runtime assets" \
  "cd '$repo_root' && \
   rg -n '^tree\\|docs/methodology\\|docs/methodology\\|preserve\\|required$' scripts/lib/distribution-manifest.txt && \
   rg -n '^tree\\|scripts/lib\\|scripts/lib\\|preserve\\|required$' scripts/lib/distribution-manifest.txt && \
   rg -n '^file\\|scripts/(close-gate|record-phase-checkpoint|close-phase|record-deployment-approval|methodology-guard|check-methodology)\\.sh\\|' scripts/lib/distribution-manifest.txt" \
  'scripts/check-methodology.sh'

th_run_case "RC-006" 0 "current examples expose strict metadata and legacy boundary" \
  "cd '$repo_root' && rg -n 'strict_schema_mode|non_authoritative_current_example' docs/resources/examples/current/*/example.json && rg -n 'historical, non-authoritative|pre-phase-loop' docs/resources/examples/legacy/0.1.0-pre-phase-loop/README.md" \
  'non_authoritative_current_example'

th_run_case "RC-007" 0 "release index presents 0.5 as latest release" \
  "cd '$repo_root' && \
   rg -n '^Latest release: 0\\.5\\.0-operational-coherence$' docs/resources/releases/README.md && \
   ! rg -n '^Latest release-prep candidate:' docs/resources/releases/README.md && \
   ! rg -n '^Latest published release:' docs/resources/releases/README.md" \
  'Latest release'

th_run_case "RC-008" 0 "independent review artifact records a non-pending result" \
  "cd '$repo_root' && \
   rg -n '^Status: Independent review complete' docs/resources/evolution/0.5.0-operational-coherence-review.md && \
   rg -n '^Blocking findings after remediation:' docs/resources/evolution/0.5.0-operational-coherence-review.md && \
   ! rg -n 'Review result: Pending|independent review pending|Review package prepared; independent review pending' docs/resources/evolution/0.5.0-operational-coherence-review.md" \
  'Independent review complete'

th_run_case "RC-009" 0 "closeout ledger records all findings and WP-11 tasks" \
  "cd '$repo_root' && \
   ledger='docs/resources/evolution/0.5.0-operational-coherence-closeout-ledger.md' && \
   test -f \"\$ledger\" && \
   rg -n '^## 2\\. F-001 Through F-020 Final Closure Record$' \"\$ledger\" && \
   rg -n '^## 3\\. WP-11 Task Ledger$' \"\$ledger\" && \
   for finding in F-001 F-002 F-003 F-004 F-005 F-006 F-007 F-008 F-009 F-010 F-011 F-012 F-013 F-014 F-015 F-016 F-017 F-018 F-019 F-020; do \
     rg -n \"^### \${finding}$\" \"\$ledger\" >/dev/null || exit 1; \
   done && \
   finding_status_count=\$(rg -c '^- final status: (CLOSED|RESIDUAL_ACCEPTED|BLOCKED)$' \"\$ledger\") && \
   test \"\$finding_status_count\" -eq 20 && \
   for task in OC-WP11-T001 OC-WP11-T002 OC-WP11-T003 OC-WP11-T004 OC-WP11-T005 OC-WP11-T006 OC-WP11-T007 OC-WP11-T008 OC-WP11-T009 OC-WP11-T010 OC-WP11-T011 OC-WP11-T012 OC-WP11-T013 OC-WP11-T014 OC-WP11-T015 OC-WP11-T016 OC-WP11-T017 OC-WP11-T018 OC-WP11-T019 OC-WP11-T020; do \
     rg -n \"^\\| \${task} \\|\" \"\$ledger\" >/dev/null || exit 1; \
   done && \
   rg -n '^## 31\\. Closeout Ledger Addendum$' docs/resources/evolution/0.5.0-operational-coherence-execution-log.md" \
  'Closeout Ledger Addendum'

th_summary

exit $(( TH_CASE_FAIL > 0 ))
