#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -u

script_dir="$(cd "$(dirname "$0")" && pwd)"
. "$script_dir/lib/gendev-common.sh"

# Point-of-use guard: every assertion below runs through rg. Without this
# guard, a missing rg makes the negative assertions pass silently, which is
# the failure mode this checker exists to prevent.
gendev_require_tool "check-doc-coherence.sh" rg || exit 3

# Authority-context guard: release-identity assertions are meaningless in an
# installed product repository, where the installed docs truthfully describe
# a release published elsewhere.
gendev_refuse_in_installed_context "check-doc-coherence.sh" "$script_dir/.." || exit "$?"

errors=0

fail() {
  errors=$((errors + 1))
  printf 'ERROR: %s\n' "$1" >&2
}

require_no_match() {
  pattern="$1"
  shift
  if rg -n "$pattern" "$@" >/tmp/gendev-doc-coherence.$$ 2>/dev/null; then
    cat /tmp/gendev-doc-coherence.$$ >&2
    rm -f /tmp/gendev-doc-coherence.$$
    fail "unexpected active documentation match: $pattern"
  else
    rm -f /tmp/gendev-doc-coherence.$$
  fi
}

require_file() {
  path="$1"
  if [ ! -f "$path" ]; then
    fail "required file missing: $path"
  fi
}

require_executable() {
  path="$1"
  if [ ! -x "$path" ]; then
    fail "required executable missing or not executable: $path"
  fi
}

require_line() {
  pattern="$1"
  path="$2"
  if ! rg -n "$pattern" "$path" >/dev/null 2>&1; then
    fail "required pattern missing from $path: $pattern"
  fi
}

require_no_match 'Status: Draft' docs/resources/practitioner-guide
require_no_match 'pre-1\.0' README.md AGENTS.md docs/resources/practitioner-guide docs/methodology/schema/README.md docs/project-template/project.yaml
require_no_match '^## 0\.5' docs/resources/practitioner-guide docs/methodology/agents docs/methodology/dev-skills
require_no_match '0\.5 Operational Coherence' docs/resources/practitioner-guide docs/methodology/agents docs/methodology/dev-skills
require_no_match 'current 0\.5 lifecycle|In 0\.5' docs/resources/practitioner-guide
require_no_match '^## Legacy Migration Hazard$' docs/resources/practitioner-guide
require_no_match '^Latest release:\s*1\.0\.0\s*$' docs/resources/releases/README.md

require_line '^Current methodology version: `1\.0\.1`$' README.md
require_line '^Version: 1\.0\.1$' docs/methodology/constitution/gendev.md
if git rev-parse --verify refs/tags/v1.0.1 >/dev/null 2>&1; then
  require_line '^Latest published release: 1\.0\.1$' docs/resources/releases/README.md
  require_no_match '^Active release candidate:' docs/resources/releases/README.md
  require_line '^Status: Published production release$' docs/resources/releases/1.0.1.md
  require_line '^Publication tag: `v1\.0\.1`$' docs/resources/releases/1.0.1.md
  require_line '^Status: Released production registry$' docs/methodology/schema/README.md
else
  require_line '^Latest published release: 0\.5\.0-operational-coherence$' docs/resources/releases/README.md
  require_line '^Active release candidate: 1\.0\.1$' docs/resources/releases/README.md
  require_line '^Status: Production candidate; publication pending required gates$' docs/resources/releases/1.0.1.md
  require_line '^Publication tag: planned `v1\.0\.1`$' docs/resources/releases/1.0.1.md
  require_line '^Status: Release-mode production registry; publication pending$' docs/methodology/schema/README.md
fi
require_line '^Status: Superseded production candidate; never published; superseded by 1\.0\.1$' docs/resources/releases/1.0.0.md
require_line 'methodology_version: 1\.0\.1' docs/project-template/project.yaml
require_line 'methodology_release_stage: production' docs/project-template/project.yaml

require_file docs/resources/releases/1.0.0.md
require_file docs/resources/releases/1.0.1.md
require_file docs/resources/releases/1.0.1-adoption.md
require_line '^Status: Active 1\.0 adoption guidance$' docs/resources/releases/1.0.1-adoption.md
require_line 'docs/resources/releases/1\.0\.1-adoption\.md' docs/resources/practitioner-guide/README.md
require_line 'docs/resources/releases/1\.0\.1-adoption\.md' docs/resources/practitioner-guide/04-starting-a-new-project.md
require_line 'docs/resources/releases/1\.0\.1-adoption\.md' docs/resources/practitioner-guide/19-starting-mid-stream.md
# Tool-specific notes must carry a dated review line. The assertion is
# structural (a valid date must exist) rather than pinned to a single date, so
# reviewing the notes does not require editing this checker in lockstep.
require_line 'Last reviewed: 2[0-9]{3}-[0-9]{2}-[0-9]{2}' docs/resources/practitioner-guide/13-codex-specific-notes.md
require_line 'Last reviewed: 2[0-9]{3}-[0-9]{2}-[0-9]{2}' docs/resources/practitioner-guide/14-claude-code-specific-notes.md
require_line '^## Prerequisites$' README.md
require_line 'ripgrep' README.md
require_line 'ripgrep' AGENTS.md
require_line 'ripgrep' docs/resources/practitioner-guide/04-starting-a-new-project.md
require_line 'ripgrep' docs/resources/practitioner-guide/16-checklists.md
require_line '^## Prerequisites$' docs/resources/releases/1.0.1-adoption.md
require_executable scripts/gendev-doctor.sh
require_executable scripts/pin-provenance.sh
require_file docs/resources/runbook/g0-to-g7-runbook.md
require_line 'pin-provenance' docs/resources/runbook/g0-to-g7-runbook.md
require_line 'pin-provenance' docs/methodology/templates/architecture-template.md
require_line '^Failure modes: <answer>$' docs/methodology/templates/architecture-template.md
require_line 'pin-provenance' docs/resources/practitioner-guide/04-starting-a-new-project.md
require_executable scripts/project-state.sh
require_executable scripts/new-artifact.sh

for path in approvals architecture as-built build-plan build-plan/phases decisions deployment design prd review security-governance testing traceability vision; do
  require_line "docs/project/$path" docs/methodology/schema/lifecycle.json
done

for path in approvals architecture as-built build-plan decisions deployment design prd review security-governance testing traceability vision; do
  require_line "^  $path/" docs/resources/practitioner-guide/03-repository-map.md
done

for command_file in \
  docs/resources/practitioner-guide/04-starting-a-new-project.md \
  docs/resources/practitioner-guide/16-checklists.md \
  docs/methodology/guides/start-and-next-step-protocol.md; do
  require_line './scripts/gendev-doctor\.sh' "$command_file"
  require_line './scripts/project-state\.sh' "$command_file"
done
require_line './scripts/check-doc-coherence\.sh' docs/resources/practitioner-guide/16-checklists.md
require_line './scripts/new-artifact\.sh' docs/resources/practitioner-guide/16-checklists.md

if [ "$errors" -eq 0 ]; then
  printf 'Documentation coherence: clean\n'
else
  printf 'Documentation coherence: %s finding(s)\n' "$errors" >&2
fi

exit "$errors"
