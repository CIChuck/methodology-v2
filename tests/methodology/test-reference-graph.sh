#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
helpers="$script_dir/lib/test-helpers.sh"

. "$helpers"

th_set_suite "reference-graph"
th_set_keep_on_failure "${TH_KEEP_ON_FAILURE:-0}"
th_require_compatible_bash
th_init_suite
trap th_cleanup EXIT

th_run_case "REF-001" 0 "release lifecycle validates the reference graph contract" \
  "cd '$repo_root' && ./scripts/check-lifecycle-coherence.py --mode release" \
  'Lifecycle coherence: clean \(release mode\)'

th_run_case "REF-002" 0 "reference graph declares canonical and supporting target kinds" \
  "cd '$repo_root' && \
   rg -n '\"id\": \"canonical_artifact\"' docs/methodology/schema/lifecycle.json && \
   rg -n '\"id\": \"supporting_design\"' docs/methodology/schema/lifecycle.json && \
   rg -n '\"REF-NO-CYCLE\"' docs/methodology/schema/lifecycle.json && \
   rg -n '\"REF-DEPTH\"' docs/methodology/schema/lifecycle.json" \
  'REF-DEPTH'

th_run_case "REF-003" 0 "retired supporting directory is not scaffolded" \
  "cd '$repo_root' && test ! -d docs/project/supporting && test ! -d docs/project-template/supporting" \
  ''

th_summary

exit $(( TH_CASE_FAIL > 0 ))
