# Decision Record: Documentation Structure and Technique Neutrality

Date: 2026-06-15
Status: Accepted
Owner: Chuck Russell

## Context

An audit of the ratified baseline surfaced a naming defect (slugged filenames,
baked slug cross-references, AGENTS.md unable to point at canonical files).
Working that defect exposed a deeper, unstated principle the methodology has been
following by accident, and several structural rules that should follow from it.
This record states the principle and the rules together, because they are one
coherent statement about how a project's documentation is structured.

## Principle: Technique Neutrality

GenDev governs how work earns authority and how authority is gated, reviewed, and
kept coherent. It does not specify how the work is conceived, modeled, or built.
Method is the authority-and-gate machinery; technique is everything about how a
team designs and constructs. The method must not couple itself to a technology
stack or to a software-engineering approach: object-oriented, data-driven,
event-driven, and yet-uninvented techniques must all be expressible within it.

The blend point is the artifact. A technique's artifacts enter through a fixed
authority-and-reference discipline; because they obey that discipline, the method
can gate and coherence-check them without knowing which technique produced them.

Stated as a maxim: the method does not specify the technique, but the technique
must blend with the method.

The consequences below are derived from this principle and must remain consistent
with it.

## Consequence 1: Canonical Artifact Naming

Per-project artifacts use fixed, role-based filenames identical across all
projects. A filename identifies an artifact's role (vision.md, prd.md,
architecture.md, phase-plan.md), never its project.

- The slug and project name MUST NOT appear in any artifact filename or in any
  cross-reference. Cross-references use fixed canonical paths.
- The slug MAY exist only as a field in docs/project/project.yaml.
- Project identity is carried by location (the docs/project/ tree and the
  repository), by project.yaml, and by a strictly required front-matter field,
  project: <name>, on every per-project artifact. That field MUST be present and
  MUST match project.yaml. It is a checkable provenance claim, not decoration.
- AGENTS.md and other authority pointers reference canonical artifacts by fixed
  full path.

The four currently slugged artifacts are renamed: vision.md, prd.md,
architecture.md, traceability-matrix.md. All 15 slug occurrences in
init-project.sh (4 filenames plus 11 cross-references and echoes) are removed.

## Consequence 2: Documentation Scaffold Is Canonical and Architecture-Independent

The documentation scaffold — the docs/project/ directory tree and the canonical
filenames within it — is fixed and identical for every project regardless of
technology stack or engineering approach.

The code scaffold (src layout, package structure) is architecture-determined. The
method does not prescribe it. The method only records it, through the
technology-stack decision artifact (docs/project/decisions/0001-technology-stack.md)
and the implementation_paths field in project.yaml. This is the seam between the
canonical documentation layer and the technique-specific code layer.

## Consequence 3: Supporting Artifacts via a "See Also" Section

Every canonical gate-artifact template carries a uniform Supporting Artifacts
section. It is empty when a project needs no supporting artifacts and populated
when it does. Presence of supporting artifacts is declared by reference from the
canonical artifact; absence is declared by silence.

This lets technique-specific design artifacts (a data model, an object-interaction
model, a state-transition model, a user-story set, a UX specification) be
first-class authority — authored, reviewed, version-controlled, cited — without
being baked into the canonical set or inflating the host document.

## Consequence 4: The Reference Graph Is a Typed, Acyclic, Depth-Bounded DAG

Supporting-artifact references form a directed acyclic graph rooted at canonical
gate artifacts.

- References point along the authority gradient, from a canonical artifact to its
  supporters. Circular references are forbidden and MUST be flagged.
- References are one level deep by default: supporting artifacts do not themselves
  carry supporting-artifact references. Greater depth is an exception that must be
  declared and justified.
- Each reference carries a relationship type from a bounded, defined vocabulary.
  The type declares the coherence obligation that must hold, which is what makes
  cross-document coherence checkable rather than open-ended. The vocabulary:

  - implements — the source realizes a structure the target defines. Obligation:
    named elements in the source resolve to definitions in the target; the source
    introduces nothing structural the target does not define. (Mechanical where
    elements are named; judgment where prose.)
  - satisfies — the source fulfills requirements the target states. Obligation:
    every requirement in the target is covered by the source. (Mechanical where
    both carry ids; traceability-shaped.)
  - tested-by — the source's correctness is verified by the target test artifact.
    Obligation: the target exists, covers the source's claims, and (where results
    are visible) passes. Points at test/UAT plans and phase exit tests; this is the
    link a testing-gate reviewer or the linter walks to confirm a claim is proven,
    not merely addressed. (Mechanically strong.)
  - constrained-by — the source must not violate limits the target sets.
    Obligation: the source contains nothing the target forbids. (A negative check;
    largely judgment-deferred.)
  - refines — the source adds detail within the target's scope. Obligation: the
    source stays within the target's scope and adds detail without contradicting or
    expanding it. (Mechanical where scope is enumerable.)

  The provenance relationship (which canonical artifact an artifact descends from)
  is handled separately by the existing Derived from header and is not part of the
  see-also vocabulary.

  Each type's checkability marker (mechanical vs. judgment-deferred) feeds the
  linter's error-vs-warning severity: mechanically determinate obligations are
  errors when violated; judgment-requiring obligations are escalated as warnings.

The purpose of this structure is to present proper, coherent context to an AI
coding assistant. The reference graph is the context an agent walks to understand
what it is building; a cycle or a drifted reference is misleading context.

## Consequence 5: Supporting Artifacts Are Form-Disciplined, Content-Free

The method constrains the form of a supporting artifact, not its content or name.

- Form (method-governed): filename is a valid lowercase-kebab identifier (no
  spaces, quotes, or slashes; .md extension); the artifact lives at the canonical
  supporting-artifact location in the locked scaffold; it carries the required
  project front-matter field and its typed relationship to what it supports.
- Content and name (technique-governed): the artifact is whatever the technique
  requires and named whatever the technique calls it, within the form constraint.

Identity is the typed reference edge plus front matter, not the filename. A
supporting artifact may be renamed freely as long as the reference pointing at it
is updated.

The authoritative form of a supporting artifact is textual (markdown). Diagrams
are embedded (for example Mermaid) or referenced from authoritative text, so the
whole artifact stays diff-able and coherence-checkable.

## Consequence 6: Phase Plan Absorbs the Roadmap and Defines the Feature Breakdown

phase-roadmap.md is retired. It overlapped phase-plan.md and its only unique
content was live phase tracking, which the phase plan absorbs.

- init-project.sh stops generating phase-roadmap.md; the roadmap field is removed
  from project.yaml; references point at phase-plan.md.
- The phase-plan template gains a per-phase feature breakdown: one detail block
  per phase stating the features it delivers, the requirements it covers, its
  dependencies on prior phases, and its exit signal. This is the partition made
  concrete (what lands in which phase), distinct from the phase build plan, which
  gives implementation detail (how, tested how).
- The feature breakdown is authoritative but revisable. A phase may, during
  implementation, reveal that its breakdown needs adjustment. Such adjustments are
  recorded through the phase plan's existing Amendments section with a reason, not
  silently overwritten (consistent with D11). Each phase detail block indicates
  whether it has been amended and points at the amendment entry, so the original
  partition and any revision are both legible.

## Consequence 7: Extract the Gate-Log Template

The gate log is the one named artifact with no standalone template; its structure
lives inline in init-project.sh. Extract it to gate-log-template.md.

- The template houses the canonical schema for all gate-log event types
  (gate_transition, phase_checkpoint, phase_transition, traceability_sample,
  amendment, gate_regression, reconciliation, enforcement_attestation,
  enforcement_override).
- init-project.sh renders the gate log from the template instead of carrying the
  inline heredoc.
- The template carries the required project front-matter field and a note that the
  gate log is an append-only running record: no draft-review-accept lifecycle,
  never marked Accepted or Stale, Active for the project's life, corrections are
  new events not edits.
- Benefit beyond consistency: with event schemas in a canonical template rather
  than a shell heredoc, the checker and the coherence linter can validate gate-log
  entries against a declared source — every event block's event_type must match a
  catalog entry and its fields must conform to that entry's shape.

## Enforcement

- Form (Consequence 1 and 5): mechanically determinate, enforced by
  check-methodology.sh as hard errors. Ships with this amendment. Attested
  conformance class now; candidate for enforced gate-binding later.
- Graph (Consequence 4): reference resolution and cycle detection are errors;
  coherence-obligation checks are errors where mechanically determinate and
  warnings (escalated to a human or judge) where they require judgment. These are
  enforced by the documentation coherence linter, a separate project; this
  amendment establishes the rules as normative, the linter becomes their enforcer.

## Rejected Alternatives

- Fold supporting artifacts into existing canonical documents (user stories into
  the PRD, data model into the architecture). Rejected: host documents become
  heavy and the distinct artifact loses independent identity and review.
- Enumerate every supporting artifact type as optional-mandatory in the canonical
  set. Rejected: unbounded, and couples the method to a fixed catalog of
  technique-specific artifacts, violating technique neutrality.
- Impose a canonical naming scheme on supporting artifacts. Rejected: naming a
  supporting artifact type (data-model.md) blesses a technique, violating
  technique neutrality. The method constrains form, not name.
- Keep floating descriptive filenames for canonical artifacts and update AGENTS.md
  per project. Rejected: manual cross-reference sync is the drift this amendment
  prevents.
- Allow a free (non-DAG) reference graph. Rejected: cycles are logically
  incoherent and produce untraceable documentation; the graph must be acyclic to
  be walkable and checkable.

## Consequences for the Baseline

- Constitution gains the Technique Neutrality principle and the rules above.
- init-project.sh: rename the four artifacts, remove all 15 slug occurrences, add
  the project front-matter field to generated artifacts, add the canonical
  supporting-artifact location to the scaffold.
- Every canonical gate template: add the Supporting Artifacts section and the
  required project front-matter field; drop [project-slug] placeholders.
- AGENTS.md: point at canonical files by full path.
- check-methodology.sh: validate the project front-matter field (present and
  matching project.yaml) and supporting-artifact form (identifier, location).
- phase-plan template: add the per-phase feature breakdown; retire
  phase-roadmap.md (init-project.sh stops generating it; remove the roadmap field
  from project.yaml).
- gate-log: extract gate-log-template.md; init-project.sh renders from it.
- Practitioner guide: update to teach canonical naming, the scaffold distinction,
  the supporting-artifact mechanism, and the reference DAG. (In scope from the
  start, not a later sweep.)
- No migration: GenDev is not in production; the standard applies to new inits.

## Verification

- Fresh init produces vision.md, prd.md, architecture.md, traceability-matrix.md;
  no $slug- in init-project.sh; no [project-slug] in templates.
- A fresh project passes the checker, including the new front-matter check.
- An artifact with a missing or mismatched project field is rejected.
- A malformed supporting-artifact filename or location is rejected.
- AGENTS.md names canonical files and those paths exist after init.
- Every canonical template contains a Supporting Artifacts section.
