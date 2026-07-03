#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# install-methodology.sh
#
# Copies the GenDev methodology (the rulebook) from this methodology repo into
# an existing target repo. This is not the same as init-project.sh. That script
# starts a fresh project inside this repo. This one installs the governing
# methodology into a repo that already has its own code, so that repo can then
# be run under GenDev governance.
#
# What gets copied by default:
#   docs/methodology/       the constitution, guides, templates, agents
#   docs/project-template/   the empty project skeleton init-project renders from
#   scripts/                 the checker, guard, hooks, init-project, metrics
#   AGENTS.md                agent operating rules the methodology references
#
# The practitioner guide, examples, and research under docs/resources/ are not
# copied by default (they are reference, not the governing rulebook). Add them
# with --with-resources.
#
# What does not get copied:
#   docs/project/            per-project authority, never travels between repos
#   this repo's .git         the target keeps its own history

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/install-methodology.sh [--force] [--with-resources] TARGET_REPO_PATH

Run this from inside the methodology repo. It copies the methodology into
TARGET_REPO_PATH, an existing repo you want to bring under GenDev.

Options:
  --force            Overwrite an existing docs/methodology in the target.
  --with-resources   Also copy docs/resources (practitioner guide, examples, research).
  -h, --help         Show this help.

Example:
  scripts/install-methodology.sh ~/code/my-existing-app
  scripts/install-methodology.sh --with-resources ~/code/my-existing-app
USAGE
}

force=0
with_resources=0

while [ "$#" -gt 0 ]; do
  case "${1:-}" in
    -h|--help)
      usage
      exit 0
      ;;
    --force)
      force=1
      shift
      ;;
    --with-resources)
      with_resources=1
      shift
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

if [ "$#" -ne 1 ]; then
  usage
  exit 2
fi

target_repo="$1"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

# Sanity: are we actually in the methodology repo?
if [ ! -f "$repo_root/docs/methodology/constitution/gendev.md" ]; then
  echo "This does not look like the methodology repo (no docs/methodology/constitution/gendev.md)." >&2
  echo "Run this script from inside the methodology repo." >&2
  exit 1
fi

# Sanity: does the target exist and look like a repo?
if [ ! -d "$target_repo" ]; then
  echo "Target does not exist: $target_repo" >&2
  exit 1
fi
target_repo="$(cd "$target_repo" && pwd)"

if [ "$target_repo" = "$repo_root" ]; then
  echo "Target is the methodology repo itself. Nothing to install." >&2
  exit 1
fi

if [ ! -d "$target_repo/.git" ]; then
  echo "Warning: $target_repo has no .git directory. Continuing, but this does not look like a repo." >&2
fi

# Refuse to clobber an existing install unless forced.
if [ -e "$target_repo/docs/methodology" ] && [ "$force" -ne 1 ]; then
  echo "docs/methodology already exists in the target. Re-run with --force to overwrite." >&2
  exit 1
fi

echo "Installing methodology into: $target_repo"

mkdir -p "$target_repo/docs"

# The rulebook.
copy_tree() {
  src="$1"
  dest="$2"
  if [ ! -e "$src" ]; then
    echo "Warning: expected source missing, skipping: $src" >&2
    return 0
  fi
  rm -rf "$dest"
  cp -R "$src" "$dest"
  echo "  copied $(basename "$src")"
}

copy_tree "$repo_root/docs/methodology"      "$target_repo/docs/methodology"
copy_tree "$repo_root/docs/project-template" "$target_repo/docs/project-template"

# Scripts the methodology references (checker, guard, hooks, init-project, metrics).
mkdir -p "$target_repo/scripts"
for s in check-methodology.sh methodology-guard.sh install-hooks.sh init-project.sh methodology-metrics.sh test-checker.sh; do
  if [ -f "$repo_root/scripts/$s" ]; then
    cp "$repo_root/scripts/$s" "$target_repo/scripts/$s"
    chmod +x "$target_repo/scripts/$s"
    echo "  copied scripts/$s"
  fi
done

# AGENTS.md, referenced throughout the methodology. Do not overwrite the
# target's own AGENTS.md if it already has one; that is theirs to own.
if [ -f "$repo_root/AGENTS.md" ]; then
  if [ -e "$target_repo/AGENTS.md" ] && [ "$force" -ne 1 ]; then
    echo "  target already has AGENTS.md, left untouched (use --force to overwrite)"
  else
    cp "$repo_root/AGENTS.md" "$target_repo/AGENTS.md"
    echo "  copied AGENTS.md"
  fi
fi

# Optional reference material.
if [ "$with_resources" -eq 1 ]; then
  copy_tree "$repo_root/docs/resources" "$target_repo/docs/resources"
fi

echo
echo "Done. The methodology is installed in $target_repo."
echo
echo "Next steps in the target repo:"
echo "  1. Review docs/methodology/constitution/gendev.md, the governing authority."
echo "  2. Start a project against your existing code:"
echo "       scripts/init-project.sh \"Your Project Name\""
echo "  3. Optional: install the pre-commit checker:"
echo "       scripts/install-hooks.sh"
echo "  4. Verify the install:"
echo "       scripts/check-methodology.sh"
