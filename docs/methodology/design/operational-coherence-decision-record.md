# Decision Record: Operational Coherence Contract

Date: 2026-07-10
Status: Ready for Approval
Ratification method: Exact-revision named-human approval
Owner: GenDev maintainers
Target release: `0.5.0-operational-coherence`
Drafting authority: Approved remediation plan, D-001 through D-006 and D-008 through D-018

## Authority And Effect

Chuck Russell approved drafting D-001 through D-018 without amendment on
2026-07-10. That approval authorized preparation of this record; it did not
ratify this record or amend the methodology.

Until the external ratification event described at the end of this record is completed:

- this record is proposed design authority only;
- the constitution and existing Accepted decision records remain controlling;
- the lifecycle registry and downstream implementation must identify themselves
  as proposed 0.5 candidate material; and
- no downstream work package may represent these decisions as Accepted.

If ratified, this record controls within its stated overlap with earlier design
records. Constitutional and guide text is amended separately so that an
accepted decision is never implemented only by implication.

## Context

The current baseline contains individually reasonable lifecycle, documentation,
and verification decisions, but their combined operational contract is
incomplete. The observed defects include an ambiguous G5-to-G6 transition,
under-specified phase exit, approval records that do not bind reviewed bytes,
non-portable transition tooling, inconsistent release identity, incomplete
scaffolding, an untyped distinction between canonical and supporting artifact
references, and post-loop evidence with no complete gate ownership model.

This record establishes one implementable contract for release shape, platform
support, state, evidence, approval, identity, compatibility, initialization,
verification scaling, and terminal close-out. It intentionally does not decide
the No Undeclared Abstractions boundary; that focused decision is recorded in
`naa-authority-boundary-decision-record.md`.

## Decision Summary

| ID | Decision |
| --- | --- |
| D-001 | Deliver one umbrella 0.5 operational-coherence release through independently reviewable work packages. |
| D-002 | Support macOS system Bash 3.2/BSD utilities and Ubuntu runner Bash/GNU utilities. |
| D-003 | Keep installed core commands dependency-light; Python standard library is baseline-only unless explicitly enabled downstream. |
| D-004 | Separate the major gate from the interior G5 phase position. |
| D-005 | Require a complete, pinned evidence set for each phase exit. |
| D-006 | Require a named-human phase-exit approval under explicit delegation rules. |
| D-008 | Give tactical workstreams and tasks immutable, parseable identifiers. |
| D-009 | Distinguish canonical evidence references from technique-specific supporting-design references. |
| D-010 | Replace an undefined universal coverage percentage with a project-declared coverage contract. |
| D-011 | Treat a complete append-only event, not a manifest summary, as approval evidence. |
| D-012 | Bind approval to exact reviewed and resulting artifact bytes under three explicit result categories. |
| D-013 | Apply strict schema version 2 prospectively through explicit migration. |
| D-014 | Initialize project-wide authority first and scaffold complete phase sets just in time. |
| D-015 | Publish release identity and historical tags only from verified provenance and separate publication approval. |
| D-016 | Maintain one machine-readable lifecycle registry with same-change coherence validation. |
| D-017 | Scale G2 criterion form by blast radius while retaining Verification-First for every class. |
| D-018 | Assign complete aggregate evidence, deployment authorization, value disposition, and terminal close-out across G6-G9. |

## D-001: Release Shape

### Decision

Use one umbrella release named `0.5.0-operational-coherence`. Its work packages
remain independently reviewable and independently reversible until release
preparation.

The implementation must preserve the version claims observed in the baseline:
some active surfaces report `0.1.0-baseline`, while the project template reports
`0.4.0-verification-first`. Work before final release preparation must record
that split rather than silently normalize it. Candidate registries and generated
contracts identify their target as a proposed 0.5 candidate; they must not claim
that 0.5 is released.

Only release preparation may atomically synchronize all active version surfaces
to 0.5, and only after full verification and independent review. Normalizing the
repository to 0.4 as an intermediate release is outside this decision.

### Alternatives Rejected

- Separate patch releases per finding were rejected because their authority,
  event, lifecycle, and tooling contracts are interdependent.
- Silent normalization to 0.4 was rejected because it would invent a release
  state not consistently represented by the current repository.
- Early 0.5 version stamping was rejected because a candidate must not claim the
  authority or verification status of a released baseline.

### Consequences, Enforcement, And Migration

- A release index must distinguish candidate, released, superseded, and unknown
  historical states.
- Coherence validation must reject candidate/released status contradictions and
  active-version drift after release preparation.
- Existing projects retain their declared methodology version until they
  explicitly adopt 0.5 under D-013.
- Release publication, tag creation, tag push, and merge remain separate human
  actions; ratifying this record authorizes none of them.

## D-002: Platform Contract

### Decision

Installed shell tooling must run without modification under both:

1. macOS system Bash 3.2 with BSD `sed`, `awk`, `grep`, `date`, `tar`, and
   `mktemp`; and
2. the Ubuntu GitHub-hosted runner environment with Bash and GNU utilities.

Installed code must not use `mapfile`, associative arrays, `sed -i`, GNU
`0,/regex/` addressing, GNU-only `cpio` flags, or an undeclared package.

### Alternatives Rejected

- Requiring Homebrew Bash 4+ on macOS was rejected because the repository
  currently presents its shell commands as directly usable baseline tools.
- Supporting only CI's Ubuntu environment was rejected because it would leave a
  documented local workflow unverified on the maintainer platform.
- Maintaining divergent macOS and Linux implementations was rejected because it
  doubles authority and behavior surfaces.

### Consequences, Enforcement, And Migration

- Every installed script must pass syntax and behavior tests on both platform
  classes.
- Portability is an enforced release condition, not a best-effort warning.
- Migration and transition algorithms must use portable temporary-file and
  archive patterns and must preserve file modes and bytes.
- A platform waiver requires a later explicit amendment; it cannot be inferred
  from a passing Linux CI job.

## D-003: Core Dependency Policy

### Decision

Core installed commands depend only on Bash 3.2, portable utilities, Git, and
tar. A baseline-maintenance coherence validator may use Python 3 standard
library for reliable JSON parsing. If that validator is distributed into a
downstream project, it remains optional unless the project explicitly enables
the baseline-maintenance CI profile.

No installed gate or phase transition command may require Python.

### Alternatives Rejected

- Parsing lifecycle JSON ad hoc in shell was rejected as structurally fragile.
- Making Python a new universal downstream runtime dependency was rejected as an
  unnecessary expansion of the baseline contract.
- Introducing a third-party JSON/YAML command was rejected because it would
  violate the dependency-light installation goal.

### Consequences, Enforcement, And Migration

- The registry generator emits a read-only Bash-3-compatible contract consumed
  by installed commands.
- Registry validation fails with a distinct parser/invocation status when Python
  is unavailable or input cannot be parsed; installed project operations remain
  usable.
- Installation manifests must identify baseline-only optional tools separately
  from required downstream tools.

## D-004: Two-Axis G5 State Model

### Decision

`project.current_gate` records the active major gate.
`phase.phase_position` records the most recently completed interior G5
checkpoint.

- `G4 -> G5` enters phase planning after governance is accepted.
- `G5.0` records acceptance of the phase plan and authorization of the phase
  loop. It is a `phase_checkpoint`, not a `gate_transition`.
- `project.current_gate` remains `G5` at `G5.0` and at every
  `G5.<phase-id>.1` through `G5.<phase-id>.4` checkpoint.
- Phase checkpoints mutate phase state only; they never imply a major-gate
  transition.
- `G5.0` and `G5.<phase-id>.1` through `.3` may accept their owning authority
  only through a named-human checkpoint event under D-011. This is checkpoint
  acceptance inside G5, not a major-gate approval or transition.
- The sole `G5 -> G6` transition occurs after every currently declared,
  non-superseded phase has one valid exit and final integration/regression
  criteria pass or have an allowed, named-human residual disposition.
- `G8 -> G9` is terminal. It sets `project.current_gate: G9` and
  `project.status: closed`. G9 has no outgoing close-gate operation.
- Later work starts through the governed amendment, regression, new phase, or
  new-project path. It does not invent G10.

Allowed loop states are `not_started`, `active`, `blocked`, `ready_for_g6`,
`closed`, and `legacy_unreconciled`. Allowed phase states are `pending`,
`planning`, `authorized`, `in_progress`, `ready_for_exit`, `exited`, `blocked`,
and `superseded`.

### Alternatives Rejected

- Treating `G5.0` as both the closure of G5 and a state inside G5 was rejected
  because it creates a destination-free transition and contradictory manifest
  values.
- Promoting every phase checkpoint to a major gate was rejected because it
  makes the gate enumeration unbounded.
- Advancing `current_gate` through pseudo-gates such as `G5.1` was rejected
  because gate and checkpoint have different approval and state semantics.

### Consequences, Enforcement, And Migration

- The registry owns legal major-transition and checkpoint enumerations; guides
  explain them in human-readable form.
- The checker must reject a phase position outside major gate G5, skipped or
  duplicated live checkpoints, and G5-to-G6 with missing phase exits.
- Legacy projects with absent or ambiguous phase fields remain pinned or enter
  `legacy_unreconciled`; migration must not infer checkpoint completion.
- This decision partially supersedes the G5 phase-loop record as itemized below.

## D-005: Complete Phase Exit

### Decision

A `G5.<phase-id>.4` phase transition requires separately pinned evidence for:

1. the implementation candidate revision and implementation evidence;
2. the accepted test/UAT plan and its executed result;
3. independent phase review and the exact revision reviewed;
4. remediation status, including an explicit `not_required` result backed by a
   clean review;
5. a cumulative traceability update identifying the phase requirements;
6. a Complete per-phase as-built close-out;
7. Accepted phase learnings;
8. regression command, result, coverage, and phases covered;
9. the declared coverage policy, actual result, and any shortfall disposition;
10. residual findings, risks, and applicable amendments; and
11. the D-006 named-human approval and substantive checked statement.

Every evidence reference binds the canonical path, relevant status, reviewed or
result revision, Git blob OID, portable digest, and originating event where
required by D-012. Missing, duplicate, stale, superseded, dirty, untracked, or
placeholder evidence blocks exit.

The complete per-phase path set for `<phase-id>` is:

```text
docs/project/build-plan/phases/phase-<phase-id>-build-plan.md
docs/project/build-plan/phases/phase-<phase-id>-tactical-implementation-plan.md
docs/project/build-plan/phases/phase-<phase-id>-construction-directive.md
docs/project/build-plan/phases/phase-<phase-id>-build-prompt.md
docs/project/build-plan/phases/phase-<phase-id>-implementation-evidence.md
docs/project/build-plan/phases/phase-<phase-id>-code-review.md
docs/project/build-plan/phases/phase-<phase-id>-remediation.md
docs/project/build-plan/phases/phase-<phase-id>-learnings.md
docs/project/testing/phase-<phase-id>-test-uat-plan.md
docs/project/as-built/phase-<phase-id>-as-built-closeout.md
docs/project/as-built/phase-<phase-id>-value-review.md
```

The cumulative traceability artifact remains
`docs/project/traceability/traceability-matrix.md`. The phase value-review path
must be bound at exit even when its separately structured disposition is
`not_due`; a due review cannot be omitted. A Draft `not_due` value record is not
a fourth D-012 evidence category. Its exact path, status, revision, blob,
digest, trigger, owner, and disposition are pinned as a subordinate reference
in the Complete phase as-built evidence item. A Complete value record is pinned
through the same subordinate-reference contract; it is not a separately
required phase-exit evidence item.

G6 remains aggregate whole-build review readiness, G7 remains aggregate final
acceptance, and G9 owns a distinct project-level as-built close-out. A per-phase
close-out does not substitute for aggregate or project close-out.

### Alternatives Rejected

- Treating "built, tested, learnings written" as sufficient was rejected because
  it omits review, remediation, traceability, as-built state, regression scope,
  and accountable risk acceptance.
- Deferring all review and close-out to G6/G7 was rejected because it loses the
  bounded defect-discovery value of the phase loop.
- Allowing a clean review to omit remediation status was rejected because the
  absence of work must be explicit and machine-distinguishable from missing work.

### Consequences, Enforcement, And Migration

- The per-phase canonical set expands beyond the earlier six-artifact set to
  include plans, directive/prompt, implementation evidence, test/UAT, review,
  remediation, traceability linkage, as-built, value disposition, and learnings.
- Phase closure tooling must validate all evidence before rendering any mutation.
- An active legacy phase either finishes under its pinned methodology or is
  explicitly amended and reissued under 0.5.

## D-006: Phase Exit Approval

### Decision

Every phase exit requires a named-human approver.

- C1 and C2 may delegate phase-exit approval only to another named human when
  `project.yaml` identifies the person or governed role assignment and the gate
  log records delegator, delegate, acceptance, scope, and duration.
- C3 requires the specifically authorized named human under the project's
  approval policy.
- An agent, model, automation identity, or unbound role label cannot approve.
- Critical findings block exit. Every major residual requires explicit
  named-human risk acceptance with rationale.

### Alternatives Rejected

- Role labels without a bound person were rejected because they do not establish
  accountable authority.
- Automated approval after green tests was rejected because tests cannot accept
  residual product, security, or governance risk.
- Universal non-delegability was rejected because low- and medium-blast-radius
  projects may establish controlled, accountable delegation.

### Consequences, Enforcement, And Migration

- Approval validation must resolve identity and delegation as of the event date.
- Historical records with missing people or delegation facts remain incomplete;
  migration cannot synthesize them.
- Combined-gate operation cannot erase the required phase-exit approval.

## D-008: Tactical Identifier Contract

### Decision

Use these stable identifiers:

```text
Workstream: PH-<phase-id>-WS<NN>
Task:       PH-<phase-id>-T<NNN>
```

Phase IDs may contain uppercase or lowercase ASCII alphanumerics and internal
hyphens. The workstream or task suffix is the final segment and has fixed width.
Examples are `PH-1-WS01`, `PH-1-T010`, and `PH-10-5-T020`.

IDs become immutable when the tactical plan is Accepted. A retired ID is marked
`deferred` or `superseded` and is never reused. Dependencies and evidence cite
IDs, not table row numbers or mutable headings.

### Alternatives Rejected

- Sequential row numbers were rejected because insertions renumber accepted
  work.
- Parsing the phase identifier by splitting on every hyphen was rejected because
  hyphens are legal inside the phase ID.
- Reusing deleted IDs was rejected because it corrupts traceability history.

### Consequences, Enforcement, And Migration

- Templates and the registry must publish one grammar and parse the suffix from
  the right.
- Duplicate, malformed, dangling, or reused IDs are hard errors.
- Migration adds stable IDs with a preserved legacy-ID mapping; it does not
  reorder tasks or invent completion.

## D-009: Canonical Artifact References

### Decision

`docs/project/design/` is the sole canonical directory for technique-specific
supporting design artifacts. A competing `docs/project/supporting/` directory is
not part of the 0.5 scaffold.

Every typed reference declares both a relationship and a target kind:

- `canonical_artifact` targets another canonical authority or evidence artifact,
  such as a `tested-by` edge to a canonical test/UAT plan; or
- `supporting_design` targets a technique-specific textual artifact under
  `docs/project/design/`.

The target kind selects the allowed path, identity/provenance rules,
authority-direction rule, lifecycle owner, cycle/depth rule, and validation
severity. A relationship name alone is not enough to infer the target kind.

### Alternatives Rejected

- Treating every referenced artifact as a supporting artifact was rejected
  because canonical evidence has its own lifecycle and identity.
- Maintaining both `design/` and `supporting/` was rejected because identical
  concepts would gain competing canonical locations.
- Inferring target kind from path or relationship was rejected because
  `tested-by` can legitimately target canonical evidence while other
  relationships can target supporting design.

### Consequences, Enforcement, And Migration

- Reference validation must reject missing target kind, wrong target location,
  invalid authority direction, and prohibited cycles.
- Canonical-to-canonical evidence references remain canonical; they are not
  downgraded to technique-specific supporters.
- Migration compares any competing legacy locations and requires human
  disposition for conflicting content; it does not silently move or delete it.

## D-010: Coverage Policy

### Decision

Replace the universal phrase `90% meaningful coverage` with a project-declared
verification coverage contract containing:

- metric and measurement tool;
- target and scope;
- exact measurement command;
- exclusions and rationale;
- accountable owner; and
- shortfall disposition.

Templates may recommend a C2 default, but no percentage is authoritative until
its metric, denominator, scope, and command are defined. A shortfall records a
residual risk and requires named-human acceptance at the applicable checkpoint.

### Alternatives Rejected

- Keeping an undefined universal percentage was rejected because it is neither
  comparable nor reproducible across technology stacks.
- Eliminating coverage planning entirely was rejected because verification scope
  still needs an explicit, reviewable contract.
- Allowing an agent to waive a shortfall was rejected under D-006's authority
  boundary.

### Consequences, Enforcement, And Migration

- Checker enforcement verifies contract completeness and evidence binding, not
  the semantic superiority of a particular metric.
- Legacy text does not become measured evidence. Migration creates a pending
  project policy for human review when none exists.

## D-011: Approval Evidence Contract

### Decision

In strict structured mode, an Accepted artifact requires a complete durable
approval event under `## Gate Records`. `approvals.latest_decision` is a derived
summary and never substitutes for the event.

Each artifact-acceptance event binds the exact gate or checkpoint, event ID and
schema version, canonical artifact path, reviewed revision/blob/digest,
deterministic resulting blob/digest under D-012, decision/status, named
approver, ISO date, substantive checked statement, risk disposition,
enforcement context, and next state. Corrections and supersessions are new
events carrying `supersedes_event_id` and `correction_reason`; prior event text
remains unchanged. Duplicate unsuperseded latest decisions and supersession
cycles are invalid.

An administrative approval event such as gate regression or enforcement
override does not imply artifact acceptance. Its schema binds the administrative
subject, decision, named approver and date, substantive checked statement, risk
disposition, enforcement context, and next state. If it accepts or reuses an
artifact, each artifact evidence item still satisfies D-012.

An operational event for a boundary whose registry approval mode is
`not_required` records its accountable recorder, date, checked statement, and
explicit no-additional-approval basis. It does not invent an approver or an
approval decision.

Every schema-2 event uses the registry's restricted YAML serialization
contract. Each top-level field has one declared scalar, scalar-list, record, or
record-list shape; scalar values use the declared fixed, pattern, vocabulary,
or semantic value contract; and nested records reject undeclared keys. A
conditional record declares the selector and selector-to-profile mapping that
activates its additional fields. Evidence-bearing lists declare nonzero minimum
cardinality. Test commands and results are paired records, and each due value
criterion is a keyed result record that carries its own evidence, result, and
required follow-up decision. Correction fields use the common correction
profile. Consumers derive these rules from `event_serialization`; they do not
maintain a second event-shape table.

### Alternatives Rejected

- Treating manifest summary fields as approval was rejected because summaries
  are mutable and omit event-level provenance.
- Searching free prose for approval words was rejected because it creates false
  positives and ambiguous scope.
- Editing an erroneous event in place was rejected because it destroys durable
  approval history.

### Consequences, Enforcement, And Migration

- Strict checkers parse complete events and derive or compare summaries.
- A missing, ambiguous, duplicated-latest, or supersession-cyclic event blocks
  the affected transition.
- Legacy incomplete events remain visible; only new schema-2 events are required
  to be strict after opt-in.

## D-012: Reviewed Revision Contract

### Decision

A transition requires a non-placeholder Git revision that resolves and whose
artifact blob matches the exact pre-closure bytes reviewed by the human. The
event records canonical path, reviewed revision, reviewed Git blob OID, portable
content digest, result category, resulting Git blob OID, and resulting digest.
Dirty, untracked, mismatched, missing, or `TBD` evidence is rejected.

Each evidence item declares exactly one category:

1. `new_acceptance_status_only`: the only allowed authority transformation;
2. `complete_report_unchanged`: a Complete evidence report is byte-identical
   before and after the transition; or
3. `accepted_authority_unchanged`: reused Accepted authority is byte-identical
   and cites the originating approval event that binds the same path and blob.

For `new_acceptance_status_only`, the artifact must contain exactly one canonical
header `Status: Ready for Approval`. Before writing, the tool renders a candidate
that replaces only that header value with `Status: Accepted`, preserves every
other byte and the line-ending convention, verifies the exact one-line semantic
diff, and records the deterministic resulting OID and digest. Any other content,
path, provenance, encoding, whitespace, line-ending, or status-line change
blocks approval.

Complete reports are never status-rewritten during approval. Previously Accepted
authority remains byte-identical. Multi-artifact events bind every evidence item
separately. Manifest and gate-log candidates are separate transaction files and
are not represented as the already-reviewed authority revision.

A checkpoint may also pin a Draft or otherwise non-acceptance input as an event
reference containing path, status, revision, blob, and digest. That reference is
not an evidence item, has no fourth result category, and cannot satisfy an
artifact acceptance. The accepting evidence item must declare the reference and
its role explicitly.

### Alternatives Rejected

- Binding only a branch or commit name was rejected because the relevant path can
  differ from the bytes actually reviewed.
- Reviewing the post-approval mutation was rejected as circular: that mutation
  does not yet exist when approval is given.
- Allowing a transition tool to normalize whitespace or rewrite report status was
  rejected because it changes reviewed evidence.

### Consequences, Enforcement, And Migration

- Git-object and portable-digest checks must agree before mutation.
- Transition preparation is read-only and deterministic; writes occur only after
  the complete candidate transaction validates.
- Historical evidence without an exact revision stays unresolved and cannot be
  fabricated by migration.

## D-013: Legacy Compatibility

### Decision

New 0.5 projects use strict schema version 2. Existing projects remain pinned to
their declared release until they explicitly opt in. A visible temporary legacy
migration mode may warn about incomplete historical records, but every event
created after mode activation must satisfy strict schema 2.

Migration does not fabricate historical facts, overwrite project-owned content,
or automatically regress a gate. It assesses before mutation, displays exact
actions, binds application to the accepted assessment digest, validates a
candidate transaction, and updates the methodology version last.

Historical mappings use a schema-2 `migration_reconciliation` event containing
source and target methodology versions, a stable historical event reference,
the mapped gate or checkpoint, mapped evidence classes, unresolved fields,
inspected provenance, mapping decision, any required named-human approval, and
risk disposition. Normal amendment reconciliation remains the distinct
`reconciliation` event; gate regression remains `gate_regression`.
A historical reference is either a stable event ID or a SHA-256-bound source
path and reviewed revision; a line number alone is not durable. C3 mappings and
accepted residual historical uncertainty require a named human. Critical
security or approval uncertainty is not waivable for migration convenience.

### Alternatives Rejected

- Reinterpreting all historical projects under 0.5 was rejected because it would
  retroactively change approval and evidence requirements.
- Permanently tolerating weak new events in legacy mode was rejected because the
  project would never converge.
- Inventing missing historical approvals was rejected because provenance cannot
  be reconstructed from desired state.

### Consequences, Enforcement, And Migration

- Compatibility is version-bound and prospective, not a blanket checker bypass.
- Unresolved historical facts remain visible in readiness decisions.
- A mid-phase project either completes the phase under its pinned version or
  opens an amendment and reissues it under 0.5.

## D-014: Scaffold Timing

### Decision

Fresh initialization creates project-wide authority files and canonical
directories. It does not create a hard-coded, partially valid Phase 1 artifact
set before an Accepted phase plan defines the phase IDs.

A phase-scaffold command creates the complete D-005 per-phase artifact set after
the phase plan declares the ID. A compatibility `--seed-phase` option may create
a complete first-phase set during initialization, but every file must be rendered
from the same canonical templates and pass the same identity checks.

The installed command is `scripts/init-phase.sh <phase-id>`. Initialization may
expose `scripts/init-project.sh --seed-phase <phase-id>` as the compatibility
entry point; it delegates to the same renderer and validation contract.

### Alternatives Rejected

- Continuing to emit partial Phase 1 artifacts was rejected because the checker
  can falsely report an unusable scaffold as healthy.
- Generating every possible phase at initialization was rejected because phase
  IDs and count are project authority, not baseline assumptions.
- Maintaining separate seed and phase templates was rejected because they would
  drift.

### Consequences, Enforcement, And Migration

- The phase plan is the source for phase IDs and ordering.
- Initialization and phase scaffolding must be independently idempotent and
  refuse conflicting existing content.
- Backfill creates only missing files with honest Draft/pending state and never
  claims historical completion.

## D-015: Release And Historical Tags

### Decision

Create a release index that records version, status, date, tag, ratification
commit, supersedes/superseded-by relation, and migration guide. Verify each
historical ratification commit from repository evidence. When a mapping cannot
be proven, record `unknown` and the search performed; do not create or recommend
that historical tag.

An unknown mapping blocks 0.5 only when current authority or version identity
depends on it. Contradictory historical release prose is corrected by append-only
erratum. Historical and 0.5 tag creation or publication requires a separate
maintainer approval over the exact mapping.

### Alternatives Rejected

- Guessing tag commits from dates or nearby changes was rejected because tags are
  durable authority signals.
- Blocking all current work on unrelated unknown history was rejected because it
  does not improve current evidence.
- Rewriting historical release prose in place was rejected because it hides the
  record that needs correction.

### Consequences, Enforcement, And Migration

- Release validation checks metadata completeness and active-version coherence.
- Tag and push operations are never performed merely because this decision is
  ratified.
- Downstream migration uses the release index only where its mapping is proven.

## D-016: Single Lifecycle Registry

### Decision

Create one machine-readable JSON lifecycle registry for mechanically determinate
enumerations and bindings. The constitution delegates gate enumeration to the
canonical lifecycle model. `gates.md` remains the normative human explanation;
the registry is the machine-readable contract for the same model.

The registry must declare schema/version status, G0-G9, legal transitions,
G5 checkpoints, canonical paths and phase patterns, artifacts/templates/statuses,
event types and fields, role and approval rules, criterion IDs, task grammar,
reference target kinds, class scaling, document sweep classes, active/partial
decision classifications, version targets, and G6-G9 evidence bindings.

It ships in the same change as a standard-library coherence validator and a
deterministic Bash-3-compatible generated read-only contract. The validator must
check the registry internally and against normative files. The registry may not
generate whole prose guides or silently override a constitutional conflict.

### Alternatives Rejected

- Continuing to duplicate enumerations only in prose and shell was rejected
  because drift is not mechanically visible.
- Making the registry the sole human authority was rejected because operational
  rationale and judgment rules require normative prose.
- Adding an unvalidated registry was rejected because it would become another
  source of drift.

### Consequences, Enforcement, And Migration

- Exit statuses are 0 for clean, 1 for coherence findings, and 2 for invocation
  or parser failure; human and JSON reports use stable rule IDs.
- Generated output must be byte-deterministic and committed with its source.
- Active and partially superseded design clauses are classified in the registry;
  historical/research prose is excluded from current-rule checks but still gets
  link and release-metadata validation.

## D-017: Verification-First Scaling

### Decision

G2 criterion form is class-aware:

- C2 and C3 PRDs require mechanically recognizable EARS-formed acceptance
  criteria.
- C1 PRDs may use plain, concrete, observable acceptance criteria instead of
  EARS.
- Every class requires explicit unwanted-behavior criteria wherever an error or
  failure path exists.

G3 requires a human-approved verification specification and proportional design-
verification interrogation for every blast-radius class. Templates, registry,
checker, transition tools, and examples must encode both the C1 alternative and
the C2/C3 EARS rule. C1 is never silently exempt from Verification-First.

The registry represents criterion-form applicability explicitly: C1 requires at
least one of the EARS or plain-observable form criteria, while C2 and C3 require
the EARS form criterion. The observable-form ID is not an unconditional
requirement merely because the G2 transition catalogs both possible criteria.

### Alternatives Rejected

- Universal EARS for C1 was rejected as ceremony not always justified by its
  blast radius.
- Exempting C1 from verification planning was rejected because small scope does
  not make correctness or failure behavior unknowable.
- Optional error-path criteria were rejected because silent negative-case gaps
  are a recurring false-green source.

### Consequences, Enforcement, And Migration

- Criterion validation is conditional on the manifest's declared blast-radius
  class and fails when that class is absent or invalid.
- G3 approval remains mandatory for every class, with depth proportional to risk.
- Existing C1 projects can migrate their observable criteria without mechanical
  conversion to EARS; C2/C3 projects must satisfy EARS before strict G2 approval.
- This decision partially supersedes universal-EARS language in the
  Verification-First decision record as itemized below.

## D-018: Post-Loop Evidence Chain

### Decision

Post-loop lifecycle ownership is:

| Boundary | Required evidence | State and approval |
| --- | --- | --- |
| `G5 -> G6` | Valid exit event for every declared live phase; exact whole-build candidate; cumulative integration/regression result; current traceability; residuals | Close the phase loop, retain final phase position, enter G6. Phase approvals normally suffice; any allowed skipped critical verification or otherwise nonwaivable residual requires named-human acceptance. |
| `G6 -> G7` | Complete `docs/project/build-plan/implementation-summary.md` with exact candidate, changed files, commands/results, deviations, integration/regression, residuals, and review package; current traceability | Enter final whole-build review at G7. This transition does not claim implementation acceptance. |
| `G7 -> G8` | Complete `docs/project/review/code-review.md`; Complete `docs/project/review/remediation.md` or explicit `not_required`; Complete `docs/project/testing/final-test-uat-report.md`; current traceability; residual disposition; byte-identical upstream authority | Named human accepts implementation; critical findings are closed and major residuals explicitly accepted. Enter G8 with exact release candidate and deployment disposition pending. |
| G8 deployment authorization | Ready-for-Approval `docs/project/deployment/deployment-readiness.md`; Complete `docs/project/deployment/production-runbook.md`; release scope, configuration/secrets, migration/rollback, monitoring, incident ownership, post-deployment validation, and value prerequisites | A separate `deployment_approval` event retains G8, accepts readiness by status-only transformation, binds exact candidate, and performs no deployment. Named deployment/release approver is required; security approval is added where governance requires. |
| `G8 -> G9` | Prior deployment approval or approved non-deployment disposition; Complete `docs/project/deployment/deployment-record.md`; operational results; Complete `docs/project/as-built/value-review.md` with valid disposition; final traceability; Complete `docs/project/as-built/as-built-closeout.md` | Named project-closeout approver and operational owner accept terminal closure. Set G9/closed, active role `none`, and no next gate or mandatory authority artifact. |

G6 owns aggregate implementation/readiness evidence. G7 owns final review,
aggregate remediation, final verification/UAT, traceability, and implementation
acceptance. G8 owns deployment readiness, operations, rollback, monitoring, and
the separate pre-production authorization. G9 owns terminal project-level
as-built reconciliation after deployment or explicit non-deployment.

The authorization and terminal records must correlate. A `deploy` authorization
closes only with terminal disposition `deployed` and a recorded production
action. A `non_deployment` authorization closes only with disposition
`not_deployed` and `production_action_performed: false`. Both paths use the
canonical `approver`/`approved_on` fields and bind the same exact release
candidate; one intent cannot satisfy the other path.

Value artifacts retain the normal artifact `Status` vocabulary and separately
declare `value_review.disposition`:

- `complete`: due criteria cite evidence and report `met`, `missed`, or
  `unmeasurable`; missed/unmeasurable results have a follow-up decision;
- `not_due`: record trigger, expected date when knowable, named owner, evidence
  source, and next review mechanism; or
- `not_applicable`: record rationale and the named human accepting it.

The aggregate value-review artifact becomes `Status: Complete` when the
disposition record is complete. Absence, `TBD`, unowned future work, conflating
status with disposition, or treating `unmeasurable` as success blocks G8-to-G9.

### Alternatives Rejected

- Treating G6 as though final code review already occurred was rejected because
  readiness and review result are different facts.
- Combining implementation acceptance and deployment authorization was rejected
  because production action has distinct operational and security risk.
- Omitting value evidence when it is not yet due was rejected because a governed
  future trigger is still required.
- Closing G9 through a `G9 -> G10` operation was rejected because G9 is terminal.

### Consequences, Enforcement, And Migration

- Aggregate review, remediation, final test/UAT, deployment, value, and as-built
  artifacts require canonical paths and registry bindings.
- Combined C1/C2 documents may combine form but may not omit an evidence class,
  approval, status, or byte binding.
- Migration preserves completed phase evidence and separately reconciles
  aggregate boundaries; it cannot relabel a historical transition without an
  append-only mapping event.
- This decision partially supersedes incomplete G6/value-review placement in the
  Phase Loop and Verification-First records.

## Cross-Decision Invariants

The following invariants apply across all decisions in this record:

1. Plan endorsement, artifact review, implementation acceptance, deployment
   approval, release publication, and tag publication are distinct decisions.
2. A manifest summary never creates authority absent its durable event.
3. A transition validates immutable evidence before it writes any active file.
4. Artifact status and value-review disposition are separate vocabularies.
5. Gate and checkpoint state are separate axes.
6. A combined artifact may reduce document count but never omit evidence.
7. Migration preserves unknowns and project-owned bytes; it does not manufacture
   conformance.
8. The registry cannot silently defeat constitution or Accepted decision text;
   coherence conflicts fail validation.
9. No acceptance can be attributed to an AI or unbound role.
10. Release identity changes only after verified implementation and explicit
    publication approval.

## Relationship To Earlier Decision Records

This section identifies the exact earlier clauses affected. It does not edit or
erase their historical text. Until ratification, each item is only a proposed
partial supersession.

### `phase-loop-decision-record.md`

- Decision item 2, specifically "Closing G5 is the checkpoint `G5.0`", is
  superseded by D-004. `G5.0` accepts the phase plan inside major gate G5 and does
  not close or leave G5.
- Decision item 3 remains active for checkpoint order, phase-ID semantics, and
  aggregate G5-to-G6 intent, but its abbreviated phase-exit and G6-entry
  conditions are superseded by D-005 and D-018.
- Decision item 5's "Six-artifact phase set" is superseded by D-005's complete
  canonical evidence set. The six named planning/learnings artifacts remain
  members of that larger set.
- Decision item 6 remains active for distinct checkpoint/transition events, but
  its event and manifest contract is superseded where D-004, D-011, D-012,
  D-016, and D-018 impose schema-2 state and evidence bindings.
- Consequence "Existing initialized projects remain valid: phase-loop manifest
  fields are optional" is superseded by D-013. Historical projects remain pinned
  or explicitly migrate; fields are not permanently optional in strict schema 2.
- Consequence "The G0-G9 enumeration and all other gate criteria are unchanged"
  is superseded only for G5-G9 criteria changed by D-004, D-005, D-006, D-017,
  and D-018.

### `documentation-structure-decision-record.md`

- Consequences 3 through 5 remain active for Technique Neutrality, textual
  supporting design artifacts, typed relationships, and DAG discipline. D-009
  supersedes any implication that every typed reference targets a supporting
  artifact: each edge now declares `canonical_artifact` or `supporting_design`.
- Consequence 5's unspecified "canonical supporting-artifact location" is fixed
  by D-009 as `docs/project/design/`; a competing `docs/project/supporting/`
  location is invalid for 0.5.
- Consequence 7's statement that the gate-log template houses the canonical event
  schema is narrowed by D-011 and D-016: the lifecycle registry owns the
  mechanically determinate event vocabulary and required bindings; the template
  remains the human-facing rendered event form. Append-only history remains
  active.
- Baseline consequence "No migration" is superseded by D-013's explicit,
  preservation-first migration contract.
- Scaffold consequences remain active for project-wide canonical structure but
  are refined by D-014: phase-specific artifacts are created just in time from
  canonical templates.

### `gate-numbering-reconciliation-decision-record.md`

- The G0-G9 enumeration and old-to-current mapping remain active.
- Decision text declaring `gates.md` canonical for gate numbers and criteria is
  narrowed by D-016: the constitution delegates enumeration to the canonical
  lifecycle model, the registry provides its validated machine-readable
  contract, and `gates.md` remains the normative human explanation.
- The statement that enforcement semantics are unchanged is historical; D-004,
  D-005, D-006, D-011, D-012, and D-018 introduce new 0.5 enforcement semantics
  without changing the G0-G9 numbering decision.

### `verification-first-decision-record.md`

- Context, principle, the three verification questions, and the human-approved
  G3 verification-specification keystone remain active.
- Universal-EARS statements in the Context summary, G2 table row, Step 1,
  Consequence 2, Enforcement, and Scope/Sequencing are superseded by D-017 only
  for C1. C2/C3 retain EARS; every class retains observable negative criteria.
- The open question asking whether C1 may use a relaxed criterion form is
  resolved by D-017.
- Consequence 4's phase-exit/value-review language is superseded where D-005 and
  D-018 assign complete canonical evidence, lifecycle ownership, status, and
  disposition requirements.
- The statement that verification evidence uses `tested-by` remains active, with
  D-009 requiring an explicit target kind.

## Implementation And Verification Obligations

Ratification authorizes downstream work only within the approved remediation
plan. Implementation must prove at minimum:

- registry internal validity and deterministic generated contract;
- stable negative-test rule IDs and caller-visible exit statuses;
- Bash 3.2/BSD and Ubuntu behavior;
- exact Git-object evidence validation and status-only transformation;
- full phase and G6-G9 lifecycle happy paths plus missing, stale, duplicate,
  superseded, dirty, untracked, residual-risk, and rollback failures;
- fresh initialization, just-in-time phase scaffold, installed-copy operation,
  non-destructive backfill, and version-bound migration;
- C1 observable criteria and C2/C3 EARS enforcement;
- canonical/reference target-kind validation; and
- release identity coherence without creating or publishing tags.

## Human Ratification

The plan endorsement dated 2026-07-10 is not this ratification. A named human
must review this exact file revision and complete a durable record containing:

```text
Decision record: docs/methodology/design/operational-coherence-decision-record.md
Decision: Accepted | Rejected | Accepted with recorded amendment
Approver: <named human>
Decision date: <YYYY-MM-DD>
Reviewed Git revision: <non-placeholder revision>
Reviewed Git blob OID: <blob OID for this file at that revision>
Checked statement: <what D-001-D-006 and D-008-D-018 were reviewed and accepted>
Amendments or constraints: <none or explicit list>
Risk disposition: <explicit>
Approval record: <durable event or ratification record path/id>
```

The named human supplies the decision fields above. Ratification closeout then
computes and records the reviewed SHA-256 digest, D-012
`new_acceptance_status_only` category, deterministic resulting Git blob OID,
and resulting SHA-256 digest. Those computed values are evidence derived from
the exact reviewed revision; they are not additional discretionary answers.

Only an `Accepted` decision over the exact reviewed bytes permits this record's
status to be changed in a later, status-only ratification change and permits
WP-02 through WP-11 to treat these decisions as normative design authority.
