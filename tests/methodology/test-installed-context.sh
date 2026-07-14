#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# Installed-context regression suite.
#
# Builds the distribution context end to end in scratch: installs the
# methodology into an empty repository, initializes a project, closes G1
# from fixtures, and asserts the product-context contract. This suite is the
# structural lesson of release 1.0.2: every release must validate on both
# sides of the distribution boundary, because the authority repository is
# the one place where authority context and execution context coincide.
#
# Runs only in the authority repository; it is what proves installed
# behavior, not what runs in it.

set -u
set -o pipefail

test_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$test_dir/../.." && pwd)"
. "$test_dir/lib/test-helpers.sh"

th_set_suite "installed-context"
th_set_keep_on_failure "${TH_KEEP_ON_FAILURE:-0}"
th_require_compatible_bash
th_init_suite
trap 'th_cleanup; rm -rf "$work"' EXIT

work="$(mktemp -d "${TMPDIR:-/tmp}/gendev-installed.XXXXXX")"
target="$work/product"
mkdir -p "$target"

th_run_case "IC-001" 0 "install writes the installation record with provenance and digests" \
  "cd '$target' && git init -qb main && git config user.name t && git config user.email t@t && \
   git commit -q --allow-empty -m baseline && \
   '$repo_root/scripts/install-methodology.sh' --protected-branch main '$target' >/dev/null && \
   python3 -c \"
import json
r = json.load(open('$target/docs/methodology/schema/installation.json'))
assert r['record'] == 'gendev-installation'
assert r['methodology_version'] not in ('', 'unknown')
assert r['source_commit'] not in ('', 'unknown')
assert len(r['files']) > 100
assert 'AGENTS.md' not in r['files']
print('record ok:', r['methodology_version'], len(r['files']), 'files')
\"" \
  'record ok'

th_run_case "IC-002" 0 "doctor reports installed context with verified integrity" \
  "cd '$target' && ./scripts/gendev-doctor.sh | grep -E 'Context: installed|Integrity: verified' | wc -l | grep -q 2 && \
   ./scripts/gendev-doctor.sh | grep 'Integrity: verified'" \
  'Integrity: verified'

th_run_case "IC-003" 5 "doctor exits 5 and names the file when an installed file is tampered" \
  "cd '$target' && cp scripts/check-methodology.sh /tmp/ic3.bak && \
   printf '\\n' >> scripts/check-methodology.sh && \
   out=\"\$(./scripts/gendev-doctor.sh 2>&1)\"; rc=\$?; \
   cp /tmp/ic3.bak scripts/check-methodology.sh && rm -f /tmp/ic3.bak && \
   printf '%s\\n' \"\$out\" | grep -q 'modified: scripts/check-methodology.sh' && exit \$rc" \
  ''

th_run_case "IC-004" 4 "authority suites refuse installed context with exit 4" \
  "cd '$target' && ./scripts/test-methodology.sh --suite release-coherence" \
  'not applicable in an installed product repository'

th_run_case "IC-005" 0 "authority-only checkers are not shipped" \
  "cd '$target' && test ! -e scripts/check-doc-coherence.sh && \
   test ! -e scripts/check-lifecycle-coherence.py && echo unshipped" \
  'unshipped'

th_run_case "IC-006" 0 "product workflow is rendered, not the authority workflow" \
  "cd '$target' && grep -q 'gendev-product-checks' .github/workflows/methodology.yml && \
   grep -q '^      - main$' .github/workflows/methodology.yml && \
   ! grep -q 'release-coherence' .github/workflows/methodology.yml && echo rendered" \
  'rendered'

th_run_case "IC-007" 0 "initialized project closes G1 and the product contract holds" \
  "cd '$target' && ./scripts/init-project.sh 'Runtime Fixtures' >/dev/null && \
   printf '# Runtime Fixtures\\n\\nInstalled-context regression fixture project.\\n' > README.md && \
   . tests/methodology/lib/runtime-write-fixtures.sh && \
   rtw_prepare_g1_close_fixture && rtw_git_baseline && \
   ./scripts/close-gate.sh --answers-file answers.env G1 >/dev/null && \
   ./scripts/check-methodology.sh >/dev/null && \
   ./scripts/test-methodology.sh --suite shell-syntax >/dev/null && \
   ./scripts/gendev-doctor.sh >/dev/null 2>&1; rc=\$?; \
   test \$rc -eq 0 -o \$rc -eq 5 || exit 1; \
   grep -q 'G1' docs/project/approvals/gate-log.md && echo contract-holds" \
  'contract-holds'

th_run_case "IC-008" 0 "no suite residue remains in the product repository" \
  "cd '$target' && test ! -e .tmp && grep -q '^\\.tmp/$' .gitignore && echo no-residue" \
  'no-residue'

th_summary

exit $(( TH_CASE_FAIL > 0 ))
