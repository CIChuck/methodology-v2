#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
helpers="$script_dir/lib/test-helpers.sh"

. "$helpers"

th_set_suite "distribution-tools"
th_set_keep_on_failure "${TH_KEEP_ON_FAILURE:-0}"
th_require_compatible_bash
th_init_suite
trap th_cleanup EXIT

source_root="$TH_WORKDIR/source"
th_temp_copy "$repo_root" "$source_root"

target_root="$TH_WORKDIR/distribution target"
mkdir -p "$target_root"

th_run_case "DI-001" 0 "install-methodology usage text" \
  "cd '$source_root' && ./scripts/install-methodology.sh --help" \
  'Usage:'

th_run_case "DI-002" 1 "install-methodology fails when target is missing" \
  "cd '$source_root' && ./scripts/install-methodology.sh '$source_root/no-such-target'" \
  'Target does not exist'

th_run_case "DI-003" 0 "install-methodology preserves existing AGENTS.md by default" \
  "mkdir -p '$target_root'; printf '# existing\\n' > '$target_root/AGENTS.md'; \
    printf '# existing\\n' > '$target_root/AGENTS.md.expected'; \
    cd '$source_root' && ./scripts/install-methodology.sh '$target_root' >/dev/null; \
    cmp -s '$target_root/AGENTS.md' '$target_root/AGENTS.md.expected'" \
  ''

target_runtime="$TH_WORKDIR/distribution-runtime-target"
mkdir -p "$target_runtime"
mkdir -p \"$target_runtime\"

th_run_case "DI-004" 0 "install-methodology copies runtime transition tools from manifest" \
  "cd '$source_root' && ./scripts/install-methodology.sh '$target_runtime' >/dev/null; \
  if [ -x '$target_runtime/scripts/check-methodology.sh' ] && \
     [ -x '$target_runtime/scripts/methodology-guard.sh' ] && \
     [ -x '$target_runtime/scripts/install-hooks.sh' ] && \
     [ -x '$target_runtime/scripts/init-project.sh' ] && \
     [ -x '$target_runtime/scripts/test-checker.sh' ] && \
     [ -x '$target_runtime/scripts/methodology-metrics.sh' ] && \
     [ -x '$target_runtime/scripts/close-gate.sh' ] && \
     [ -x '$target_runtime/scripts/record-phase-checkpoint.sh' ] && \
     [ -x '$target_runtime/scripts/close-phase.sh' ] && \
     [ -x '$target_runtime/scripts/record-deployment-approval.sh' ]; then \
    echo 'close-gate was copied'; \
  else \
    echo 'Expected runtime transition tools to be copied by install-methodology'; \
    exit 1; \
  fi" \
  'close-gate was copied'

target_nores="$TH_WORKDIR/distribution-no-resources"
target_res="$TH_WORKDIR/distribution-with-resources"
mkdir -p "$target_nores" "$target_res"

th_run_case "DI-007" 0 "install-methodology installs resources only with explicit flag" \
  "cd '$source_root' && ./scripts/install-methodology.sh '$target_nores' >/dev/null && \
   test ! -e '$target_nores/docs/resources' && \
   ./scripts/install-methodology.sh --with-resources '$target_res' >/dev/null && \
   test -d '$target_res/docs/resources'" \
  ''

target_collision="$TH_WORKDIR/distribution-collision"
mkdir -p "$target_collision/docs/methodology"
printf '# target owned\n' > "$target_collision/docs/methodology/README.md"

th_run_case "DI-008" 1 "install-methodology blocks collisions before writing" \
  "cd '$source_root' && ./scripts/install-methodology.sh '$target_collision'; rc=\$?; \
   grep -q '# target owned' '$target_collision/docs/methodology/README.md' && \
   test ! -e '$target_collision/scripts/check-methodology.sh' && exit \$rc" \
  'docs/methodology'

target_force="$TH_WORKDIR/distribution-force"
mkdir -p "$target_force/docs/methodology"
printf '# local agents\n' > "$target_force/AGENTS.md"
printf '# old methodology\n' > "$target_force/docs/methodology/README.md"
cp "$target_force/AGENTS.md" "$target_force/AGENTS.md.expected"

th_run_case "DI-009" 0 "install-methodology force upgrades owned paths and preserves AGENTS" \
  "cd '$source_root' && ./scripts/install-methodology.sh --force '$target_force' >/dev/null && \
   test -f '$target_force/docs/methodology/constitution/gendev.md' && \
   cmp -s '$target_force/AGENTS.md' '$target_force/AGENTS.md.expected'" \
  ''

target_branch="$TH_WORKDIR/distribution-branch"
mkdir -p "$target_branch"

th_run_case "DI-010" 0 "install-methodology renders protected branch into workflow" \
  "cd '$source_root' && ./scripts/install-methodology.sh --protected-branch release '$target_branch' >/dev/null && \
   grep -q '^      - release$' '$target_branch/.github/workflows/methodology.yml'" \
  ''

target_dry="$TH_WORKDIR/distribution-dry-run"
mkdir -p "$target_dry"

th_run_case "DI-011" 0 "install-methodology dry-run makes no writes" \
  "cd '$source_root' && ./scripts/install-methodology.sh --dry-run '$target_dry' >/dev/null && \
   test ! -e '$target_dry/docs/methodology' && test ! -e '$target_dry/scripts'" \
  ''

target_rollback="$TH_WORKDIR/distribution-rollback"
mkdir -p "$target_rollback/docs/methodology"
printf '# old methodology\n' > "$target_rollback/docs/methodology/README.md"

th_run_case "DI-012" 1 "install-methodology rolls back simulated copy failure" \
  "cd '$source_root' && GENDEV_INSTALL_FAIL_AFTER=1 ./scripts/install-methodology.sh --force '$target_rollback'; rc=\$?; \
   grep -q '# old methodology' '$target_rollback/docs/methodology/README.md' && exit \$rc" \
  'Simulated install failure'

th_run_case "DI-005" 1 "backfill requires vision/prd/architecture docs" \
  "mkdir -p '$TH_WORKDIR/needs_docs'; cd '$source_root' && ./scripts/backfill-methodology.sh '$TH_WORKDIR/needs_docs'" \
  'Expected doc not found'

target_with_docs="$TH_WORKDIR/backfill_target"
mkdir -p "$target_with_docs/docs/project/vision" "$target_with_docs/docs/project/prd" "$target_with_docs/docs/project/architecture"
cat > "$target_with_docs/docs/project/vision/vision.md" <<'EOF'
Status: Draft
EOF
cat > "$target_with_docs/docs/project/prd/prd.md" <<'EOF'
Status: Draft
EOF
cat > "$target_with_docs/docs/project/architecture/architecture.md" <<'EOF'
Status: Draft
EOF

th_run_case "DI-006" 0 "backfill generates a conformance report" \
  "cd '$source_root' && ./scripts/backfill-methodology.sh '$target_with_docs' >/dev/null && \
  test -f '$target_with_docs/docs/project/backfill-conformance-report.md'" \
  ''

th_summary

exit $(( TH_CASE_FAIL > 0 ))
