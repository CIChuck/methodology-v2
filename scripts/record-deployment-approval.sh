#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -eu

script_dir="$(cd "$(dirname "$0")" && pwd)"
. "$script_dir/lib/gendev-transition.sh"

usage() {
  cat <<'USAGE'
Usage:
  scripts/record-deployment-approval.sh [--dry-run] [--answers-file PATH]

Records a G8 deployment or non-deployment approval event without changing the
major gate and without running any production action.
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
    *) usage >&2; exit 2 ;;
  esac
done

gendev_record_deployment_approval "$dry_run" "$answers_file"
