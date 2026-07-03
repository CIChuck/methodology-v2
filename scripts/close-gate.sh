#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# close-gate.sh
#
# Approver-facing gate closer. Run from the root of a project repo that has been
# initialized (project.yaml and approvals/gate-log.md exist). It closes one gate
# by:
#   1. refusing if the prior gate is not accepted (no out-of-order closes),
#   2. walking the approver through that gate's real exit checklist, item by
#      item, read live from the gate's template so it never drifts,
#   3. refusing to close if any checklist item is not affirmed,
#   4. collecting the approval metadata the gate-log block requires,
#   5. on full affirmation, writing all three records:
#        - the artifact's own front-matter Status -> Accepted,
#        - project.yaml current_gate -> the next gate,
#        - a structured Gate Event block appended to approvals/gate-log.md,
#          including the checklist affirmations.
#
# The script does not decide anything. It records a decision the approver makes,
# and it will not let the ledger run ahead of an actual affirmation.

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/close-gate.sh G1|G2|G3

Run from the project repo root. Closes the named gate after the approver
affirms its exit checklist. Writes the artifact status, the ledger
(project.yaml), and a gate-log approval record.

Only G1, G2, and G3 are supported by this script (the document gates).
USAGE
}

if [ "$#" -ne 1 ]; then usage; exit 2; fi
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

gate="$1"

# --- Gate metadata: artifact, template, next gate, next role/artifact ---
case "$gate" in
  G1)
    artifact="docs/project/vision/vision.md"
    template="docs/methodology/templates/vision-template.md"
    next_gate="G2"; next_role="prd-agent"; next_artifact="docs/project/prd/prd.md"
    prior_gate=""    # G1 has no prior document gate to require
    ;;
  G2)
    artifact="docs/project/prd/prd.md"
    template="docs/methodology/templates/prd-template.md"
    next_gate="G3"; next_role="architecture-agent"; next_artifact="docs/project/architecture/architecture.md"
    prior_gate="G1"
    ;;
  G3)
    artifact="docs/project/architecture/architecture.md"
    template="docs/methodology/templates/architecture-template.md"
    next_gate="G4"; next_role="governance-agent"; next_artifact="docs/project/security-governance/governance-security-spec.md"
    prior_gate="G2"
    ;;
  *)
    echo "close-gate.sh handles the linear document gates G1, G2, and G3 only." >&2
    echo "" >&2
    echo "G4 (governance) and G5 and later (the phase loop) are deliberately not" >&2
    echo "handled here. Those gates are iterative and human-intensive: governance" >&2
    echo "needs judgment this script should not automate, and the G5-G6 phase loop" >&2
    echo "involves per-phase build, testing, integration, and review that cannot be" >&2
    echo "reduced to a single checklist affirmation. They are deferred to a future" >&2
    echo "methodology update and a separate tool (close-phase.sh) by design, not by" >&2
    echo "oversight. Do not extend this script to cover them without that work." >&2
    exit 2
    ;;
esac

ledger="docs/project/project.yaml"
gate_log="docs/project/approvals/gate-log.md"

# --- Preconditions ---
for f in "$ledger" "$gate_log" "$artifact" "$template"; do
  if [ ! -f "$f" ]; then
    echo "Required file missing: $f" >&2
    echo "Run this from an initialized project root (init-project.sh must have run)." >&2
    exit 1
  fi
done

# The artifact must carry a Status: front-matter line, because closing the gate
# sets it to Accepted. If it is absent, the three records cannot be written
# consistently, so abort before touching the ledger or gate log rather than
# advancing them while the artifact status stays unset.
if ! grep -qE '^Status:' "$artifact"; then
  echo "No 'Status:' front-matter line found in $artifact." >&2
  echo "The artifact must be template-conformed (with front-matter) before its gate can close." >&2
  echo "Nothing was written." >&2
  exit 1
fi

current_gate="$(grep -E '^\s*current_gate:' "$ledger" | head -1 | sed -E 's/.*current_gate:\s*//; s/\s*$//')"

# Refuse out-of-order: the ledger must currently sit at the gate being closed.
if [ "$current_gate" != "$gate" ]; then
  echo "Ledger current_gate is '$current_gate', not '$gate'." >&2
  if [ -n "$prior_gate" ]; then
    echo "Close $prior_gate first. Gates close in order; the ledger will not skip ahead." >&2
  else
    echo "The ledger is not positioned at $gate. Nothing to close." >&2
  fi
  exit 1
fi

# --- Extract the real exit-checklist items from the template ---
# Items live as '[ ] text' lines inside the template's exit-checklist code block.
mapfile -t checklist < <(awk '/Exit Checklist/{f=1} f && /^\[ \]/{sub(/^\[ \] /,""); print} f && /^```$/ && seen{exit} f && /^```/{seen=1}' "$template")

if [ "${#checklist[@]}" -eq 0 ]; then
  echo "Could not read the exit checklist from $template." >&2
  exit 1
fi

echo "Closing $gate. Artifact: $artifact"
echo "Approver must affirm each exit-checklist item. Answer y or n."
echo

affirmations=()
for item in "${checklist[@]}"; do
  while true; do
    printf '  [%s] %s (y/n): ' "$gate" "$item"
    read -r ans
    case "$ans" in
      y|Y) affirmations+=("affirmed: $item"); break ;;
      n|N)
        echo
        echo "Not affirmed: \"$item\"" >&2
        echo "$gate cannot close until every exit-checklist item is affirmed." >&2
        echo "Address this item, then re-run close-gate.sh $gate. Nothing was written." >&2
        exit 1
        ;;
      *) echo "  Please answer y or n." ;;
    esac
  done
done

echo
echo "All exit-checklist items affirmed. Collecting approval record."
echo

prompt_val() {
  # prompt_val VARNAME "Prompt text" "default"
  local __var="$1" __prompt="$2" __default="${3:-}"
  local __in
  if [ -n "$__default" ]; then
    printf '%s [%s]: ' "$__prompt" "$__default"
  else
    printf '%s: ' "$__prompt"
  fi
  read -r __in
  [ -z "$__in" ] && __in="$__default"
  printf -v "$__var" '%s' "$__in"
}

today="$(date +%F)"
prompt_val decided_by            "Approver name (decided_by)"          ""
prompt_val blast_radius_class    "Blast-radius class (C1/C2/C3)"       "C2"
prompt_val gate_started_on       "Gate started on (YYYY-MM-DD)"        "$today"
prompt_val ready_for_approval_on "Ready for approval on (YYYY-MM-DD)"  "$today"
prompt_val approval_requested_on "Approval requested on (YYYY-MM-DD)"  "$today"
prompt_val decided_on            "Decided on (YYYY-MM-DD)"             "$today"
prompt_val artifact_revision     "Artifact revision (commit or tag)"   "TBD"
prompt_val checked_stmt          "One substantive statement from you (checked)" ""

if [ -z "$decided_by" ] || [ -z "$checked_stmt" ]; then
  echo "Approver name and the 'checked' statement are required. Nothing was written." >&2
  exit 1
fi

echo
echo "Optional: risks accepted and open questions carried forward."
prompt_val risk_text     "Known risk accepted (blank for none)" ""
risk_rationale=""
if [ -n "$risk_text" ]; then
  prompt_val risk_rationale "  Rationale for accepting that risk" ""
fi
prompt_val oq_text       "Open question carried forward (blank for none)" ""
oq_owner=""
if [ -n "$oq_text" ]; then
  prompt_val oq_owner "  Owner of that open question" ""
fi

# --- Confirm before writing ---
echo
echo "About to close $gate:"
echo "  - set $artifact front-matter Status: Accepted"
echo "  - set $ledger current_gate: $next_gate"
echo "  - append a Gate Event: $gate -> $next_gate record to $gate_log"
printf 'Proceed? (y/n): '
read -r go
case "$go" in y|Y) ;; *) echo "Aborted. Nothing was written."; exit 1 ;; esac

# --- Write 1: artifact front-matter Status -> Accepted ---
# The Status: line is guaranteed present by the precondition check above.
sed -i.bak -E '0,/^Status:.*/s//Status: Accepted/' "$artifact" && rm -f "$artifact.bak"

# --- Write 2: ledger current_gate -> next_gate ---
sed -i.bak -E "0,/^([[:space:]]*current_gate:).*/s//\\1 $next_gate/" "$ledger" && rm -f "$ledger.bak"

# --- Write 3: append the Gate Event block to the gate log ---
{
  echo ""
  echo "## Gate Event: $gate -> $next_gate"
  echo ""
  echo '```yaml'
  echo "event_type: gate_transition"
  echo "from_gate: $gate"
  echo "to_gate: $next_gate"
  echo "decision: approved"
  echo "decided_by: $decided_by"
  echo "gate_started_on: $gate_started_on"
  echo "ready_for_approval_on: $ready_for_approval_on"
  echo "approval_requested_on: $approval_requested_on"
  echo "decided_on: $decided_on"
  echo "enforcement_class: attested"
  echo "blast_radius_class: $blast_radius_class"
  echo "combined_gates: N/A"
  echo "combined_gate_justification: N/A"
  echo "artifact_status: Accepted"
  echo "evidence:"
  echo "  - path: $artifact"
  echo "    revision: $artifact_revision"
  echo "    status: Accepted"
  echo "checked: \"$checked_stmt\""
  echo "exit_checklist_affirmed:"
  for a in "${affirmations[@]}"; do
    echo "  - \"${a#affirmed: }\""
  done
  echo "known_risks_accepted:"
  if [ -n "$risk_text" ]; then
    echo "  - risk: \"$risk_text\""
    echo "    rationale: \"$risk_rationale\""
  else
    echo "  - risk: none"
    echo "    rationale: N/A"
  fi
  echo "open_questions_carried_forward:"
  if [ -n "$oq_text" ]; then
    echo "  - question: \"$oq_text\""
    echo "    owner: \"$oq_owner\""
    echo "    target_gate: $next_gate"
  else
    echo "  - question: none"
    echo "    owner: N/A"
    echo "    target_gate: $next_gate"
  fi
  echo "next_role: $next_role"
  echo "next_artifact: $next_artifact"
  echo "manifest_updated: true"
  echo '```'
} >> "$gate_log"

echo
echo "$gate closed."
echo "  artifact status: Accepted"
echo "  ledger current_gate: $next_gate"
echo "  approval recorded in: $gate_log"
echo
echo "Next: $next_gate ($next_role, $next_artifact)."
