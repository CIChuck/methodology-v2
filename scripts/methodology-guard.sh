#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -eu

GENDEV_LIB_DIR="$(cd "$(dirname "$0")/lib" && pwd)"
. "$GENDEV_LIB_DIR/gendev-common.sh"

usage() {
  cat <<'USAGE'
Usage:
  scripts/methodology-guard.sh
  scripts/methodology-guard.sh --staged
  scripts/methodology-guard.sh --range BASE_REF HEAD_REF
  scripts/methodology-guard.sh --changed-paths PATHS_FILE [--base-ref BASE_REF] [--context CONTEXT_FILE] [--require-task-id]

Runs the GenDev methodology checker. When changed-path context is supplied, the checker also
evaluates enforcement rules that depend on a diff, such as implementation-path protection.
USAGE
}

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root"

tmpdir="$(gendev_mktemp_dir)"
range_worktree=""

cleanup() {
  if [ -n "${range_worktree}" ] && [ -d "${range_worktree}" ]; then
    git worktree remove --force "${range_worktree}" >/dev/null 2>&1 || rm -rf "${range_worktree}"
  fi
  gendev_cleanup_tmp "$tmpdir"
}
trap cleanup EXIT

changed_paths_file=""
base_ref=""
context_file=""
require_task_id=0
methodology_root=""

case "${1:-}" in
  "")
    ;;
  --staged)
    changed_paths_file="$tmpdir/changed-paths.txt"
    git diff --cached --name-only > "$changed_paths_file"

    methodology_root="$tmpdir/staged-methodology"
    staged_index="$tmpdir/staged.index"
    mkdir -p "$methodology_root"
    cp "$(git rev-parse --git-path index)" "$staged_index"
    GIT_INDEX_FILE="$staged_index" git checkout-index -a -f --prefix="${methodology_root}/" >/dev/null
    ;;
  --range)
    if [ "$#" -ne 3 ]; then
      usage
      exit 2
    fi
    base_ref="$2"
    head_ref="$3"
    changed_paths_file="$tmpdir/changed-paths.txt"
    context_file="$tmpdir/review-context.txt"
    git diff --name-only "$base_ref" "$head_ref" > "$changed_paths_file"
    git log --format=%B "$base_ref..$head_ref" > "$context_file"
    require_task_id=1
    range_worktree="$tmpdir/range-methodology"
    git worktree add --detach "${range_worktree}" "$head_ref" >/dev/null
    methodology_root="$range_worktree"
    ;;
  --changed-paths)
    if [ "$#" -lt 2 ]; then
      usage
      exit 2
    fi
    changed_paths_file="$2"
    shift 2
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --base-ref)
          [ "$#" -ge 2 ] || {
            usage
            exit 2
          }
          base_ref="$2"
          shift 2
          ;;
        --context)
          [ "$#" -ge 2 ] || {
            usage
            exit 2
          }
          context_file="$2"
          shift 2
          ;;
        --require-task-id)
          require_task_id=1
          shift
          ;;
        *)
          usage
          exit 2
          ;;
      esac
    done
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    usage
    exit 2
    ;;
esac

if [ -n "$changed_paths_file" ]; then
  export GENDEV_CHANGED_PATHS_FILE="$changed_paths_file"
fi

if [ -n "$base_ref" ]; then
  export GENDEV_BASE_REF="$base_ref"
fi

if [ -n "$context_file" ]; then
  export GENDEV_TRACE_CONTEXT_FILE="$context_file"
fi

if [ "$require_task_id" -eq 1 ]; then
  export GENDEV_REQUIRE_TASK_ID=1
fi

if [ -n "$methodology_root" ]; then
  (cd "$methodology_root" && ./scripts/check-methodology.sh)
else
  ./scripts/check-methodology.sh
fi
