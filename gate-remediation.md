# Gate Numbering Reconciliation

Status: Ready for Execution
Date: 2026-06-11
Authority: `docs/methodology/constitution/gendev.md` — Rule 6 (AI Build Prompts Are Controlled Artifacts)
Target repository: `CIChuck/methodology`
Target baseline: `master` at `a9ab264` (hardened-pre-1-baseline)

## Role

You are acting as a methodology maintenance agent performing an authority-document
reconciliation. This is documentation work on the methodology baseline itself, not product
implementation. The amendment-and-regression protocol's spirit applies: this is an
additive-within-scope correction that conforms the constitution to the operating gate model
already in force everywhere else in the repository.

## Source Authority

Read these before changing anything:

- `docs/methodology/guides/gates.md` — the canonical G0–G9 gate model. This document is
  CORRECT and must not change, except as noted in Implementation Requirements item 5.
- `docs/methodology/constitution/gendev.md` — contains the defective six-gate section.
- `docs/methodology/guides/enforcement-contract.md` — EC-1 through EC-10 reference gate
  values in the G0–G9 form. These thresholds are CORRECT and must not change.
- `docs/project-template/project.yaml` and `scripts/check-methodology.sh` — both already
  validate against G0–G9. These are CORRECT and must not change.

## Problem Statement

The constitution's Process Gates section (currently lines 812–884) defines six gates using
bare ordinal numbering: Gate 1 Vision Ready, Gate 2 Requirements Ready, Gate 3 Architecture
Ready, Gate 4 Build Ready, Gate 5 Implementation Ready For Review, Gate 6 Acceptance Ready.

Every other authority surface uses the ten-gate G0–G9 model: G0 Project Initialized,
G1 Vision Ready, G2 Requirements Ready, G3 Architecture Ready, G4 Governance Ready,
G5 Build Ready, G6 Implementation Ready For Review, G7 Acceptance Ready, G8 Deployment
Ready, G9 As-Built Closed.

The numbers collide where the models diverge. "Gate 5" means Implementation Ready For
Review in the constitution and Build Ready everywhere else. EC-1 freezes implementation
paths "below G5," which is coherent only under the canonical model. The constitution never
references `gates.md` and contains no mapping. An agent that reads the constitution first,
as `AGENTS.md` instructs, inherits the wrong gate model.

## Canonical Mapping

Map by gate NAME and exit-criteria content. Do not map by adding an offset to the number.
The mapping is non-uniform:

| Old (constitution) | Canonical (gates.md) | Note |
| --- | --- | --- |
| Gate 1: Vision Ready | G1 | number coincides |
| Gate 2: Requirements Ready | G2 | number coincides |
| Gate 3: Architecture Ready | G3 | number coincides |
| Gate 4: Build Ready | G5 | collision |
| Gate 5: Implementation Ready For Review | G6 | collision |
| Gate 6: Acceptance Ready | G7 | collision; see warning below |

WARNING on old Gate 6: its exit criteria conflate acceptance (G7) with close-out content
(traceability update and documentation close-out, which belong to G9). When a document's
"Gate 6" checklist contains as-built or traceability close-out items, it maps to G9, not
G7. Classify each occurrence by its content before relabeling it.

## Objective

Make the G0–G9 model the single gate enumeration across the repository, with `gates.md`
declared canonical, and eliminate every residual use of the old bare-ordinal numbering.

## Scope

Pre-audited occurrences of the old numbering. Verify this list, then fix all of it:

1. `docs/methodology/constitution/gendev.md` — Process Gates section (lines 812–884).
2. `docs/methodology/templates/vision-template.md` — "Gate 1 Exit Checklist" → G1.
3. `docs/methodology/templates/prd-template.md` — "Gate 2 Exit Checklist" → G2.
4. `docs/methodology/templates/architecture-template.md` — "Gate 3 Exit Checklist" → G3.
5. `docs/methodology/templates/phase-build-plan-template.md` — "Gate 4 Exit Checklist" → G5.
6. `docs/methodology/templates/tactical-implementation-template.md` — "Gate 4 Exit
   Checklist" → G5.
7. `docs/methodology/templates/code-review-report-template.md` — "Gate 5" references
   (lines 44 and 173) → G6.
8. `docs/methodology/templates/as-built-closeout-template.md` — "Gate 6 Exit Checklist" →
   classify by content per the warning above; expected G9.
9. `docs/examples/minimal-saas-product/phase-1-code-review.md` — "Gate 5 Status" → G6.

Then run your own audit to catch anything this list missed:

```bash
grep -rn 'Gate [0-9]' --include='*.md' AGENTS.md README.md docs/ \
  | grep -v 'docs/methodology/guides/gates.md'
```

Every surviving hit must either use a canonical G-number with its canonical name or be
prose that does not assign a number at all.

## Non-Goals

- Do not change gate definitions, entry criteria, or exit criteria in `gates.md`.
- Do not change EC-1 through EC-10 thresholds or any enforcement semantics.
- Do not change `project.yaml`, the gate-log templates, or `check-methodology.sh` gate
  validation. They are already correct.
- Do not renumber gates in `docs/project/` of any downstream initialized project. This
  change is to the baseline only.
- Do not restructure the constitution beyond the Process Gates section and the precedence
  clause described below.
- Do not "improve" prose you pass through. Numbering reconciliation only.

## Implementation Requirements

1. Rewrite the constitution's Process Gates section to enumerate all ten gates, G0 through
   G9, using the exact names from `gates.md`. For G1, G2, G3, G5, G6, and G7, carry forward
   the constitution's existing exit criteria under the corrected numbers, reconciling any
   wording drift against `gates.md` (where they differ, `gates.md` wording wins). For G0,
   G4, G8, and G9, synchronize exit criteria from `gates.md`.

2. Split old Gate 6's conflated criteria: acceptance items stay under G7; documentation
   close-out and traceability-update items move under G9.

3. Add a precedence clause to the constitution, immediately before the gate enumeration:

   ```text
   The canonical gate enumeration and detailed entry/exit criteria live in
   docs/methodology/guides/gates.md. The enumeration below must remain synchronized
   with that document. In any conflict, gates.md controls.
   ```

4. Update the templates and example file listed in Scope. Section headers take the form
   "G5 Exit Checklist (Build Ready)" — number plus name, so a future renumbering cannot
   silently strand them again.

5. In `gates.md`, add one reciprocal line in the Purpose section noting that the
   constitution's Process Gates section mirrors this enumeration and that this document is
   canonical. This is the sole permitted edit to `gates.md`.

6. Record the change as a decision record using the constitution's Decision Record
   Template, stored at `docs/methodology/design/` or the repository's established decision
   location. The record must state: the collision, the decision to adopt G0–G9 with
   `gates.md` canonical, the mapping table above, and the rejected alternative (renumbering
   `gates.md` back to six gates, rejected because the checker, manifest, enforcement
   contract, gate log, metrics, and practitioner guide all depend on G0–G9).

## Review Requirement

Per Rule 7 and the reviewer-independence standard: conformance review of this change must
be performed in a context independent of the implementation context. The reviewer receives
this build prompt, the diff, and the verification transcript. The reviewer does not receive
the implementing agent's session transcript.

## Verification

All of the following must pass before the work is reported complete:

```bash
# 1. No residual bare-ordinal gate numbering outside gates.md
grep -rn 'Gate [0-9]' --include='*.md' AGENTS.md README.md docs/ \
  | grep -v 'docs/methodology/guides/gates.md' ; test $? -eq 1

# 2. Constitution enumerates all ten canonical gates
for g in G0 G1 G2 G3 G4 G5 G6 G7 G8 G9; do
  grep -q "### ${g}:" docs/methodology/constitution/gendev.md || echo "MISSING ${g}"
done

# 3. Constitution gate names match gates.md gate names exactly
# (extract '### Gn: Name' lines from both files, normalize, diff — must be empty)

# 4. Structural validation still passes
./scripts/check-methodology.sh
bash -n scripts/check-methodology.sh

# 5. Guard still behaves correctly on an initialized test project:
#    init a throwaway project, set enforcement.implementation_paths to src/,
#    stage a file under src/, and confirm methodology-guard.sh --staged FAILS
#    with the EC-1 implementation-path error while current_gate is G1.
```

Verification step 5 confirms the reconciliation changed labels, not behavior.

## Reporting

Report back with:

- the full diff;
- the verification transcript for all five checks;
- the decision record path;
- any "Gate N" occurrence you classified by content rather than by the mapping table, with
  your classification rationale;
- any occurrence you could not classify, left unchanged and flagged for human decision.

Do not merge. Open the change for independent review and human approval per the
human-approval protocol.