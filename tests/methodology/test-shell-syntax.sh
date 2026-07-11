#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
helpers="$script_dir/lib/test-helpers.sh"

. "$helpers"

th_set_suite "shell-syntax"
th_set_keep_on_failure "${TH_KEEP_ON_FAILURE:-0}"
th_require_compatible_bash
th_init_suite
trap th_cleanup EXIT

list_file="$TH_WORKDIR/shell-files.txt"
find "$repo_root/scripts" "$repo_root/tests" "$repo_root/docs/resources/examples/current" \
  -type f \( -name '*.sh' -o -perm -111 \) -print | sort > "$list_file"

th_run_case "SH-001" 0 "shell syntax discovery finds shipped shell files" \
  "test -s '$list_file' && rg -n 'scripts/check-methodology\.sh|scripts/test-methodology\.sh|docs/resources/examples/current/c1-csv-cleanup/tests/run\.sh' '$list_file'" \
  'scripts/check-methodology.sh'

case_id=2
while IFS= read -r file_path; do
  if head -n 1 "$file_path" | rg -q 'python|awk'; then
    continue
  fi
  case_name="SH-$(printf '%03d' "$case_id")"
  rel_path="${file_path#$repo_root/}"
  th_run_case "$case_name" 0 "bash -n $rel_path" "/bin/bash -n '$file_path'" ''
  case_id=$((case_id + 1))
done < "$list_file"

th_summary

exit $(( TH_CASE_FAIL > 0 ))
