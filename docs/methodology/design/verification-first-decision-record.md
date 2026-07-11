# Decision Record: Verification-First Amendment

Status: Accepted
Date: 2026-06-20
Author: Collective Intelligence Inc.
Amendment: verification-first

## Context

GenDev holds a shift-left commitment to testing, but it holds it implicitly. The
commitment is distributed across the Core Principle, Rule 3, and the G2
requirements gate, and it is partially enforced through the phase loop's exit
tests. It is never named as a first-order principle. It does not distinguish the
categorically different kinds of verification a project owes. And it does not say
how a human-approved document becomes something an AI-generated implementation can
be reliably tested against.

That last gap is the sharpest. GenDev's premise is AI-generated code under gated
human authority. But human authority attaches to prose, and prose cannot test
code. Language models are, by training, masters at passing tests; green tests on
AI-generated code are exactly the false comfort the method exists to prevent. If
an AI judge grades AI-generated code against its own reinterpretation of the same
prose a human approved, nothing has actually been verified. Something must carry
human-verified intent across the gap into a machine-checkable form.

This record names the verification commitment, elevates it to a first-order
principle, differentiates the kinds of verification, and defines the chain by
which approved documents become reliably testable: EARS-formed acceptance criteria
at G2, a human-approved test specification at G3, and a build loop that grades
generated code against that approved specification rather than against prose.

### What already exists

- The Core Principle lists "what tests prove it works?" among the questions that
  must be answered before code generation.
- Rule 3 (Tests Are Design Artifacts) requires tests planned before or during
  architecture, lists test types, and requires the absence of tests to be
  justified.
- G2 requires acceptance criteria on every requirement and makes untestable
  criteria a failure condition.
- The phase loop gates a phase exit ("built, tested, learnings written") and keeps
  an accumulating regression suite green.
- The supporting-artifact mechanism (Rules 12 and 13) and the `tested-by`
  relationship type already exist, providing a typed-reference path for
  verification evidence to attach to canonical artifacts.
- The cold-judge review pattern (an independent AI judge with no authoring
  context) is established practice for gate and amendment review.

### The gaps

Gap 1 — Not named or elevated. Four principles are named (Core, Blast-Radius
Scaling, Enforcement, Measurement) plus one first-order principle (Technique
Neutrality). Verification is not among them. Security was elevated as "first-class"
(Rule 4); testing was framed as a categorization (Rule 3). Peers in substance, not
in standing.

Gap 2 — The kinds of verification are undifferentiated. Rule 3 presents a flat list
of test types as if they answer one question at one time. A project owes three
categorically different kinds of verification, and they shift left to different
gates.

Gap 3 — No reliable bridge from approved prose to testable code. Acceptance
criteria exist at G2 but in free prose, which is ambiguous and not mechanically
convertible to a test. There is no point at which a human approves the tests as a
faithful encoding of intent, separately from approving the code. Without that, an
AI judge grades against interpretation, not against certified intent.

## Principle

Verification-First (proposed first-order principle): a project must define how it
will know the work is correct before it builds the work, and a human must approve
that definition of correctness in a form precise enough to test. Verification is a
design input, not a downstream check.

Verification answers three distinct, exhaustive questions. There is nothing to
verify outside the requirement, the design, and the code.

- Behavioral verification — does the implementation do what is required, including
  the negative and edge cases, not only the happy path? User-acceptance testing
  (UAT) is the user-facing slice of this question.
- Design verification — does the design hold under the conditions it must survive
  (partition, network loss, security boundary, degradation, scale, evolution)? It
  can be evaluated the moment the design is written, before any code exists.
- Implementation verification — is the code sound as an artifact and durable under
  change (correct types and contracts, no brittle assumptions that erode over
  time)?

What unifies them: each asks whether the work is correct under conditions the happy
path does not reveal — the requirement's edges, the design's failure modes, and
time.

Relationship to technique. Verification-First is a methodological commitment, not a
technique. The method requires the verification and gates it; it does not prescribe
how the verification is produced. Test-driven, behavior-driven,
acceptance-test-driven, property-based, and classic test-after development are
techniques; the method stays neutral under Technique Neutrality. The philosophy is
methodology; the practice is technique. The maxim: define how you will know it
works before you make it work.

## Verification changes character across the gates

Verification is not uniform. It begins observational, becomes intellectual, then
becomes empirical. Each gate carries the verification character native to it, in
that gate's own existing deliverable.

```text
Gate            What is verified            Character            Form
G1 Vision       scope and traceability      observational        does it map back; in or out of scope
G2 PRD          behavioral; UAT design       declarative          EARS acceptance criteria; a UAT scenario per feature
G3 Architecture design under stress;         intellectual;        failure-mode interrogation; the human-approved
                the test specification        keystone             test specification derived from G2 criteria
G5.x Phase      behavioral; implementation;  empirical            code graded against the approved test spec;
                design re-checked                                 phase held up against the G3 architecture (mirror)
Phase-exit UAT  user acceptance              subjective, scaffolded  scenarios plus checklist plus hints
```

## The verification chain: approved documents to reliably testable code

This is the mechanism that gives the principle teeth. It moves human-verified
intent across the prose-to-code gap without letting an AI judge grade against its
own interpretation.

Step 1 — Capture intent testably at G2 (EARS). Acceptance criteria are expressed in
EARS notation (Easy Approach to Requirements Syntax): five sentence templates that
remove the ambiguity free prose hides.

```text
Ubiquitous:  The system shall <response>.
Event:       When <trigger>, the system shall <response>.
State:       While <state>, the system shall <response>.
Unwanted:    If <condition>, then the system shall <response>.
Optional:    Where <feature>, the system shall <response>.
```

EARS does three things. It makes each requirement structurally already a test
("When X, the system shall Y" is "trigger X, assert Y"). It forces the
unwanted-behavior (error-path) cases into the open as a named, first-class shape,
so their absence is visible. And it makes G2 conformance mechanically checkable by
an AI judge ("is every requirement in one of the five forms, with a trigger and a
shall, and are the error paths covered?") — a structural question with right
answers, which is where AI judging is reliable. EARS disciplines form, not
correctness: a requirement can be EARS-formed and still wrong. Human approval still
certifies rightness; EARS ensures the human approves something precise enough to be
worth approving and to convert to a test without reinterpretation.

Step 2 — Encode intent as an approved test specification at G3 (the keystone).
A human-approved test specification is a required section of the G3 architecture
deliverable. It is derived from the G2 EARS criteria and, because those criteria
are already test-shaped, each test assertion traces directly back to a same-shaped
requirement, so the specification is checkable by inspection rather than
interpretation. The human approves this specification as a faithful encoding of
intent, separately from and before approving any code. This separation is the move
that breaks the self-grading trap: the AI judge later grades against tests a human
certified as faithful to approved intent, not against tests the model invented and
not against prose the model reinterpreted.

Step 3 — Grade generated code against the approved specification at G5.x to G6.
Code is generated to satisfy the approved test specification for the phase. The
loop is synthesis to check to repair: the AI generates code, the deterministic test
run rejects what fails, the AI repairs, round and round until green. The
deterministic, human-approved test specification is the checker that has the final
word — the same role a model checker plays for formal specs. The AI judge does not
adjudicate whether tests pass (that is deterministic); it does the work tests
cannot: design verification (does the phase still conform to the G3 architecture —
the mirror check) and implementation verification (edge cases the tests miss,
assumptions that will erode). Division of labor: deterministic tests do behavioral
verification; the AI judge does design and implementation verification; the human
holds authority at the points where authority is cheap to give and hard to fake —
approving the EARS criteria and approving the test specification as faithful.

```text
Gate     Verification act                          Adjudicator        Why reliable
G1-G4    coherence, traceability, EARS conformance  AI judge           checks form, not truth
G2       intent captured as EARS criteria           human approves     authority on precise statements
G3       criteria encoded as test specification     human approves     faithful-encoding gate; breaks self-grading
G5.x     code satisfies the test specification      deterministic run  no judgment needed
G5.x/G6  code beyond the tests; design conformance  AI judge           judgment where tests are blind
```

## Decision

Adopt Verification-First as a first-order principle and express it through the
existing gate deliverables and the verification chain.

### Consequences

Consequence 1 — Name and elevate the principle.
Add Verification-First to the constitution as a first-order principle, defined
around the three verification questions. Reframe Rule 3 as a consequence of the
principle and align its standing with Rule 4. Name the three questions; do not
enumerate exhaustive per-question test-type catalogs in the constitution (that is
technique and guidance).

Consequence 2 — Require EARS acceptance criteria at G2.
Acceptance criteria, already required at G2, must be expressed in EARS notation.
This specifies the form of an existing requirement rather than adding a new one.
The G2 exit criteria gain a checkable condition: every requirement is in an EARS
form with a testable response, and unwanted-behavior cases are present for the
error paths. EARS is the cheapest rung of the verification ladder and the input
that makes every downstream verification step reliable rather than interpretive.

Consequence 3 — Require a human-approved test specification at G3 (the keystone).
The G3 architecture deliverable gains a required section: a test specification
derived from the G2 EARS criteria, approved by a human as a faithful encoding of
intent, separately from approving code. This is the artifact that carries
human-verified intent into a machine-checkable form. It is a section of the
architecture deliverable, not a free-standing artifact, so it cannot be deferred
and is gated by the existing G3 machinery.

Consequence 4 — Distribute the remaining verification criteria into the gate
templates.
Beyond EARS (G2) and the test specification (G3), each gate's template carries its
native verification character: the G3 failure-mode/scale/evolution interrogation
(design verification); the phase build plan's architecture mirror check and phase
exit criteria traced to PRD and vision; the phase-exit/value-review scaffolded UAT
(scenarios, checklist, hints). Verification intent and criteria live in the
templates; verification evidence and results attach as supporting artifacts through
the existing `tested-by` typed reference, produced when the work is done.

Consequence 5 — Scale verification by blast radius, and keep the common case light.
Verification scales with blast radius like all GenDev ceremony. A C1 project records
a few lines, including honest compact negatives ("no failure modes beyond
single-process operation"). A C3 project expands to a full interrogation, where the
weight is earned. The C2 standard case is the adoption risk: its verification
sections must read as a few pointed prompts answered inline, not a testing
appendix. If the C2 shape cannot be made lightweight, that is a signal the design
is wrong, not a signal to push it through.

### Enforcement

- EARS conformance at G2, the test-specification section at G3, and the per-gate
  verification sections are checkable by the existing gate machinery and the
  methodology checker (presence, form, acceptance) and by gate exit criteria
  (traceability of verification to the requirements and design it protects).
- Verification evidence rides the existing supporting-artifact checks and, in time,
  the planned coherence linter.
- Verification-First does not introduce mechanical test execution into the method.
  It gates the existence and acceptance of verification criteria and the approved
  test specification, consistent with the Enforcement Principle's attested-by-
  default stance.

## Scope and sequencing

Proposed as one amendment, executed through the phase loop with an independent cold
judge.

- Phase 1 — constitution: name and elevate Verification-First around the three
  questions (Consequence 1); reframe Rule 3.
- Phase 2 — gates and templates: EARS at G2 (Consequence 2); the human-approved
  test-specification section at G3 (Consequence 3); the remaining distributed
  verification criteria (Consequence 4); blast-radius scaling with the C2-light
  constraint (Consequence 5).
- Phase 3 — checker and sweep: validate EARS conformance checking, the G3
  test-specification section, the new exit criteria, and the `tested-by` evidence
  path; sweep docs and the practitioner guide for coherence.

One-amendment versus two: this record is drafted as one amendment because the chain
(EARS to approved test spec to judged loop) is what gives the principle its
mechanism; naming the principle without the chain would leave it aspirational. If,
on review, the scope proves too large to execute cleanly in one pass, the natural
split is Phase 1 as a "name the principle" amendment and Phases 2 to 3 as a
follow-on "verification chain" amendment. The decision is deferred to after review
of this record, when the full scope is visible on the page.

## Explicitly out of scope (noted, deferred)

- Formal methods and the rigor ladder (Design-by-Contract, property-based testing,
  model checking with TLA+/TLC, Alloy, proof assistants). The research in
  docs/resources/research/ argues that at high blast radius a proof and a test are different
  classes of guarantee, and that verification class — not only volume — should
  scale with blast radius. This is a substantial, separate exploration, best
  pursued as a blast-radius-dependent rigor addendum to GenDev after this base
  amendment lands. This record acknowledges it exists and that Consequence 5's
  blast-radius scaling is the natural attachment point, but does not gate formal
  methods here. TLA+ in particular fits G3 design verification for distributed and
  temporal-state components; it is not a general tool and not part of this
  amendment.
- The practitioner-guide testing chapter (teaching TDD, EARS, and UAT-driven
  practice as technique) is separate downstream work. This amendment makes the
  methodology correct and gated; the guide teaches the practice afterward.

## Open questions (for the amendment plan, not this record)

- Exact placement and wording of each template's verification prompts, tuned so the
  C2 case stays light.
- Whether the G3 failure-mode interrogation is a named subsection or an inline
  prompt block (leaning inline, to avoid appendix feel).
- Whether requiring EARS risks friction for very small (C1) projects, and whether
  C1 may use a relaxed criterion form.
- Whether retitling Rule 3 risks breaking cross-references (the sweep must
  enumerate references to "Rule 3" and "Tests Are Design Artifacts").
- The relationship between this amendment's G5–G6 verification loop and the
  separate loop research (docs/resources/research/loops.md). They meet at the same gates;
  this amendment should not depend on that research but should not contradict it.

## Consequences of not doing this

The verification commitment stays implicit, undifferentiated, and unevenly gated,
and the prose-to-code gap stays unbridged. Practitioners who know the method will
verify early; those who read the gates literally will treat verification as a
build-phase activity and defer it. Worse, AI judges will grade AI-generated code
against reinterpreted prose, which verifies nothing — the precise failure a
method built on AI-generated code can least afford.

## Append-Only Classification Notice: 2026-07-10

This notice preserves the complete historical record above. It does not alter
the original Accepted status or make the proposed successor effective before
explicit human ratification.

Current classification: **Active; proposed partial supersession pending human
ratification**.

Proposed successor:
`docs/methodology/design/operational-coherence-decision-record.md` (D-005,
D-009, D-010, D-017, and D-018).

If and only if that exact successor record is ratified, this record becomes
**Partially Superseded** with this clause-level disposition:

| Historical clause | Disposition after ratification | Successor rule |
| --- | --- | --- |
| Verification-First principle and three verification questions | Remain active | D-017 scales form, not the requirement to define and approve correctness. |
| Context summary: "EARS-formed acceptance criteria at G2" | Partially superseded for C1 | D-017 permits plain, concrete, observable C1 criteria; C2/C3 retain EARS. |
| Gate table G2 row: "EARS acceptance criteria" | Partially superseded for C1 | D-017 requires the C1 observable alternative and negative cases for every class. |
| Step 1: universal EARS capture at G2 | Partially superseded for C1 | Its EARS mechanism remains active for C2/C3; C1 may use observable criteria. |
| Step 2 and Consequence 3: human-approved G3 verification specification | Remain active and are clarified | D-017 requires the specification and proportional design interrogation for every class. |
| Step 3: code graded against approved verification | Remains active | D-005 provides the complete per-phase evidence binding. |
| Consequence 2: every G2 criterion must use EARS | Partially superseded for C1 | C2/C3 remain mechanically EARS-formed; all classes require explicit unwanted behavior where failure paths exist. |
| Consequence 4: phase-exit/value-review evidence through `tested-by` | Partially superseded | D-005 supplies complete phase exit; D-018 assigns post-loop/value ownership; D-009 requires reference target kind. |
| Consequence 5: scale verification by blast radius | Remains active and is made determinate | D-017 defines the C1/C2/C3 criterion-form boundary. D-010 requires a project-declared coverage contract. |
| Enforcement bullet: EARS conformance at G2 | Partially superseded for C1 | Enforcement is class-aware under D-017. |
| Open question: whether C1 may use relaxed criterion form | Resolved | Yes, under D-017's concrete-observable and negative-case requirements. |
| Open question: relationship to the G5-G6 loop | Resolved for operational ownership | D-005 and D-018 define phase and aggregate evidence boundaries. |

Technique neutrality, the human-approved test-specification keystone, the
division between deterministic tests and independent judgment, and the
requirement to approve verification before construction remain active. Until
successor ratification, every historical clause retains its prior authority.
