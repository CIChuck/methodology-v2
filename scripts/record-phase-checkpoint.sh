#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -eu

script_dir="$(cd "$(dirname "$0")" && pwd)"
. "$script_dir/lib/gendev-transition.sh"

usage() {
  cat <<'USAGE'
Usage:
  scripts/record-phase-checkpoint.sh [--dry-run] [--answers-file PATH] G5.0|G5.<id>.1|G5.<id>.2|G5.<id>.3

Records an interior phase checkpoint. This command is intentionally separate
from close-gate.sh because phase checkpoints do not advance project.current_gate.
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
  G5.0 | G5.*.1 | G5.*.2 | G5.*.3)
    ;;
  *)
    printf 'Unsupported phase checkpoint: %s\n' "$1" >&2
    exit 2
    ;;
esac

gendev_record_phase_checkpoint "$1" "$dry_run" "$answers_file"
