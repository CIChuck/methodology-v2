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
# README.md, the workflow, docs/resources/examples, etc. — are satisfied), minus version
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
gate_log="$proj/docs/project/approvals/gate-log.md"
gate_log_base="$workdir/gate-log-template.md"
tactical="$proj/docs/project/build-plan/phases/phase-1-tactical-implementation-plan.md"
traceability="$proj/docs/project/traceability/traceability-matrix.md"
prd="$(find "$proj/docs/project/prd" -maxdepth 1 -type f -name '*.md' | sort | head -n 1)"
architecture="$(find "$proj/docs/project/architecture" -maxdepth 1 -type f -name '*.md' | sort | head -n 1)"

append_strict_gate_transition_event() {
  _log_file="$1"
  _tmp_log="$(mktemp)"
  sed '/^No gate approvals recorded yet\.$/d' "$_log_file" > "$_tmp_log" && mv "$_tmp_log" "$_log_file"

  cat >> "$_log_file" <<'EOF'

### Gate Event: G0 -> G1

```yaml
event_id: EV-20260710-selftest-g0-g1
schema_version: 2
event_type: gate_transition
from_gate: G0
to_gate: G1
decision: approved
decided_by: Selftest Owner
status: approved
checked: "Selftest Owner reviewed gate requirements and accepted the transition."
evidence:
  - artifact_id: vision
    artifact_path: docs/project/vision/vision.md
    category: new_acceptance_status_only
    reviewed_revision: 0000000
    reviewed_blob_oid: 1111111111111111111111111111111111111111
    reviewed_digest: 1111111111111111111111111111111111111111111111111111111111111111
    resulting_blob_oid: 2222222222222222222222222222222222222222
    resulting_digest: 2222222222222222222222222222222222222222222222222222222222222222
    status: Accepted
```

EOF
}

append_phase_exit_event() {
  _log_file="$1"
  _phase_id="$2"

  cat >> "$_log_file" <<EOF

### Phase Transition: G5.${_phase_id}.4

\`\`\`yaml
event_id: EV-20260710-selftest-phase-${_phase_id}
schema_version: 2
event_type: phase_transition
position: G5.${_phase_id}.4
phase_id: "${_phase_id}"
decision: exited
decided_by: Selftest Owner
decided_on: 2026-07-10
exit_test:
  path: docs/project/testing/phase-${_phase_id}-test-uat-plan.md
  revision: 0000000
  result: passed
regression_suite:
  result: green
  phases_covered:
    - "${_phase_id}"
checked: "Selftest Owner accepted the phase exit evidence."
learnings: docs/project/build-plan/phases/phase-${_phase_id}-learnings.md
\`\`\`
EOF
}

write_status_artifact() {
  _path="$1"
  _status="$2"
  mkdir -p "$(dirname "$_path")"
  cat > "$_path" <<EOF
# Selftest Artifact

Status: ${_status}
project: checker-selftest
Date: 2026-07-10
Owner: Selftest Owner

Body: complete selftest evidence.
EOF
}

update_manifest_phase_state() {
  _gate="$1"
  _position="$2"
  _phase_lines="$3"
  _tmp_manifest="$(mktemp)"
  _phase_file="$(mktemp)"
  printf '%s\n' "$_phase_lines" > "$_phase_file"

  awk -v gate="$_gate" -v position="$_position" -v phase_file="$_phase_file" '
    BEGIN {
      while ((getline line < phase_file) > 0) {
        phase[++n] = line
      }
      close(phase_file)
    }
    skipping_phases && /^[^[:space:]]/ {
      skipping_phases = 0
    }
    skipping_phases {
      next
    }
    /^  current_gate:/ && !gate_done {
      print "  current_gate: " gate
      gate_done = 1
      next
    }
    /^  phase_position:/ {
      print "  phase_position: " position
      next
    }
    /^  phases:/ {
      print "  phases:"
      for (i = 1; i <= n; i++) {
        if (phase[i] != "") {
          print phase[i]
        }
      }
      skipping_phases = 1
      next
    }
    { print }
  ' "$manifest" > "$_tmp_manifest" && mv "$_tmp_manifest" "$manifest"
  rm -f "$_phase_file"
}

write_prd_fixture() {
  _criteria="$1"
  cat > "$prd" <<EOF
# Product Requirements Document: Checker Selftest

Status: Accepted
project: checker-selftest
Date: 2026-07-10
Owner: Selftest Owner
Authority: \`docs/methodology/constitution/gendev.md\` - Product Requirements Document
Produced by: prd-agent
Produced on: 2026-07-10
Produced with: human-agent collaboration
Agent identity: selftest
Derived from:
  - path: docs/project/vision/vision.md
    revision: 0000000

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Testability Notes | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| REQ-001 | Produce a report | ${_criteria} | command output is observable | baseline | none |

## Edge Cases

| Case | Expected Behavior | Requirement ID |
| --- | --- | --- |
| Invalid input | Error is reported | REQ-001 |

## G2 Exit Checklist (Requirements Ready)

All required G2 criteria are represented by the table above.
EOF
}

write_architecture_fixture() {
  _spec="$1"
  cat > "$architecture" <<EOF
# Architecture Specification: Checker Selftest

Status: Accepted
project: checker-selftest
Date: 2026-07-10
Owner: Selftest Owner
Authority: \`docs/methodology/constitution/gendev.md\` - Architecture Specification
Produced by: architecture-agent
Produced on: 2026-07-10
Produced with: human-agent collaboration
Agent identity: selftest
Derived from:
  - path: docs/project/prd/prd.md
    revision: 0000000

## Requirement Traceability

| Architecture Rule | PRD Requirement(s) |
| --- | --- |
| ARCH-001 | REQ-001 |

${_spec}
EOF
}

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
  's/^    decided_on: TBD/    decided_on: 2026-01-01/' \
  's/^    required_attester: TBD/    required_attester: Selftest Owner/'

cp "$gate_log" "$gate_log_base"
append_strict_gate_transition_event "$gate_log"

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
# TEST 1B (placeholder false-positive): markdown and ordinary bracket syntax pass.
# ============================================================================
cp "$vision" "$vision.bak"
cat >> "$vision" <<'EOF'

## Markdown Syntax Fixture

This accepted artifact cites [ordinary bracketed note] without making it a template token.
See [linked guide](docs/project/prd/prd.md), ![diagram alt](docs/project/design/diagram.png),
and [reference guide][guide-ref].
The escaped literal \[brackets\] are intentional.
Anti-drift markers [YAGNI] [KISS] [DRY] [SRP] [LA] [NAA] [GOV] [INT] remain valid.

[guide-ref]: docs/project/prd/prd.md
EOF
run_checker "$proj"
if [ "$CHECK_RC" -eq 0 ] && ! printf '%s\n' "$CHECK_OUT" | grep -q 'still has placeholders'; then
  ok "markdown links, images, reference labels, escaped brackets, and rule markers are not placeholders"
else
  ko "markdown/bracket syntax was incorrectly flagged as placeholder content (RC=$CHECK_RC)"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$vision.bak" "$vision"

# ============================================================================
# TEST 2 (strict-mode event + approval authority): a real gate transition event is
# present and the checker exits 0 with no approval-summary warning.
# ============================================================================
run_checker "$proj"
if [ "$CHECK_RC" -eq 0 ] && ! printf '%s\n' "$CHECK_OUT" | grep -q 'no complete durable approval'; then
  ok "a strict-mode transition event is recognized and the checker exits clean (RC=0)"
else
  ko "a correctly-completed, manifest-approved project did not pass clean (RC=$CHECK_RC)"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi

# ============================================================================
# TEST 3 (the false-negative a prior fix introduced): approved summary data should
# never substitute for a complete durable transition event in strict mode.
# ============================================================================
cp "$gate_log" "$gate_log.bak"
cp "$manifest" "$manifest.bak"
edit "$manifest" \
  's/^    decision: approved/    decision: approved/' \
  's/^    decided_by: Selftest Owner/    decided_by: Selftest Owner/'
cp "$gate_log_base" "$gate_log"
if ! grep -q 'decision: approved' "$gate_log"; then
  ko "test setup: expected the gate-log template example to remain present"
fi
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q 'no complete durable approval event'; then
  ok "approved summary without durable transition event still fails"
else
  ko "FALSE NEGATIVE: strict mode accepted template summary without durable evidence"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$manifest.bak" "$manifest"
mv "$gate_log.bak" "$gate_log"

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

# ============================================================================
# TEST 6 (manifest authority): project/approval gate mismatch is blocking.
# ============================================================================
cp "$manifest" "$manifest.bak"
edit "$manifest" 's/^  current_gate: G1/  current_gate: G2/'
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q 'differs from approvals.current_gate.gate' &&
   printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-MANIFEST-APPROVAL-001\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q 'expected="project.current_gate equals approvals.current_gate.gate"'; then
  ok "negative control: manifest project/approval gate mismatch is blocking"
else
  ko "negative control: manifest gate mismatch was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$manifest.bak" "$manifest"

# ============================================================================
# TEST 7 (manifest authority): attested enforcement requires a named attester.
# ============================================================================
cp "$manifest" "$manifest.bak"
edit "$manifest" 's/^    required_attester: Selftest Owner/    required_attester: TBD/'
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q 'attested enforcement is missing required_attester' &&
   printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-MANIFEST-ENFORCEMENT-002\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q 'expected="enforcement.attested.required_attester is a named human"'; then
  ok "negative control: missing attested required_attester is blocking"
else
  ko "negative control: missing required_attester was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$manifest.bak" "$manifest"

# ============================================================================
# TEST 8 (manifest authority): approved-state dates must be valid ISO dates.
# ============================================================================
cp "$manifest" "$manifest.bak"
edit "$manifest" \
  's/^    status: pending/    status: approved/' \
  's/^    approved_by: TBD/    approved_by: Selftest Owner/' \
  's/^    approved_on: TBD/    approved_on: 2026\/07\/10/' \
  's/^      - TBD/      - none/g'
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q 'approved_on is not an ISO date' &&
   printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-MANIFEST-APPROVAL-002\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q 'actual="2026/07/10"'; then
  ok "negative control: invalid approved-state date is blocking"
else
  ko "negative control: invalid approved-state date was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$manifest.bak" "$manifest"

# ============================================================================
# TEST 9 (compatibility): incomplete explicit legacy migration mode is blocked.
# ============================================================================
cp "$manifest" "$manifest.bak"
edit "$manifest" 's/^  methodology_version: 1.0.0/  methodology_version: 0.4.0-verification-first/'
cat >> "$manifest" <<'EOF'

migration:
  mode: explicit_version_bound_migration
  source_methodology_version: 0.4.0-verification-first
  target_methodology_version: 1.0.0
  assessment_digest: sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
  approved_by: TBD
  approved_on: TBD
EOF
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q 'legacy migration mode requires migration.approved_by'; then
  ok "negative control: incomplete explicit legacy migration mode is blocked"
else
  ko "negative control: incomplete legacy migration mode was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$manifest.bak" "$manifest"

# ============================================================================
# TEST 10 (compatibility): complete explicit legacy migration mode can pass.
# ============================================================================
cp "$manifest" "$manifest.bak"
edit "$manifest" 's/^  methodology_version: 1.0.0/  methodology_version: 0.4.0-verification-first/'
cat >> "$manifest" <<'EOF'

migration:
  mode: explicit_version_bound_migration
  source_methodology_version: 0.4.0-verification-first
  target_methodology_version: 1.0.0
  assessment_digest: sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
  approved_by: Selftest Owner
  approved_on: 2026-07-10
EOF
run_checker "$proj"
if [ "$CHECK_RC" -eq 0 ] && ! printf '%s\n' "$CHECK_OUT" | grep -q 'legacy migration mode requires'; then
  ok "complete explicit legacy migration mode can pass with schema-2 events"
else
  ko "complete explicit legacy migration mode did not pass (RC=$CHECK_RC)"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$manifest.bak" "$manifest"

# ============================================================================
# TEST 11 (compatibility): 1.0 strict mode requires schema-2 events.
# ============================================================================
cp "$manifest" "$manifest.bak"
cp "$gate_log" "$gate_log.bak"
edit "$manifest" 's/^  methodology_version: 0.4.0-verification-first/  methodology_version: 1.0.0/'
edit "$gate_log" 's/^schema_version: 2/schema_version: 1/'
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q 'declares methodology_version 1.0.0' &&
   printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-COMPAT-001\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q 'expected="all 1.0 structured events have event_id and schema_version 2"'; then
  ok "negative control: 1.0 strict mode requires schema-2 events"
else
  ko "negative control: 1.0 non-schema-2 event was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$manifest.bak" "$manifest"
mv "$gate_log.bak" "$gate_log"

# ============================================================================
# TEST 12 (tactical tasks): Accepted tactical task declarations and traceability pass.
# ============================================================================
cp "$tactical" "$tactical.bak"
cp "$traceability" "$traceability.bak"
cat > "$tactical" <<'EOF'
# Tactical Implementation Plan: Checker Selftest - Phase 1

Status: Accepted
project: checker-selftest
Date: 2026-07-10
Owner: Selftest Owner
Position: G5.1.2
Authority: `docs/methodology/constitution/gendev.md` - Tactical Implementation Plan
Produced by: phase-planning-agent
Produced on: 2026-07-10
Produced with: human-agent collaboration
Agent identity: selftest
Derived from:
  - path: docs/project/build-plan/phases/phase-1-build-plan.md
    revision: 0000000

## Workstreams

### Workstream PH-1-WS01: Checker path

| Task ID | Workstream | Depends On | Traceability |
| --- | --- | --- | --- |
| PH-1-T001 | PH-1-WS01 | none | REQ-001 |
| PH-1-T002 | PH-1-WS01 | PH-1-T001 | REQ-002 |

## Accuracy Pass

All task IDs use the accepted tactical task grammar.

## Verification Commands

```bash
./scripts/test-checker.sh
```
EOF
cat > "$traceability" <<'EOF'
# Traceability Matrix: Checker Selftest

Status: Active
project: checker-selftest

## Matrix

| Req ID | Requirement | Source | Architecture Rule | Build Item | Tactical Task | Implementation | Test / UAT Evidence | Review Confirmation | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| REQ-001 | First requirement | PRD | ARCH-001 | Build item | PH-1-T001 | source path | test path | review path | planned |  |
| REQ-002 | Second requirement | PRD | ARCH-002 | Build item | PH-1-T002 | source path | test path | review path | implemented |  |
EOF
run_checker "$proj"
if [ "$CHECK_RC" -eq 0 ] && ! printf '%s\n' "$CHECK_OUT" | grep -q 'tactical task ID'; then
  ok "Accepted tactical task declarations and traceability references pass"
else
  ko "valid tactical task declarations or traceability references failed (RC=$CHECK_RC)"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi

# ============================================================================
# TEST 13 (negative control): undeclared tactical dependency is caught.
# ============================================================================
cp "$tactical" "$tactical.valid"
edit "$tactical" 's/PH-1-T001 | REQ-002/PH-1-T999 | REQ-002/'
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q 'references undeclared tactical task ID: PH-1-T999' &&
   printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-TACTICAL-REF-001\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q 'actual="PH-1-T999"'; then
  ok "negative control: undeclared tactical dependency is caught"
else
  ko "negative control: undeclared tactical dependency was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$tactical.valid" "$tactical"

# ============================================================================
# TEST 14 (negative control): traceability cannot cite undeclared task IDs.
# ============================================================================
cp "$traceability" "$traceability.valid"
edit "$traceability" 's/PH-1-T002/PH-1-T999/'
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q 'references tactical task ID not declared in an Accepted tactical plan: PH-1-T999' &&
   printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-TRACE-TASK-001\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q 'actual="PH-1-T999"'; then
  ok "negative control: traceability reference to undeclared tactical task is caught"
else
  ko "negative control: undeclared traceability tactical task was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$traceability.valid" "$traceability"
mv "$tactical.bak" "$tactical"
mv "$traceability.bak" "$traceability"

# ============================================================================
# TEST 15 (negative control): phase checkpoint order requires prior exits.
# ============================================================================
cp "$manifest" "$manifest.bak"
update_manifest_phase_state "G5" "G5.2.1" "    - id: 1
      status: in_progress
    - id: 2
      status: in_progress"
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q 'prior phase 1 has not exited' &&
   printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-PHASE-ORDER-001\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q 'expected="prior phase status exited before later phase checkpoint"'; then
  ok "negative control: phase checkpoint order requires prior phase exit"
else
  ko "negative control: phase checkpoint order violation was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$manifest.bak" "$manifest"

# ============================================================================
# TEST 16 (negative control): G6 cannot be reached before all phases exit.
# ============================================================================
cp "$manifest" "$manifest.bak"
update_manifest_phase_state "G6" "G5.1.3" "    - id: 1
      status: in_progress"
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q 'current_gate is G6 but not every declared phase has exited' &&
   printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-PHASE-EXIT-002\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q 'expected="all declared phases have status exited before G6+"'; then
  ok "negative control: G6 is blocked until all declared phases exit"
else
  ko "negative control: premature G6 was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$manifest.bak" "$manifest"

# ============================================================================
# TEST 17 (phase loop positive): completed phase exit evidence permits G6 state.
# ============================================================================
cp "$manifest" "$manifest.bak"
cp "$gate_log" "$gate_log.bak"
cp "$traceability" "$traceability.bak"
update_manifest_phase_state "G6" "G5.1.4" "    - id: 1
      status: exited"
edit "$manifest" 's/^    gate: G1/    gate: G6/'
append_phase_exit_event "$gate_log" "1"
cat >> "$gate_log" <<'EOF'

### Gate Event: G5 -> G6

```yaml
event_id: EV-20260710-selftest-g5-g6
schema_version: 2
event_type: gate_transition
from_gate: G5
to_gate: G6
decision: approved
decided_by: Selftest Owner
status: approved
checked: "Selftest Owner accepted the whole-build readiness transition."
evidence:
  - artifact_id: phase_plan
    artifact_path: docs/project/build-plan/phase-plan.md
    category: accepted_authority_unchanged
    reviewed_revision: 0000000
    reviewed_blob_oid: 3333333333333333333333333333333333333333
    reviewed_digest: 3333333333333333333333333333333333333333333333333333333333333333
    resulting_blob_oid: 3333333333333333333333333333333333333333
    resulting_digest: 3333333333333333333333333333333333333333333333333333333333333333
    status: Accepted
    originating_event_id: EV-20260710-selftest-g0-g1
verification_evidence:
  - command: ./scripts/test-checker.sh
    result: passed
```
EOF
write_status_artifact "$proj/docs/project/build-plan/phases/phase-1-implementation-evidence.md" "Complete"
write_status_artifact "$proj/docs/project/testing/phase-1-test-uat-plan.md" "Accepted"
write_status_artifact "$proj/docs/project/build-plan/phases/phase-1-code-review.md" "Complete"
write_status_artifact "$proj/docs/project/build-plan/phases/phase-1-remediation.md" "Complete"
write_status_artifact "$proj/docs/project/traceability/traceability-matrix.md" "Complete"
write_status_artifact "$proj/docs/project/as-built/phase-1-as-built-closeout.md" "Complete"
write_status_artifact "$proj/docs/project/build-plan/phases/phase-1-learnings.md" "Accepted"
run_checker "$proj"
if [ "$CHECK_RC" -eq 0 ] && ! printf '%s\n' "$CHECK_OUT" | grep -Eq 'Phase 1 is marked exited|not every declared phase|required phase-exit artifact'; then
  ok "completed phase exit evidence permits G6 state"
else
  ko "valid completed phase exit evidence did not permit G6 state (RC=$CHECK_RC)"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$manifest.bak" "$manifest"
mv "$gate_log.bak" "$gate_log"
mv "$traceability.bak" "$traceability"

# ============================================================================
# TEST 18 (G2 positive): C1 observable criteria plus unwanted behavior pass.
# ============================================================================
cp "$manifest" "$manifest.bak"
cp "$prd" "$prd.bak"
edit "$manifest" 's/^  blast_radius_class: C2/  blast_radius_class: C1/'
write_prd_fixture "User can observe the generated report in the command output. If input is invalid, then the system reports the validation error."
run_checker "$proj"
if [ "$CHECK_RC" -eq 0 ] && ! printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-G2-'; then
  ok "C1 observable acceptance criteria with unwanted behavior pass"
else
  ko "valid C1 observable acceptance criteria failed (RC=$CHECK_RC)"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$manifest.bak" "$manifest"
mv "$prd.bak" "$prd"

# ============================================================================
# TEST 19 (G2 negative): C1 cannot omit concrete observable criteria.
# ============================================================================
cp "$manifest" "$manifest.bak"
cp "$prd" "$prd.bak"
edit "$manifest" 's/^  blast_radius_class: C2/  blast_radius_class: C1/'
write_prd_fixture ""
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-G2-OBSERVABLE-001\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q 'expected="C1 PRD has concrete observable acceptance criteria"'; then
  ok "negative control: C1 PRD without observable acceptance criteria is blocked"
else
  ko "negative control: missing C1 observable criteria was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$manifest.bak" "$manifest"
mv "$prd.bak" "$prd"

# ============================================================================
# TEST 20 (G2 negative): C2/C3 require EARS-form acceptance criteria.
# ============================================================================
cp "$prd" "$prd.bak"
write_prd_fixture "User can observe the generated report in the command output. If input is invalid, then the system reports the validation error."
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-G2-EARS-001\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q 'expected="C2/C3 PRD has concrete EARS-form acceptance criteria"'; then
  ok "negative control: C2/C3 PRD without EARS criteria is blocked"
else
  ko "negative control: missing C2/C3 EARS criteria was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$prd.bak" "$prd"

# ============================================================================
# TEST 21 (G2 negative): all blast-radius classes require unwanted behavior.
# ============================================================================
cp "$prd" "$prd.bak"
write_prd_fixture "When a report is requested, the system shall write the report."
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-G2-UNWANTED-001\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q 'expected="PRD includes all-class unwanted-behavior If/then criteria"'; then
  ok "negative control: PRD without unwanted-behavior criteria is blocked"
else
  ko "negative control: missing unwanted-behavior criteria was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$prd.bak" "$prd"

# ============================================================================
# TEST 22 (G3 negative): verification specification must be human-approved.
# ============================================================================
cp "$architecture" "$architecture.bak"
write_architecture_fixture "## Verification Specification

Requirement: REQ-001
Behavioral: Run the report command and inspect the output.
Design: Confirm ARCH-001 holds under invalid input.
Implementation: Review command contract checks.
UAT: Operator generates one report.
Interrogation: Invalid input is the only expected failure mode.

Approved by: TBD
Approved on: TBD"
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-G3-VERIFICATION-002\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q 'expected="Verification Specification has non-placeholder Approved by and Approved on"'; then
  ok "negative control: G3 verification specification without human approval is blocked"
else
  ko "negative control: missing G3 verification approval was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$architecture.bak" "$architecture"

# ============================================================================
# TEST 23 (G3 negative): verification specification must trace to G2 criteria.
# ============================================================================
cp "$architecture" "$architecture.bak"
write_architecture_fixture "## Verification Specification

Behavioral: Run the report command and inspect the output.
Design: Confirm ARCH-001 holds under invalid input.
Implementation: Review command contract checks.
UAT: Operator generates one report.
Interrogation: Invalid input is the only expected failure mode.

Approved by: Selftest Owner
Approved on: 2026-07-10"
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-G3-TRACE-001\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q 'expected="Verification Specification maps REQ IDs to Behavioral, Design, Implementation, and UAT checks"'; then
  ok "negative control: G3 verification specification without G2 trace is blocked"
else
  ko "negative control: missing G3 verification trace was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$architecture.bak" "$architecture"

# ============================================================================
# TEST 24 (G3 negative): design-verification interrogation must be answered.
# ============================================================================
cp "$architecture" "$architecture.bak"
write_architecture_fixture "## Verification Specification

Requirement: REQ-001
Behavioral: Run the report command and inspect the output.
Design: Confirm ARCH-001 holds under invalid input.
Implementation: Review command contract checks.
UAT: Operator generates one report.

Approved by: Selftest Owner
Approved on: 2026-07-10"
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-G3-INTERROGATION-001\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q 'expected="architecture records design-verification interrogation answers"'; then
  ok "negative control: G3 without design-verification interrogation is blocked"
else
  ko "negative control: missing G3 design interrogation was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$architecture.bak" "$architecture"

# ============================================================================
# TEST 25 (D-012 evidence negative): evidence items require reviewed digest.
# ============================================================================
cp "$gate_log" "$gate_log.bak"
edit "$gate_log" '/^[[:space:]]*reviewed_digest: 1111111111111111111111111111111111111111111111111111111111111111$/d'
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-EVIDENCE-ITEM-001\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q 'expected="reviewed_digest"'; then
  ok "negative control: gate-log evidence item missing reviewed_digest is blocked"
else
  ko "negative control: missing evidence reviewed_digest was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$gate_log.bak" "$gate_log"

# ============================================================================
# TEST 26 (D-012 evidence negative): Complete reports must be byte-identical.
# ============================================================================
cp "$gate_log" "$gate_log.bak"
edit "$gate_log" 's/category: new_acceptance_status_only/category: complete_report_unchanged/'
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-EVIDENCE-ITEM-006\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q 'expected="reviewed/resulting blob OIDs and digests match"'; then
  ok "negative control: complete_report_unchanged evidence with changed blob/digest is blocked"
else
  ko "negative control: changed complete_report_unchanged evidence was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$gate_log.bak" "$gate_log"

# ============================================================================
# TEST 27 (D-012 evidence negative): reused Accepted authority needs origin event.
# ============================================================================
cp "$gate_log" "$gate_log.bak"
edit "$gate_log" \
  's/category: new_acceptance_status_only/category: accepted_authority_unchanged/' \
  's/resulting_blob_oid: 2222222222222222222222222222222222222222/resulting_blob_oid: 1111111111111111111111111111111111111111/' \
  's/resulting_digest: 2222222222222222222222222222222222222222222222222222222222222222/resulting_digest: 1111111111111111111111111111111111111111111111111111111111111111/'
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-EVIDENCE-ITEM-008\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q 'expected="originating_event_id"'; then
  ok "negative control: accepted_authority_unchanged without originating_event_id is blocked"
else
  ko "negative control: missing accepted-authority originating event was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$gate_log.bak" "$gate_log"

# ============================================================================
# TEST 28 (late-gate negative): G8 requires aggregate review/deployment artifacts.
# ============================================================================
cp "$manifest" "$manifest.bak"
cp "$gate_log" "$gate_log.bak"
update_manifest_phase_state "G8" "G5.1.4" "    - id: 1
      status: exited"
edit "$manifest" 's/^    gate: G1/    gate: G8/'
append_phase_exit_event "$gate_log" "1"
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-LATE-GATE-ARTIFACT-001\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q "docs/project/review/code-review.md"; then
  ok "negative control: G8 without aggregate review/deployment artifacts is blocked"
else
  ko "negative control: missing G8 aggregate artifacts were NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$manifest.bak" "$manifest"
mv "$gate_log.bak" "$gate_log"

# ============================================================================
# TEST 29 (deployment negative): Accepted deployment readiness needs approval event.
# ============================================================================
cp "$manifest" "$manifest.bak"
cp "$gate_log" "$gate_log.bak"
cp "$traceability" "$traceability.bak"
update_manifest_phase_state "G8" "G5.1.4" "    - id: 1
      status: exited"
edit "$manifest" 's/^    gate: G1/    gate: G8/'
append_phase_exit_event "$gate_log" "1"
write_status_artifact "$proj/docs/project/build-plan/implementation-summary.md" "Complete"
write_status_artifact "$proj/docs/project/review/code-review.md" "Complete"
write_status_artifact "$proj/docs/project/review/remediation.md" "Complete"
write_status_artifact "$proj/docs/project/testing/final-test-uat-report.md" "Complete"
write_status_artifact "$proj/docs/project/traceability/traceability-matrix.md" "Complete"
write_status_artifact "$proj/docs/project/deployment/deployment-readiness.md" "Accepted"
write_status_artifact "$proj/docs/project/deployment/production-runbook.md" "Complete"
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-G8-DEPLOYMENT-001\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q 'expected="structured deployment_approval event"'; then
  ok "negative control: G8 Accepted deployment readiness without deployment approval is blocked"
else
  ko "negative control: missing G8 deployment approval was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$manifest.bak" "$manifest"
mv "$gate_log.bak" "$gate_log"
mv "$traceability.bak" "$traceability"

# ============================================================================
# TEST 30 (terminal negative): G9 requires terminal state and value disposition.
# ============================================================================
cp "$manifest" "$manifest.bak"
cp "$gate_log" "$gate_log.bak"
cp "$traceability" "$traceability.bak"
update_manifest_phase_state "G9" "G5.1.4" "    - id: 1
      status: exited"
edit "$manifest" 's/^    gate: G1/    gate: G9/'
append_phase_exit_event "$gate_log" "1"
write_status_artifact "$proj/docs/project/build-plan/implementation-summary.md" "Complete"
write_status_artifact "$proj/docs/project/review/code-review.md" "Complete"
write_status_artifact "$proj/docs/project/review/remediation.md" "Complete"
write_status_artifact "$proj/docs/project/testing/final-test-uat-report.md" "Complete"
write_status_artifact "$proj/docs/project/traceability/traceability-matrix.md" "Complete"
write_status_artifact "$proj/docs/project/deployment/deployment-readiness.md" "Ready for Approval"
write_status_artifact "$proj/docs/project/deployment/production-runbook.md" "Complete"
write_status_artifact "$proj/docs/project/deployment/deployment-record.md" "Complete"
write_status_artifact "$proj/docs/project/as-built/value-review.md" "Complete"
write_status_artifact "$proj/docs/project/as-built/as-built-closeout.md" "Complete"
run_checker "$proj"
if printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-G9-TERMINAL-003\]' &&
   printf '%s\n' "$CHECK_OUT" | grep -q '\[GENDEV-G9-VALUE-001\]'; then
  ok "negative control: G9 without terminal closeout event and value disposition is blocked"
else
  ko "negative control: invalid G9 terminal/value state was NOT caught"
  printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
fi
mv "$manifest.bak" "$manifest"
mv "$gate_log.bak" "$gate_log"
mv "$traceability.bak" "$traceability"

printf '\n%d passed, %d failed\n' "$pass_count" "$fail_count"
[ "$fail_count" -eq 0 ]
