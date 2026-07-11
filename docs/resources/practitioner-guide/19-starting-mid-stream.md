# Starting GenDev Mid-Stream

## Why this addendum exists

The standard practitioner guide assumes you start at G0 with nothing and author each gate's
artifact in order. That is not how most engagements begin. A presales effort produces
a vision. A scoping conversation produces something that reads like a PRD. A solution architect
sketches an architecture before the deal even closes. By the time GenDev enters the picture, one
or two or three of the first gates' documents already exist, written for a customer to read, not
to satisfy a template.

This addendum covers that case: the methodology is seated in the repository, agent instructions are
preserved or explicitly integrated, the control plane exists with the ledger at G1, and you already
hold real vision, PRD, or architecture content that predates the method. The question this answers
is narrow and practical. Given what you already have, what is the next gate you must work, and what
does working it require.

The concise 1.0 adoption path is recorded in `docs/resources/releases/1.0.0-adoption.md`. This
appendix expands that path for repositories that already contain product artifacts. It is not a
legacy GenDev migration workflow.

## The one rule underneath every entry point

You enter the methodology at the gate after your last *accepted* artifact, not the gate after
your last *existing* artifact.

This is the load-bearing idea, and it is worth stating plainly because it is easy to get wrong.
An existing document is not an accepted document. A vision written for a sales deck is content,
not a passed gate. Until that content is conformed to its template, reconciled against its
authority, and accepted by the named approver, the ledger stays at the gate that document belongs
to and that gate is unpassed, no matter how good the document is or how much work went into it.

So the presence of three documents does not mean you are entering at G4. It means you have three
gates' worth of content to conform and accept before G4 is even reachable. The documents shorten
the work at each gate, because you are reformatting rather than authoring from a blank page. They
do not skip the gate.

## The two universal first steps

Regardless of what you start with, before any gate work begins, two things must be true. These
are mechanical, deterministic, and non-negotiable, because the rest of the methodology reads from
specific paths and will not find content that sits anywhere else.

### Prerequisite: the control plane exists

For a normal existing-code repository with no prior authority documents, run
`scripts/install-methodology.sh TARGET_REPO`, then run `scripts/init-project.sh "Project Name"` from
inside the target. That is the G0 act, and it creates the ledger you are about to advance.

For a presales or discovery repository that already holds one or more authority documents, run
`scripts/backfill-methodology.sh` from the baseline repository and declare the imported sources, for
example:

```bash
./scripts/backfill-methodology.sh \
  --project-name "Customer Portal" \
  --vision ../customer/vision.md \
  --prd ../customer/prd.md \
  ../customer-repo
```

Backfill seeds the methodology, creates missing `docs/project/` control-plane files and directories,
copies only missing imported authority into canonical paths, preserves existing imported bytes, and
writes `docs/project/backfill-conformance-report.md`. It runs the checker and records the real exit
status in the report. It does not mark imported documents Accepted and it does not infer missing
customer intent.

The order for a mid-stream start is therefore: install or backfill to create the control plane,
confirm the imported documents are in canonical paths, then begin the per-gate conformance cycle.
There is no separate destructive initialization step after backfill.

After install or backfill, run:

```bash
./scripts/gendev-doctor.sh
./scripts/project-state.sh
./scripts/check-methodology.sh
```

The lead agent should report the command results before conforming imported documents or asking for
gate approval.

If the repository already has a `project.yaml` and a gate log, initialization has already
happened; do not run it again, since it will refuse to overwrite an existing project without
approval, and go straight to placing documents and conforming.

### First step: name each document correctly

Each artifact must carry its methodology name: `vision.md`, `prd.md`, `architecture.md`. Whatever
the presales team called the file, a solution overview, a technical approach, a discovery
summary, it is renamed to the name the method expects. The methodology's gates, checker, and
traceability tooling look for these names. A correctly written vision under the wrong filename is,
to the method, not there.

### Second step: place each document in its correct project folder

Each named document goes in its gate's subfolder:

```text
docs/project/vision/vision.md
docs/project/prd/prd.md
docs/project/architecture/architecture.md
```

Once named and placed, the documents are positioned where every later step expects to find them.
Nothing else can proceed until this is done, which is why it comes before all gate work rather
than inside it.

(If the repository was seeded with the backfill script, these two steps are already satisfied and
a conformance report already exists in `docs/project/`. Skip to the per-gate cycle and use the
report to drive each gate's reformatting directive.)

## The per-gate cycle

Every gate you work in a mid-stream start has the same shape. It does not matter whether you are
at G1, G2, or G3. The cycle is identical. What changes is only which document it operates on and
which exit checklist closes it.

For each gate, in order:

1. **Conform.** Reformat the existing document to its template. Preserve the customer-facing
   content. Map what exists into the template's required sections. Where a required section's
   content is present under a different heading, rename and adapt it. Where a required section's
   content does not exist, write it only from what the document and its upstream
   authority already support, or mark it explicitly as "None" or "Open question." Do not invent
   scope to fill a template slot.

2. **Reconcile.** Check the conformed document against its upstream authority. A PRD reconciles
   against the accepted vision and introduces no goal the vision did not establish. An
   architecture reconciles against the accepted PRD and invents no requirement. If reconciliation
   surfaces a genuine gap, that is a finding sent upstream as a named amendment, not a silent fix.

3. **Set front-matter and status.** The document carries its required front-matter (status,
   project slug, date, owner, authority reference, provenance). Its status moves from Draft toward
   Ready for Approval as the conform and reconcile work completes.

4. **Submit for acceptance.** The named human approver reviews the conformed document against its
   exit checklist. This is a real approval, not a formality. The document written for a customer
   was persuasive; the document the approver accepts must be complete and testable.

5. **Accept and stamp the ledger.** On approval, the document's status becomes Accepted and the
   gate ledger advances to record that gate as passed. Stamping the ledger is two writes, not one:
   update `current_gate` in `docs/project/project.yaml` to the new gate, and append a structured
   transition record (for example, `## Gate Event: G1 -> G2`) to
   `docs/project/approvals/gate-log.md`. The `project.yaml` field is the current-state summary an
   agent reads to orient; the gate log is the durable approval history. Both update together on
   every acceptance. Only now is the next gate reachable.

   You do not have to make these writes by hand. `scripts/close-gate.sh G1` performs the whole
   step: it refuses to close if the prior gate is not accepted, walks the approver through that
   gate's real exit checklist item by item, refuses to close unless every item is affirmed,
   collects the approval metadata, and on approval flips the artifact status, advances the ledger,
   and appends the gate-log record with the affirmed checklist items named in it. The script
   records a decision the approver makes; it does not make the decision, and it will not let the
   ledger run ahead of an actual affirmation. Run interactively, it prompts for each answer. It
   also reads from standard input, so a prepared set of answers can be piped in, which makes gate
   closure usable in regression tests and automated pipelines as well as by hand.

You repeat this cycle for each artifact you hold, in gate order, and you stop advancing
when you run out of existing artifacts. That boundary is the important one, and the next section
is about it.

## The agent directives, gate by gate

The per-gate cycle above describes what happens. This section gives the directives that make it
run. Each gate has a pair: a reformat directive handed to the engineering agent (Codex or
equivalent) to conform the document, and a validation directive handed to a separate sub-agent
that checks the result against spec. The two are not the same agent, and that is deliberate.

Three rules govern every pair, at every gate:

The reformatter and the validator are different agents. The validator operates under the
Fresh-Context Review Rule: it receives the conformed document, the template, the gate's exit
checklist, and the upstream authority at pinned revisions, and it does not receive the
reformatter's session, reasoning, or chat history. It checks the artifact, not the story of how
the artifact was made.

The validator is advisory. It never approves the gate. It returns a clean report or a list of
findings. Acceptance is the named human's act, always, and it happens after the validator reports
clean, not instead of it.

The verdict feeds a fix loop with a stop condition. The reformatter conforms, the validator
checks, and if the validator returns findings, the reformatter addresses those specific findings
and the validator re-checks. The loop continues until the validator returns no findings, at which
point the document goes to the human approver. The loop stops early and escalates to the human if
the validator returns the same finding twice after a fix attempt, or if a finding requires a scope
or authority change the reformatter is not allowed to make. Reformatting never invents scope to
satisfy a check; a finding that can only be closed by adding scope is a finding for the human, not
the loop.

### G1: reformat and validate the vision

**Reformat directive (to the engineering agent):**

```text
Conform docs/project/vision/vision.md to docs/methodology/templates/vision-template.md.

Inputs: the existing vision document, the vision template, and (if present)
docs/project/backfill-conformance-report.md.

Preserve the existing customer-facing content. Do not rewrite its substance.

For each required section in the template:
- If the content exists under a different heading, rename and adapt it to the
  template's exact section title. This is a mapping task, not an authoring task.
- If the content does not exist, write it only from what the vision and its
  source material already support. If it does not exist at all, mark it
  "None" or "Open question". Do not invent scope.

Add the required front-matter: Status, project slug, Date, Owner, Authority,
Produced by, Produced on, Derived from. Set Status to "Ready for Review".

Do not introduce goals, users, or outcomes the source vision did not contain.
Return the conformed document only.
```

**Validation directive (to a fresh-context sub-agent):**

```text
You are a conformance validator with fresh context. You did not write this
document and you must not request the writing agent's reasoning or session.

Inputs: docs/project/vision/vision.md (under review), the vision template, and
the G1 Exit Checklist (Vision Ready).

Check and report, do not fix:
1. Front-matter: every required field present and non-placeholder.
2. Sections: every required template section present by its exact title.
3. Content integrity: each section contains real content or an explicit
   "None"/"Open question", not a leftover template prompt.
4. No new scope: the vision introduces no goal, user, or outcome absent from
   the source material.
5. G1 exit checklist: each item satisfiable from the document.

Return either "No findings" or a numbered list of findings, each naming the
section, the specific gap, and what would close it. You are advisory. You do
not approve G1. Report only.
```

The loop: reformatter runs, validator checks, findings go back to the reformatter, repeat until
"No findings", then the human approver reviews against the G1 exit checklist and accepts. On
acceptance, Status becomes Accepted and the ledger advances to G1 passed (update current_gate in project.yaml to G2, append the G1 -> G2 record to the gate log).

### G2: reformat and validate the PRD

**Reformat directive (to the engineering agent):**

```text
Conform docs/project/prd/prd.md to docs/methodology/templates/prd-template.md.

Inputs: the existing PRD, the PRD template, the ACCEPTED vision
(docs/project/vision/vision.md) as upstream authority, and (if present) the
backfill conformance report.

Preserve the existing content. Map it into the template's required sections by
the same rules as G1 (rename-and-adapt where content exists under another
heading; write-from-source or mark explicitly where it does not).

Reconcile against the accepted vision: the PRD may introduce no goal the vision
did not establish. If the source PRD contains a goal absent from the accepted
vision, do not delete it and do not silently keep it. Flag it as a reconciliation
finding for the human, because closing it may require a vision amendment.

Give every functional requirement a stable ID. Add the required front-matter and
set Status to "Ready for Review". Return the conformed document and any
reconciliation findings.
```

**Validation directive (to a fresh-context sub-agent):**

```text
You are a conformance validator with fresh context. You did not write this
document.

Inputs: docs/project/prd/prd.md (under review), the PRD template, the ACCEPTED
vision as upstream authority, and the G2 Exit Checklist (Requirements Ready).

Check and report, do not fix:
1. Front-matter: all required fields present and non-placeholder.
2. Sections: every required template section present by exact title.
3. Requirement IDs: every functional requirement carries a stable, unique ID.
4. Testability: each requirement is stated so a test could confirm or deny it.
5. Upstream reconciliation: the PRD introduces no goal absent from the accepted
   vision. List any that do as findings.
6. G2 exit checklist: each item satisfiable from the document.

Return "No findings" or a numbered findings list, each naming the section, the
gap, and what would close it. Flag any upstream-reconciliation finding as
requiring human decision, not an in-loop fix. You are advisory. Report only.
```

The loop runs as in G1, with one addition: reconciliation findings against the accepted vision
route to the human, not back into the reformatter, because they may require amending an
already-accepted artifact, which the loop is not allowed to do. Human accepts against the G2 exit
checklist; the ledger advances to G2 passed (update current_gate to G3, append the G2 -> G3 record to the gate log).

### G3: reformat and validate the architecture

**Reformat directive (to the engineering agent):**

```text
Conform docs/project/architecture/architecture.md to
docs/methodology/templates/architecture-template.md.

Inputs: the existing architecture, the architecture template, the ACCEPTED PRD
as upstream authority, and (if present) the backfill conformance report.

Preserve the existing content. Map it into the required sections by the standard
rules. This gate is the heaviest: a presales architecture is usually a diagram
and a stack recommendation, and the template requires a closed Domain Model,
Component Ownership with explicit boundaries, Runtime and Data models, State
Lifecycle, Interfaces, Error and Failure Behavior, Security-Sensitive
Boundaries, a Requirement Traceability section, and a Verification Specification
derived from the G2 acceptance criteria. Expect to write the sections a sales
document never had, using only what the accepted PRD and the existing
architecture support.

Treat the Domain Model as a closed list once written: it is the approved set of
entities, fields, relationships, classes, and interfaces. Do not introduce
architecture that invents a requirement the accepted PRD does not contain; flag
any such gap as a reconciliation finding for the human.

Add required front-matter, set Status to "Ready for Review". Return the conformed
document and any reconciliation findings.
```

**Validation directive (to a fresh-context sub-agent):**

```text
You are a conformance validator with fresh context. You did not write this
document.

Inputs: docs/project/architecture/architecture.md (under review), the
architecture template, the ACCEPTED PRD as upstream authority, and the G3 Exit
Checklist (Architecture Ready).

Check and report, do not fix:
1. Front-matter: all required fields present and non-placeholder.
2. Sections: every required template section present by exact title, including
   Domain Model, Component Ownership, Verification Specification, and Requirement
   Traceability.
3. Traceability: architecture rules trace to accepted PRD requirements; the
   Verification Specification traces to the G2 acceptance criteria.
4. Ownership: component boundaries are stated and do not overlap.
5. Stack: the technology stack decision is stated as accepted, not proposed.
6. Upstream reconciliation: the architecture invents no requirement absent from
   the accepted PRD. List any as findings.
7. G3 exit checklist: each item satisfiable from the document.

Return "No findings" or a numbered findings list, each naming the section, the
gap, and what would close it. Flag reconciliation findings as requiring human
decision. You are advisory. You do not approve G3. Report only.
```

The loop runs as before. Because G3 requires human approval and its exit criteria are the
strictest, expect more loop iterations here than at G1 or G2. When the validator returns clean,
the human approver reviews against the full G3 exit checklist, and only the human's acceptance
advances the ledger to G3 passed (update current_gate to G4, append the G3 -> G4 record to the gate log), which is what makes G4 reachable.

## Where backfilling ends and ordinary GenDev resumes

Backfilling is conforming content that already exists. The moment you pass the gate of your last
existing artifact, there is nothing left to conform, and the next gate is authored from scratch
the way the standard practitioner guide describes. At that boundary, this addendum hands off. You
are no longer starting mid-stream; you are simply doing GenDev.

This is why the entry point determines the destination, and why "move into G4" is only sometimes
the answer.

## The three entry scenarios

### Entry A: vision only

You hold a vision. No PRD, no architecture.

Conform and accept the vision through G1 using the per-gate cycle. That is the only backfill work
you have. Your last existing artifact was the vision, so once G1 is accepted, backfilling is
over. Your next gate is G2, and the PRD is authored fresh from the accepted vision, following the
standard practitioner guide. You are not headed for G4 yet; you are headed for ordinary G2
authoring.

### Entry B: vision and PRD

You hold a vision and a PRD. No architecture.

Conform and accept the vision through G1, then conform and accept the PRD through G2, each with
the full per-gate cycle, in order, vision first because the PRD reconciles against the accepted
vision. Your last existing artifact was the PRD, so once G2 is accepted, backfilling is over.
Your next gate is G3, and the architecture is authored fresh from the accepted PRD. Again, not
G4 yet; ordinary G3 authoring.

### Entry C: vision, PRD, and architecture

You hold all three.

Conform and accept the vision through G1, the PRD through G2, and the architecture through G3,
in order, each reconciling against the accepted artifact above it. This is the only entry point
where all three backfill gates get worked and where G3 acceptance is the finish line for
backfilling.

Because G3 requires human approval and its exit criteria are the strictest of the three
(architecture rules trace to requirements, ownership boundaries are clear, the verification
specification is human-approved and traces to the G2 acceptance criteria, and implementation does
not need to invent core structure), expect the architecture conformance to be the heaviest of the
three. A presales architecture is usually a diagram and a stack recommendation. A G3-accepted
architecture is a component-ownership contract with a closed domain model and a verification
specification. Conforming one into the other is real work, not relabeling.

Once G3 is accepted and the ledger records it, backfilling is complete and you move into G4,
Governance Ready, where the security, policy, identity, audit, and agent-behavior specification
is authored. This is the first new authoring work in Entry C, and it is where the
mid-stream start finally rejoins the standard methodology.

## The G3-to-G4 transition, specifically

Entry C is the only scenario that reaches G4 through backfilling, so the transition deserves an
explicit note. Moving into G4 is not automatic on finishing the architecture document. It
requires that G3's exit criteria are met and its human approval is recorded. Concretely, before
the ledger advances to G4:

- the architecture traces to the accepted PRD's requirements;
- component ownership boundaries do not overlap;
- the technology stack decision is accepted, not merely proposed;
- the verification specification is human-approved and traces to the G2 acceptance criteria;
- the design-verification interrogation (failure modes, scale, evolution, proportional to blast
  radius) is answered;
- no upstream authority the architecture depends on is marked Stale or Superseded.

When those hold and the approver accepts G3, the ledger moves to G4 and governance authoring
begins. If any of them do not hold, the correct action is to stay at G3 and finish the
conformance, not to advance the ledger and backfill the gap later. A ledger that runs ahead of
reality is the precise failure the method exists to prevent.

## Summary

The mid-stream start is not a special mode of the methodology. It is the ordinary methodology with
the first one to three gates' authoring replaced by conformance. Name the documents, place them,
then run each existing artifact through the same conform, reconcile, accept, and stamp cycle in
gate order. Stop backfilling when you run out of existing artifacts; author the rest normally. And
remember the one rule that governs all of it: you are only as far along as your last accepted
artifact, never as far as your last existing one.
