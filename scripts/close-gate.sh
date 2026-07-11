#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -eu

script_dir="$(cd "$(dirname "$0")" && pwd)"
. "$script_dir/lib/gendev-transition.sh"

usage() {
  cat <<'USAGE'
Usage:
  scripts/close-gate.sh [--dry-run] [--answers-file PATH] G1|G2|G3|G4|G5|G6|G7|G8

Records a major lifecycle gate transition. G9 is terminal and has no outgoing
transition. The command validates the initialized project control plane, renders
candidate files first, installs them under a project-local lock, and rolls back
on post-write validation failure.
USAGE
}

dry_run=0
answers_file=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --answers-file)
      if [ "$#" -lt 2 ]; then
        usage >&2
        exit 2
      fi
      answers_file="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*)
      usage >&2
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

if [ "$#" -ne 1 ]; then
  usage >&2
  exit 2
fi

gendev_close_major_gate "$1" "$dry_run" "$answers_file"
