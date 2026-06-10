# GenDev Methodology Hardening Plan

Status: Draft plan for review  
Prepared: 2026-06-10  
Scope: Hardening the GenDev methodology based on the assessment documents in `docs/assessment/`  
Source assessments:

- `docs/assessment/gendev-methodology-review.md`
- `docs/assessment/enforcement-contract.md`

## 1. Purpose

This plan converts the independent methodology review and draft enforcement contract into a precise,
sequenced hardening roadmap for GenDev.

The goal is not to apply every recommendation mechanically. The goal is to preserve GenDev's core
strength, documentation as durable build authority, while adding the controls needed for a robust
AI-assisted agentic development methodology:

- meaningful human approval;
- independent review;
- enforceable gate boundaries;
- artifact provenance and revision pinning;
- controlled amendment and regression loops;
- measurable process telemetry;
- blast-radius-scaled ceremony;
- cleaner repository, version, and licensing posture.

The assessment documents are advisory until accepted into the methodology. Nothing in
`docs/assessment/` is currently methodology authority unless a later change moves or references it
from `AGENTS.md`, `README.md`, `docs/methodology/constitution/gendev.md`, `docs/methodology/guides/`,
or the project template manifest.

## 2. Current Baseline

The repository currently has these major strengths:

- a reusable constitution in `docs/methodology/constitution/gendev.md`;
- explicit lifecycle gates in `docs/methodology/guides/gates.md`;
- an orchestration layer for short prompts and next-step behavior;
- approval, collaboration, sub-agent, artifact, gate-transition, and production protocols;
- project initialization through `scripts/init-project.sh`;
- structural validation through `scripts/check-methodology.sh`;
- an 18-chapter practitioner guide;
- an assessment folder containing the independent review and draft enforcement contract.

The repository currently has these important gaps:

- approval records do not yet force the approver to state what they checked;
- review independence is not yet codified as a constitutional or template requirement;
- the enforcement contract is not ratified into `docs/methodology/guides/`;
- `project.yaml` has no enforcement class block;
- `gate-log.md` is not yet machine-parseable enough to support enforcement and metrics;
- artifact templates do not yet carry provenance headers or pinned source revisions;
- `stale` is referenced informally in some prose but is not a formal artifact status;
- amendment versus regression is not yet a documented protocol;
- `check-methodology.sh` treats unknown gate/status values too softly in some cases;
- there is no pre-commit or CI reference binding;
- no measurement layer computes gate cycle time, approval latency, drift incidents, or related
  process telemetry;
- blast-radius-scaled ceremony is permitted but not operationalized;
- repository hygiene and licensing are unresolved.

## 3. Hardening Principles

Use these principles when converting the assessment into methodology changes.

### 3.1 Keep GenDev Standalone

The assessment usefully references the Agentic Architecture Framework and the Optimism Tax. GenDev
should learn from those concepts, but its practitioner-facing vocabulary should remain standalone
unless there is a deliberate positioning decision to couple the publications.

Recommended rule:

```text
Use GenDev-native terms in methodology authority. Cite external frameworks as influence where
helpful, but do not require a practitioner to know another framework to operate GenDev.
```

### 3.2 Separate Contract From Binding

The enforcement contract should define what a conforming environment must prevent and verify. A
binding should implement that contract for a specific toolchain.

Recommended rule:

```text
The contract is normative. Shell hooks, GitHub Actions, local scripts, and other tool integrations
are replaceable reference bindings.
```

### 3.3 Do Not Let Enforcement Outrun The Data Model

Some enforcement requirements depend on structured records:

- gate movement enforcement depends on parseable gate-log entries;
- staleness enforcement depends on provenance headers and revision pinning;
- task-traceability enforcement depends on stable tactical task IDs;
- metrics depend on structured gate events.

Recommended rule:

```text
Define the data shape before enforcing it mechanically.
```

### 3.4 Prefer Ratified Minimums Over Broad Aspirations

Each wave should add a small number of enforceable, testable rules rather than broad prose that
cannot be validated.

Recommended rule:

```text
Every hardening change should name its target files, acceptance criteria, and validation path.
```

### 3.5 Preserve The Human As Governor

The human approves product intent, risk, gate movement, and production decisions. Enforcement does
not replace this role. Enforcement executes previously recorded human decisions so humans are not
forced to rediscover violations at runtime.

Recommended rule:

```text
Human judgment defines authority. Enforcement protects authority after it is recorded.
```

## 4. Decision Log Needed Before Ratification

These decisions should be made before moving the assessment content into authoritative methodology
files.

| ID | Decision | Recommendation | Blocks |
| --- | --- | --- | --- |
| D1 | Should GenDev use AAF vocabulary directly? | Use GenDev-native terms; cite AAF as influence only. | Constitution wording, practitioner guide updates. |
| D2 | Is attested conformance available to any project? | Yes at baseline, declared in `project.yaml`; revisit after blast-radius tiering. | Enforcement contract, project template. |
| D3 | Does emergency override require one approver or two? | One approver plus mandatory record at baseline; C3/critical projects may require two later. | Enforcement contract, gate-log schema. |
| D4 | Should metrics be on-demand or persisted? | Compute on demand; append phase-closeout snapshots later. | Metrics script, gate-log schema. |
| D5 | Should provenance be mandatory on all docs or only authority/evidence docs? | Mandatory for authority and evidence artifacts; optional elsewhere. | Templates, checker. |
| D6 | Should methodology versioning happen before or after patch wave? | Tag current state as pre-release baseline; cut 1.0 after hardening waves. | Versioning, release notes. |
| D7 | Should implementation path protection be active before source paths are known? | Allow `implementation_paths` to be `TBD` until G5; checker warns before G5 and errors at G5+. | Enforcement schema, checker. |
| D8 | Should the reference binding initially include GitHub Actions? | Yes, as the first non-normative binding, because this repo already uses GitHub. | CI workflow, README wording. |

## 5. Dependency Model

The assessment's amendments are not independent in practice. Use this dependency order.

```text
Repository/version/licensing hygiene
  -> structured gate log
     -> meaningful approval fields
     -> approval sampling
     -> basic metrics

Artifact provenance and revision pinning
  -> formal stale status
     -> amendment/regression protocol
        -> staleness checker
           -> rework-radius metric

Review independence
  -> context provenance in review reports
     -> reviewer-independent gate evidence

Enforcement contract ratification
  -> project.yaml enforcement block
     -> checker hardening
        -> hook/CI reference binding
           -> enforced conformance validation

Blast-radius classification
  -> scaled ceremony rules
     -> GenDev Lite example
        -> critical-project addenda
```

## 6. Workstream Overview

| Workstream | Purpose | Primary Assessment Inputs |
| --- | --- | --- |
| W0 Baseline release hygiene | Make the current baseline identifiable and legally usable. | Finding 8, Open Question 5. |
| W1 Approval and gate-log structure | Turn approvals into parseable, meaningful records. | A1.1-A1.3, A7.1. |
| W2 Provenance and status model | Add artifact provenance, revision pinning, and `stale`. | A4.1-A4.2, A6.2. |
| W3 Amendment and regression | Define legal mid-flight change loops. | A6.1-A6.4. |
| W4 Review independence | Break the self-attestation loop. | A2.1-A2.3. |
| W5 Enforcement contract | Ratify the contract and add conformance classes. | A3.4-A3.6, enforcement contract. |
| W6 Checker and reference binding | Make the contract mechanically real. | A3.1-A3.3, EC-1 through EC-10. |
| W7 Measurement layer | Let GenDev argue from records, not assertions. | A7.1-A7.5. |
| W8 Blast-radius scaling | Make GenDev appropriately light or strict by exposure. | A5.1-A5.3. |
| W9 Practitioner guide alignment | Teach the hardened methodology without burying novices. | All accepted hardening changes. |

## 7. Wave Plan

### Wave 0: Baseline Hygiene And Release Marker

Purpose: make the current methodology baseline identifiable, clean enough to distribute, and ready
for controlled hardening.

Assessment drivers:

- Finding 8 repository hygiene;
- Finding 8 licensing;
- Open Question 5 version timing.

Target files:

- `.gitignore`
- root `LICENSE`
- `LICENSE-MIT`
- `LICENSE-CC-BY-4.0`
- `README.md`
- `docs/methodology/constitution/gendev.md`
- `docs/project-template/project.yaml`
- any committed `.DS_Store` files
- optional release notes file, if added

Tasks:

1. Remove committed `.DS_Store` files.
2. Add `.DS_Store` to `.gitignore`.
3. Decide whether `main.py`, `pyproject.toml`, and `.python-version` are intentional.
4. If Python scaffolding is not intentional, remove it in a dedicated cleanup commit.
5. Add licensing split:
   - documentation under CC BY 4.0;
   - scripts under MIT.
6. Add root README licensing section.
7. Add one-line license notice to `docs/methodology/constitution/gendev.md`.
8. Add a methodology version policy:
   - tag current state as pre-release baseline;
   - reserve `1.0.0` for the hardened methodology.
9. Decide whether `methodology_version: baseline` becomes a semantic version or a named release.

Acceptance criteria:

- no `.DS_Store` files are tracked;
- license files exist and match README;
- scripts and docs have an explicit licensing model;
- `project.yaml` template has an unambiguous methodology version field;
- repository status is clean after the change;
- `./scripts/check-methodology.sh` passes.

Validation:

```bash
git ls-files '*DS_Store'
./scripts/check-methodology.sh
```

Risks:

- Removing Python scaffolding may break assumptions not visible in methodology docs.
- License decisions should be confirmed before publishing a formal release.

### Wave 1: Structured Gate Log And Meaningful Approval

Purpose: make gate approvals explicit, parseable, auditable, and harder to rubber-stamp.

Assessment drivers:

- A1.1 add `Checked`;
- A1.2 evidence sampling;
- A1.3 meaningful oversight;
- A7.1 structured gate log.

Target files:

- `docs/methodology/guides/human-approval-protocol.md`
- `docs/methodology/guides/gate-transition-protocol.md`
- `docs/project-template/approvals/gate-log.md`
- `docs/project-template/project.yaml`
- `docs/practitioner-guide/06-gates-and-artifacts.md`
- `docs/practitioner-guide/07-approvals-and-risk.md`
- `docs/practitioner-guide/16-checklists.md`
- `docs/practitioner-guide/18-glossary.md`
- `scripts/check-methodology.sh`

Design decisions:

- Use fenced YAML blocks inside Markdown gate-log entries.
- Keep human-readable prose after the structured block.
- Make `checked` required for standard approval records.
- Make `checked` optional for minimal draft movement.
- Add `sampled_traceability_rows` as optional until G7/G9, then required per sampling policy.

Proposed gate-log event shape:

````markdown
## Gate Event: G1 -> G2

```yaml
event_type: gate_transition
from_gate: G1
to_gate: G2
decision: approved
decided_by: TBD
decided_on: YYYY-MM-DD
enforcement_class: attested
artifact_status: Accepted
evidence:
  - path: docs/project/vision/[project-slug]-vision.md
    revision: TBD
checked: "TBD: one substantive statement from the approver."
known_risks_accepted:
  - risk: TBD
    rationale: TBD
open_questions_carried_forward:
  - question: TBD
    owner: TBD
    target_gate: G2
conditions:
  - TBD
next_role: prd-agent
next_artifact: docs/project/prd/[project-slug]-prd.md
manifest_updated: true
```
````

Proposed attestation event shape:

````markdown
## Enforcement Attestation

```yaml
event_type: enforcement_attestation
gate: G5
attested_by: TBD
attested_on: YYYY-MM-DD
requirements_checked:
  - EC-1
  - EC-2
result: passed
exceptions:
  - requirement: EC-6
    reason: "Task IDs not yet adopted for this phase."
```
````

Proposed override event shape:

````markdown
## Enforcement Override

```yaml
event_type: enforcement_override
gate: G8
approved_by: TBD
approved_on: YYYY-MM-DD
requirements_bypassed:
  - EC-3
reason: TBD
incident_or_emergency: TBD
normal_enforcement_resumed_on: TBD
reconciliation_required: true
```
````

Tasks:

1. Add `Checked:` to the standard approval record.
2. Define meaningful approval:
   - approver can explain the artifact;
   - approver can identify principal risks;
   - approver could credibly stop the work.
3. Add evidence sampling rule:
   - once per phase at minimum;
   - sample one traceability row end to end;
   - discrepancy blocks phase close-out until explained or remediated.
4. Replace the project-template gate log with structured starter records.
5. Teach `check-methodology.sh` to detect structured event blocks.
6. Keep old prose records valid during migration, but warn that they are legacy.

Acceptance criteria:

- gate-log template contains structured YAML examples;
- approval protocol defines `checked`;
- gate transition protocol references structured records;
- checker can identify at least one gate transition event in an initialized project;
- practitioner guide explains the new approval fields without overwhelming Chapter 7.

Validation:

```bash
./scripts/init-project.sh "Approval Log Test"
./scripts/check-methodology.sh
```

Risks:

- A schema that is too complex will discourage use.
- YAML-in-Markdown parsing in shell can become brittle; keep the first schema shallow.

### Wave 2: Artifact Provenance, Revision Pinning, And Status Model

Purpose: make artifact authority falsifiable by recording who produced each artifact, from what
inputs, and at which revisions.

Assessment drivers:

- A4.1 provenance header;
- A4.2 Rule 6 hardening;
- A6.2 `stale` status;
- EC-5 staleness blocking;
- EC-8 provenance verification.

Target files:

- `docs/methodology/constitution/gendev.md`
- all authority/evidence templates in `docs/methodology/templates/`
- `docs/methodology/guides/human-approval-protocol.md`
- `docs/methodology/guides/gates.md`
- `docs/methodology/guides/artifact-collaboration-protocol.md`
- `docs/project-template/project.yaml`
- `scripts/check-methodology.sh`
- practitioner guide chapters 6, 7, 10, 17, and 18

Artifacts requiring provenance:

- vision;
- PRD;
- architecture;
- governance/security specification;
- ADRs;
- phase build plan;
- tactical implementation plan;
- test/UAT plan;
- construction directive;
- code review report;
- remediation summary;
- traceability matrix;
- deployment readiness/runbook artifacts;
- as-built close-out;
- value review, once added.

Recommended provenance header:

```text
Produced by: TBD
Produced on: YYYY-MM-DD
Produced with: human | agent | human-agent collaboration
Agent identity: TBD model/version/session, or N/A
Derived from:
  - path: docs/project/vision/[project-slug]-vision.md
    revision: TBD
  - path: docs/project/prd/[project-slug]-prd.md
    revision: TBD
Status: Draft
```

Status model:

```text
Draft
Ready for Review
Ready for Approval
Accepted
Stale
Superseded
Complete
```

Definitions:

- `Stale`: an upstream authority this artifact derives from has changed since the pinned revision;
  the artifact requires reconciliation review before it can support a gate transition.
- `Superseded`: the artifact has been replaced by a newer accepted artifact and should no longer
  govern.
- `Complete`: the artifact records evidence or close-out rather than planning authority.

Tasks:

1. Add provenance principle to constitution.
2. Make construction directives mandatory controlled artifacts.
3. Replace Rule 6 "should be saved or reproducible" with "must be preserved and bound to the
   resulting change."
4. Add provenance headers to templates.
5. Add `Stale` to artifact status values.
6. Add template guidance for `Derived from` revision pinning.
7. Teach checker to warn when authority/evidence artifacts lack provenance.
8. Delay hard staleness enforcement until the amendment protocol and parser are in place.

Acceptance criteria:

- all authority/evidence templates include provenance headers;
- status values are consistent across constitution, guides, templates, and practitioner guide;
- checker emits warnings for missing provenance in initialized projects;
- construction directives are defined as mandatory preserved artifacts;
- no artifact template still implies large build prompts are optional to preserve.

Validation:

```bash
./scripts/check-methodology.sh
rg -n "Large implementation prompts should|Status: Draft|Status:" docs/methodology
```

Risks:

- Revision pinning is only meaningful after a VCS revision exists; draft artifacts may initially use
  `TBD`.
- Provenance headers can become noisy if agents overfill them with session detail. Keep the fields
  bounded.

### Wave 3: Amendment And Regression Protocol

Purpose: define a controlled path for mid-flight discovery without forcing every change to replay
the full gate chain.

Assessment drivers:

- A6.1 new amendment/regression protocol;
- A6.3 computed staleness;
- A6.4 constitutional amendment section.

Target files:

- new `docs/methodology/guides/amendment-and-regression-protocol.md`
- `docs/methodology/constitution/gendev.md`
- `docs/methodology/guides/gates.md`
- `docs/methodology/guides/gate-transition-protocol.md`
- `docs/methodology/guides/artifact-collaboration-protocol.md`
- `docs/project-template/approvals/gate-log.md`
- `docs/project-template/project.yaml`
- `scripts/check-methodology.sh`
- practitioner guide chapters 5, 6, 7, 9, 10, 17, and 18

Core definitions:

- Amendment: a lower-gate artifact changes while the current project gate holds.
- Regression: the current project gate formally moves backward because the change invalidates gate
  entry conditions.
- Editorial amendment: no semantic change; no re-approval.
- Additive-within-scope amendment: adds detail without changing boundaries; lightweight approval.
- Structural amendment: changes scope, security behavior, architecture, acceptance criteria, or
  deployment risk; full re-approval of affected authority and downstream reconciliation.

Dirty subtree model:

```text
amended artifact
  -> artifacts derived from it
     -> traceability rows citing it
        -> plans, tests, reviews, or evidence affected by the change
```

Tasks:

1. Add constitutional principle:
   - authority may be amended;
   - amendment cost scales with blast radius;
   - unamended stale authority is a methodology violation, not permission for agents to infer.
2. Create guide with:
   - amendment classes;
   - regression criteria;
   - gate-log record shapes;
   - downstream reconciliation rules;
   - when `Stale` is applied;
   - when `Superseded` is applied.
3. Add amendment event schema to gate log.
4. Add project manifest fields for active amendments.
5. Teach agents how to ask for amendment approval.
6. Add checker warnings for stale evidence.
7. Add checker errors when a stale artifact is cited as evidence for a gate transition.

Acceptance criteria:

- practitioners can change an accepted PRD during G6 without pretending the project is at G2;
- structural changes identify downstream artifacts requiring reconciliation;
- regression is reserved for invalidated gate entry conditions;
- checker can distinguish stale from superseded;
- practitioner guide contains a practical example of amendment versus regression.

Validation:

```bash
./scripts/init-project.sh "Amendment Test"
./scripts/check-methodology.sh
```

Manual validation scenario:

1. Initialize a project.
2. Approve a vision and PRD in sample records.
3. Amend the PRD structurally.
4. Confirm downstream architecture/build artifacts become stale or require reconciliation.
5. Confirm a gate cannot advance with stale evidence.

Risks:

- Computed staleness may be hard to implement robustly in shell.
- The protocol should not make harmless wording edits expensive.

### Wave 4: Reviewer Independence And Context Provenance

Purpose: prevent implementation agents from self-attesting to their own conformance.

Assessment drivers:

- A2.1 independent review rule;
- A2.2 context provenance in review report;
- A2.3 fresh-context sub-agent requirement.

Target files:

- `docs/methodology/constitution/gendev.md`
- `docs/methodology/guides/subagent-coordination-protocol.md`
- `docs/methodology/templates/code-review-report-template.md`
- `docs/methodology/agents/roles/code-review-agent.md`
- `docs/practitioner-guide/08-subagents-and-delegation.md`
- `docs/practitioner-guide/10-review-remediation-and-closeout.md`
- `docs/practitioner-guide/13-codex-specific-notes.md`
- `docs/practitioner-guide/14-claude-code-specific-notes.md`
- `docs/practitioner-guide/18-glossary.md`

Constitutional rule:

```text
Conformance review must be performed in a context independent of the implementation context.
```

Review inputs:

- authority documents at pinned revisions;
- implementation diff or artifact under review;
- applicable test/UAT evidence;
- no implementer session transcript;
- no implementer reasoning trace;
- no conversational history unless explicitly justified.

Context provenance section:

```text
Reviewing agent:
Model/version:
Review context created on:
Inputs provided:
Authority document revisions used:
Implementation diff or commit reviewed:
Implementer session shared with reviewer: No
Exceptions:
```

Tasks:

1. Add reviewer independence rule to constitution.
2. Add fresh-context requirement to sub-agent protocol.
3. Add context provenance to code review template.
4. Add guidance that review sub-agents are automated governance agents but remain advisory.
5. Add practitioner guidance for Codex and Claude Code fresh-context review patterns.
6. Add checker warning when code review reports lack context provenance.

Acceptance criteria:

- review templates require context provenance;
- sub-agent protocol says review/evaluation/governance agents start from fresh context;
- code review role playbook names allowed and disallowed reviewer inputs;
- practitioner guide distinguishes independent review from ordinary continuation.

Validation:

```bash
rg -n "Context Provenance|fresh context|independent" docs/methodology docs/practitioner-guide
./scripts/check-methodology.sh
```

Risks:

- Tool-specific fresh-context mechanics differ. Keep methodology tool-agnostic and add details only
  in Codex/Claude chapters.

### Wave 5: Enforcement Contract Ratification

Purpose: move the draft enforcement contract from assessment into methodology authority with the
right dependencies and wording.

Assessment drivers:

- A3.4 adopt enforcement contract;
- A3.5 declare enforcement class in control plane;
- A3.6 constitutional enforcement principle;
- `docs/assessment/enforcement-contract.md`.

Target files:

- new `docs/methodology/guides/enforcement-contract.md`
- `docs/methodology/constitution/gendev.md`
- `AGENTS.md`
- `README.md`
- `docs/methodology/guides/gate-transition-protocol.md`
- `docs/methodology/guides/orchestration-validation.md`
- `docs/project-template/project.yaml`
- `scripts/init-project.sh`
- `scripts/check-methodology.sh`
- practitioner guide chapters 3, 4, 6, 7, 11, 16, 18

Important ratification correction:

The assessment draft says the repository provides a pre-commit hook and CI workflow. That statement
must not become authoritative until those files exist. Before the binding is implemented, use:

```text
A reference binding should provide...
```

After implementation, change to:

```text
This repository provides...
```

Project manifest enforcement block:

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
    pre_commit_hook: TBD
    ci_workflow: TBD
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

Tasks:

1. Move revised enforcement contract into `docs/methodology/guides/`.
2. Reference it from `AGENTS.md`, `README.md`, and the project manifest template.
3. Add constitutional enforcement principle:
   - enforce where possible;
   - attest where enforcement is unavailable;
   - declare class in control plane.
4. Add version-control capability assumption to constitution.
5. Add enforcement block to project template.
6. Update `init-project.sh` if slug/template rendering needs to fill enforcement fields.
7. Make checker warn when `docs/project/project.yaml` lacks an enforcement block.
8. Do not require enforcement block for the uninitialized baseline repo.

Acceptance criteria:

- enforcement contract is discoverable from `AGENTS.md` and README;
- initialized projects include an enforcement block;
- checker warns on missing/invalid enforcement fields;
- attested mode is valid at baseline;
- no methodology doc falsely claims an unimplemented binding exists.

Validation:

```bash
./scripts/init-project.sh "Enforcement Contract Test"
./scripts/check-methodology.sh
rg -n "enforcement-contract|enforcement:" AGENTS.md README.md docs/methodology docs/project-template
```

Risks:

- Enforcing too early may make the baseline hard to use.
- Attested conformance must not become a loophole; exceptions need reasons and cadence.

### Wave 6: Checker Hardening And Reference Binding

Purpose: convert ratified enforcement requirements into mechanical validation.

Assessment drivers:

- A3.1 pre-commit and CI;
- A3.2 checker hardening;
- A3.3 approval-coupled gate movement;
- EC-1 through EC-10.

Target files:

- `scripts/check-methodology.sh`
- new `scripts/install-hooks.sh`
- optional new `scripts/methodology-guard.sh`
- `.github/workflows/methodology.yml`
- `docs/methodology/guides/enforcement-contract.md`
- `docs/practitioner-guide/04-starting-a-new-project.md`
- `docs/practitioner-guide/13-codex-specific-notes.md`
- `docs/practitioner-guide/14-claude-code-specific-notes.md`
- `docs/practitioner-guide/16-checklists.md`

Checker hardening tasks:

1. Validate `project.current_gate` against `G0` through `G9`.
2. Validate `approvals.current_gate.gate` against `G0` through `G9`.
3. Treat unknown gate values as errors.
4. Validate gate status values.
5. Treat unknown gate statuses as errors once methodology version is hardened; warnings during
   transition are acceptable.
6. Deduplicate repeated missing-path errors.
7. Return failure for gate/log mismatch where a gate is approved without a parseable approval event.
8. Detect gate movement in a diff when used by CI.
9. Detect implementation path changes below G5 when implementation paths are known.
10. Detect missing tactical task IDs for implementation changes on protected branch.
11. Require executable evidence for G6+ approvals where records are structured.
12. Verify enforcement block presence and consistency.

Reference binding behavior:

- Pre-commit hook:
  - run checker;
  - block implementation path changes below G5 when possible;
  - block invalid gate/status values.
- CI workflow:
  - run checker on pull requests and pushes to protected branch;
  - evaluate changed paths;
  - enforce EC-1 through EC-6 as far as repository data permits.

Implementation path logic:

```text
If docs/project/project.yaml does not exist:
  do not enforce project gates.

If enforcement.implementation_paths contains only TBD:
  warn before G5;
  error at G5+ if implementation is expected and paths are still unknown.

If current_gate is G0-G4:
  reject changes under implementation_paths.

If current_gate is G5+:
  allow implementation path changes when task traceability and evidence requirements are met.
```

Acceptance criteria:

- invalid gate values fail the checker;
- gate approval without parseable gate-log event fails when structured mode is active;
- initialized project with valid baseline passes;
- uninitialized methodology repo still passes;
- CI workflow exists and runs the checker;
- hook installer exists but is optional.

Validation:

```bash
./scripts/check-methodology.sh
tmpdir="$(mktemp -d /tmp/gendev-hardening.XXXXXX)"
tar --exclude .git -cf - . | tar -C "$tmpdir" -xf -
cd "$tmpdir"
./scripts/init-project.sh "Checker Test"
./scripts/check-methodology.sh
```

Negative validation scenarios:

- set `current_gate: G99`; checker must fail;
- set `approvals.current_gate.gate: G99`; checker must fail;
- mark gate approved without `approved_by`; checker must fail;
- mark gate approved without structured gate-log event; checker must fail once structured mode is
  active;
- modify implementation path below G5; hook/CI must fail when paths are known.

Risks:

- Shell parsing of YAML is fragile. For deeper validation, consider a small Python script only if
  the repository intentionally adopts Python as a tooling dependency.
- CI cannot inspect local pre-commit behavior; it must enforce independently.

### Wave 7: Measurement Layer

Purpose: let GenDev measure whether it actually reduces drift, rework, approval delay, and escaped
defects.

Assessment drivers:

- A7.1 structured gate log;
- A7.2 metrics mode;
- A7.3 measurable G1 success criteria;
- A7.4 value review;
- A7.5 measurement principle.

Target files:

- `docs/methodology/constitution/gendev.md`
- `docs/methodology/guides/human-approval-protocol.md`
- `docs/methodology/guides/production-operations-protocol.md`
- `docs/methodology/templates/vision-template.md`
- `docs/methodology/templates/as-built-closeout-template.md`
- optional new `docs/methodology/templates/value-review-template.md`
- optional new `scripts/methodology-metrics.sh`
- `docs/project-template/project.yaml`
- practitioner guide chapters 1, 6, 7, 11, 12, 16, 18

Tier 1 process metrics:

- gate cycle time;
- approval latency;
- amendment frequency by originating gate;
- drift incidents;
- remediation ratio;
- escape rate;
- traceability coverage;
- rework radius;
- override frequency.

Tier 2 value metrics:

- each G1 success criterion has:
  - measure;
  - target;
  - read date or read trigger;
  - owner;
  - evidence source.
- post-deployment value review reports actuals as:
  - met;
  - missed;
  - unmeasurable.

Tier 3 methodology ROI:

- out of scope for per-project docs;
- derived later from portfolio analysis;
- GenDev project records should emit the data needed for that analysis.

Tasks:

1. Add measurement principle to constitution.
2. Update vision template so success criteria require measure, target, and read timing.
3. Add value review checkpoint to production operations protocol.
4. Add value review section or template.
5. Add metrics script or checker mode.
6. Add gate-log fields needed for cycle time and approval latency.
7. Add phase close-out metrics snapshot recommendation.
8. Add Goodhart warning:
   - outcome metrics outrank activity metrics;
   - findings count is not a quality proxy;
   - escape rate disciplines review quality.

Acceptance criteria:

- G1 cannot be considered complete with purely vague success criteria;
- production operations protocol includes value review;
- structured gate log supports at least gate cycle time and approval latency;
- metrics command can emit a basic report from sample records;
- practitioner guide explains measurement without turning it into a management dashboard.

Validation:

```bash
./scripts/check-methodology.sh
./scripts/methodology-metrics.sh docs/project
```

Risks:

- Over-measuring can cause agent optimization toward the wrong targets.
- Keep metrics derivable from required artifacts; do not add a separate reporting bureaucracy.

### Wave 8: Blast-Radius Scaling And GenDev Lite

Purpose: make GenDev scalable without abandoning required content.

Assessment drivers:

- A5.1 blast radius classification;
- A5.2 lightweight example;
- A5.3 cost control.

Target files:

- `docs/methodology/constitution/gendev.md`
- `docs/methodology/guides/gates.md`
- `docs/methodology/guides/subagent-coordination-protocol.md`
- `docs/methodology/guides/enforcement-contract.md`
- `docs/project-template/project.yaml`
- new or updated `docs/examples/`
- practitioner guide chapters 1, 4, 6, 8, 9, 12, 16, 18

Recommended classes:

```text
C1 Contained
  Internal tools, reversible outputs, no sensitive data, low operational risk.

C2 Standard
  Default product work, moderate operational or data risk, ordinary production release discipline.

C3 Critical
  Regulated data, irreversible actions, external integrations, production-sensitive automation,
  agentic runtime behavior, or high operational impact.
```

Gate scaling:

| Class | Gate/artifact handling | Non-negotiables |
| --- | --- | --- |
| C1 | G1-G4 may combine into one framing document if required content exists. Per-phase planning and close-out may combine. | Build-ready approval, production approval if deployed, explicit security assumptions. |
| C2 | Full default chain. Gates combine only with recorded justification. | G4, G5, G8, G9 approvals. |
| C3 | No gate combination. Stronger independent review, evidence sampling, and enforcement. | Reviewer independence, evidence sampling at every major gate, stricter override policy. |

Cost control:

- sub-agent assignments may include budget expectations;
- budgets may be tokens, time, dollars, or rough effort;
- exceeding budget surfaces to the lead agent;
- no automated runaway delegation.

Tasks:

1. Add blast-radius classification to constitution.
2. Add class field to `project.yaml`.
3. Add gate-combination table to gates guide.
4. Add cost/budget fields to sub-agent assignment format.
5. Add GenDev Lite worked example in `docs/examples/`.
6. Update practitioner guide to explain legitimate scaling down.
7. Add checker warning when combined gates lack recorded justification.

Acceptance criteria:

- C1 projects have an explicit, legitimate lightweight path;
- C3 projects have stronger controls;
- sub-agent protocol includes budget expectation;
- examples show both default/full and lightweight operation;
- "small projects may combine artifacts" is no longer left to practitioner intuition.

Validation:

```bash
./scripts/check-methodology.sh
rg -n "C1|C2|C3|blast|budget|GenDev Lite" docs/methodology docs/practitioner-guide docs/examples
```

Risks:

- Too much class vocabulary may make the methodology feel heavier.
- Do not let C1 become an excuse to omit security assumptions or production approval.

### Wave 9: Practitioner Guide Alignment

Purpose: update user-facing teaching material after hardening changes are accepted.

Assessment drivers:

- all accepted hardening changes;
- novice-practitioner clarity requirements already established in the guide.

Target files:

- `docs/practitioner-guide/README.md`
- `docs/practitioner-guide/01-orientation.md`
- `docs/practitioner-guide/02-core-mental-model.md`
- `docs/practitioner-guide/04-starting-a-new-project.md`
- `docs/practitioner-guide/06-gates-and-artifacts.md`
- `docs/practitioner-guide/07-approvals-and-risk.md`
- `docs/practitioner-guide/08-subagents-and-delegation.md`
- `docs/practitioner-guide/09-build-planning-and-implementation.md`
- `docs/practitioner-guide/10-review-remediation-and-closeout.md`
- `docs/practitioner-guide/11-production-operations.md`
- `docs/practitioner-guide/12-vendor-contract-tracker-walkthrough.md`
- `docs/practitioner-guide/13-codex-specific-notes.md`
- `docs/practitioner-guide/14-claude-code-specific-notes.md`
- `docs/practitioner-guide/15-prompt-library.md`
- `docs/practitioner-guide/16-checklists.md`
- `docs/practitioner-guide/17-common-failure-modes.md`
- `docs/practitioner-guide/18-glossary.md`

Tasks:

1. Add concise explanations for:
   - enforcement class;
   - attested conformance;
   - enforced conformance;
   - provenance;
   - stale;
   - amendment;
   - regression;
   - blast radius;
   - value review;
   - override.
2. Update walkthrough to show:
   - structured approval event;
   - provenance header;
   - amendment example;
   - independent review context provenance;
   - deployment value review.
3. Update prompt library with:
   - amendment prompts;
   - enforcement attestation prompts;
   - independent review prompts;
   - value review prompts.
4. Update checklists with hardened controls.
5. Keep first-use definitions inline to avoid terminology drift.

Acceptance criteria:

- practitioner guide remains readable for a novice practitioner;
- new terms are defined before or at first use;
- Chapter 18 glossary covers every new methodology term;
- walkthrough remains thin but end-to-end.

Validation:

```bash
rg -n "enforcement class|attested|provenance|stale|amendment|regression|blast radius|value review|override" docs/practitioner-guide
./scripts/check-methodology.sh
```

Risks:

- Guide could become too dense. Prefer concise chapter updates plus glossary depth.

## 8. Assessment Amendment Traceability

| Assessment item | Plan location | Notes |
| --- | --- | --- |
| A1.1 Checked field | Wave 1 | Add to standard approval record and gate-log schema. |
| A1.2 Sampling rule | Wave 1 | Requires traceability matrix; supports metrics. |
| A1.3 Meaningful oversight | Wave 1 | Use GenDev-native wording; optional AAF citation. |
| A2.1 Review independence | Wave 4 | Constitutional rule. |
| A2.2 Context provenance | Wave 4 | Code review template. |
| A2.3 Fresh-context sub-agents | Wave 4 | Sub-agent protocol and tool notes. |
| A3.1 Pre-commit and CI | Wave 6 | Reference binding after contract ratification. |
| A3.2 Checker hardening | Wave 6 | Start with gate/status validation. |
| A3.3 Gate movement approval record | Waves 1 and 6 | Requires structured gate-log schema first. |
| A3.4 Enforcement contract | Wave 5 | Move revised contract into methodology guides. |
| A3.5 Enforcement block | Wave 5 | Add to project.yaml template. |
| A3.6 Enforcement principle | Wave 5 | Constitution. |
| A4.1 Provenance header | Wave 2 | All authority/evidence templates. |
| A4.2 Rule 6 must | Wave 2 | Constitution. |
| A5.1 Blast radius | Wave 8 | C1/C2/C3 classes. |
| A5.2 Lightweight example | Wave 8 | Add GenDev Lite example. |
| A5.3 Cost control | Wave 8 | Sub-agent budget expectation. |
| A6.1 Amendment/regression guide | Wave 3 | New guide. |
| A6.2 Stale status | Wave 2 | Formal status value. |
| A6.3 Checker staleness | Wave 3 and Wave 6 | Depends on provenance. |
| A6.4 Amendment constitution | Wave 3 | Principle. |
| A7.1 Gate-log schema | Wave 1 | Foundation for enforcement and metrics. |
| A7.2 Metrics mode | Wave 7 | Script or checker mode. |
| A7.3 Measurable G1 success | Wave 7 | Vision template and gates. |
| A7.4 Value review | Wave 7 | Production protocol and as-built/value artifact. |
| A7.5 Measurement principle | Wave 7 | Constitution. |
| Finding 8 concurrency | Wave 4 and future wave | Covered partly by lead-agent serialization; deeper merge semantics later. |
| Finding 8 methodology versioning | Wave 0 | Semantic versioning and release tags. |
| Finding 8 guide consolidation | Future consolidation | Defer until hardening content stabilizes. |
| Finding 8 repository hygiene | Wave 0 | `.DS_Store`, scaffolding, README quick-start. |
| Finding 8 licensing | Wave 0 | CC BY 4.0 plus MIT split. |

## 9. Checker Capability Roadmap

The checker should evolve in layers.

### Checker Layer 1: Baseline Structural Integrity

Already mostly present:

- required files;
- required project directories;
- manifest paths;
- approval state sanity;
- accepted-document placeholder detection;
- current gate artifact status alignment;
- phase plan section checks;
- traceability evidence sanity.

Hardening additions:

- valid gate value errors;
- valid status value errors;
- duplicate error suppression;
- enforcement block warning.

### Checker Layer 2: Structured Record Validation

Add after Wave 1:

- parse structured gate-log event blocks;
- require `checked` in standard approvals;
- detect missing approval event for approved gate;
- detect missing enforcement attestation when class is attested;
- detect override events and report them.

### Checker Layer 3: Provenance And Staleness

Add after Waves 2 and 3:

- require provenance headers on authority/evidence artifacts;
- parse `Derived from` entries;
- compare pinned revisions to current revisions;
- mark stale artifacts;
- block gate transition when stale artifacts are cited as evidence.

### Checker Layer 4: Enforcement Binding Support

Add after Wave 5:

- evaluate changed paths from Git diff;
- reject implementation path changes below G5;
- require task IDs in commit messages or merge descriptions for implementation path changes;
- require executable evidence for G6+ gate events;
- validate enforcement class and exceptions.

### Checker Layer 5: Metrics

Add after Wave 7:

- gate cycle time;
- approval latency;
- amendment frequency;
- drift incident count;
- remediation ratio;
- traceability coverage;
- override frequency;
- basic value review status.

## 10. Reference Binding Plan

The first binding should be Git-based and GitHub-compatible because the repository is currently on
GitHub. The methodology must still state that other bindings conform if they implement the contract.

### Local Hook Binding

Files:

- `scripts/install-hooks.sh`
- generated `.git/hooks/pre-commit`, not tracked directly
- optional `scripts/methodology-guard.sh`

Responsibilities:

- run `./scripts/check-methodology.sh`;
- inspect staged changes;
- prevent implementation-path changes below G5 when paths are known;
- reject invalid gate/status values.

Constraints:

- hooks are advisory on developer machines because they can be bypassed;
- CI must enforce independently.

### CI Binding

Files:

- `.github/workflows/methodology.yml`

Responsibilities:

- run checker on pull requests and pushes to protected branch;
- fail on structural errors;
- evaluate gate movement and changed paths;
- publish warnings visibly;
- optionally upload metrics report after Wave 7.

Constraints:

- branch protection must be configured in GitHub outside the repo;
- the workflow can exist without branch protection, but enforcement is weaker.

### Protected Branch Policy

Recommended baseline:

```text
protected_branch: master
required_checks:
  - methodology
direct_push_allowed: false after branch protection is enabled
emergency_override: allowed with gate-log record
```

## 11. Migration Strategy For Existing Initialized Projects

This baseline repo will be cloned into downstream projects. Hardening must not strand existing
projects.

Recommended migration posture:

- introduce new fields as warnings first;
- provide migration notes for initialized projects;
- treat missing provenance as warning until a project opts into the hardened methodology version;
- treat missing enforcement block as warning for baseline projects and error for hardened versions;
- allow legacy gate-log prose records, but warn that structured records are required for metrics and
  enforcement.

Migration steps for an existing project:

1. Update methodology version in `project.yaml`.
2. Add enforcement block.
3. Add structured gate-log event for current gate state.
4. Add provenance headers to active authority/evidence artifacts.
5. Mark stale or superseded artifacts as needed.
6. Run checker.
7. Record a migration attestation in gate log.

## 12. Branch And Commit Strategy

Use branch-based review for the hardening wave. Avoid direct-to-`master` pushes except for trivial
or explicitly approved administrative changes.

Recommended branches:

```text
hardening/wave-0-baseline-hygiene
hardening/wave-1-gate-log-approval
hardening/wave-2-provenance
hardening/wave-3-amendment-regression
hardening/wave-4-review-independence
hardening/wave-5-enforcement-contract
hardening/wave-6-checker-binding
hardening/wave-7-measurement
hardening/wave-8-blast-radius
hardening/wave-9-practitioner-guide-alignment
```

Commit discipline:

- one wave may contain multiple commits if the diff is large;
- keep normative docs, templates, scripts, and practitioner guide updates logically grouped;
- do not mix repository hygiene with methodology semantics except in Wave 0;
- run the checker before every commit;
- dry-run initialization for waves that affect templates, project.yaml, or scripts.

## 13. Validation Matrix

| Validation | Applies To | Command or Method | Pass Standard |
| --- | --- | --- | --- |
| Baseline checker | Every wave | `./scripts/check-methodology.sh` | zero errors; warnings understood. |
| ASCII scan | Every docs wave | `rg -n "[^\x00-\x7F]" docs README.md AGENTS.md` | no unintended non-ASCII. |
| Stale path scan | Every wave | `rg -n "docs/methodology/Agents|docs/methodology/Design|Sample-AGENTS|Sample-DESIGN"` | no stale uppercase references. |
| Init dry run | Template/script waves | initialize in `/tmp` | project created and checker passes. |
| Negative checker tests | Checker waves | mutate temp project intentionally | expected failures occur. |
| Practitioner readability | Guide waves | read changed chapters in order | first-use definitions present. |
| Enforcement binding | Wave 6 | local hook and CI | invalid changes are blocked. |
| Metrics smoke | Wave 7 | metrics script on sample records | report emits expected fields. |

## 14. Dry-Run Scenarios

Each major wave should be validated against scenarios, not only file existence.

### Scenario A: Short Prompt Startup

1. Initialize a project.
2. Start an agent.
3. Prompt `Let's begin`.
4. Agent should identify gate, mode, artifact, owner/approver gaps, and next step.
5. Agent must not implement.

### Scenario B: Meaningful Approval

1. Draft G1 vision.
2. Ask for approval.
3. Agent presents evidence, risks, open questions, and `checked` prompt.
4. Approval is recorded as structured gate event.

### Scenario C: Independent Review

1. Implement a bounded phase in sample project.
2. Launch reviewer with only authority docs, diff, and evidence.
3. Review report records context provenance.
4. Implementer session is not shared.

### Scenario D: Amendment Without Regression

1. Reach G6.
2. Amend PRD with additive-within-scope clarification.
3. Current gate remains G6.
4. Affected downstream artifacts are reconciled.
5. Gate can proceed after dirty subtree is clean.

### Scenario E: Structural Change With Regression

1. Reach G6.
2. Discover architecture is invalid.
3. Record regression reason.
4. Move current gate back only as far as needed.
5. Re-approve affected authority.

### Scenario F: Enforcement Block

1. Initialize project.
2. Set class to `enforced`.
3. Define implementation path.
4. Attempt source change at G2.
5. Hook/CI rejects.

### Scenario G: Emergency Override

1. Simulate production incident.
2. Record override event.
3. Bypass one requirement.
4. Resume normal enforcement.
5. Record reconciliation.

### Scenario H: Value Review

1. Define measurable G1 success criteria.
2. Deploy Phase 1.
3. At read date, record actuals.
4. Mark each criterion met, missed, or unmeasurable.

## 15. Risk Register For The Hardening Program

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Over-hardening makes GenDev feel bureaucratic. | Practitioners route around the methodology. | Add blast-radius scaling and GenDev Lite example. |
| Enforcement depends on data that is not yet structured. | Checker becomes brittle or misleading. | Sequence gate-log schema and provenance before strict enforcement. |
| Shell parsing becomes too complex. | False positives or maintenance pain. | Keep schemas shallow; consider a dedicated parser only if tooling dependency is accepted. |
| Attested conformance becomes a loophole. | Projects claim conformance without effective controls. | Require declared exceptions, cadence, and gate-log attestations. |
| Metrics create Goodhart behavior. | Agents optimize activity metrics instead of outcomes. | Prioritize escape rate, value review, and sampling over findings volume. |
| AAF vocabulary coupling confuses practitioners. | GenDev loses standalone clarity. | Use GenDev-native terms; cite AAF only where useful. |
| Existing initialized projects break on upgrade. | Adoption friction. | Warn first, provide migration checklist, version methodology. |
| Reference binding overfits GitHub. | Platform-neutral claim weakens. | Keep binding non-normative; document contract separately. |

## 16. Definition Of Done For The Hardening Patch Wave

The hardening effort is complete when:

```text
[ ] Current methodology has a versioned release identity.
[ ] Licensing is explicit.
[ ] Gate-log events are structured and parseable.
[ ] Approval records include a substantive checked statement.
[ ] Evidence sampling is required at least once per phase.
[ ] Authority/evidence templates include provenance headers.
[ ] Construction directives are mandatory preserved build artifacts.
[ ] Stale is a formal artifact status.
[ ] Amendment and regression protocol exists and is referenced.
[ ] Review independence is constitutional and present in review templates.
[ ] Enforcement contract is ratified into methodology guides.
[ ] Project template declares enforcement class and enforcement configuration.
[ ] Checker validates gate/status values as errors.
[ ] Checker validates structured approval records.
[ ] Reference hook/CI binding exists or the methodology honestly says it is pending.
[ ] G1 success criteria are measurable.
[ ] Production protocol includes value review.
[ ] Basic metrics can be computed from project records.
[ ] Blast-radius classes define when ceremony may be reduced or must be increased.
[ ] GenDev Lite example exists.
[ ] Practitioner guide reflects all accepted terminology and workflow changes.
[ ] Dry-run scenarios pass.
```

## 17. Recommended Immediate Next Step

Start with Wave 0 and Wave 1.

Rationale:

- Wave 0 removes distracting repository issues and makes the baseline releasable.
- Wave 1 creates the structured event substrate needed by enforcement and measurement.
- Enforcement should not be ratified before gate-log data is parseable.
- Provenance should follow immediately after because it enables amendment, staleness, and stronger
  review claims.

Recommended first branch:

```text
hardening/wave-0-baseline-hygiene
```

Recommended first implementation sequence:

1. Clean repository hygiene and licensing.
2. Add methodology versioning policy.
3. Create structured gate-log schema.
4. Add `Checked` to approval records.
5. Update checker to recognize structured records without requiring them yet.
6. Dry-run project initialization.
7. Review before moving to provenance.

## 18. Notes On Ratifying The Assessment Documents

The assessment documents should remain in `docs/assessment/` as advisory source material. Ratified
content should be moved into methodology authority through deliberate patches.

Do not copy `docs/assessment/enforcement-contract.md` directly into `docs/methodology/guides/`
without changes. At minimum, revise:

- the reference binding section, unless hook and CI files are implemented in the same wave;
- EC-5 and EC-8 dependency language, once provenance is adopted;
- EC-6 to define task ID format and path applicability;
- conformance class policy once blast-radius tiering is adopted;
- emergency override approver count if the project chooses a stricter baseline.

The assessment review and enforcement contract are strong design inputs. The hardening program
should convert them into versioned, testable, practitioner-readable methodology authority.
