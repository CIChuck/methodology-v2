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

th_run_case "DI-004" 1 "install-methodology currently omits close-gate.sh from copy list" \
  "mkdir -p '$target_root'; cd '$source_root' && ./scripts/install-methodology.sh '$target_root' >/dev/null; \
  if [ -x '$target_root/scripts/check-methodology.sh' ] && \
     [ -x '$target_root/scripts/methodology-guard.sh' ] && \
     [ -x '$target_root/scripts/install-hooks.sh' ] && \
     [ -x '$target_root/scripts/init-project.sh' ] && \
     [ -x '$target_root/scripts/test-checker.sh' ] && \
     [ -x '$target_root/scripts/methodology-metrics.sh' ] && \
     [ -x '$target_root/scripts/close-gate.sh' ]; then \
    echo 'close-gate was copied'; \
  else \
    echo 'Expected scripts to be copied by install-methodology but close-gate.sh is missing'; \
    exit 1; \
  fi" \
  'close-gate.sh'

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
