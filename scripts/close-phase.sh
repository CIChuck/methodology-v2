#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -eu

script_dir="$(cd "$(dirname "$0")" && pwd)"
. "$script_dir/lib/gendev-transition.sh"

usage() {
  cat <<'USAGE'
Usage:
  scripts/close-phase.sh [--dry-run] [--answers-file PATH] <phase-id>

Records G5.<id>.4 phase exit after phase evidence is complete.
USAGE
}

dry_run=0
answers_file=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h | --help) usage; exit 0 ;;
    --dry-run) dry_run=1; shift ;;
    --answers-file)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      answers_file="$2"
      shift 2
      ;;
    --) shift; break ;;
    -*) usage >&2; exit 2 ;;
    *) break ;;
  esac
done

if [ "$#" -ne 1 ]; then
  usage >&2
  exit 2
fi

case "$1" in
  "" | *[!A-Za-z0-9._-]*)
    printf 'Invalid phase id: %s\n' "$1" >&2
    exit 2
    ;;
esac

gendev_close_phase "$1" "$dry_run" "$answers_file"
