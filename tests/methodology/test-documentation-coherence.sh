#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
helpers="$script_dir/lib/test-helpers.sh"

. "$helpers"

th_set_suite "documentation-coherence"
th_set_keep_on_failure "${TH_KEEP_ON_FAILURE:-0}"
th_require_compatible_bash
th_init_suite
trap th_cleanup EXIT

th_run_case "DOC-001" 0 "methodology checker accepts active documentation" \
  "cd '$repo_root' && ./scripts/check-methodology.sh" \
  'Methodology check passed'

th_run_case "DOC-002" 1 "active practitioner docs contain no raw refinement notes" \
  "cd '$repo_root' && rg -n '^\\s*refinement:' docs/resources/practitioner-guide" \
  ''

th_run_case "DOC-003" 1 "active docs contain no retired phase roadmap references" \
  "cd '$repo_root' && rg -n 'phase-roadmap\\.md|^## Phase Roadmap' README.md AGENTS.md docs/methodology docs/project-template docs/resources/practitioner-guide scripts" \
  ''

th_run_case "DOC-004" 1 "active docs contain no canonical placeholder document paths" \
  "cd '$repo_root' && rg -n 'docs/project/(vision|prd|architecture|security-governance)/\\[[^]]+\\]\\.md' README.md AGENTS.md docs/methodology docs/project-template docs/resources/practitioner-guide scripts" \
  ''

th_run_case "DOC-005" 0 "current examples stay non-authoritative and strict" \
  "cd '$repo_root' && rg -n 'strict_schema_mode|non_authoritative_current_example' docs/resources/examples/current/*/example.json" \
  'non_authoritative_current_example'

th_run_case "DOC-006" 0 "active documentation passes release identity and preflight coherence" \
  "cd '$repo_root' && ./scripts/check-doc-coherence.sh" \
  'Documentation coherence: clean'

th_run_case "DOC-007" 3 "doc-coherence checker fails loudly when ripgrep is missing" \
  "tmpbin=\"\$(mktemp -d)\" && \
   for tool in bash sh dirname cat rm; do \
     src=\"\$(command -v \"\$tool\" 2>/dev/null)\" && [ -n \"\$src\" ] && ln -s \"\$src\" \"\$tmpbin/\$tool\"; \
   done; \
   cd '$repo_root' && PATH=\"\$tmpbin\" ./scripts/check-doc-coherence.sh" \
  'requires rg'

th_summary

exit $(( TH_CASE_FAIL > 0 ))
