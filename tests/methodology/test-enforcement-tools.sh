#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
helpers="$script_dir/lib/test-helpers.sh"

. "$helpers"

th_set_suite "enforcement-tools"
th_set_keep_on_failure "${TH_KEEP_ON_FAILURE:-0}"
th_require_compatible_bash
th_init_suite
trap th_cleanup EXIT

base_repo="$TH_WORKDIR/base"
mkdir -p "$base_repo"
cp -R "$repo_root/." "$base_repo"

th_run_case "EN-001" 0 "check-methodology reports uninitialized state" \
  "cd '$base_repo' && ./scripts/check-methodology.sh" \
  'project is not initialized'

th_run_case "EN-002" 0 "check-methodology detects placeholder placeholders from checker" \
  "cd '$base_repo' && ./scripts/test-checker.sh" \
  '5 passed'

th_run_case "EN-003" 0 "methodology-guard accepts --help" \
  "cd '$base_repo' && ./scripts/methodology-guard.sh --help" \
  'Usage:'

init_target="$TH_WORKDIR/init_target"
mkdir -p "$init_target"
cp -R "$base_repo/." "$init_target"
cd "$init_target"
./scripts/init-project.sh "Enforcement Fixtures" > /dev/null

th_run_case "EN-004" 0 "methodology-guard runs in staged mode" \
  "cd '$init_target' && git add docs/project/vision/vision.md >/dev/null 2>&1 || true; ./scripts/methodology-guard.sh --staged" \
  'Methodology check passed:'

th_summary

exit $(( TH_CASE_FAIL > 0 ))
