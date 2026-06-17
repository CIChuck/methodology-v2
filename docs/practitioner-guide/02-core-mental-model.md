# 02. Core Mental Model

## The Four Operating Roles

GenDev works best when the practitioner thinks in four roles (sets of responsibilities, not
necessarily four separate people). One person may fill several roles, but the responsibilities
should remain distinct.

## Human Team Member

The human team member owns intent (what the product is meant to achieve) and approval (the human
decision that an artifact, gate, risk, phase, or release may move forward). This includes:

- product goals;
- target users;
- business constraints;
- scope boundaries (what is inside and outside the current effort);
- non-goals (things the team is explicitly choosing not to build now);
- accepted risks (known risks the human permits the project to carry forward);
- production deployment decisions (decisions about releasing to a real operating environment);
- final approval to advance gates (move from one lifecycle checkpoint to the next).

The human does not need to write every artifact (durable project document or record) by hand. The
agent can draft. The human must review, correct, approve, or reject what becomes project authority
(accepted repository state that future humans and agents should trust).

## Lead Agent

The lead agent owns orchestration (coordinating the process, sequencing work, and keeping state
coherent). It reads the current project state, recommends the next methodology-aware step (a next
action that follows GenDev rather than generic coding instinct), drafts artifacts, reconciles
feedback (turns comments and reviews into one coherent proposal), coordinates sub-agents, updates
records, and stops at approval boundaries (points where human approval is required before
continuing).

The lead agent should behave like a disciplined technical facilitator. It may be proactive, but it
must not bypass required approvals.

The lead agent is expected to:

- read `AGENTS.md`;
- read `docs/project/project.yaml`;
- follow `docs/methodology/guides/`;
- use the current active artifact;
- keep `project.yaml` and `gate-log.md` coherent;
- recommend the next step instead of asking vague process questions;
- stop when the current gate requires human approval.

## Sub-Agents

Sub-agents provide bounded advisory input (limited review or analysis that informs the lead agent
but does not control the project). They may review architecture, test coverage, security risk,
product clarity, or implementation conformance (whether the implementation matches accepted
authority). They do not own approval and do not become authority by themselves.

The lead agent should use sub-agents when independent analysis is useful, especially for:

- broad document review;
- security/governance analysis;
- test/UAT coverage analysis (unit, integration, and user acceptance testing coverage);
- code conformance review;
- deployment readiness review.

The lead agent must reconcile sub-agent outputs and surface conflicts to the human.

## Project Documents

Project documents are the durable authority (the stored project record that survives beyond chat).
The active project lives under `docs/project/` after initialization. The manifest (the compact
`project.yaml` state summary), artifact documents, decision records (durable records of important
technical or product decisions), traceability matrix (the map from requirements to tests,
implementation, and evidence), approval log (the history of approval decisions), and as-built
close-out (the final record of what was actually built) are the state that future agents can trust.

The practical rule is:

```text
If it affects scope, architecture, risk, approval, implementation, tests, or production, record it.
```

## The Project Control Plane

`docs/project/project.yaml` is the project control plane (the compact state summary that tells a
future human or agent how to proceed). It does not replace the artifacts, but it names the current
state and points to the records that matter.

The control plane should make these controls visible:

- current gate and approval state;
- collaboration mode;
- blast-radius class, meaning `C1`, `C2`, or `C3` risk/exposure level;
- enforcement class, meaning `attested` human-verified controls or `enforced` mechanical controls;
- active artifact and evidence paths;
- active amendments or regressions;
- measurement and value-review records.

The lead agent should report these fields during orientation. If any field is missing or
contradictory, the next step is to repair state before implementation.

## Authority Versus Conversation

Conversations between human and lead agent are useful for discovery (exploring options, asking questions, and making corrections). However, this is not enough for durable project state (the repository-backed record of current authority).

For example, the human might say:

```text
Yes, approve the vision and move to PRD. The main risk is that integrations may be needed sooner
than we expect, but we accept that for the first phase.
```

The agent should convert that into durable records:

- update the vision artifact status;
- add a gate approval record to `docs/project/approvals/gate-log.md`;
- update `docs/project/project.yaml`;
- identify G2 as the next gate and PRD Agent as the next role.

## Gate Discipline

The methodology is gate-driven (organized around explicit lifecycle checkpoints). Gates do not
exist to slow the team down. They exist to prevent the agent from making hidden decisions.
G0 through G9 are gate labels (short names for the ordered checkpoints).

The normal flow is:

```text
G0 initialized
G1 vision ready
G2 requirements ready
G3 architecture ready
G4 governance ready
G5 build ready
G6 implementation ready for review
G7 acceptance ready
G8 deployment ready
G9 as-built closed
```

The practitioner should expect the agent to say "stop" at certain moments. A stop is not failure.
It is the methodology protecting the project from ambiguity.

Gate discipline can scale by blast radius. `C1` contained work may use GenDev Lite, a lightweight
path where some artifacts are combined while required content remains explicit. `C2` standard work
usually uses the full default chain. `C3` critical work should add review, evidence, and
enforcement discipline rather than compressing gates.

## Methodology Versus Technique

This distinction is foundational, and it is the one novices most often miss. People routinely
confuse a methodology with a technique, and the confusion makes GenDev harder to understand than it
needs to be.

A **methodology** is the governing process: how work earns authority, and how that authority is
gated, reviewed, and kept coherent. It is prescriptive about order and trust. You cannot pass G3
before G2. The architecture must cohere with the PRD. Decisions must be recorded. A methodology
answers one question: *what must be true for this work to be trusted, and in what order?*

A **technique** is how you actually do the thinking at any given point: object-oriented
decomposition, data modeling, event storming, domain-driven design, user-story mapping,
state-machine analysis. A technique answers a different question: *how do I conceive, model, and
reason about this particular problem?* Techniques produce artifacts (a class diagram, an
entity-relationship model, a state chart), but which technique you reach for is your choice, driven
by the problem in front of you and your own training.

The common error is to picture techniques as steps *on* the methodology's path. They are not. They
are orthogonal to it. A useful picture: the methodology is the road and its tollgates; the
technique is the vehicle you choose to drive. A data-driven team and an object-oriented team travel
the same road through the same gates, but they drive entirely different vehicles and arrive with
entirely different artifacts. GenDev gates both identically, because it checks *that you arrived
with valid authority*, not *how you drove*.

### Why GenDev Separates Them

This separation is one of GenDev's defining choices, and it is worth understanding as a value
proposition, not just a definition.

Most methodologies fail by coupling. They bake a technique into the process ("perform
object-oriented analysis at this step and produce these diagrams"), and then they age badly. The
technique goes out of fashion, or does not fit the problem, or a better one appears, and the whole
methodology is now dated because it married a technique that died. The history of software process
is a graveyard of methodologies that could not outlive the technique they assumed.

GenDev stays silent on technique on purpose. Because it governs only authority and gating, the same
methodology serves an object-oriented team, a data-driven team, an event-driven team, and a team
using a technique that has not been invented yet. A technique's artifacts enter through GenDev's
artifact discipline (canonical naming, the Supporting Artifacts mechanism, typed references covered
in later chapters) without the method ever needing to know which technique produced them. The
method outlives any technique because it never depended on one.

This is stated in the constitution as the principle of **Technique Neutrality**, with the maxim:
the method does not specify the technique, but the technique must blend with the method.

For the practitioner, the distinction is also practical: it tells you what is negotiable. How you
model a domain is your call and your expertise. Whether the architecture must cohere with the PRD
before G4 is not your call; that is the method. Knowing which is which keeps you from fighting the
gates and from mistaking your preferred technique for a law. Bring whatever technique serves the
problem, and let the method handle authority.

## Collaboration Modes

The human may choose a collaboration mode (the operating style that tells the agent how much to
lead, pause, advise, or execute):

- `proactive`: the agent leads the process and recommends steps;
- `approval-gated`: the agent pauses for explicit approvals;
- `advisory`: the agent analyzes but does not change artifacts unless asked;
- `execution-focused`: the agent implements an already accepted plan.

Modes change agent behavior. They do not change the constitution (the methodology's controlling
principles), gates, security rules, or approval requirements.

Example:

```text
Lead proactively, but preserve all gate approvals.
```

Expected agent behavior:

- draft current-gate artifacts without waiting for every small instruction;
- ask only material questions;
- propose approval language;
- stop before advancing the gate.

## The Mental Checklist

At any point in a GenDev project, the practitioner should be able to answer:

- What gate are we in?
- What blast-radius class applies?
- What enforcement class applies?
- What artifact is active?
- What document is current authority?
- What questions are blocking?
- What risks require human acceptance?
- Are there active amendments, stale artifacts, or overrides?
- What approval is needed next?
- What evidence or value review is due?
- What role should the agent assume next?
- What file will be updated next?

If those questions cannot be answered, the next step is orientation, not implementation.
