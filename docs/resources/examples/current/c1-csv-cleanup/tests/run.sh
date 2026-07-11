#!/usr/bin/env bash
set -eu
example_dir="$(cd "$(dirname "$0")/.." && pwd)"
out="${TMPDIR:-/tmp}/gendev-c1-csv-cleanup-output.$$"
trap 'rm -f "$out" "$out.err"' EXIT
python3 "$example_dir/src/csv_cleanup.py" "$example_dir/fixtures/input.csv" "$out"
cmp -s "$example_dir/fixtures/expected.csv" "$out"
if python3 "$example_dir/src/csv_cleanup.py" "$example_dir/fixtures/missing.csv" "$out" 2>"$out.err"; then
  echo "missing input unexpectedly succeeded" >&2
  exit 1
fi
grep -q 'input file not found' "$out.err"
if python3 "$example_dir/src/csv_cleanup.py" "$example_dir/fixtures/input.csv" "$example_dir/fixtures/input.csv" 2>"$out.err"; then
  echo "same input/output unexpectedly succeeded" >&2
  exit 1
fi
grep -q 'input and output paths must differ' "$out.err"
