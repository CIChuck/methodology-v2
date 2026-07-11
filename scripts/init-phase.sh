#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -eu

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage:
  scripts/init-phase.sh <phase-id> [project-name]

Create the complete canonical phase artifact set for <phase-id> without
overwriting existing files.
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage >&2
  exit 2
fi

phase_id="$1"
project_name="${2:-Project}"

case "$phase_id" in
  *[!A-Za-z0-9-]* | "" | -* | *--)
    printf 'ERROR: invalid phase id: %s\n' "$phase_id" >&2
    exit 2
    ;;
esac

project_root="$repo_root/docs/project"
template_root="$repo_root/docs/methodology/templates"

if [ ! -d "$project_root" ]; then
  printf 'ERROR: docs/project is not initialized. Run scripts/init-project.sh first.\n' >&2
  exit 1
fi

mkdir -p \
  "$project_root/build-plan/phases" \
  "$project_root/testing" \
  "$project_root/as-built"

today="$(date +%F)"
slug="$(printf '%s' "$project_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9][^a-z0-9]*/-/g; s/^-//; s/-$//')"
if [ -z "$slug" ]; then
  slug="project"
fi

render_template() {
  src="$1"
  dest="$2"

  if [ -e "$dest" ]; then
    printf 'SKIP: %s exists\n' "$dest"
    return
  fi

  sed \
    -e "s/\[Project Name\]/$project_name/g" \
    -e "s/\[project name\]/$project_name/g" \
    -e "s/\[project-slug\]/$slug/g" \
    -e "s/\[phase-id\]/$phase_id/g" \
    -e "s/\[YYYY-MM-DD\]/$today/g" \
    -e "s/^Date:$/Date: $today/g" \
    -e "s/^Owner:$/Owner: TBD/g" \
    "$src" > "$dest"
  printf 'CREATE: %s\n' "$dest"
}

render_template "$template_root/phase-build-plan-template.md" \
  "$project_root/build-plan/phases/phase-$phase_id-build-plan.md"
render_template "$template_root/tactical-implementation-template.md" \
  "$project_root/build-plan/phases/phase-$phase_id-tactical-implementation-plan.md"
render_template "$template_root/phase-construction-directive-template.md" \
  "$project_root/build-plan/phases/phase-$phase_id-construction-directive.md"
render_template "$template_root/phase-build-prompt-template.md" \
  "$project_root/build-plan/phases/phase-$phase_id-build-prompt.md"
render_template "$template_root/phase-implementation-evidence-template.md" \
  "$project_root/build-plan/phases/phase-$phase_id-implementation-evidence.md"
render_template "$template_root/code-review-report-template.md" \
  "$project_root/build-plan/phases/phase-$phase_id-code-review.md"
render_template "$template_root/phase-remediation-template.md" \
  "$project_root/build-plan/phases/phase-$phase_id-remediation.md"
render_template "$template_root/phase-learnings-template.md" \
  "$project_root/build-plan/phases/phase-$phase_id-learnings.md"
render_template "$template_root/test-uat-plan-template.md" \
  "$project_root/testing/phase-$phase_id-test-uat-plan.md"
render_template "$template_root/as-built-closeout-template.md" \
  "$project_root/as-built/phase-$phase_id-as-built-closeout.md"
render_template "$template_root/value-review-template.md" \
  "$project_root/as-built/phase-$phase_id-value-review.md"
