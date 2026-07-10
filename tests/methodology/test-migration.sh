#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
helpers="$script_dir/lib/test-helpers.sh"

. "$helpers"

th_set_suite "migration"
th_set_keep_on_failure "${TH_KEEP_ON_FAILURE:-0}"
th_require_compatible_bash
th_init_suite
trap th_cleanup EXIT

source_root="$TH_WORKDIR/source"
th_temp_copy "$repo_root" "$source_root"

empty_target="$TH_WORKDIR/migration-missing"
th_run_case "MI-001" 1 "backfill requires G1-G3 docs" \
  "mkdir -p '$empty_target'; cd '$source_root' && ./scripts/backfill-methodology.sh '$empty_target'" \
  'Expected doc not found'

migration_target="$TH_WORKDIR/migration-ok"
mkdir -p "$migration_target/docs/project/vision" \
  "$migration_target/docs/project/prd" \
  "$migration_target/docs/project/architecture"
printf '# Vision\nStatus: Draft\n' > "$migration_target/docs/project/vision/vision.md"
printf '# PRD\nStatus: Draft\n' > "$migration_target/docs/project/prd/prd.md"
printf '# Architecture\nStatus: Draft\n' > "$migration_target/docs/project/architecture/architecture.md"

th_run_case "MI-002" 0 "backfill writes conformance report without replacing project authority" \
  "cp '$migration_target/docs/project/vision/vision.md' '$migration_target/docs/project/vision/vision.md.bak' && \
   cd '$source_root' && ./scripts/backfill-methodology.sh '$migration_target' >/dev/null && \
   cmp -s '$migration_target/docs/project/vision/vision.md' '$migration_target/docs/project/vision/vision.md.bak' && \
   test -f '$migration_target/docs/project/backfill-conformance-report.md'" \
  ''

th_run_case "MI-003" 1 "backfill refuses existing docs/methodology without force" \
  "mkdir -p '$migration_target/docs/methodology'; printf '# existing\n' > '$migration_target/docs/methodology/README.md'; \
   cd '$source_root' && ./scripts/backfill-methodology.sh '$migration_target'" \
  'docs/methodology already exists'

th_summary

exit $(( TH_CASE_FAIL > 0 ))
