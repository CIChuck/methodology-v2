#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/backfill-methodology.sh [options] TARGET_REPO_PATH

Installs the methodology and creates a non-destructive GenDev control plane for
an existing project that already has at least one authority document.

Options:
  --project-name NAME          Project name for a newly-created manifest.
  --vision PATH                Existing vision document to import or validate.
  --prd PATH                   Existing PRD document to import or validate.
  --architecture PATH          Existing architecture document to import or validate.
  --dry-run                    Validate and report without writing.
  --force                      Upgrade GenDev-owned methodology assets only; never overwrite imported authority.
  --with-resources             Also install docs/resources reference material.
  -h, --help                   Show this help.
USAGE
}

force=0
with_resources=0
dry_run=0
project_name=""
vision_src=""
prd_src=""
architecture_src=""

while [ "$#" -gt 0 ]; do
  case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    --force) force=1; shift ;;
    --with-resources) with_resources=1; shift ;;
    --dry-run) dry_run=1; shift ;;
    --project-name)
      [ "$#" -ge 2 ] || { echo "--project-name requires a value" >&2; exit 2; }
      project_name="$2"; shift 2 ;;
    --vision)
      [ "$#" -ge 2 ] || { echo "--vision requires a path" >&2; exit 2; }
      vision_src="$2"; shift 2 ;;
    --prd)
      [ "$#" -ge 2 ] || { echo "--prd requires a path" >&2; exit 2; }
      prd_src="$2"; shift 2 ;;
    --architecture)
      [ "$#" -ge 2 ] || { echo "--architecture requires a path" >&2; exit 2; }
      architecture_src="$2"; shift 2 ;;
    -*) echo "Unknown option: $1" >&2; usage; exit 2 ;;
    *) break ;;
  esac
done

if [ "$#" -ne 1 ]; then
  usage
  exit 2
fi

target_repo="$1"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
. "$repo_root/scripts/lib/gendev-distribution.sh"

if [ ! -d "$target_repo" ]; then
  echo "Target does not exist: $target_repo" >&2
  exit 1
fi
target_repo="$(cd "$target_repo" && pwd)"
if [ "$target_repo" = "$repo_root" ]; then
  echo "Target is the methodology repo itself. Nothing to do." >&2
  exit 1
fi

if [ -z "$project_name" ]; then
  project_name="$(basename "$target_repo")"
fi

canonical_vision="docs/project/vision/vision.md"
canonical_prd="docs/project/prd/prd.md"
canonical_architecture="docs/project/architecture/architecture.md"

legacy_mode=0
if [ -z "$vision_src$prd_src$architecture_src" ]; then
  legacy_mode=1
  vision_src="$target_repo/$canonical_vision"
  prd_src="$target_repo/$canonical_prd"
  architecture_src="$target_repo/$canonical_architecture"
fi

import_count=0
missing=0
for pair in \
  "vision|$vision_src|$canonical_vision" \
  "prd|$prd_src|$canonical_prd" \
  "architecture|$architecture_src|$canonical_architecture"; do
  kind="${pair%%|*}"
  rest="${pair#*|}"
  src="${rest%%|*}"
  rel="${rest#*|}"
  [ -z "$src" ] && continue
  if [ ! -f "$src" ]; then
    echo "Expected doc not found in target: $rel" >&2
    missing=1
    continue
  fi
  import_count=$((import_count + 1))
done

if [ "$missing" -ne 0 ]; then
  if [ "$legacy_mode" -eq 1 ]; then
    echo "This script expects at least one existing authority document; legacy invocation checked vision, PRD, and architecture paths." >&2
  fi
  exit 1
fi
if [ "$import_count" -eq 0 ]; then
  echo "Declare at least one existing authority document with --vision, --prd, or --architecture." >&2
  exit 2
fi

preflight_import_collision() {
  src="$1"
  rel="$2"
  [ -z "$src" ] && return 0
  dest="$target_repo/$rel"
  [ -f "$dest" ] || return 0
  if cmp -s "$src" "$dest"; then
    return 0
  fi
  src_abs="$(cd "$(dirname "$src")" && pwd)/$(basename "$src")"
  dest_abs="$(cd "$(dirname "$dest")" && pwd)/$(basename "$dest")"
  if [ "$src_abs" != "$dest_abs" ]; then
    echo "Refusing to overwrite imported authority: $rel" >&2
    return 1
  fi
}

preflight_import_collision "$vision_src" "$canonical_vision"
preflight_import_collision "$prd_src" "$canonical_prd"
preflight_import_collision "$architecture_src" "$canonical_architecture"

hash_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    python3 - "$1" <<'PY'
import hashlib
import sys
with open(sys.argv[1], 'rb') as handle:
    print(hashlib.sha256(handle.read()).hexdigest())
PY
  fi
}

slug="$(printf '%s' "$project_name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
[ -n "$slug" ] || { echo "Project name must contain at least one alphanumeric character." >&2; exit 2; }
today="$(date +%F)"

if [ "$dry_run" -ne 1 ]; then
  if [ -e "$target_repo/docs/methodology" ] && [ "$force" -ne 1 ]; then
    echo "docs/methodology already exists in the target. Re-run with --force to upgrade GenDev-owned paths." >&2
    exit 1
  fi
  install_args=""
  [ "$force" -eq 1 ] && install_args="$install_args --force"
  [ "$with_resources" -eq 1 ] && install_args="$install_args --with-resources"
  # shellcheck disable=SC2086
  "$repo_root/scripts/install-methodology.sh" $install_args "$target_repo" >/dev/null
fi

if [ "$dry_run" -eq 1 ]; then
  echo "DRY RUN: would backfill $target_repo"
  exit 0
fi

mkdir -p \
  "$target_repo/docs/project/approvals" \
  "$target_repo/docs/project/vision" \
  "$target_repo/docs/project/prd" \
  "$target_repo/docs/project/architecture" \
  "$target_repo/docs/project/security-governance" \
  "$target_repo/docs/project/decisions" \
  "$target_repo/docs/project/build-plan/phases" \
  "$target_repo/docs/project/testing" \
  "$target_repo/docs/project/traceability" \
  "$target_repo/docs/project/as-built" \
  "$target_repo/docs/project/deployment" \
  "$target_repo/docs/project/review"

install_import() {
  src="$1"
  rel="$2"
  [ -z "$src" ] && return 0
  dest="$target_repo/$rel"
  if [ -f "$dest" ]; then
    if cmp -s "$src" "$dest"; then
      return 0
    fi
    if [ "$(cd "$(dirname "$src")" && pwd)/$(basename "$src")" != "$(cd "$(dirname "$dest")" && pwd)/$(basename "$dest")" ]; then
      echo "Refusing to overwrite imported authority: $rel" >&2
      return 1
    fi
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
}

install_import "$vision_src" "$canonical_vision"
install_import "$prd_src" "$canonical_prd"
install_import "$architecture_src" "$canonical_architecture"

render_template() {
  src="$1"
  dest="$2"
  [ -f "$dest" ] && return 0
  project_name_sed="$(printf '%s' "$project_name" | sed 's/[\/&]/\\&/g')"
  slug_sed="$(printf '%s' "$slug" | sed 's/[\/&]/\\&/g')"
  today_sed="$(printf '%s' "$today" | sed 's/[\/&]/\\&/g')"
  sed \
    -e "s/\[Project Name\]/$project_name_sed/g" \
    -e "s/\[project name\]/$project_name_sed/g" \
    -e "s/\[project-slug\]/$slug_sed/g" \
    -e "s/\[YYYY-MM-DD\]/$today_sed/g" \
    -e "s/^Date:$/Date: $today_sed/g" \
    -e "s/^Owner:$/Owner: TBD/g" \
    "$src" > "$dest"
}

render_template "$target_repo/docs/project-template/project.yaml" "$target_repo/docs/project/project.yaml"
render_template "$target_repo/docs/methodology/templates/gate-log-template.md" "$target_repo/docs/project/approvals/gate-log.md"
render_template "$target_repo/docs/methodology/templates/governance-security-template.md" "$target_repo/docs/project/security-governance/governance-security-spec.md"
render_template "$target_repo/docs/methodology/templates/traceability-matrix-template.md" "$target_repo/docs/project/traceability/traceability-matrix.md"
render_template "$target_repo/docs/methodology/templates/0001-technology-stack-template.md" "$target_repo/docs/project/decisions/0001-technology-stack.md"
render_template "$target_repo/docs/methodology/templates/phase-plan-template.md" "$target_repo/docs/project/build-plan/phase-plan.md"

report="$target_repo/docs/project/backfill-conformance-report.md"
checker_output="$target_repo/docs/project/backfill-checker-output.txt"
checker_rc=0
(
  cd "$target_repo"
  ./scripts/check-methodology.sh > "$checker_output" 2>&1
) || checker_rc=$?

front_matter_keys='Status project Date Owner Authority Produced by Produced on Produced with Agent identity Derived from'

has_key() {
  doc="$1"
  key="$2"
  grep -qi "^${key}:" "$doc"
}

write_doc_report() {
  label="$1"
  rel="$2"
  src="$3"
  [ -z "$src" ] && return 0
  doc="$target_repo/$rel"
  {
    echo "## $label"
    echo
    echo "canonical_path: $rel"
    echo "source_path: $src"
    echo "sha256: $(hash_file "$doc")"
    echo
    echo "### Required provenance and identity fields"
    for key in $front_matter_keys; do
      case "$key" in
        Produced|by|on|with|Agent|identity|Derived|from) continue ;;
      esac
      if has_key "$doc" "$key"; then
        echo "- present: $key"
      else
        echo "- MISSING: $key"
      fi
    done
    for key in "Produced by" "Produced on" "Produced with" "Agent identity" "Derived from"; do
      if has_key "$doc" "$key"; then
        echo "- present: $key"
      else
        echo "- MISSING: $key"
      fi
    done
    echo
  } >> "$report"
}

cat > "$report" <<EOF_REPORT
# Backfill Conformance Report

Status: Complete
project: $slug
Date: $today
Owner: TBD
Authority: docs/methodology/constitution/gendev.md
Produced by: scripts/backfill-methodology.sh
Produced on: $today
Produced with: GenDev methodology backfill
Agent identity: gendev-backfill
Derived from:
  - path: docs/project/project.yaml
    revision: N/A

This report is heuristic guidance, not approval. It does not mark imported authority as Accepted.
Lifecycle progression must stop at the first missing or unaccepted upstream gate.

checker_exit_status: $checker_rc
checker_output: docs/project/backfill-checker-output.txt
next_gate_specific_conformance_action: reconcile the first imported authority document that is missing required fields or remains unaccepted.

EOF_REPORT

write_doc_report "Vision" "$canonical_vision" "$vision_src"
write_doc_report "PRD" "$canonical_prd" "$prd_src"
write_doc_report "Architecture" "$canonical_architecture" "$architecture_src"

cat >> "$report" <<EOF_REPORT
## Imported Document Availability

- vision: $([ -n "$vision_src" ] && echo present || echo missing)
- prd: $([ -n "$prd_src" ] && echo present || echo missing)
- architecture: $([ -n "$architecture_src" ] && echo present || echo missing)

## Real Checker Status

The checker was run after the control plane existed. Exit status: $checker_rc.
Expected conformance gaps remain until imported authority is reconciled to templates and approved.
EOF_REPORT

echo "Backfill complete. Report: docs/project/backfill-conformance-report.md"
echo "Checker exit status: $checker_rc"
