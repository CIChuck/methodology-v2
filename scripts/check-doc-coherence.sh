#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -u

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
require_no_match '^## 0\.5' docs/resources/practitioner-guide
require_no_match 'current 0\.5 lifecycle|In 0\.5' docs/resources/practitioner-guide

require_line '^Current methodology version: `1\.0\.0`$' README.md
require_line '^Version: 1\.0\.0$' docs/methodology/constitution/gendev.md
require_line '^Latest release: 1\.0\.0$' docs/resources/releases/README.md
require_line '^Status: Released production registry$' docs/methodology/schema/README.md
require_line 'methodology_version: 1\.0\.0' docs/project-template/project.yaml
require_line 'methodology_release_stage: production' docs/project-template/project.yaml

require_file docs/resources/releases/1.0.0.md
require_file docs/resources/releases/1.0.0-adoption.md
require_executable scripts/gendev-doctor.sh
require_executable scripts/project-state.sh
require_executable scripts/new-artifact.sh

if [ "$errors" -eq 0 ]; then
  printf 'Documentation coherence: clean\n'
else
  printf 'Documentation coherence: %s finding(s)\n' "$errors" >&2
fi

exit "$errors"
