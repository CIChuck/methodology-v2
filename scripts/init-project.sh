#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/init-project.sh [--force] "Project Name"

Creates docs/project/ from the methodology templates.

Options:
  --force   Replace an existing docs/project directory.
USAGE
}

force=0

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if [ "${1:-}" = "--force" ]; then
  force=1
  shift
fi

if [ "$#" -ne 1 ]; then
  usage
  exit 2
fi

project_name="$1"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
target="$repo_root/docs/project"
template_root="$repo_root/docs/methodology/templates"
project_template="$repo_root/docs/project-template"

slug="$(
  printf '%s' "$project_name" |
    tr '[:upper:]' '[:lower:]' |
    sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
)"

if [ -z "$slug" ]; then
  echo "Project name must contain at least one alphanumeric character." >&2
  exit 2
fi

if [ -e "$target" ]; then
  if [ "$force" -ne 1 ]; then
    echo "docs/project already exists. Re-run with --force to replace it." >&2
    exit 1
  fi
  rm -rf "$target"
fi

today="$(date +%F)"
project_name_sed="$(printf '%s' "$project_name" | sed 's/[\/&]/\\&/g')"
slug_sed="$(printf '%s' "$slug" | sed 's/[\/&]/\\&/g')"
today_sed="$(printf '%s' "$today" | sed 's/[\/&]/\\&/g')"

mkdir -p \
  "$target/approvals" \
  "$target/vision" \
  "$target/prd" \
  "$target/architecture" \
  "$target/security-governance" \
  "$target/decisions" \
  "$target/build-plan/phases" \
  "$target/testing" \
  "$target/traceability" \
  "$target/as-built"

render_template() {
  src="$1"
  dest="$2"

  sed \
    -e "s/\[Project Name\]/$project_name_sed/g" \
    -e "s/\[project name\]/$project_name_sed/g" \
    -e "s/\[project-slug\]/$slug_sed/g" \
    -e "s/\[YYYY-MM-DD\]/$today_sed/g" \
    -e "s/^Date:$/Date: $today_sed/g" \
    -e "s/^Owner:$/Owner: TBD/g" \
    "$src" > "$dest"
}

render_template "$project_template/project.yaml" "$target/project.yaml"
render_template "$project_template/approvals/gate-log.md" "$target/approvals/gate-log.md"
render_template "$template_root/vision-template.md" "$target/vision/$slug-vision.md"
render_template "$template_root/prd-template.md" "$target/prd/$slug-prd.md"
render_template "$template_root/architecture-template.md" "$target/architecture/$slug-architecture.md"
render_template "$template_root/governance-security-template.md" "$target/security-governance/governance-security-spec.md"
render_template "$template_root/traceability-matrix-template.md" "$target/traceability/$slug-traceability-matrix.md"
render_template "$template_root/0001-technology-stack-template.md" "$target/decisions/0001-technology-stack.md"
render_template "$template_root/phase-build-plan-template.md" "$target/build-plan/phases/phase-1-build-plan.md"
render_template "$template_root/tactical-implementation-template.md" "$target/build-plan/phases/phase-1-tactical-implementation-plan.md"
render_template "$template_root/test-uat-plan-template.md" "$target/testing/phase-1-test-uat-plan.md"
render_template "$template_root/code-review-report-template.md" "$target/build-plan/phases/phase-1-code-review.md"
render_template "$template_root/as-built-closeout-template.md" "$target/as-built/phase-1-as-built-closeout.md"
render_template "$template_root/value-review-template.md" "$target/as-built/phase-1-value-review.md"

cat > "$target/build-plan/phase-roadmap.md" <<EOF
# Phase Roadmap: $project_name

Status: Draft | Ready for Review | Ready for Approval | Accepted | Stale | Superseded
Date: $today
Owner: TBD
Authority: docs/methodology/constitution/gendev.md
Produced by: TBD
Produced on: $today
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/prd/$slug-prd.md
    revision: TBD
  - path: docs/project/architecture/$slug-architecture.md
    revision: TBD
  - path: docs/project/security-governance/governance-security-spec.md
    revision: TBD

## Purpose

This roadmap records the planned phase sequence for $project_name.

Do not treat this roadmap as tactical implementation authority. Each phase still requires a phase
build plan, tactical implementation plan, construction directive, tests/UAT evidence, review, and
as-built close-out.

## Current Phase

| Phase | Name | Status | Notes |
| --- | --- | --- | --- |
| 1 | Foundation | planning | Replace with the first accepted product phase. |

## Accuracy Pass

Before accepting this roadmap, check for:

\`\`\`text
[ ] phases that are too broad
[ ] missing dependencies
[ ] deferred items without target phase
[ ] phases with no acceptance signal
[ ] security-sensitive work before governance is ready
\`\`\`
EOF

cat > "$target/build-plan/phases/phase-1-construction-directive.md" <<EOF
# Phase 1 Construction Directive: $project_name

Status: Draft | Ready for Review | Ready for Approval | Accepted | Stale | Superseded
Date: $today
Owner: TBD
Authority: docs/methodology/constitution/gendev.md
Source:
  Phase Build Plan: docs/project/build-plan/phases/phase-1-build-plan.md
  Tactical Plan: docs/project/build-plan/phases/phase-1-tactical-implementation-plan.md
  PRD: docs/project/prd/$slug-prd.md
  Architecture: docs/project/architecture/$slug-architecture.md
  Governance/Security: docs/project/security-governance/governance-security-spec.md
Produced by: TBD
Produced on: $today
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/build-plan/phases/phase-1-build-plan.md
    revision: TBD
  - path: docs/project/build-plan/phases/phase-1-tactical-implementation-plan.md
    revision: TBD
  - path: docs/project/prd/$slug-prd.md
    revision: TBD
  - path: docs/project/architecture/$slug-architecture.md
    revision: TBD
  - path: docs/project/security-governance/governance-security-spec.md
    revision: TBD

## Completion Standard

This directive is complete when it can be sent to an implementation agent as the controlling build
authority for Phase 1.

## AI Builder Role

You are implementing a bounded phase from documented authority. Implement only the scope authorized
by this directive and the tactical implementation plan.

## Source Authority And Precedence

1. docs/project/security-governance/governance-security-spec.md
2. docs/project/architecture/$slug-architecture.md
3. docs/project/prd/$slug-prd.md
4. docs/project/build-plan/phases/phase-1-build-plan.md
5. docs/project/build-plan/phases/phase-1-tactical-implementation-plan.md
6. This construction directive

## Implementation Objective

\`\`\`text
Replace with the exact Phase 1 implementation objective.
\`\`\`

## Allowed Scope

\`\`\`text
Replace with authorized files, modules, behavior, tests, and documentation changes.
\`\`\`

## Non-Goals

\`\`\`text
List deferred and forbidden behavior. The implementation agent must not build these items.
\`\`\`

## Required Workstreams

\`\`\`text
Summarize tactical workstreams that must be implemented.
\`\`\`

## Required Tests And Verification

\`\`\`text
List required tests, UAT checks, verification commands, and expected evidence.
\`\`\`

## Security And Governance Requirements

\`\`\`text
List active security/governance constraints for this phase.
\`\`\`

## Documentation Close-Out

\`\`\`text
List docs that must be updated before phase close.
\`\`\`

## Stop Conditions

Stop and request human or planning review if implementation requires new scope, architecture
changes, deferred behavior, unapproved external services, destructive migration, or changed
security/governance behavior.
EOF

cat > "$target/README.md" <<EOF
# $project_name

This is the active project authority directory for $project_name.

Start with the vision document, then move through PRD, architecture, governance/security,
phase planning, tactical implementation planning, construction directives, implementation,
review, remediation, and as-built close-out.

Controlling methodology:

\`\`\`text
docs/methodology/constitution/gendev.md
\`\`\`

Project manifest:

\`\`\`text
docs/project/project.yaml
\`\`\`

Current gate:

\`\`\`text
G1 Vision Ready
\`\`\`
EOF

cat > "$target/build-plan/README.md" <<EOF
# Build Plan

Use this directory for roadmap-level build planning and phase-specific plans.

Phase plans live under:

\`\`\`text
docs/project/build-plan/phases/
\`\`\`
EOF

echo "Initialized docs/project for $project_name"
echo "Project slug: $slug"
echo "Next document: docs/project/vision/$slug-vision.md"
