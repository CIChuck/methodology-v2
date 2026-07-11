#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/install-methodology.sh [options] TARGET_REPO_PATH

Installs the GenDev methodology into an existing repository without copying
project authority from this repository.

Options:
  --dry-run                    Validate and report planned actions without writing.
  --force                      Upgrade existing GenDev-owned paths only.
  --with-resources             Also install docs/resources reference material.
  --integrate-agents           Add a managed GenDev include block to existing AGENTS.md.
  --protected-branch BRANCH    Render workflow push checks for BRANCH.
  -h, --help                   Show this help.
USAGE
}

force=0
with_resources=0
dry_run=0
integrate_agents=0
protected_branch=""

while [ "$#" -gt 0 ]; do
  case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    --force) force=1; shift ;;
    --with-resources) with_resources=1; shift ;;
    --dry-run) dry_run=1; shift ;;
    --integrate-agents) integrate_agents=1; shift ;;
    --protected-branch)
      [ "$#" -ge 2 ] || { echo "--protected-branch requires a value" >&2; exit 2; }
      protected_branch="$2"
      shift 2
      ;;
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
  echo "Target is the methodology repo itself. Nothing to install." >&2
  exit 1
fi

if [ ! -d "$target_repo/.git" ]; then
  echo "Warning: $target_repo has no .git directory. Continuing with explicit file operations." >&2
fi

if gendev_dist_install "$repo_root" "$target_repo" "$force" "$with_resources" "$dry_run" "$integrate_agents" "$protected_branch"; then
  gendev_dist_print_report
  echo
  if [ -f "$target_repo/AGENTS.md" ] && ! grep -q 'BEGIN MANAGED GENDEV INSTRUCTIONS' "$target_repo/AGENTS.md"; then
    echo "Install completed with preserved AGENTS.md; fully governed operation requires explicit AGENTS integration."
  else
    echo "Install completed."
  fi
  echo "Next: run scripts/init-project.sh \"Your Project Name\" in the target, then scripts/check-methodology.sh."
  exit 0
fi

gendev_dist_print_report >&2
exit 1
