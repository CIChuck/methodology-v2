#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# backfill-methodology.sh
#
# For a presales repo that already has the methodology folder tree and already
# has vision, PRD, and architecture docs sitting in their correct subfolders
# (written for customer consumption, not yet conformed to the templates), this
# script does two deterministic jobs:
#
#   1. Seeds the methodology (the rulebook) into the repo, same as
#      install-methodology.sh.
#   2. Produces a per-gate conformance report: for each of the three docs
#      already in place, which required front-matter fields and which required
#      sections the template wants but the document does not yet have.
#
# It does not move, rewrite, or reformat any document. Conforming the content
# is per-gate agent work, driven by the report this script produces. Each gate
# (G1 vision, G2 PRD, G3 architecture) becomes: reformat the already-placed
# document to its template and satisfy the exit checklist. The report is what
# makes each of those directives precise.
#
# Assumes the target already has:
#   docs/project/vision/vision.md
#   docs/project/prd/prd.md
#   docs/project/architecture/architecture.md

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/backfill-methodology.sh [--force] [--with-resources] TARGET_REPO_PATH

Run from inside the methodology repo. Seeds the methodology into a presales
repo that already has the project folder tree and its vision, PRD, and
architecture docs in place, then writes a conformance report to
docs/project/backfill-conformance-report.md in the target.

Options:
  --force            Overwrite an existing docs/methodology in the target.
  --with-resources   Also copy docs/resources.
  -h, --help         Show this help.
USAGE
}

force=0
with_resources=0

while [ "$#" -gt 0 ]; do
  case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    --force) force=1; shift ;;
    --with-resources) with_resources=1; shift ;;
    -*) echo "Unknown option: $1" >&2; usage; exit 2 ;;
    *) break ;;
  esac
done

if [ "$#" -ne 1 ]; then usage; exit 2; fi

target_repo="$1"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

if [ ! -f "$repo_root/docs/methodology/constitution/gendev.md" ]; then
  echo "Not in the methodology repo (no docs/methodology/constitution/gendev.md)." >&2
  exit 1
fi
if [ ! -d "$target_repo" ]; then
  echo "Target does not exist: $target_repo" >&2
  exit 1
fi
target_repo="$(cd "$target_repo" && pwd)"
if [ "$target_repo" = "$repo_root" ]; then
  echo "Target is the methodology repo itself. Nothing to do." >&2
  exit 1
fi

# The three docs must already be in place. This script backfills, it does not
# create or move them.
missing_docs=0
for rel in \
  "docs/project/vision/vision.md" \
  "docs/project/prd/prd.md" \
  "docs/project/architecture/architecture.md"; do
  if [ ! -f "$target_repo/$rel" ]; then
    echo "Expected doc not found in target: $rel" >&2
    missing_docs=1
  fi
done
if [ "$missing_docs" -ne 0 ]; then
  echo "This script expects vision, PRD, and architecture already placed in their subfolders." >&2
  echo "For a repo without them, use install-methodology.sh then init-project.sh." >&2
  exit 1
fi

# --- Step 1: seed the methodology (same rulebook install) ---
if [ -e "$target_repo/docs/methodology" ] && [ "$force" -ne 1 ]; then
  echo "docs/methodology already exists in the target. Re-run with --force to overwrite." >&2
  exit 1
fi

echo "Seeding methodology into: $target_repo"

copy_tree() {
  src="$1"; dest="$2"
  [ -e "$src" ] || { echo "Warning: missing source $src" >&2; return 0; }
  rm -rf "$dest"; cp -R "$src" "$dest"; echo "  copied $(basename "$src")"
}

mkdir -p "$target_repo/docs"
copy_tree "$repo_root/docs/methodology"      "$target_repo/docs/methodology"
copy_tree "$repo_root/docs/project-template" "$target_repo/docs/project-template"

mkdir -p "$target_repo/scripts"
for s in check-methodology.sh methodology-guard.sh install-hooks.sh init-project.sh methodology-metrics.sh test-checker.sh; do
  [ -f "$repo_root/scripts/$s" ] && { cp "$repo_root/scripts/$s" "$target_repo/scripts/$s"; chmod +x "$target_repo/scripts/$s"; echo "  copied scripts/$s"; }
done

if [ -f "$repo_root/AGENTS.md" ]; then
  if [ -e "$target_repo/AGENTS.md" ] && [ "$force" -ne 1 ]; then
    echo "  target already has AGENTS.md, left untouched"
  else
    cp "$repo_root/AGENTS.md" "$target_repo/AGENTS.md"; echo "  copied AGENTS.md"
  fi
fi

[ "$with_resources" -eq 1 ] && copy_tree "$repo_root/docs/resources" "$target_repo/docs/resources"

# --- Step 2: conformance report ---
report="$target_repo/docs/project/backfill-conformance-report.md"
tpl_root="$repo_root/docs/methodology/templates"

# Front-matter fields every template requires (the keys, minus the placeholder values).
FRONT_MATTER="Status project Date Owner Authority Produced-by Produced-on Derived-from"

# Extract the required '## ' section titles from a template.
required_sections() {
  grep "^## " "$1" | sed 's/^## //'
}

# Classify a required section against the doc's actual headings:
#   present  - a heading matches the template title (leading words, case-insensitive)
#   likely   - no title match, but the section's distinctive keyword appears as
#              some heading in the doc (content probably there under another name)
#   absent   - neither
classify_section() {
  doc="$1"; title="$2"
  key="$(printf '%s' "$title" | sed 's/ *(.*//')"
  # tolerate an optional numbering prefix like "## 6. " before the title
  if grep -qiE "^## *([0-9]+\.? *)?${key}" "$doc"; then
    echo "present"; return
  fi
  kw="$(printf '%s' "$key" | awk '{print $NF}')"
  if [ -n "$kw" ] && grep -qiE "^##.*${kw}" "$doc"; then
    echo "likely"; return
  fi
  echo "absent"
}

# Does the doc carry a front-matter key?
has_front_matter() {
  doc="$1"; key="$2"
  case "$key" in
    Produced-by) grep -qi "^Produced by:" "$doc" ;;
    Produced-on) grep -qi "^Produced on:" "$doc" ;;
    Derived-from) grep -qi "^Derived from:" "$doc" ;;
    project) grep -qi "^project:" "$doc" ;;
    *) grep -qi "^${key}:" "$doc" ;;
  esac
}

report_doc() {
  gate="$1"; label="$2"; doc="$3"; tpl="$4"
  {
    echo "## $gate: $label"
    echo ""
    echo "Document: \`${doc#$target_repo/}\`"
    echo "Template: \`docs/methodology/templates/$(basename "$tpl")\`"
    echo ""
    echo "### Front-matter"
    echo ""
    fm_missing=0
    for key in $FRONT_MATTER; do
      if has_front_matter "$doc" "$key"; then
        echo "- present: $key"
      else
        echo "- MISSING: $key"
        fm_missing=$((fm_missing + 1))
      fi
    done
    echo ""
    echo "### Required sections"
    echo ""
    sec_absent=0
    sec_likely=0
    while IFS= read -r title; do
      [ -z "$title" ] && continue
      state="$(classify_section "$doc" "$title")"
      case "$state" in
        present) echo "- present: $title" ;;
        likely)  echo "- LIKELY (content present under a different heading, rename/adapt): $title"; sec_likely=$((sec_likely + 1)) ;;
        absent)  echo "- ABSENT (no matching content, must be written): $title"; sec_absent=$((sec_absent + 1)) ;;
      esac
    done <<EOF
$(required_sections "$tpl")
EOF
    echo ""
    echo "### $gate reformatting directive (for the agent)"
    echo ""
    echo "Conform \`${doc#$target_repo/}\` to its template. Preserve the existing"
    echo "customer-facing content. Three kinds of work, in order of care:"
    echo ""
    echo "1. Add the $fm_missing missing front-matter field(s) listed above."
    echo "2. For the $sec_likely LIKELY section(s): the content already exists under"
    echo "   a different heading. Rename and lightly adapt to the template's exact"
    echo "   section title and structure. Do not rewrite the substance or invent new"
    echo "   content; this is a mapping task, not an authoring task."
    echo "3. For the $sec_absent ABSENT section(s): no matching content exists. Write"
    echo "   it only from what the document and its upstream authority already support."
    echo "   If the content genuinely does not exist, mark it explicitly (\"None\" or"
    echo "   \"Open question\") rather than inventing scope."
    echo ""
    echo "Then satisfy the $gate exit checklist. Do not introduce new scope at any step."
    echo ""
    echo "---"
    echo ""
  } >> "$report"
}

cat > "$report" <<EOF
# Backfill Conformance Report

Generated by backfill-methodology.sh. This repo entered the methodology with
vision, PRD, and architecture already written for customer consumption. Each
gate below becomes a reformatting task: conform the already-placed document to
its template and satisfy the exit checklist. This report lists, per document,
which required front-matter and sections are present and which are missing, so
each gate's agent directive is precise.

Gate sequence for this backfill: G1 (vision), then G2 (PRD), then G3
(architecture). Do them in order. Close G3 to reach architecture-ready.

---

EOF

report_doc "G1" "Vision"       "$target_repo/docs/project/vision/vision.md"             "$tpl_root/vision-template.md"
report_doc "G2" "PRD"          "$target_repo/docs/project/prd/prd.md"                   "$tpl_root/prd-template.md"
report_doc "G3" "Architecture" "$target_repo/docs/project/architecture/architecture.md" "$tpl_root/architecture-template.md"

echo
echo "Done."
echo "Methodology seeded, and conformance report written to:"
echo "  ${report#$target_repo/}"
echo
echo "Next: work the report gate by gate (G1 vision, G2 PRD, G3 architecture)."
echo "Each gate's reformatting directive is in the report. Close G3 to finish the backfill."
