#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# pin-provenance.sh — maintain Derived from revision pins.
#
# For each named artifact, reads its Derived from entries and repins every
# entry whose path exists in the repository to that source's current
# last-touching commit hash: the same computation the staleness detector in
# check-methodology.sh performs, so tool and checker cannot disagree about
# what "current" means.
#
# Usage:
#   scripts/pin-provenance.sh [--check] ARTIFACT [ARTIFACT...]
#
#   --check   Report stale pins without writing; exit 1 if any are stale.
#
# Run it whenever a source artifact has moved, which every gate closure
# causes, and after any rebase or merge from the integration branch.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
. "$script_dir/lib/gendev-common.sh"

gendev_require_tool "pin-provenance.sh" git || exit 3
command -v python3 >/dev/null 2>&1 || { printf 'pin-provenance.sh requires python3\n' >&2; exit 3; }

check_only=0
if [ "${1:-}" = "--check" ]; then
  check_only=1
  shift
fi

if [ "$#" -lt 1 ]; then
  sed -n '3,18p' "$0"
  exit 2
fi

status=0
for artifact in "$@"; do
  if [ ! -f "$artifact" ]; then
    printf 'pin-provenance.sh: no such artifact: %s\n' "$artifact" >&2
    status=2
    continue
  fi
  GENDEV_PIN_CHECK="$check_only" GENDEV_PIN_ROOT="$repo_root" \
  python3 - "$artifact" <<'PYEOF' || status=$?
import os
import re
import subprocess
import sys

artifact = sys.argv[1]
check_only = os.environ["GENDEV_PIN_CHECK"] == "1"
root = os.environ["GENDEV_PIN_ROOT"]

text = open(artifact).read()
pattern = re.compile(r"(- path: (\S+)\n(\s*)revision: )(\S+)")

stale = []
def current_hash(path):
    out = subprocess.run(
        ["git", "-C", root, "log", "-1", "--format=%H", "--", path],
        capture_output=True, text=True, check=True,
    ).stdout.strip()
    return out

def repin(match):
    path, pinned = match.group(2), match.group(4)
    full = os.path.join(root, path)
    if not os.path.exists(full):
        return match.group(0)
    current = current_hash(path)
    if not current:
        return match.group(0)
    if pinned != current:
        stale.append((path, pinned, current))
        if not check_only:
            return match.group(1) + current
    return match.group(0)

new_text = pattern.sub(repin, text)

if check_only:
    for path, pinned, current in stale:
        print(f"{artifact}: stale pin for {path}: {pinned} -> {current}")
    sys.exit(1 if stale else 0)

if stale:
    open(artifact, "w").write(new_text)
    for path, pinned, current in stale:
        print(f"{artifact}: repinned {path}: {pinned} -> {current}")
else:
    print(f"{artifact}: all pins current")
PYEOF
done
exit "$status"
