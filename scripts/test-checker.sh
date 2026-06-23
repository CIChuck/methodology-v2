#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# test-checker.sh — focused regression tests for scripts/check-methodology.sh
#
# SCOPE (read this before assuming coverage):
# This is NOT comprehensive checker coverage. It locks down the specific defects
# that shipped because the checker had never been run against a COMPLETED gate
# document:
#
#   - Placeholder false-positive: completed markdown checkboxes ("[x]") and the
#     empty checkboxes ("[ ]") the templates ship were read as unfilled
#     placeholders, so a correctly-completed Accepted artifact failed the checker.
#   - Approval-record authority: a real approval must be evidenced by the MANIFEST
#     (approvals.current_gate.status / approvals.latest_decision), not by grepping
#     the gate-log, whose shipped template contains an example "decision: approved"
#     block that must never count as a real approval.
#
# The tests build a real project with the real init script and the real templates,
# complete one gate the way a practitioner would (including a COMPLETE success-
# criteria row, so the project is genuinely checker-clean), assert the checker
# passes it clean AND exits 0; then inject genuine defects and assert the checker
# still catches them, including the gate-log-example false-negative a prior fix
# introduced.
#
# Portability: avoids GNU-only "sed -i" (BSD/macOS sed differs) via a temp-file edit
# helper, and uses a portable cp (no cpio) for the sandbox copy.
#
# Usage: scripts/test-checker.sh
# Exit:  0 if all assertions pass, 1 otherwise. Makes no changes outside a temp dir.

set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
checker="$repo_root/scripts/check-methodology.sh"

pass_count=0
fail_count=0
ok() { printf 'PASS: %s\n' "$1"; pass_count=$((pass_count + 1)); }
ko() { printf 'FAIL: %s\n' "$1"; fail_count=$((fail_count + 1)); }

# Portable in-place edit: edit <file> <sed-expr> [<sed-expr> ...]
edit() {
  _f="$1"; shift
  _tmp="$(mktemp)"
  _args=()
  for _e in "$@"; do _args+=(-e "$_e"); done
  sed "${_args[@]}" "$_f" > "$_tmp" && mv "$_tmp" "$_f"
}

workdir="$(mktemp -d)"
check_tmp="$workdir/checker-output.txt"
trap 'rm -rf "$workdir"' EXIT

# Run the checker in a project root. Captures BOTH the combined output (in global
# CHECK_OUT) and the checker's REAL exit status (in global CHECK_RC). We deliberately
# do NOT capture via command substitution: that would run the assignment in a subshell
# and CHECK_RC would never reach the caller. Redirect to a temp file, read $? directly
# in this (the caller's) scope, then load the text.
CHECK_OUT=""
CHECK_RC=0
run_checker() {
  ( cd "$1" && "$checker" ) > "$check_tmp" 2>&1
  CHECK_RC=$?
  CHECK_OUT="$(cat "$check_tmp")"
}

# Isolated tree: copy the WHOLE repo (so all checker preconditions — AGENTS.md,
# README.md, the workflow, docs/examples, etc. — are satisfied), minus version
# control and any pre-existing project, then init a FRESH project. This way the only
# variable under test is the project we build; unrelated "missing file" errors cannot
# mask or fake a result. Portable cp (works on GNU and BSD/macOS); cpio and its
# GNU-only flags are deliberately avoided.
proj="$workdir/repo"
mkdir -p "$proj"
cp -R "$repo_root/." "$proj/" 2>/dev/null || cp -R "$repo_root/" "$proj/"
rm -rf "$proj/.git" "$proj/docs/project"

init_err="$(cd "$proj" && ./scripts/init-project.sh "Checker Selftest" 2>&1 >/dev/null)" || {
  echo "FATAL: init-project.sh failed in the test sandbox"
  printf '%s\n' "$init_err" | sed 's/^/  /'
  exit 1
}

vision="$proj/docs/project/vision/vision.md"
manifest="$proj/docs/project/project.yaml"

# --- Complete the vision as a practitioner would. The init script already scaffolds
#     valid front-matter (project:, Authority:, Derived from: path/revision); we only
#     replace the placeholder VALUES it leaves (Status enum, Owner/Produced by/Agent
#     identity = TBD), mark the checklist boxes ([ ] -> [x]), and fill ONE complete
#     success-criteria row so the project is genuinely checker-clean. We do NOT alter
#     document structure (notably we leave "Derived from:" and its path/revision
#     intact, since the provenance check requires them). ---
edit "$vision" \
  's/^Status: Draft.*$/Status: Accepted/' \
  's/^Owner: TBD$/Owner: Selftest Owner/' \
  's/^Produced by: TBD$/Produced by: product-vision-agent/' \
  's/^Agent identity: TBD$/Agent identity: selftest/' \
  's/\[ \]/[x]/g'

# Fill the empty success-criteria data row. The empty row is six pipe-delimited
# cells; we match it with a literal-pipe BRE (note: in sed BRE an unescaped | is a
# literal pipe) and replace with one complete, measurable criterion.
edit "$vision" \
  's/^|  |  |  |  |  |  |$/| Adoption | active users | 10 | at 30 days | Selftest Owner | usage log |/'

# Record a REAL approval in the manifest (the authority). This is what a correct
# gate transition fills; the gate-log keeps the human-readable history separately.
edit "$manifest" \
  's/^    decision: TBD/    decision: approved/' \
  's/^    decided_by: TBD/    decided_by: Selftest Owner/' \
  's/^    decided_on: TBD/    decided_on: 2026-01-01/'

# ============================================================================
# TEST 1 (placeholder false-positive): completed [x] checklists pass clean.
# ============================================================================
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q 'still has placeholders'; then
  ko "completed [x] checklist incorrectly flagged as placeholder"
  printf '%s\n' "$CHECK_OUT" | grep 'placeholders' | sed 's/^/      /'
else
  ok "completed checklists ([x]) are not treated as placeholders"
fi

# ============================================================================
# TEST 2 (approval authority + genuinely clean): a real manifest approval is
# recognized AND the checker exits 0 with no errors at all. This asserts the REAL
# exit status (CHECK_RC), so an unrelated checker error cannot pass silently.
# ============================================================================
run_checker "$proj"
if [ "$CHECK_RC" -eq 0 ] && ! printf '%s\n' "$CHECK_OUT" | grep -q 'no real approval'; then
  ok "a real manifest approval is recognized and the checker exits clean (RC=0)"
else
  ko "a correctly-completed, manifest-approved project did not pass clean (RC=$CHECK_RC)"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi

# ============================================================================
# TEST 3 (the false-negative a prior fix introduced): an Accepted artifact with NO
# real manifest approval must WARN, even though the shipped gate-log template still
# contains an example "decision: approved" block. Revert ONLY the manifest (leaving
# the gate-log example untouched) to prove the checker keys on the manifest.
# ============================================================================
cp "$manifest" "$manifest.bak"
edit "$manifest" \
  's/^    decision: approved/    decision: TBD/' \
  's/^    decided_by: Selftest Owner/    decided_by: TBD/'
if ! grep -q 'decision: approved' "$proj/docs/project/approvals/gate-log.md"; then
  ko "test setup: expected the gate-log template example to remain present"
fi
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q 'no real approval'; then
  ok "no real manifest approval still warns despite the gate-log template example (false-negative fixed)"
else
  ko "FALSE NEGATIVE: gate-log template example accepted as a real approval"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$manifest.bak" "$manifest"

# ============================================================================
# TEST 4 (negative control): a GENUINE [bracketed] placeholder is still caught.
# ============================================================================
cp "$vision" "$vision.bak"
edit "$vision" 's/^Owner: Selftest Owner/Owner: [fill in the owner name]/'
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q 'still has placeholders'; then
  ok "negative control: a real [bracketed] placeholder is still caught"
else
  ko "negative control: a real placeholder was NOT caught (fix too permissive)"
fi
mv "$vision.bak" "$vision"

# ============================================================================
# TEST 5 (negative control): a TBD in an Accepted doc is still caught.
# ============================================================================
cp "$vision" "$vision.bak"
edit "$vision" 's/^Owner: Selftest Owner/Owner: TBD/'
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q 'still has placeholders'; then
  ok "negative control: a real TBD is still caught"
else
  ko "negative control: a TBD was NOT caught (fix too permissive)"
fi
mv "$vision.bak" "$vision"

printf '\n%d passed, %d failed\n' "$pass_count" "$fail_count"
[ "$fail_count" -eq 0 ]
