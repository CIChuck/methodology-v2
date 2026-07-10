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

th_run_case "EX-001" 0 "example directories exist" \
  "test -d '$repo_root/docs/resources/examples/gendev-lite-contained-tool' && \
  test -d '$repo_root/docs/resources/examples/minimal-saas-product'" \
  ''

th_run_case "EX-002" 1 "current examples are not yet phase-structured" \
  "if [ -f '$repo_root/docs/resources/examples/minimal-saas-product/docs/project/project.yaml' ]; then \
     echo 'project.yaml exists unexpectedly'; \
     exit 0; \
   else \
     echo 'project.yaml missing as expected'; \
     exit 1; \
   fi" \
  'project.yaml missing'

th_run_case "EX-003" 1 "legacy example has no governance gate-log" \
  "if [ -f '$repo_root/docs/resources/examples/gendev-lite-contained-tool/docs/project/approvals/gate-log.md' ]; then \
     echo 'governance gate-log exists unexpectedly'; \
     exit 0; \
   else \
     echo 'governance gate-log missing as expected'; \
     exit 1; \
   fi" \
  'governance gate-log missing'

th_summary

exit $(( TH_CASE_FAIL > 0 ))
