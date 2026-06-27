# Research Note: Starting GenDev at a Gate Above G0 (Project Adoption)

Status: Parked — revisit after the Verification-First amendment lands
Date: 2026-06-20
Author: Collective Intelligence Inc.

## The idea

GenDev today assumes greenfield: G0 init, then build authority gate by gate. But
most real projects arrive with documents already in hand — a vision, a PRD with
supporting material, an architecture draft — produced before GenDev was involved.
Those projects have no clean entry path. Adoption fills that gap: a way to start
GenDev at a gate above G0 by bringing existing documents in as already-satisfied
gates, leaving the project at its real current gate to continue natively.

This is the document half of "onboarding existing work." The code half
(reverse-engineering an existing system into artifacts, per
docs/resources/research/existing-codebase.md) is explicitly out of scope here and revisited
later.

## Settled decisions

This is NOT a methodology change. It is a script plus a practitioner-guide section.
The constitution, gates, and scaffold are untouched.

1. Attestation by invocation. A human running the adoption script IS the
   attestation. The script does not forge approvals; the human's act of running it,
   declaring the docs are in place and the gates closed, is the attestation. This
   is why no methodology change is needed — the gate log already records human
   attestations; adoption writes a particular kind of entry.

2. Honest provenance in the gate log. Adoption entries are distinguishable from
   native production: "G2 closed by adoption: imported PRD reviewed and attested by
   [human] on [date]," not conflated with "produced through GenDev." A regulator or
   future maintainer must be able to see how authority was established. Same honesty
   principle that keeps dated historical records unrewritten.

3. The practitioner closes the current gate. The script stamps the gates the human
   declares complete. Whatever gate the project is actually mid-stream on (e.g. an
   architecture draft) is just the current open gate, closed natively the normal
   way. No special partial-satisfaction or draft-state machinery needed.

4. Legacy code is out of scope. Document adoption only. Reverse-engineering code
   into artifacts is a separate, harder problem, parked.

5. Gate selection by arguments. Non-interactive, argument-driven, like
   init-project.sh. Pattern: a per-document flag plus a close-through gate, e.g.
   adopt-project.sh "Project Name" --vision ./old-vision.md --prd ./old-prd.md
   --close-through G2. The in-progress artifact (architecture draft) is left as the
   open gate.

6. Place-and-flag, not auto-reformat. The script places files at canonical paths
   and scaffolds the manifest and gate log — deterministic work a shell script can
   do. It does NOT restructure prose into template form; that is judgment work
   (which content maps to which template section, are the acceptance criteria
   testable) that a script cannot do reliably. Reformatting is done by the human or
   an agent the human directs, taught in the practitioner guide. This draws the line
   exactly where the tooling's reliability ends — the same deterministic-vs-judgment
   split as the verification chain.

## Two tracks (both downstream of Verification-First)

Track A — the adopt-project.sh script. A tool build. Non-interactive,
argument-driven. Places existing docs at canonical paths, writes manifest and
gate-log entries closing the declared gates as adoption-attested with honest
provenance, leaves the project at its real current gate. Place-and-flag: does not
reformat content. Cousin of init-project.sh.

Track B — practitioner-guide section: "Starting GenDev at a Gate Above G0." Teaches:
when and why to adopt rather than init; how to run the script; how to reformat
existing documents into GenDev template form (the judgment part — mapping content
onto canonical sections, identifying gaps against gate exit criteria, resolving or
recording them before attesting); and what "closed by adoption" means for
practitioner accountability.

## Why this is downstream of Verification-First (not just bandwidth)

Verification-First changes the gate exit criteria: G2 will require EARS-formed
acceptance criteria, G3 will require the human-approved test-specification section.
The adoption guide's "reformat to meet gate standards" content must teach meeting
THOSE criteria. Writing adoption guidance before verification lands would target
gate criteria that are about to change. So adoption genuinely depends on the final
gate definitions, not only on available attention.

## Intersection to reconcile later

Track B intersects existing practitioner-guide `refinement:` markers in chapter 04
(the legacy/branch marker around line 18 mentioned "pre-init gates" and
reverse-engineering). Document adoption is the document half of what that marker
gestures at; legacy-code is the parked half. When the big practitioner-guide edit
pass happens, the "starting above G0" section and that refinement marker want
reconciling so they are not written as two disconnected things.

## Next step

Revisit for implementation after the Verification-First unit of work is complete
(record reviewed, one-vs-two decided, amendment planned, executed, merged,
ratified).
