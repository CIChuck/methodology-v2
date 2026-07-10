#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
helpers="$script_dir/lib/test-helpers.sh"

. "$helpers"

th_set_suite "runtime-tools"
th_set_keep_on_failure "${TH_KEEP_ON_FAILURE:-0}"
th_require_compatible_bash

work_root="$repo_root/.tmp/methodology-runtime-tools-$(date +%s)-$$"
if [ -z "$work_root" ] || [ "$work_root" = "" ]; then
  th_init_suite
else
  TH_WORKDIR="$work_root"
  rm -rf "$TH_WORKDIR"
  th_init_suite "$TH_WORKDIR"
fi

trap th_cleanup EXIT

base_repo="$TH_WORKDIR/source"
th_temp_copy "$repo_root" "$base_repo"

fixture_root="$TH_WORKDIR/project fixture"
th_temp_copy "$base_repo" "$fixture_root"

th_run_case "RT-001" 0 "init-project displays usage" \
  "cd '$fixture_root' && ./scripts/init-project.sh --help" \
  '^Usage:'

th_run_case "RT-002" 2 "init-project rejects missing project name" \
  "cd '$fixture_root' && ./scripts/init-project.sh" \
  'Usage:'

th_run_case "RT-003" 1 "init-project rejects duplicate init when docs/project exists" \
  "cd '$fixture_root' && ./scripts/init-project.sh 'Runtime Fixtures' >/dev/null && ./scripts/init-project.sh 'Runtime Fixtures'" \
  'docs/project already exists'

th_run_case "RT-004" 0 "close-gate shows usage" \
  "cd '$fixture_root' && ./scripts/close-gate.sh --help" \
  'Usage:'

th_run_case "RT-005" 2 "close-gate requires supported document gate" \
  "cd '$fixture_root' && ./scripts/close-gate.sh G9" \
  'close-gate.sh handles the linear'

th_run_case "RT-006" 0 "methodology-guard shows usage" \
  "cd '$fixture_root' && ./scripts/methodology-guard.sh --help" \
  'Usage:'

th_run_case "RT-007" 2 "methodology-guard --range requires base/head" \
  "cd '$fixture_root' && ./scripts/methodology-guard.sh --range" \
  'Usage:'

th_run_case "RT-008" 1 "close-gate fails without initialized project" \
  "mkdir -p '$fixture_root/no-project'; cd '$fixture_root/no-project'; ../scripts/close-gate.sh G1" \
  'Required file missing'

th_summary

exit $(( TH_CASE_FAIL > 0 ))
