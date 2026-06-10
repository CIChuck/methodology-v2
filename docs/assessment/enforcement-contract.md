# Enforcement Contract

Status: Reusable Standard (Draft for ratification)
Authority: `docs/methodology/constitution/gendev.md`

## Purpose

This guide defines what a conforming environment must mechanically prevent and verify. It converts
gate boundaries from policy statements into enforced properties of the development environment.

Enforcement does not displace human governance. It executes governance decisions humans have
already made and recorded. A human approves a gate once; the enforcement layer applies that
decision thereafter, instead of requiring a human to re-notice every violation. The human is the
policy author. The enforcement layer is not a governor; it is the recorded will of one.

Two facts motivate prevention over detection:

- Premature artifacts anchor. Once a working implementation exists, review shifts from "what
  should we build" to "what is wrong with this code," and a rejected artifact has still shaped
  the decision space on its way out.
- Volume. A human can stop one premature implementation. No human polices thirty parallel agent
  branches a day. The economics that justify documentation as build authority equally break
  human-only policing.

## Position on Platform Neutrality

The contract is normative and platform-free. Bindings are non-normative and replaceable.

This guide names no CI vendor and no hosting platform. It defines requirements. A binding is a
concrete implementation of those requirements on a specific platform. The repository ships one
reference binding (see below). Any binding that implements the requirements conforms identically.
Bindings must not add requirements; they implement the contract.

## Assumptions

The methodology assumes a version control system providing:

- Immutable revision identifiers
- Diffable history
- Branch isolation

Git is the default implementation. Any system with equivalent properties conforms. No hosting
platform or CI vendor is assumed.

## Conformance Classes

A project declares one of two enforcement classes in `docs/project/project.yaml`:

```text
enforced:  the requirements below are implemented mechanically
           (hooks, pipelines, merge protection).
attested:  named humans perform the checks on a defined cadence and
           record attestation entries in the gate log.
```

Rules:

- The class is declared in the project control plane and inherited by gate-log entries, so every
  approval is readable in its enforcement context.
- A project may run attested for specific requirements only, with each exception documented in
  the enforcement block.
- Attested conformance is legitimate, not deficient. It is the documented fallback for
  environments without pipeline maturity, and it is labeled so that auditors, clients, and future
  maintainers can price it accordingly.
- An attested project should migrate requirements to enforced as tooling permits.

## Normative Requirements

The key words MUST, MUST NOT, SHOULD, and MAY are to be interpreted as described in RFC 2119.

```text
EC-1  Gate-state write protection.
      While current_gate is below G5, changes to implementation paths
      MUST be rejected. Implementation paths are defined in the
      project enforcement block; methodology docs/ and scripts/ are
      excluded by default.

EC-2  Approval-coupled gate movement.
      A change to current_gate MUST be accompanied, in the same commit
      or merge, by a corresponding entry in
      docs/project/approvals/gate-log.md. Gate movement without a
      record MUST be rejected.

EC-3  Checker on every change.
      The methodology checker MUST run on every commit or merge to the
      protected branch. Structural errors MUST block. Warnings MUST be
      visible and MAY block per project policy.

EC-4  Gate value validation.
      Gate values outside the defined set (G0 through G9) MUST be
      treated as errors, not warnings.

EC-5  Staleness blocking.
      Where provenance headers are in use, an artifact whose pinned
      upstream revision is out of date MUST be flagged stale, and a
      stale artifact cited as evidence for a pending gate MUST block
      that gate. Until provenance headers are adopted (A4.1, A6.2),
      this requirement is SHOULD.

EC-6  Task traceability.
      Implementation changes MUST reference a tactical-plan task
      identifier in the commit message or merge description. Changes
      without one MUST be rejected on the protected branch.

EC-7  Executable evidence.
      Gates G6 and above MUST cite executable evidence (test runs,
      pipeline run identifiers, command transcripts) rather than
      narrative claims alone.

EC-8  Provenance verification.
      Authority and evidence artifacts MUST carry provenance headers,
      and the enforcement layer MUST verify their presence. Until
      provenance headers are adopted (A4.1), this requirement is
      SHOULD.

EC-9  Branch isolation for agent work.
      Agent-generated implementation work SHOULD occur on branches
      isolated from the protected branch and merge only through the
      checks above. Sub-agent output remains advisory until accepted,
      per the subagent coordination protocol.

EC-10 Enforcement is versioned.
      The enforcement configuration (hooks, pipeline definitions,
      protected paths, the enforcement block itself) MUST live in
      version control, and changes to it MUST pass through review
      like any other authority change.
```

## Failure Semantics

- Errors block. Warnings are recorded and visible.
- An emergency override MUST be possible. Production incidents outrank ceremony.
- An override MUST leave a record: who overrode, why, which requirements were bypassed, and when
  normal enforcement resumed. The record belongs in the gate log.
- An override is not an amendment. The authority documents are unchanged by it, and any work
  performed under override is reconciled afterward like any other deviation.
- Override entries are telemetry. Override frequency is a reportable metric under the
  measurement layer; a rising override rate is a process signal, not an embarrassment to hide.

## Attested Conformance Procedure

For each requirement run in attested mode:

- A named human performs the check on a defined cadence, at minimum at every gate transition.
- The attestation is recorded as a gate-log entry identifying the requirements checked by EC
  number, the result, and the person attesting.
- A missed attestation cadence is a warning; a gate transition without its attestation is an
  error.

## The Reference Binding (Non-Normative)

The repository provides one binding as a working example, not as a requirement:

- A pre-commit hook (installed by script) implementing EC-1, EC-3, and EC-4 locally.
- A CI workflow implementing EC-1 through EC-6 on changes to the protected branch.
- Checker extensions implementing EC-2, EC-4, and (once provenance lands) EC-5.

A binding for any other platform that implements the same requirements conforms identically.

## Verification of the Enforcement Layer

The checker SHOULD verify that the enforcement block exists in `project.yaml` and that the
declared class has a corresponding mechanism: a pipeline definition present for enforced mode, an
attestation cadence defined for attested mode. Changes to the enforcement layer itself are
reviewed like any authority change (EC-10). The watcher is watched by the same review discipline
as everything else.

## Relationship to the AAF

This guide is GenDev's adoption of the principle that autonomy boundaries must be technically
enforced, not merely policy-documented (Cloud Security Alliance, adopted as a foundational
principle of the Agentic Architecture Framework). The conformance classes map to the AAF's
distinction between meaningful and nominal oversight: enforced conformance makes a gate boundary
effective rather than declared, and attested conformance states honestly which kind it is.
