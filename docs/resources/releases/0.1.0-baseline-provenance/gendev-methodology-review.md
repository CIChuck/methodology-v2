# GenDev Methodology Review

## Findings and Proposed Amendments from the June 9, 2026 Working Session

Prepared for Chuck Russell, Collective Intelligence Inc.
Source repository: https://github.com/CIChuck/methodology (reviewed at commit `c3c4280`)
Revised June 10, 2026: Finding 3 updated with the enforcement discussion and its resolution; amendments A3.4 through A3.6 added; the enforcement contract drafted as a companion document (`enforcement-contract.md`); open question 6 added.

---

## 1. Purpose and How to Use This Document

This document records the full assessment-and-rebuttal discussion of the GenDev methodology baseline, organized so each thread can be acted on independently. Every finding follows the same shape: the discussion as it actually ran (including where you pushed back and where the pushback won), a disposition stating where the matter landed, and proposed amendments with identifiers, target files, and draft language where useful.

Amendments are numbered (A1.1, A2.1, and so on) so you can accept, reject, or modify them individually. Draft language is offered as a starting point, not a finished artifact. It's written to match the repository's house idiom (fenced text blocks, semicolon lists, imperative voice) rather than my own.

References to the AAF mean the Agentic Architecture Framework: the five-tier maturity model, the five governance non-negotiables (identity, scope limitation, reversibility, audit completeness, cost control), the agent harness as the unit of governance analysis, blast radius assessment, and the meaningful-versus-nominal oversight distinction. References to the Optimism Tax mean the thesis of that essay: organizations pay a recurring tax for assuming technology value materializes on its own, and the remedy is deliberate value measurement (the TVR framework).

---

## 2. The Frame: What GenDev Bets On

Strip away the gates and templates and GenDev rests on one wager: AI agents invert the economics of documentation.

Agile won the last methodology war for a specific reason. Heavyweight documentation was expensive for humans to produce and nearly impossible to keep synchronized with reality. The documents rotted, and teams rationally stopped writing them. GenDev bets that agents make documentation cheap to generate and cheap to reconcile, so the traceability-heavy tradition (V-model, DO-178C, RUP, and GenDev is recognizably in that lineage) becomes viable again. This time the documents aren't bureaucratic exhaust. They're the build authority a non-deterministic implementer actually needs.

The wager is mostly right, and it's the original idea here. But it's only half-inverted. Generation got cheap. Human verification of generated material did not. That asymmetry runs underneath several findings below, and the discussion sharpened it considerably: the question isn't whether humans are a soft spot (they always were), it's whether GenDev spends the scarce resource (qualified human attention) at higher leverage than the alternatives. The conclusion we reached: it does, with specific reinforcements needed.

What's already strong and should not be touched in the patch wave:

- Governance and security as a hard gate (G4) before build authority exists. Correctly tuned for regulated verticals (healthcare, government, financial services) where this is table stakes, not ceremony.
- Rule 6, treating construction prompts as controlled build artifacts. Ahead of common practice.
- Rule 9, making as-built reconciliation the definition of done. Attacks documentation rot at the root.
- The sub-agent rule: output is advisory until accepted into the record. A write-permission model for cognition. This is also a failure-containment-at-handoff control straight out of the AAF's multi-agent governance section, so the two frameworks already converge here.
- The authority precedence chain, with the current user instruction ranked last. Ulysses governance: the human binds their future self against redesigning the system in a chat message. Correct, distinctive, and worth defending when clients push on it.

---

## 3. Findings

### Finding 1: The Human Approval Surface

**Discussion.** The original critique: the methodology defines what an approval record contains but not what reviewing evidence means, and with roughly fourteen required human approval points, the failure mode is approval theater (the gate log fills with timestamps while actual engagement decays to a skim).

Your rebuttal: we trust the humans. The human is the soft spot of any methodology, regardless of era or framework. GenDev's value is drift reduction and context enhancement, and forcing a human to read documentation is far less labor-intensive than forcing a human to write it. The methodology doesn't make the human problem worse.

**Disposition.** Your rebuttal carries the core point. GenDev relocates human attention from authorship (low leverage, high fatigue) to ratification (high leverage, bounded), which is better attention economics, full stop. One caveat survives, and it's narrower than the original critique: AI-generated documents fail differently than human ones. A weak human spec looks weak. The hedging, the gaps, and the awkward seams are visible from across the room. A weak agent spec arrives fluent, confident, and well-formatted, so the surface cues a reviewer unconsciously relies on are gone. Call it fluency masking. Verification per page gets harder even as authorship gets cheaper.

The AAF supplies the standard to write into the methodology: meaningful versus nominal oversight. An approval is meaningful when the approver can explain the artifact, identify its risks, and could credibly stop it. The `risks_accepted` field in the existing approval record is already a forcing function in this direction. The amendments extend that pattern rather than inventing a new one.

**Proposed amendments.**

**A1.1: Add a "Checked" field to the standard approval record.**
Target: `docs/methodology/guides/human-approval-protocol.md` (Standard Approval Record section).
The approver must produce one substantive statement of what was actually verified, not merely assent. Draft addition to the record shape:

```text
Decision:
Approved by:
Date:
Scope approved:
Checked: (one specific thing the approver verified, in their own words)
Known risks accepted:
Conditions:
Next gate:
```

**A1.2: Add a sampling rule.**
Target: `docs/methodology/guides/human-approval-protocol.md`, new section "Evidence Sampling."
Once per phase, before phase close-out approval, the approver selects one traceability row (ideally at random) and re-derives it end to end: requirement to architecture rule to build item to test evidence. The sampled row and the result are recorded in the gate log. The purpose isn't catching every defect. It's changing the incentive structure: an agent that knows any row may be audited behaves differently than one whose attestations are never opened. Draft language:

```text
Once per phase, the phase close-out approver must select at least one
traceability matrix row and verify it end to end against the actual
artifacts and evidence. Record the row, the verification result, and
any discrepancy in docs/project/approvals/gate-log.md. A discrepancy
in a sampled row blocks phase close-out until explained or remediated.
```

**A1.3: Adopt the meaningful-oversight standard by name.**
Target: `docs/methodology/guides/human-approval-protocol.md` (Approval Principles section).
Add a principle: an approval is meaningful only if the approver can explain the artifact, identify its principal risks, and could credibly stop the work. Cite the AAF as the source of the distinction. This gives practitioners (and clients) a test for whether their approvals are real or ceremonial.

---

### Finding 2: Reviewer Independence and the Self-Attestation Loop

**Discussion.** The critique: walk the chain as an adversary and the agent writes the code, writes the tests, updates the traceability matrix, and drafts the code review report. The roles separate concerns but not trust. It can be the same model, even the same context window, attesting to its own conformance at every link. The checker validates structure, not semantics.

Your response: 100% agreement. Reviewers would be sub-agents, each launched with a brand new, fresh context. The methodology does not trust; review, evaluation, and governance roles carry far less of the labor-intensive burden when agents bear them.

**Disposition.** Agreed and resolved in principle. The remaining gap is that the clean context is currently an implementation choice, not a written rule. The methodology should say what you just said, because a future practitioner (or a future agent reading `AGENTS.md`) won't know the intent unless it's authority. Three additions close it.

**Proposed amendments.**

**A2.1: Add an adversarial separation rule to the constitution.**
Target: `docs/methodology/constitution/gendev.md`, either as an addendum to Rule 7 or as a new Rule 11 ("Review Independence"). Draft language:

```text
### Rule 11: Review Must Be Independent of Implementation

Conformance review must be performed in a context that is independent
of the implementation context.

The reviewing agent must receive only:

  the relevant authority documents, at pinned revisions;
  the implementation diff or artifact under review;
  the applicable test and UAT evidence.

The reviewing agent must not receive the implementer's session,
reasoning traces, or conversational history. Where practical, the
reviewing agent should be a different model or model version than
the implementer. Human review of agent attestations should proceed
by sampling, not by reading summaries alone.
```

**A2.2: Add a Context Provenance section to the review report template.**
Target: `docs/methodology/templates/code-review-report-template.md`.
A review is only as independent as its inputs, and recording the inputs makes independence auditable rather than asserted. Draft section:

```text
## Context Provenance

Reviewing agent (model and version):
Inputs provided to the reviewer:
Authority document revisions used:
Implementer session shared with reviewer: must be "No"
```

**A2.3: Codify the fresh-context requirement in the sub-agent protocol.**
Target: `docs/methodology/guides/subagent-coordination-protocol.md`.
State that review, evaluation, and governance sub-agents are always launched with fresh contexts, and that their reports must include context provenance per A2.2. This also names what these sub-agents are in AAF terms: automated governance agents. Worth one sentence acknowledging the recursion the AAF flags (governance agents are themselves governed by the acceptance rule: their output is advisory until accepted).

---

### Finding 3: Technical Enforcement versus Policy Documentation (AAF Collision One)

**Discussion.** You asked directly where GenDev runs afoul of the AAF. The largest collision is at the AAF's foundational principle, adopted from the Cloud Security Alliance: autonomy boundaries must be technically enforced, not merely policy-documented. GenDev's boundaries today are almost entirely prose. The constitution says agents must stop at gates, but nothing technically prevents an agent from writing source files at G2. The checker detects after the fact; it does not prevent. By the AAF's own standard, that's governance at the policy layer where the AAF demands the technical layer.

**Discussion (continued, June 10).** You took up the finding directly, with three points. First, governance is performed by humans: behavior that skips a gate (code generated too early, for instance) is stopped by a human and not put into production, and no enforcement layer changes who governs. Second, the CI wiring is a great idea, and missing CI boundaries, targets, goals, and objectives is in fact one of the key missing elements of the methodology. Third, the methodology deliberately stays platform-agnostic, although git and version control are critical elements of any methodology and really cannot be ignored.

The resolution preserved all three positions. On human governance: enforcement doesn't displace the human governor; it changes where the human's decision is exercised. A human approves G4 once; the pipeline thereafter executes that recorded decision instead of requiring a human to re-notice every violation. That's human as policy author versus human as runtime detector, and the second role spends the scarcest resource in the system (qualified human attention, per Finding 1) on patrol duty rather than judgment. Two further arguments favor prevention over detection even when the human catches everything: premature artifacts anchor (once working code exists, review shifts from "what should we build" to "what's wrong with this code," and the rejected artifact has still shaped the decision space on its way out), and volume (a human can stop one premature implementation; nobody polices thirty parallel agent branches a day, and the economics that justify documentation-as-authority equally break human-only policing).

On platform neutrality: separate the contract from the binding, the way every durable standard does. The methodology defines, normatively and platform-free, what a conforming environment must mechanically prevent and verify. The repository ships one reference binding (shell scripts plus a CI workflow), labeled non-normative and replaceable. Neutrality is preserved at the vendor layer, which is the only layer it was ever protecting.

On version control: the methodology already depends on it without admitting it. Revision pinning (A4.1), staleness (A6.3), as-built reconciliation, and traceability-to-diffs all require immutable revision identifiers and diffable history. Version control as a capability becomes a stated constitutional assumption; git is named as the default implementation with an equivalence escape hatch; hosting platforms and CI vendors remain unconstrained.

The discussion also produced conformance classes: enforced conformance (the contract implemented mechanically) and attested conformance (named humans perform the checks on a cadence and record that they did). This honors your human-governance position and environments without pipeline maturity, while labeling them honestly. It rhymes with the AAF's declared-versus-effective distinction: a human-policed project isn't non-conforming, it's running a weaker enforcement class and knows it.

**Disposition.** Resolved in design; contract drafted (see `enforcement-contract.md`, delivered with this revision, defining requirements EC-1 through EC-10). `check-methodology.sh` exists and works (verified during review: it caught a deleted vision document with a hard failure) and becomes the core of the reference binding. A3.1 and A3.3 below are retained as written but reframed: they are no longer the amendment itself; they are the reference binding of the contract defined in A3.4.

**Proposed amendments.**

**A3.1: Wire the checker into pre-commit and CI.**
Targets: new `.github/workflows/methodology.yml`; new `scripts/install-hooks.sh` (or documentation of the hook in the practitioner guide); `docs/methodology/guides/gate-transition-protocol.md` (reference the mechanical enforcement).
The pre-commit hook blocks commits that modify source paths while `current_gate` in `docs/project/project.yaml` is below G5. CI refuses merges when the checker fails. Sketch of the hook logic:

```text
read current_gate from docs/project/project.yaml;
if the commit modifies paths outside docs/ and scripts/
   and current_gate is one of G0, G1, G2, G3, G4:
   reject the commit with a message naming the gate and the rule;
run scripts/check-methodology.sh;
reject the commit on checker failure.
```

This single change converts the AAF's biggest objection into GenDev's strongest differentiator: a methodology whose gates are mechanically real.

**A3.2: Harden the checker itself.**
Target: `scripts/check-methodology.sh`.
Two defects found during testing: an invalid gate value (`G99`) produced only a warning and exit code 0, and a missing manifest path emitted the same error twice. Amendments: validate `current_gate` and `approvals.current_gate.gate` against the enumerated set G0 through G9 and treat an unknown value as an error, not a warning; deduplicate error output; consider a distinct exit code (or at least distinct wording) for passed-with-warnings versus clean passes.

**A3.3: Require an approval record for gate-advancing changes.**
Target: CI configuration plus `docs/methodology/guides/gate-transition-protocol.md`.
A commit that changes `current_gate` in `project.yaml` must be accompanied (same commit or same merge) by a new entry in `docs/project/approvals/gate-log.md`. The checker can verify this mechanically: gate change without a corresponding log entry is an error. (This is requirement EC-2 of the contract.)

**A3.4: Adopt the enforcement contract as a normative guide.**
Target: new file `docs/methodology/guides/enforcement-contract.md` (full draft delivered with this revision).
Defines requirements EC-1 through EC-10; the version-control capability assumption; the two conformance classes with the per-requirement exception mechanism; failure semantics including the emergency override record (overrides are telemetry, feeding the Finding 7 metrics); the attested-conformance procedure; and the non-normative status of bindings. Reference it from `AGENTS.md`, the README, and the gate-transition protocol.

**A3.5: Declare enforcement class in the control plane.**
Targets: the project.yaml template; `scripts/init-project.sh`.
Add an `enforcement` block: `class` (enforced or attested), `implementation_paths`, `protected_branch`, and `exceptions` (per-requirement, each with a reason). Gate-log entries inherit the class label so every approval is readable in its enforcement context. The checker treats a missing enforcement block as a warning at baseline and as an error once the contract is ratified.

**A3.6: State the enforcement principle and version-control assumption constitutionally.**
Target: `docs/methodology/constitution/gendev.md`, short new section.
Draft language:

```text
## Enforcement

Gate boundaries must be technically enforced where the environment
permits; the enforcement contract defines the minimum. Attested
conformance is the documented fallback where mechanical enforcement
is unavailable, and must be declared in the project control plane.

The methodology assumes a version control system providing immutable
revision identifiers, diffable history, and branch isolation. Git is
the default implementation; any system with equivalent properties
conforms. No hosting platform or CI vendor is assumed.
```

---

### Finding 4: Identity, Provenance, and Audit Completeness (AAF Collision Two)

**Discussion.** The AAF's first non-negotiable is identity and its fourth is audit completeness. GenDev's gate log records the human approver but artifacts carry no agent provenance: which model, which version, produced this document, from which inputs, at which revisions. And Rule 6 says large implementation prompts "should be saved or reproducible." "Should" is doing heavy lifting on the highest-blast-radius action in the entire lifecycle. The AAF's reproducibility requirement would bind the construction directive, the model identity, and the resulting diff together, mandatorily.

**Disposition.** Open. Cheap to fix, and the fix enables two other amendments (revision pinning powers the staleness machinery in Finding 6 and the rework-radius metric in Finding 7), which is why it ranks high in the suggested sequence.

**Proposed amendments.**

**A4.1: Define a standard artifact provenance header.**
Targets: `docs/methodology/constitution/gendev.md` (new subsection under Documentation Artifact Chain); all templates in `docs/methodology/templates/` (add the header block).
Draft header:

```text
Produced by: (agent model and version, or human author)
Date:
Derived from:
  (authority document) @ (git revision or document version)
  (authority document) @ (git revision or document version)
Status: Draft | Ready for Review | Ready for Approval | Accepted | Stale | Superseded
```

Note the `Derived from ... @ revision` line. That single field is the foundation for computable staleness (Finding 6) and falsifiable conformance claims: "conforms to the architecture spec" is ambiguous once the spec is amended in phase three; "conforms to architecture spec @ rev N" is checkable forever.

**A4.2: Promote Rule 6 from "should" to "must."**
Target: `docs/methodology/constitution/gendev.md`, Rule 6.
Replace "Large implementation prompts should be saved or reproducible from the phase documents" with a mandatory triplet:

```text
Every construction directive used for implementation must be preserved
with: the directive text; the identity (model and version) of the
implementing agent; and a reference binding it to the resulting change
(commit hash or diff). An implementation whose directive cannot be
produced is treated as unreviewed.
```

That last sentence gives the rule teeth without inventing new ceremony: the existing review machinery becomes the consequence.

---

### Finding 5: Blast-Radius-Scaled Ceremony and Cost Control (GenDev Lite Is an AAF Application)

**Discussion.** Two threads merged here. First, from the original repository review: the constitution permits scaling down ("small projects may combine artifacts") and gates.md permits combining gates, but nothing operationalizes the permission. A practitioner running lean must decide alone what "preserving required content" means, with no reference point. Second, from the AAF comparison: GenDev applies near-uniform ceremony regardless of blast radius, where the AAF would classify the work and scale governance intensity to match. The synthesis: GenDev Lite isn't a separate profile to be invented. It's blast-radius-indexed ceremony, and the AAF already defines the mechanism. You've written the framework that solves your own scaling problem.

The AAF's fifth non-negotiable (cost control) is also absent from GenDev entirely, which matters more now that we've agreed reviewer sub-agents run in fresh contexts: clean contexts are re-paid contexts, and a methodology that spawns them has a real token surface.

**Disposition.** Open. Design work rather than patch work; the largest of the amendments.

**Proposed amendments.**

**A5.1: Add a blast radius classification to the methodology.**
Targets: `docs/methodology/constitution/gendev.md` (new section); `docs/methodology/guides/gates.md` (mapping table).
Classify projects (or phases) into roughly three blast-radius classes, defined by AAF-style questions: does the system act on the world or only produce artifacts; is its data sensitive or regulated; are its actions reversible; what's the cost of a wrong release. Map each class to ceremony: which gates may be combined, which artifacts may merge, which approvals remain non-negotiable regardless of class (security acceptance, destructive migration, production release). Draft skeleton:

```text
Class C1 (contained): internal tools, reversible outputs, no sensitive
data. G1 through G4 may be combined into a single framing document.
Per-phase artifacts may merge into one build-and-closeout document.
Required human approvals: build-ready, production release.

Class C2 (standard): the default. Full artifact chain; gates may be
combined only with recorded justification.

Class C3 (critical): regulated data, irreversible actions, external
integrations, or agentic runtime behavior. No gate combination.
Mandatory reviewer independence per Rule 11. Mandatory evidence
sampling at every gate, not once per phase.
```

**A5.2: Add a worked lightweight example.**
Target: `docs/resources/examples/` (a small C1-class project alongside the existing SaaS example).
The SaaS example shows the full ceremony. A second example showing a legitimately scaled-down project answers the question every lean practitioner will ask, and inoculates GenDev against the critique that killed RUP: tailoring left entirely to the practitioner.

**A5.3: Add cost control.**
Targets: `docs/methodology/guides/subagent-coordination-protocol.md`; `docs/project-template/project.yaml`.
One paragraph in the protocol: sub-agent delegations carry a budget expectation (tokens, runtime, or spend), and a delegation that exceeds budget surfaces to the lead agent rather than silently continuing. One optional field block in `project.yaml` for phase-level budget tracking. This honors the AAF's fifth non-negotiable without building a billing system.

---

### Finding 6: Mid-Flight Change: Amendment versus Regression

**Discussion.** You named this yourself: mid-flight adjustment of requirements is a critical missing element of the methodology, one you intend to patch, and there are loops (moving from a higher gate back to a lower gate and forward again) that need to be described and reconciled. The supporting critique from the assessment: ranking the live user instruction last in the precedence chain is correct as drift defense, but it makes discovery expensive, and agile's core empirical claim (requirements are discovered through building) was not repealed by LLMs. If every discovery convenes the full approval ceremony, practitioners will route around the documents, which is precisely the failure GenDev exists to prevent. The methodology never states its amendment cost model.

**Disposition.** Agreed as the priority patch. The design discussion produced a workable shape, recorded here in full because it's the closest thing to a specification we have.

The patch becomes tractable by separating two motions the current gate model conflates:

- **Amendment.** A lower-gate artifact changes while the project's current gate holds. The project sits at G6 while the PRD takes a scoped change. This is the common case; most mid-flight discovery needs amendment, not regression.
- **Regression.** The project's current gate formally moves backward. Reserved for the case where the change invalidates the current gate's entry conditions (the architecture is wrong, not merely incomplete; the phase scope no longer describes the work).

Amendments are then classified by blast radius, echoing Finding 5:

- **Editorial.** No semantic change. No re-approval.
- **Additive within scope.** New detail that doesn't move boundaries. Minimal approval record (the existing lightweight form).
- **Structural.** Scope, security behavior, architecture, or acceptance criteria change. Full re-approval of the affected artifact plus reconciliation downstream.

The piece that makes this mechanical rather than judgment-laden is revision pinning (A4.1). If downstream artifacts declare "derived from architecture-spec @ rev N," then an upstream amendment renders downstream documents **stale**: a new status, distinct from superseded, meaning "probably still valid, pending reconciliation." The checker can compute staleness instead of a human remembering it.

The traceability matrix then earns a second job. It stops being merely an audit record and becomes the change-impact engine. Walk the matrix from the amended node and you have the dirty subtree; re-approval scope is the dirty subtree and nothing more. Forward motion resumes the moment the subtree is clean, without replaying the chain. That is the reconciled loop: higher gate to lower artifact to forward again, with the blast radius of the change (not the full ceremony) defining the cost.

**Proposed amendments.**

**A6.1: New guide: amendment and regression protocol.**
Target: new file `docs/methodology/guides/amendment-and-regression-protocol.md`, referenced from `AGENTS.md` and the README. Contents per the shape above: definitions of amendment versus regression; the three amendment classes with their approval weights; regression criteria (current gate entry conditions invalidated, nothing less); the rule that regression requires a gate-log entry recording why.

**A6.2: Add the `stale` status.**
Targets: `docs/methodology/guides/human-approval-protocol.md` (status enumerations); `docs/methodology/guides/gates.md`; templates carrying status fields.
Add `stale` to the artifact status values, defined as: an upstream authority this artifact derives from has changed since the pinned revision; the artifact requires reconciliation review before it can support a gate transition. Stale is not superseded; a stale artifact may be re-validated unchanged.

**A6.3: Teach the checker to compute staleness.**
Target: `scripts/check-methodology.sh`.
Given provenance headers (A4.1), the checker compares each artifact's pinned upstream revisions against current revisions and flags stale artifacts. A stale artifact in the evidence list of a pending gate is an error; elsewhere it's a warning. This is the moment the traceability chain becomes self-auditing.

**A6.4: Add an amendment section to the constitution.**
Target: `docs/methodology/constitution/gendev.md`.
A short constitutional statement so the principle outranks the procedure: documented authority may be amended at any time through the amendment protocol; amendment cost scales with blast radius; an unamended document that no longer reflects intent is a methodology violation by the human, not a license for the agent to infer. That last clause preserves the precedence chain's spirit while making the lawful path cheap enough to use.

---

### Finding 7: The Measurement Layer (The Optimism Tax Applied to GenDev Itself)

**Discussion.** Your question, verbatim in spirit: where could we make measurements here, and is measurement part of the methodology or a meta-methodology step? The context is the Optimism Tax thesis: governance value asserted without measurement is the trap, and ceremony that feels rigorous is not evidence that it pays. GenDev currently asserts that it prevents drift, rework, and undocumented scope, but defines no instrumentation to test the assertion. Without it, GenDev is unfalsifiable, which is exactly the property TVR exists to indict in everyone else's technology adoption.

**Disposition.** Resolved into a three-tier answer. The tiers have different owners, which is why the question felt ambiguous: it's both.

**Tier 1: Process telemetry. Inside the methodology.** The gate log is already an event stream; it just isn't structured as one. Give entries machine-parseable fields and the checker computes the metrics. The governing principle: no new ceremony. Every metric derives from artifacts the constitution already mandates. The documents become authority and telemetry simultaneously, and the checker is the instrument. The metrics:

- **Gate cycle time.** Elapsed time per gate, split by status (drafting, ready for review, ready for approval). Locates process friction.
- **Approval latency.** Time spent waiting on the human approver. This is the direct empirical test of the approval-bottleneck question from Finding 1. If latency is low and sampling (A1.2) finds discrepancies, approvals are too fast; if latency dominates cycle time, the human is the constraint.
- **Amendment frequency by originating gate.** How often authority changes after approval, and which artifact the change originated in. High PRD amendment rates mean G2 is exiting too early.
- **Drift incidents.** Review findings classified as scope drift versus quality versus security. The direct measure of the thing GenDev claims to prevent.
- **Remediation ratio.** Remediation tasks divided by implementation tasks per phase.
- **Escape rate.** Defects surfacing after as-built close-out that G6 review should have caught. The outcome metric that disciplines all the others.
- **Traceability coverage.** Requirements with verified evidence over total requirements.
- **Rework radius.** When an authority document is amended, the size of the dirty subtree (computable once A4.1 and A6.3 exist).

**Tier 2: Value hooks. Inside the methodology, at the artifact level.** G1 already requires success criteria. Tighten the completion standard so the criteria must be measurable, then require a post-deployment value review (natural home: the production operations protocol) to report actuals against them. This is the anti-Optimism-Tax mechanism at project scale: the project that declared what success looks like at G1 must face that declaration after G9. No project gets to retroactively redefine winning.

**Tier 3: Methodology ROI. Meta-methodology. TVR territory.** A single project cannot tell you whether GenDev paid for itself. That requires portfolio comparison, baselines, and counterfactuals, which belong to the organization (or to CI as advisor), not to any one project's documents. The strategic observation, recorded because it has product implications beyond this patch: GenDev-instrumented projects emit exactly the dataset TVR consumes. The methodology is the sensor network; TVR is the analytics layer above it. They aren't two publications. They're a stack. A client running GenDev generates the evidence base for a TVR engagement as a byproduct of normal operation.

**The Goodhart warning, carried into the patch.** Agents will optimize whatever is measured. A reviewer agent judged on findings volume writes noisy reviews; one judged on low findings writes soft ones. So weight outcomes (escape rate) over activity (findings count), and let reviewer independence (Finding 2) do the rest. The Optimism Tax's sibling trap: assuming measurement is honest because it exists. GenDev should be the rare methodology that can lose an argument with its own gate log. That is the point of giving it one.

**Proposed amendments.**

**A7.1: Structure the gate log.**
Targets: `docs/project-template/approvals/gate-log.md`; `docs/methodology/guides/human-approval-protocol.md`.
Define a machine-parseable entry format (YAML front matter per entry, or a fenced YAML block) carrying: gate, status transition, timestamps, approver, evidence paths, amendment class if applicable, and sampled-row results. Human-readable prose may follow each block; the block is the telemetry.

**A7.2: Add a metrics mode to the checker.**
Target: `scripts/check-methodology.sh` (or a sibling `scripts/methodology-metrics.sh`).
Computes the Tier 1 metrics from the structured gate log and the traceability matrix; emits a small report (text or YAML) suitable for inclusion in phase close-out. No persistent metrics database required at baseline; the documents are the database.

**A7.3: Make G1 success criteria measurable.**
Targets: `docs/methodology/templates/vision-template.md`; `docs/methodology/guides/gates.md` (G1 exit criteria).
Change the completion standard from "the team can explain why the work matters and what success looks like" to add: each success criterion names a measure, a target, and when it will be read.

**A7.4: Add a value review to the production operations protocol.**
Target: `docs/methodology/guides/production-operations-protocol.md`.
A post-deployment checkpoint (timed per the G1 criteria) reporting actuals against the G1 success criteria, recorded in the as-built or a small value-review artifact. Three possible outcomes recorded honestly: met, missed, or unmeasurable (with the reason; unmeasurable criteria are a G1 defect to feed back into the template).

**A7.5: State the measurement principle constitutionally.**
Target: `docs/methodology/constitution/gendev.md`, short new section.
Draft language:

```text
## Measurement

The methodology must be able to lose an argument with its own records.

Process telemetry is derived from artifacts this constitution already
requires; measurement must not introduce new ceremony. Outcome
measures take precedence over activity measures. Success criteria
defined at vision time must be measurable and must be revisited after
deployment. Claims about the methodology's value beyond a single
project are out of scope for project documents and belong to
portfolio-level analysis.
```

---

### Finding 8: Open Items Without Resolution

Recorded so they aren't lost; none was argued to conclusion.

**Concurrency and merge semantics.** The sub-agent protocol bounds delegation but says nothing about what happens when parallel sub-agents touch overlapping artifacts. The problem arrives the first time someone runs this with three Claude Code sessions. The AAF's network blast radius and failure-containment-at-handoff concepts are the right inputs to a future protocol section; the advisory-until-accepted rule already gives you the serialization point (acceptance), so the design question is narrower than it looks: define acceptance ordering and conflict detection at the lead agent, not distributed locking.

**Methodology versioning.** `methodology_version: baseline` in `project.yaml` is a placeholder. Once cloned projects exist, the constitution can change out from under them with no record. Recommend semantic versioning of the methodology itself, with initialized projects pinning the version they adopted. This is the portfolio-level cousin of revision pinning (A4.1).

**Guide consolidation.** `gates.md`, `gate-transition-protocol.md`, and `human-approval-protocol.md` overlap and will drift apart as they're edited independently. Worth a deliberate decision: either consolidate, or assign each a single non-overlapping concern and cross-reference.

**Repository hygiene.** Carried from the original review, unchanged: committed `.DS_Store` files (and no gitignore entry for them); `main.py`, `pyproject.toml` ("Add your description here"), and `.python-version` as uv scaffolding cruft in a docs-first repo; no CI (subsumed by A3.1); a README quick-start pointer ("if you read three files, read these").

**Licensing.** Resolved during the session: CC BY 4.0 for the documentation corpus, MIT for the scripts, NC variants rejected because client adoption is by definition commercial use. Deliverables: root `LICENSE` describing the split, `LICENSE-MIT`, `LICENSE-CC-BY-4.0`, plus a License section in the README and a one-line notice in the header of `gendev.md` (the file most likely to travel standalone).

---

## 4. Corrections Record

For honest iteration, the assessment's own errata.

**The ceremony miscount.** The original assessment claimed "ten gates and nine artifacts per phase." Wrong, and you called it. The correct accounting: ten gates per project (G0 through G9), with G0 through G4 occurring once; the recurring per-phase load is the G5 through G9 loop with six artifacts (build plan, tactical implementation plan, construction directive, test/UAT plan, code review report, as-built close-out). The front-loaded authority documents amortize across every subsequent phase. The corrected picture is materially lighter than the original claim: close to what any disciplined team produces anyway, made explicit and machine-checkable.

**The scaling-down overstatement.** The original assessment said nothing operationalizes scaling down. Partially wrong: gates.md permits combining gates and designates G3/G4 as potentially lightweight. The defensible version is narrower (the permission exists but has no worked example or mechanical support), and Finding 5 addresses it.

**The approval-theater framing.** Softened per Finding 1. The human soft spot predates GenDev and the methodology improves the attention economics; the surviving concern is fluency masking, not the existence of human approval points.

---

## 5. Suggested Sequence and Dependencies

Order of attack, with reasons:

1. **A3 (enforcement wiring).** Converts the AAF's largest objection into the methodology's strongest claim, and the components already exist. Smallest effort-to-credibility ratio in the set. (Contract drafted June 10; see A3.4. Remaining effort is ratification, the reference binding, and checker hardening per A3.2.)
2. **A4 (provenance and Rule 6 hardening).** Cheap, and it's load-bearing: revision pinning is a prerequisite for computable staleness (A6.3) and the rework-radius metric (A7).
3. **A6 (amendment and regression protocol).** The patch you named as critical. Depends on A4 for its mechanical half; the procedural half (definitions, classes, regression criteria) can be drafted immediately.
4. **A7 (gate log schema and metrics).** Depends partially on A4 and A6 for two metrics; the schema and the first six metrics need neither.
5. **A2 (reviewer independence).** Codifies what you already intend; mostly writing.
6. **A1 (approval forcing functions).** Small edits to one guide and one record shape.
7. **A5 (blast-radius tiering, Lite example, cost control).** The largest design effort; benefits from everything above being settled first, since the tiering references the amendment classes and the enforcement machinery.

---

## 6. Open Questions

Decisions that are yours, flagged rather than assumed:

1. **Where does the amendment protocol live?** Recommendation: both layers, consistent with the existing pattern. A short constitutional rule states the principle (A6.4); the guide states the procedure (A6.1). But the constitution is yours to amend.
2. **Metrics persistence.** Should the checker compute metrics on demand from the documents (the documents-are-the-database position), or should a `docs/project/metrics/` ledger persist snapshots at each phase close-out? On-demand is purer; snapshots survive document restructuring. Recommendation: on-demand at baseline, snapshot at close-out as a single appended record.
3. **Provenance scope.** Mandatory headers on all artifacts, or only on artifacts cited as gate evidence? Recommendation: all authority and evidence artifacts; optional elsewhere.
4. **AAF vocabulary adoption.** Should GenDev import AAF terms directly (tiers, blast radius, non-negotiables) or define its own classes and cite the AAF as source? Direct import couples the publications into the stack described in Finding 7, Tier 3; independent vocabulary keeps GenDev standalone. This is a positioning decision as much as a technical one.
5. **Version now or after the patch wave?** Cutting a version before the patches gives cloned projects a stable "v1 baseline" to pin; versioning after gives a cleaner first release. Recommendation: tag the current state as a pre-release baseline, land the patch wave, then cut 1.0.
6. **Conformance class policy.** Should attested conformance be available to any project by declaration, or restricted (for example, to projects below an exposure threshold once the A5 tiering exists)? Recommendation: open by declaration at baseline, revisited after tiering lands. Related: should an emergency override require a second human, or is one approver with a recorded reason sufficient? The contract currently requires one approver plus the record; raising that bar is a one-line change to EC failure semantics.

---

*End of review. Amendments A1.1 through A7.5 are independent unless a dependency is noted in Section 5.*
