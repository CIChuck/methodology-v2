# Enforcement Contract

Status: Reusable Standard
Authority: `docs/methodology/constitution/gendev.md`

## Purpose

This guide defines what a conforming GenDev environment must mechanically prevent, mechanically
verify, or explicitly attest. It converts gate boundaries from policy statements into enforceable
or auditable development-environment properties.

Enforcement does not displace human governance. It executes or checks decisions humans have already
made and recorded. A human approves a gate once; the enforcement layer applies that recorded
decision thereafter instead of requiring humans to manually re-notice every violation.

Two facts motivate prevention over detection:

- premature artifacts anchor decisions, even when rejected later;
- human-only policing does not scale across parallel agent branches and repeated implementation
  attempts.

## Platform Neutrality

The contract is normative and platform-free. Bindings are non-normative and replaceable.

This guide names no CI vendor and no hosting platform. It defines requirements. A binding is a
concrete implementation of those requirements on a specific platform. Any binding that implements
the requirements conforms identically. Bindings must not add methodology requirements; they
implement the contract.

## Version-Control Assumptions

The methodology assumes a version control system with:

- immutable revision identifiers;
- diffable history;
- branch isolation.

Git is the default implementation. Any system with equivalent properties conforms. No hosting
platform or CI vendor is assumed.

## Conformance Classes

A project declares one of two enforcement classes in `docs/project/project.yaml`:

```text
enforced:  requirements are implemented mechanically through hooks, pipelines, merge protection,
           policy checks, or equivalent binding mechanisms.
attested:  named humans perform the checks on a defined cadence and record attestation entries in
           the gate log.
```

Rules:

- The class is declared in the project control plane.
- Gate-log entries should state the relevant enforcement class.
- A project may run attested for specific requirements, with each exception documented in the
  enforcement block.
- Attested conformance is legitimate at baseline. It is the documented fallback for environments
  without mature mechanical bindings.
- An attested project should migrate requirements to enforced as tooling permits.

## Relationship To Blast-Radius Class

Enforcement class and blast-radius class are related but not interchangeable.

```text
enforcement.class
  says whether methodology controls are mechanical or human-attested.

scaling.blast_radius_class
  says how much lifecycle ceremony, review depth, evidence sampling, and override discipline the
  project needs.
```

A C1 project may still use `class: attested` when the risk is low and the team records the required
checks. A C3 project should prefer mechanical enforcement where practical and should justify any
attested-only control that protects production, regulated data, irreversible actions, or agentic
runtime behavior. Lower blast radius never permits bypassing recorded gate movement, approval
evidence, or override records.

## Normative Requirements

The key words MUST, MUST NOT, SHOULD, and MAY are to be interpreted as described in RFC 2119.

```text
EC-1  Gate-state write protection.
      While current_gate is below G5, changes to implementation paths MUST be rejected or
      explicitly attested. Implementation paths are defined in the project enforcement block.
      Methodology docs and scripts are excluded by default unless the project states otherwise.

EC-2  Approval-coupled gate movement.
      A change to current_gate MUST be accompanied, in the same commit, merge, or recorded
      transition, by a corresponding entry in docs/project/approvals/gate-log.md.

EC-3  Checker on every change.
      The methodology checker MUST run on every commit or merge to the protected branch when a
      mechanical binding exists. In attested mode, the attester MUST run or review checker output
      at the declared cadence.

EC-4  Gate value validation.
      Gate values outside the defined set, G0 through G9, MUST be treated as errors once a binding
      can enforce them. During transition, they MUST at least be visible as checker findings.

EC-5  Staleness blocking.
      Where provenance headers are in use, an artifact whose pinned upstream revision is out of
      date MUST be flagged stale, and a stale artifact cited as evidence for a gate transition MUST
      block that gate.

EC-6  Task traceability.
      Implementation changes SHOULD reference a tactical-plan task identifier in the commit
      message, pull request, merge description, or review evidence. Projects with mature bindings
      MAY make this a hard rejection rule on protected branches.

EC-7  Executable evidence.
      Gates G6 and above SHOULD cite executable evidence, such as test runs, pipeline run
      identifiers, command transcripts, or equivalent verification records, rather than narrative
      claims alone.

EC-8  Provenance verification.
      Authority and evidence artifacts MUST carry provenance headers. The enforcement layer SHOULD
      verify their presence and MAY block when the project has adopted enforced mode.

EC-9  Branch isolation for agent work.
      Agent-generated implementation work SHOULD occur on branches isolated from the protected
      branch and merge only through the checks or attestations above. Sub-agent output remains
      advisory until accepted.

EC-10 Enforcement is versioned.
      Enforcement configuration, binding paths, protected paths, and the enforcement block itself
      MUST live in version control. Changes to enforcement configuration require review like any
      other authority change.
```

## Phase Loop Enforcement Disposition

The interior phase loop (the `G5.x` checkpoints defined in `gates.md`) ships in
the attested conformance class. Checkpoint closure discipline — the artifact
status change to `Accepted`, the manifest `phase_position` advance, and the
corresponding `phase_checkpoint` or `phase_transition` event landing in the same
commit — is attested, not mechanically enforced, in this release.

A candidate enforced rule is recorded for a future release: implementation
paths for phase N+1 are blocked until phase N's `G5.<id>.4` event exists. It is
not enforced now; projects attest phase progression as part of the normal
attested conformance procedure.

## Failure Semantics

- Errors block when a mechanical binding is present.
- Warnings are recorded and visible.
- Attested findings must be recorded according to the declared cadence.
- Emergency override must be possible.
- An override must leave a durable record: who overrode, why, which requirements were bypassed,
  and when normal enforcement resumed.
- Override records belong in `docs/project/approvals/gate-log.md`.
- An override is not an amendment. Authority documents are unchanged by the override, and work
  performed under override must be reconciled afterward like any other deviation.

## Attested Conformance Procedure

For each requirement run in attested mode:

- a named human performs or reviews the check on the declared cadence;
- the attestation is recorded as a gate-log entry identifying the EC requirements checked, result,
  and attester;
- the minimum cadence is every gate transition unless the project declares a stricter cadence;
- a missed attestation cadence is a warning;
- a gate transition without required attestation is an error once the project declares that
  attestation requirement binding.

## Reference Binding Expectations

This repository provides a reference binding through:

- `scripts/methodology-guard.sh`;
- `scripts/install-hooks.sh`;
- `.github/workflows/methodology.yml`.

The reference binding provides:

- a local hook or equivalent developer-side check for EC-1, EC-3, and EC-4;
- a CI or protected-branch check for EC-1 through EC-6;
- checker extensions for EC-2, EC-4, EC-5, EC-8, and enforcement block consistency;
- clear installation or activation instructions;
- version-controlled configuration.

The local hook is optional because developer-side hooks can be bypassed. The CI workflow enforces
independently when GitHub Actions is enabled. A project should still declare `class: attested`
until the project team has installed or enabled the binding it intends to rely on.

## Project Manifest Block

Initialized projects should declare enforcement state in `docs/project/project.yaml`:

```yaml
enforcement:
  contract_version: draft
  class: attested
  protected_branch: master
  implementation_paths:
    - TBD
  excluded_paths:
    - docs/
    - scripts/
  binding_paths:
    pre_commit_hook: scripts/install-hooks.sh
    ci_workflow: .github/workflows/methodology.yml
  attestation:
    cadence: every_gate_transition
    required_attester: TBD
  exceptions:
    - requirement: EC-5
      mode: attested
      reason: provenance headers not yet adopted
  override_policy:
    required_approvers: 1
    record_path: docs/project/approvals/gate-log.md
```

`class: attested` is valid at baseline. Projects should change to `class: enforced` only when a
binding actually exists and is active.

## Verification Of The Enforcement Layer

The methodology checker should verify that:

- the enforcement block exists in initialized projects;
- the declared class is `attested` or `enforced`;
- attested mode declares cadence and required attester fields;
- enforced mode declares binding paths;
- override policy records its approval count and record path.

Changes to the enforcement layer itself are reviewed like authority changes. The enforcement layer
is subject to the same review discipline as the rest of the methodology.

## Completion Standard

This contract is working when every initialized project states whether enforcement is mechanical or
attested, every gate transition is readable in that enforcement context, and no document claims a
binding exists before the binding is actually present.
