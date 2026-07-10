# Decision Record: No Undeclared Abstractions Authority Boundary

Date: 2026-07-10
Status: Ready for Approval
Ratification method: Exact-revision named-human approval
Owner: GenDev maintainers
Target release: `0.5.0-operational-coherence`
Decision ID: D-007
Drafting authority: Approved operational-coherence remediation plan

## Authority And Effect

Chuck Russell approved drafting D-007 without amendment on 2026-07-10. That
approval does not ratify this text. Until the human-ratification block is
completed, existing constitutional and directive language remains controlling.
WP-03 must amend the constitution and active guidance explicitly after
ratification; this record does not silently change them.

## Context

No Undeclared Abstractions (NAA) exists to stop implementation from inventing
product concepts, shared contracts, architectural boundaries, or governance
behavior that approved authority never contemplated. Applied literally to every
private symbol, however, it also prohibits routine implementation details that
an approved tactical task necessarily leaves to construction: local helpers,
adapters, narrow internal value types, and test doubles. That reading creates
documentation churn without improving product authority and makes ordinary
refactoring appear to require an architecture amendment.

The boundary must preserve NAA's protection against semantic and architectural
scope expansion while allowing implementation-local detail that adds no new
authority-bearing concept.

## D-007: Decision

Retain the name **No Undeclared Abstractions**. Apply its declaration requirement
to **authority-bearing abstractions**:

1. domain or business entities, concepts, rules, and invariants;
2. persisted, shared, externally exchanged, or security-relevant data and fields;
3. public, externally consumed, or cross-component interfaces and contracts;
4. architectural components, services, stores, queues, processes, deployment
   units, and ownership boundaries;
5. trust, identity, authentication, authorization, audit, privacy, retention,
   safety, and lifecycle boundaries; and
6. any abstraction that changes approved scope, observable behavior, acceptance
   criteria, architecture, security/governance posture, or phase boundaries.

Such an abstraction must already be declared in applicable accepted authority or
must enter through the amendment/regression process before implementation.

An approved tactical task may introduce implementation-local abstractions when
all of these conditions hold:

- the abstraction is private to the implementing component or test scope;
- it adds no product/domain concept or invariant;
- it adds no persisted/shared state or externally exchanged field;
- it adds no public or cross-component contract;
- it adds no component, ownership, trust, identity, authorization, audit, or
  lifecycle boundary;
- it does not weaken or extend approved behavior, security, governance, or
  acceptance criteria; and
- it is a proportionate means to complete the task under YAGNI, KISS, DRY, SRP,
  and Least Astonishment.

Typical allowed categories are private helpers, local adapters, internal value
types, framework-generated types, test fixtures, fakes, mocks, and narrowly
scoped test utilities. A category label is not an automatic exemption: its
actual semantics determine whether it crosses the authority boundary.

## Decision Procedure

For any new abstraction, answer these questions in order:

1. Does it introduce or rename a product/domain concept or rule?
2. Is its state persisted, shared between components, externally exchanged, or
   security relevant?
3. Is its interface public, externally consumed, or cross-component?
4. Does it create or move a component, deployment, ownership, trust, identity,
   authorization, audit, privacy, safety, or lifecycle boundary?
5. Does it change approved observable behavior, scope, acceptance criteria,
   architecture, governance, security, or phase boundaries?

If any answer is yes, the abstraction is authority-bearing and must be declared
or amended before implementation. If all answers are no, the tactical task may
authorize it as implementation-local, subject to normal code review and
verification.

When the answer is genuinely ambiguous, treat the abstraction as authority-
bearing until a human resolves the classification. An implementation agent may
not self-declare a disputed boundary harmless merely to continue construction.

## Scenario Classification

| Scenario | Classification | Required handling |
| --- | --- | --- |
| Add a private function that normalizes an already-approved input before calling an existing component API | Allowed local detail | Cite the tactical task; test it; no authority amendment if behavior is unchanged. |
| Extract duplicated private parsing logic into a module-private helper | Allowed local detail | Verify identical behavior and keep it private. |
| Add a local adapter between an approved component and an approved third-party client | Allowed only when local | No new public contract, state, policy, retry semantics, or trust boundary; otherwise declare it. |
| Create an immutable internal value type for an already-approved field | Allowed only when semantic-neutral | Validation and serialization must match accepted authority; a new invariant makes it authority-bearing. |
| Generate framework request/response types from an accepted public schema | Allowed generated detail | Generated output must remain traceable to the accepted schema and must not add fields. |
| Add test fixtures, fakes, or mocks for accepted behavior | Allowed test detail | They cannot become production contracts or conceal unsupported behavior. |
| Add a new database column, cache field, event attribute, or serialized property | Authority-bearing | Amend the owning data/security/architecture authority before implementation. |
| Add a new domain entity, state, transition, invariant, or business rule | Authority-bearing | Amend PRD/architecture/governance as applicable. |
| Add an endpoint, event topic, plugin hook, command option, or cross-package interface | Authority-bearing | Declare the public/cross-component contract and trace verification. |
| Split a component into a service or add a queue/store/process | Authority-bearing | Amend architecture and applicable operations/security authority. |
| Add authentication, authorization, identity mapping, audit, retention, encryption, or secret handling | Authority-bearing | Amend governance/security and architecture before construction. |
| Add retries, fallback, or error swallowing that changes observable guarantees | Authority-bearing | Amend requirements/architecture and negative acceptance criteria. |
| Rename a public concept while preserving code behavior | Authority-bearing | Names in external/shared contracts carry meaning and traceability. |
| Refactor private code across packages so it becomes shared | Review boundary | If the shared API is cross-component or creates ownership, declare it; otherwise document the tactical rationale and review. |
| Introduce a feature flag | Normally authority-bearing | It creates state/lifecycle and often release or security behavior; declare ownership and retirement. |
| Introduce a local compile-time constant | Allowed only when non-semantic | A business threshold, policy value, security limit, or externally meaningful default is authority-bearing. |

## Alternatives Rejected

### Apply NAA To Every Named Code Abstraction

Rejected because approved tactical plans cannot and should not enumerate every
private implementation symbol. The result would be performative documentation,
stale authority, and frequent unnecessary amendments without protecting product
scope.

### Remove NAA Entirely

Rejected because implementation agents could then introduce domain concepts,
interfaces, persisted fields, services, or security behavior without human-
approved authority.

### Exempt Categories By Name

Rejected because a type called a helper or adapter can still introduce a public
contract, new policy, shared state, or trust boundary. Classification depends on
semantics and reach, not the chosen label.

### Let The Implementing Agent Decide Every Ambiguous Case

Rejected because the rule exists specifically to preserve human authority over
scope, architecture, and governance. Ambiguous boundary changes require
escalation, not unilateral implementation.

## Consequences

### Positive

- NAA remains a meaningful barrier against product, architectural, and security
  invention.
- Tactical plans can authorize normal implementation detail without attempting
  to predict every private symbol.
- Review can focus on semantic reach, state, contracts, ownership, and trust
  rather than name-counting.
- Test infrastructure and behavior-preserving refactors stop generating false
  NAA violations.

### Costs And Risks

- Reviewers must exercise judgment at private/shared and local/cross-component
  boundaries.
- A seemingly local adapter can conceal policy, retry, caching, or security
  behavior and therefore needs scenario-based review.
- Teams must escalate genuinely ambiguous cases rather than rationalizing them
  after implementation.

## Enforcement Impact

Mechanically determinate checks should detect undeclared public interfaces,
persisted/shared schema fields, component/deployment boundaries, canonical
security/governance structures, and traceability gaps where the repository has a
declared source model. Judgment-based checks should inspect whether private code
introduces a new concept, invariant, policy, or effective boundary.

Construction directives must state both sides of the boundary:

- do not introduce authority-bearing abstractions absent accepted authority; and
- implementation-local abstractions are allowed only under an approved tactical
  task and the conditions in this record.

A checker must not equate every new class, function, type, or test fixture with
an NAA violation. Code review must still flag an allegedly private abstraction
whose behavior or reach crosses the boundary.

## Relationship To Current Authority

Ratification would partially supersede the following exact active clauses while
preserving their anti-expansion purpose:

| Current source and clause | Disposition after ratification |
| --- | --- |
| `docs/methodology/constitution/gendev.md`, Code Quality Principles, NAA definition: "Every entity, field, relationship, class, and interface the build introduces already appears in an approved upstream authority" | Superseded as a universal symbol-level rule. The requirement applies to the authority-bearing categories in this record; qualifying implementation-local detail may be introduced by an approved tactical task. |
| Same section: the Accepted Domain Model is "the complete set of entities, fields, relationships, classes, and interfaces the build may introduce" | Partially superseded. It remains closed for domain, persisted/shared, public/cross-component, architectural, ownership, trust, security, governance, and lifecycle abstractions, but not for purely local implementation detail. |
| Same section: "The canonical noun set for NAA is: entities, fields, relationships, classes, and interfaces" | Superseded. Classification is based on semantic authority and reach, not a universal noun list. |
| `docs/methodology/templates/architecture-template.md`, Domain Model instruction requiring every later "entity, field, relationship, class, and interface" to be named there | Partially superseded on the same authority-bearing/local boundary. The model stays closed for authority-bearing domain and design elements. |
| `docs/methodology/templates/phase-construction-directive-template.md`, `[NAA]` prohibition on "any entity, field, relationship, class, or interface" absent from the Domain Model | Superseded by the two-sided construction rule in this record: prohibit undeclared authority-bearing abstractions while allowing qualifying local detail. |
| `docs/methodology/guides/subagent-coordination-protocol.md`, NAA review question comparing every entity, field, relationship, class, and interface to the Domain Model | Superseded by the decision procedure and scenario classification in this record. |

The constitutional maxim that a build implements approved authority and does
not silently expand it remains active. So do the requirements to restate NAA in
every construction directive, review it independently, and send an actual
authority expansion upstream as a named amendment. Until this record is
ratified, none of the partial supersessions above is effective.

## Constitutional Impact

After ratification, WP-03 must revise the constitution's NAA wording to:

1. preserve the rule name and its prohibition on undeclared authority-bearing
   abstractions;
2. enumerate the protected semantic categories from this record;
3. permit implementation-local detail under an accepted tactical task;
4. require escalation for ambiguity; and
5. retain amendment/regression requirements when a boundary is crossed.

The amendment must not weaken the constitution's documentation-first,
traceability, Technique Neutrality, security/governance, or human-approval
principles.

## Compatibility And Migration

- Existing accepted authority and implementation remain governed by their pinned
  methodology version until explicit migration.
- Migration does not retroactively mark private helpers, local test types, or
  framework-generated types nonconforming solely because older directives used
  broader NAA wording.
- Existing public/shared/persisted/security-relevant abstractions do not become
  authorized merely because they already exist. Migration inventories them and
  records `declared`, `requires_amendment`, `legacy_unresolved`, or a defensible
  equivalent.
- An active phase may complete under its pinned directive, or it may be amended
  and reissued under 0.5. The two interpretations must not be mixed within one
  phase without an explicit amendment.
- No migration process may infer missing architectural or governance approval
  from source code alone.

## Verification Obligations

The implementation must include positive, negative, and boundary tests covering
every scenario class above. At minimum, review fixtures must prove:

- private helpers, local adapters, test doubles, and generated types are not
  rejected when all local-detail conditions hold;
- persisted fields, public/cross-component interfaces, components, domain
  entities, and security/lifecycle boundaries are rejected when undeclared;
- a local-looking helper that adds policy or externally observable behavior is
  classified as authority-bearing;
- ambiguity produces an escalation/block result rather than silent acceptance;
- old pinned directives remain interpretable without retroactive violation; and
- new 0.5 directives consistently use the narrowed boundary.

## Human Ratification

The plan endorsement dated 2026-07-10 is not this ratification. A named human
must review this exact file revision and complete a durable record containing:

```text
Decision record: docs/methodology/design/naa-authority-boundary-decision-record.md
Decision: Accepted | Rejected | Accepted with recorded amendment
Approver: <named human>
Decision date: <YYYY-MM-DD>
Reviewed Git revision: <non-placeholder revision>
Reviewed Git blob OID: <blob OID for this file at that revision>
Checked statement: <what D-007 boundary and scenarios were reviewed and accepted>
Amendments or constraints: <none or explicit list>
Risk disposition: <explicit>
Approval record: <durable event or ratification record path/id>
```

The named human supplies the decision fields above. Ratification closeout then
computes and records the reviewed SHA-256 digest, D-012
`new_acceptance_status_only` category, deterministic resulting Git blob OID,
and resulting SHA-256 digest. Those values derive from the exact reviewed
revision and are not additional discretionary answers.

Only an `Accepted` decision over the exact reviewed bytes permits this record's
status to be changed in a later, status-only ratification change and permits
downstream normative text to treat D-007 as authority.
