# GenDev Practitioner Runbook: G0 Through G7

Status: Active; field-validated through G3 (Briefwire dogfood, 2026-07-12);
G4 through G7 validation pending the first full traversal
Date: 2026-07-12
Applies to: GenDev 1.0.2 and later
Audience: a practitioner (human, agent, or human directing an agent) taking a
real project from an empty repository to acceptance under GenDev
Companion references: the constitution
(`docs/methodology/constitution/gendev.md`), the practitioner guide
(`docs/resources/practitioner-guide/`), and the phase-loop guide
(`docs/methodology/guides/phase-loop.md`)

## How To Read This Runbook

Commands marked REQUIRED are the methodology's control plane; skipping one
leaves the record incomplete and the checker will eventually say so. Commands
marked SUGGESTED are the ones experienced operators run anyway: they cost
seconds and catch drift early. Authoring steps are not commands; they are the
actual work, and for each one this runbook states what the checker will
demand of the result, so you learn the enforcement before it learns you.

Two habits carry the whole method. Validate after every meaningful change:

```bash
./scripts/check-methodology.sh
```

And commit at every boundary the runbook marks, because gate evidence pins
revisions, and revisions only exist if you commit. Do not paste command
blocks containing `#` comments into zsh; this runbook keeps commands and
commentary separate for exactly that reason.

Gate closes use answers files, so understand them before your first close.

### The Answers File

Every command that records a durable approval decision (`close-gate.sh`,
`record-phase-checkpoint.sh`, `close-phase.sh`) needs six answers from the
approving human: who decided, when, what they verified, which revision they
reviewed, what risks they accepted, and what questions remain open. Run
interactively in a terminal, these commands prompt for each answer. Run
noninteractively (which is how agents operate, and how most closes happen in
practice), they refuse to proceed without an answers file: a plain text file
supplying those answers as `key=value` lines. The command reads it, validates
it, renders the durable approval event into
`docs/project/approvals/gate-log.md`, and updates the artifact and manifest
under a project-local lock, rolling back if post-write validation fails.

The answers file is therefore not a convenience flag. Its contents become the
permanent record of what the approval meant; a future stranger auditing the
gate log reads these exact words.

Format rules, from the loader itself: one `key=value` pair per line; the
value is everything after the first `=`, so values may freely contain spaces,
punctuation, and further `=` signs; no quoting is needed or interpreted;
unrecognized keys are ignored; blank values are treated as absent. The six
recognized keys:

```text
decided_by=<approver's real name>
decided_on=<YYYY-MM-DD>
checked_statement=<what you actually verified before approving>
reviewed_revision=<short hash of the commit you reviewed>
risk_disposition=<accepted risks and their mitigations, or none>
open_questions=<owned open questions, or none>
```

Two fields are mandatory and refuse placeholders: `decided_by` and
`checked_statement` must be present and must not be `TBD`, `unknown`, or
similar. The methodology will not record an approval by nobody, attesting to
nothing. Three fields have defaults if omitted: `decided_on` defaults to
today's UTC date, and `risk_disposition` and `open_questions` default to
`none`. `reviewed_revision` should be the short hash of the draft commit you
are approving; obtain it with `git rev-parse --short HEAD` after committing
the draft, which is why the rhythm commits before closing.

Writing a good `checked_statement` is the skill. It is one sentence stating
what verification actually occurred: which checklist you walked, which
accuracy pass you confirmed, what you ran. "Looks good" is a placeholder
wearing a costume; "Accuracy pass confirmed; all success criteria carry
measure, target, timing, owner, and evidence source" is a record. If the
approval was delegated (a human directing an agent to record it), say so in
the statement; the record should be honest about who typed what.

A complete worked example for a G1 close, written to a temp file:

```bash
cat > /tmp/g1.txt <<'EOF'
decided_by=Jane Practitioner
decided_on=2026-07-15
checked_statement=Vision accuracy pass confirmed; success criteria complete with owners and evidence sources; non-goals reviewed against scope.
reviewed_revision=3995a62
risk_disposition=Three risks accepted with stated mitigations; none blocking.
open_questions=Two questions owned with due dates before PRD acceptance.
EOF
```

Temp files are fine; the durable record is the rendered gate-log event, not
the answers file itself. Some teams preserve the answers files under
`docs/project/approvals/` for provenance; that is a team convention, not a
requirement.

---

## G0: Repository, Installation, Initialization

Create the repository and give it an identity:

```bash
mkdir <project> && cd <project>
git init -b main
git config user.name "<Your Name>"
git config user.email "<you@example.com>"
git commit --allow-empty -m "Empty repository baseline"
```

Install the methodology from a clone of the methodology repository at its
release tag. REQUIRED:

```bash
<methodology-clone>/scripts/install-methodology.sh --with-resources --protected-branch main "$PWD"
```

Verify prerequisites and orientation. REQUIRED:

```bash
./scripts/gendev-doctor.sh
```

The doctor must show all four prerequisites present (bash 4+, git, python3,
ripgrep). Under 1.0.2 it also reports installed context, methodology version,
source provenance, and file integrity. Do not proceed past a doctor failure.

Initialize the project. REQUIRED:

```bash
./scripts/init-project.sh "<Project Name>"
./scripts/check-methodology.sh
```

Expect the first check to fail. This is the methodology refusing unnamed
authority, and fixing it is your first real task. Edit
`docs/project/project.yaml` and replace `TBD` with named humans for: owner,
approver, deployment_approver, required_approver, and
enforcement.attested.required_attester; name the lead_agent; set mode_set_by,
mode_set_on, classification_owner, and class_set_on. Create a `README.md`
describing the product in a paragraph. Review the blast-radius class: the
default is C2; if your project is genuinely contained (single operator, no
external users, no sensitive data), reclassify to C1 with the reason recorded
in classification_reason. Classification is an owner's act; record it as one.

```bash
./scripts/check-methodology.sh
git add -A
git commit -m "G0: methodology installed, authority named"
```

SUGGESTED at any point, and especially before handing the repo to anyone:

```bash
./scripts/project-state.sh
```

---

## The Gate Rhythm (G1 Through G4)

Every authoring gate follows one rhythm. Learn it here at G1 and reuse it.

```text
1. author the artifact from its scaffold
2. validate
3. commit the draft
4. close the gate with an answers file
5. validate again
6. commit the closure
```

The artifact scaffold is already in place from initialization; `project.yaml`
and `./scripts/project-state.sh` always name the current gate's artifact
path. Fill every section of the scaffold. Complete the provenance block in
the front matter (Produced by, Produced on, Produced with, Agent identity,
Derived from). Perform and record the accuracy pass. Set
`Status: Ready for Approval` when it truly is; never set `Accepted` by hand.
Acceptance is earned by the gate close, which flips the status and writes the
durable approval event. An artifact that says Accepted without a matching
gate-log event is a checker error, by design.

### G1: Vision

Author `docs/project/vision/vision.md`. What the checker and the gate demand:
a problem statement that describes a problem, not a solution; a success
criteria table where every row has measure, target, read timing, owner, and
evidence source; explicit non-goals; risks with mitigations; open questions
with owners.

```bash
./scripts/check-methodology.sh
git add -A
git commit -m "G1 draft: vision"
```

Write the answers file (say `/tmp/g1.txt`) with `reviewed_revision` set to
the draft commit's short hash, then REQUIRED:

```bash
./scripts/close-gate.sh --dry-run --answers-file /tmp/g1.txt G1
./scripts/close-gate.sh --answers-file /tmp/g1.txt G1
./scripts/check-methodology.sh
git add -A
git commit -m "Close G1: vision accepted"
```

The dry run is SUGGESTED and cheap; it renders the event without writing.

### G2: PRD

Author `docs/project/prd/prd.md` from the accepted vision. Demands: stable
`REQ-NNN` IDs that never change; every requirement testable with observable
acceptance criteria; EARS form for C2/C3 (encouraged for C1); an If/then
unwanted-behavior criterion for every requirement with an error path; edge
cases traced to requirement IDs; deferred items with reasons.

Provenance discipline: the PRD's `Derived from` block must pin the vision at
its current revision, which changed when G1's closure touched the vision
file. Under 1.0.2, one command maintains every pin in an artifact:

```bash
./scripts/pin-provenance.sh docs/project/prd/prd.md
```

It reads the artifact's own `Derived from` entries and repins each real
source path to that source's current last-touching commit, using the same
computation the staleness checker uses, so the two cannot disagree. Run it
whenever a source artifact has moved (which every gate closure causes), and
add `--check` to preview without writing. Under 1.0.1, where the tool does
not yet exist, obtain the hash manually and paste it into the revision field:

```bash
git log -1 --format=%H -- docs/project/vision/vision.md
```

Then the rhythm: validate, commit draft, close G2, validate, commit closure.

### G3: Architecture And The Stack ADR

Two artifacts, authored together: the technology stack ADR
(`docs/project/decisions/0001-technology-stack.md`) and the architecture
specification (`docs/project/architecture/architecture.md`). Demands: every
stack concern decided with rationale, alternatives, consequences, prohibited
substitutions, and executable quality gate commands in the ADR; component
ownership, data shapes, state lifecycle, failure behavior with exit codes,
and security boundaries in the architecture; a requirement traceability
table; and a Verification Specification covering every requirement with
non-placeholder `Approved by` and `Approved on` lines.

The design-verification interrogation must be recorded as labeled answer
lines, one per label, each with substance:

```text
Failure modes: <answer>
Scale limits: <answer>
Evolution risk: <answer>
Security boundary: <answer>
```

Prose answers without these labels fail validation. Pin both artifacts'
provenance to the PRD's post-closure commit hash. Then the rhythm through
`close-gate.sh ... G3`.

### G4: Governance And Security

Author `docs/project/security-governance/governance-security-spec.md`.
Demands, from the gate's exit criteria: every actor (operator, agents, the
system itself) with permitted and forbidden actions; authorization rules with
positive and negative tests; explicit audit requirements; secrets and
sensitive data handling defined, affirmatively stated even when the answer is
"none exist"; agent and tool stop conditions documented or marked N/A with
reason. Then the rhythm through `close-gate.sh ... G4`.

---

## G5 And The Interior Phase Loop

G5 is where documentation becomes software. Two layers: the gate itself
certifies the build partition; the interior loop then executes it one phase
at a time while `current_gate` remains G5.

### The Phase Plan (checkpoint G5.0)

Author `docs/project/build-plan/phase-plan.md`. Demands: ordered phases with
stable ID labels, each independently testable and sized for one agent
session; a requirement coverage map accounting for every in-scope
requirement exactly once; integration criteria; the sizing rationale. Honor
the ADR's initialization deferral: source layout, dependency lock files, and
CI setup belong to the first phase's work, not to planning.

Validate, commit, then record the plan checkpoint. REQUIRED:

```bash
./scripts/record-phase-checkpoint.sh --answers-file /tmp/g50.txt G5.0
./scripts/check-methodology.sh
git add -A
git commit -m "G5.0: phase plan accepted"
```

Then close the gate itself with the rhythm: `close-gate.sh ... G5`.

### Per Phase: The Ladder

For each phase `<id>` in plan order, scaffold the phase artifact set.
REQUIRED:

```bash
./scripts/init-phase.sh <id> "<Project Name>"
```

Climb the ladder. Each rung is authored, validated, committed, and recorded:

```text
G5.<id>.1   phase build plan            what this phase delivers and proves
G5.<id>.2   tactical plan               the ordered implementation steps
G5.<id>.3   construction directive      the binding instruction to the
                                        generating agent, carrying the Six
                                        First Principles anti-drift section
G5.<id>.4   build, test, exit           the code, its tests, its evidence
```

For rungs 1 through 3, after each artifact:

```bash
./scripts/record-phase-checkpoint.sh --answers-file /tmp/p<id>-<rung>.txt G5.<id>.<rung>
git add -A
git commit -m "G5.<id>.<rung>: <artifact> recorded"
```

Rung 4 is the build itself. Write the code the construction directive binds,
and nothing more: no undeclared abstractions, no speculative structure, no
scope beyond the phase. Run the quality gates from ADR-0001 before claiming
exit; for a typical Python stack that means, at minimum:

```bash
ruff check .
ruff format --check .
mypy --strict src/
pytest -q
```

All green, plus the phase's requirement coverage demonstrated by its tests.
Then REQUIRED:

```bash
./scripts/close-phase.sh --answers-file /tmp/p<id>-exit.txt <id>
./scripts/check-methodology.sh
git add -A
git commit -m "G5.<id>.4: phase exit"
```

SUGGESTED between phases, to watch coverage and drift trends:

```bash
./scripts/methodology-metrics.sh docs/project
```

Repeat the ladder until every phase declared in the plan has a closed
`G5.<id>.4`. Amendments mid-phase follow the amendment rules in the
phase-loop guide; do not silently widen a phase.

---

## G6: Implementation Ready For Review

All phases closed. Generate the implementation summary. REQUIRED:

```bash
./scripts/new-artifact.sh --kind implementation-summary
```

Complete it: what was built, phase by phase; the aggregate regression suite
run green at the candidate revision (record the revision); integration
criteria satisfied or carried as explicit residuals. Update the traceability
matrix to reflect actual, verified status per requirement. Then the rhythm:
validate, commit, `close-gate.sh ... G6`, validate, commit.

---

## G7: Review, Remediation, Acceptance

Three movements, in order.

First, the review. Strongly SUGGESTED: the reviewer is not the builder; use a
second cold agent or a human reviewer. The review grades the implementation
against the human-approved Verification Specification from G3, not against
taste. Author `docs/project/review/code-review.md`; for the aggregated final
review artifact:

```bash
./scripts/new-artifact.sh --kind final-code-review
```

Second, remediation. Critical findings are fixed; major findings are fixed
or explicitly accepted with rationale; the record lives in:

```bash
./scripts/new-artifact.sh --kind aggregate-remediation
```

Remediation code changes run the same quality gates as any phase.

Third, acceptance evidence:

```bash
./scripts/new-artifact.sh --kind final-test-uat
```

Execute the UAT scenarios the Verification Specification defined at G3; the
human operator runs them and records outcomes. Update the traceability
matrix to its final truthful state; capture metrics before and after
remediation. Then the rhythm: validate, commit, `close-gate.sh ... G7`,
validate, commit.

The project now stands at G8 pending: reviewed, remediated, evidenced, and
accepted. Deployment (G8) and as-built closeout (G9) are the runbook's
sequel; if the project will not deploy, G8's explicit non-deployment
disposition is the honest close.

---

## Common Failure Modes, From The Field

Every entry below happened in a real GenDev project and was caught by the
checker; the fix is stated so it costs you one read instead of one
round trip.

Unnamed authority at init: the first `check-methodology.sh` fails until the
manifest names real humans. Intended behavior; name them.

Hand-set `Accepted`: an artifact whose status says Accepted without a
matching durable gate-log event is an error. Set Ready for Approval; let
`close-gate.sh` earn the flip.

Stale provenance pin: `Derived from` must pin the source file's last-touching
commit hash, which after a gate close is the closure commit. Under 1.0.2, run
`./scripts/pin-provenance.sh <artifact>` whenever a source has moved; under
1.0.1, obtain the hash with `git log -1 --format=%H -- <source>` and repin by
hand.

Interrogation in prose: the G3 design interrogation requires the four labeled
answer lines shown above; a complete prose paragraph fails until labeled.

Comments pasted into zsh: interactive zsh does not honor `#` comments by
default; paste commands without trailing commentary.

Authority-repo checks in a product repo (pre-1.0.2): `check-doc-coherence.sh`
and lifecycle release mode produce false findings outside the methodology
repository. Under 1.0.2 they refuse politely; under 1.0.1, do not run them
here and do not chase their findings.
