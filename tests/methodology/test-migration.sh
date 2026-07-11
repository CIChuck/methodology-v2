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

vision_only="$TH_WORKDIR/migration-vision-only"
mkdir -p "$vision_only/imports"
printf '# Imported Vision\nStatus: Draft\n' > "$vision_only/imports/vision.md"
cp "$vision_only/imports/vision.md" "$vision_only/imports/vision.md.expected"

th_run_case "MI-004" 0 "backfill accepts explicit vision-only import" \
  "cd '$source_root' && ./scripts/backfill-methodology.sh --project-name 'Vision Only' --vision '$vision_only/imports/vision.md' '$vision_only' >/dev/null && \
   cmp -s '$vision_only/docs/project/vision/vision.md' '$vision_only/imports/vision.md.expected' && \
   test -f '$vision_only/docs/project/project.yaml' && \
   grep -q 'vision: present' '$vision_only/docs/project/backfill-conformance-report.md'" \
  ''

missing_declared="$TH_WORKDIR/migration-missing-declared"
mkdir -p "$missing_declared"

th_run_case "MI-005" 1 "backfill missing declared source aborts before mutation" \
  "cd '$source_root' && ./scripts/backfill-methodology.sh --vision '$missing_declared/nope.md' '$missing_declared'; rc=\$?; \
   test ! -e '$missing_declared/docs/methodology' && exit \$rc" \
  'Expected doc not found'

conflict_target="$TH_WORKDIR/migration-conflict"
mkdir -p "$conflict_target/docs/project/vision" "$conflict_target/imports"
printf '# Existing Vision\nStatus: Draft\n' > "$conflict_target/docs/project/vision/vision.md"
printf '# Different Vision\nStatus: Draft\n' > "$conflict_target/imports/vision.md"

th_run_case "MI-006" 1 "backfill refuses to overwrite imported authority before install" \
  "cd '$source_root' && ./scripts/backfill-methodology.sh --force --vision '$conflict_target/imports/vision.md' '$conflict_target'; rc=\$?; \
   test ! -e '$conflict_target/docs/methodology' && grep -q '# Existing Vision' '$conflict_target/docs/project/vision/vision.md' && exit \$rc" \
  'Refusing to overwrite imported authority'

th_summary

exit $(( TH_CASE_FAIL > 0 ))
