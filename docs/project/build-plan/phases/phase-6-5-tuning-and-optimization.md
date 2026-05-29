# Phase 6.5 Build Plan: Tuning and Optimization

**Status:** Approved for tactical planning

**Date:** 2026-05-25

**Phase:** 6.5

**Source authority:** `docs/project/build-plan/phases/phase-6-llm-assisted-crosswalk-evaluation.md`, `docs/project/build-plan/phases/phase-6-tactical-implementation-plan.md`, `docs/project/prd/pa_document_intelligence_prd.md`, `docs/project/architecture/pa_document_intelligence_architecture.md`, `docs/project/security-governance/governance-security-spec.md`, `docs/project/configuration/config_yaml_reference.md`, `docs/project/testing/cli-uat-harness.md`, `docs/project/build-plan/phase-roadmap.md`

**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/phase-build-planner.md`

## Executive Summary

Phase 6.5 tunes the Phase 6 LLM-assisted crosswalk evaluation path before Phase 7 begins. The live
Phase 6 UAT completed successfully, but it exhausted the configured `max_total_tool_calls` value of
200 and required roughly 14 minutes for one approved reference packet. This phase optimizes the
existing evaluated crosswalk workflow without changing the product contract, support-status model,
or artifact family.

## Phase Objective

Reduce unnecessary LLM and tool work while preserving auditability, reviewer usefulness, and
evidence quality. Phase 6.5 should make crosswalk evaluation more selective, more configurable, and
more predictable for local and remote LLM profiles.

## In Scope

- Add deterministic pre-evaluation gates for blank/null form values.
- Add configured administrative-field pruning so contact/routing/identity fields are excluded from
  evidence crosswalk evaluation.
- Add field prioritization so critical clinical and medication fields receive evaluation budget
  before empty or lower-value fields.
- Add candidate-page ranking before LLM evaluation using existing digest summaries, component
  types, Phase 4 hints, and Phase 5 workspace metadata.
- Add combined page analysis so digest generation can classify and summarize a page in one
  `page_analysis` LLM call when `packet_digest.page_analysis_mode: "combined"`.
- Reduce candidate context size per field through configurable top-k page/snippet limits.
- Batch compatible fields when they share evidence context and can be safely evaluated together.
- Add exact/fuzzy deterministic prechecks for highly structured values such as diagnosis codes,
  medication names, doses, directions, dates, phone/fax numbers, and identifiers.
- Add confidence-based early exit when deterministic or first-pass LLM evidence is sufficient.
- Add performance metadata to Phase 6 outputs or trace, including elapsed time, skipped fields,
  deterministic decisions, batched evaluations, LLM call count, tool call count, and limit pressure.
- Preserve `evaluated_form_evidence_crosswalk.json`,
  `evaluated_form_evidence_crosswalk_index.json`, `evaluated_form_evidence_crosswalk.md`, and
  `crosswalk_evaluation_trace.json`.
- Define a remediation path for production output optimization where the primary deliverables are
  `evaluated_form_evidence_crosswalk_index.json` and `evaluated_form_evidence_crosswalk.md`.
- Define output modes: `debug_full`, `uat_review`, `production`, and `audit_minimal`.
- Allow future implementation to keep selected intermediate stages in memory or minimize their
  durable artifacts in `production` mode while preserving audit metadata.

## Out of Scope

- Final approval, denial, final review packaging, or adjudication.
- New evidence status values unless explicitly approved.
- Provider-native LiteLLM tool-call loops.
- SQLite persistence or production audit indexing.
- Prompt/model tuning against a broader corpus that does not yet exist.
- Rewriting Phase 4 extraction or Phase 5 workspace semantics.
- Eliminating logical stages such as packet inventory, PA form extraction, candidate evidence
  selection, or evidence evaluation.

## Dependencies

- Phase 6 evaluated crosswalk behavior must remain functional.
- Existing YAML configuration must remain backward compatible.
- Approved non-PHI reference samples under `docs/project/reference/clinical-samples/` remain valid
  UAT inputs.
- LiteLLM task routing remains the only LLM path.

## Workstreams

### 1. Evaluation Budget and Field Triage

Introduce a deterministic pre-evaluation stage that marks blank values as skipped or unevaluable
without LLM calls, sorts fields by configured priority, and applies per-priority budget limits.
The output must still contain one evaluated item per extracted field.

### 2. Candidate Evidence Ranking

Rank candidate pages before LLM use. Ranking should prefer pages with matching component types,
field hints, exact/fuzzy text matches, relevant page summaries, and prior Phase 5 observations.
The evaluator should send only the top-ranked configured candidates unless escalation is needed.

### 3. Deterministic Structured-Value Matching

Add non-LLM checks for structured values that are safe to compare directly. These checks may produce
supported, contradicted, missing, or unclear recommendations, but system-owned validation must still
enforce provenance and reviewer flags.

### 4. Batched LLM Evaluation

Group related fields when they share the same high-ranked evidence context. Batches must remain
bounded by configurable field count, page count, token/context estimate, and response schema limits.
Batch failure must degrade to per-field evaluation or explicit unclear outcomes.

### 5. Early Exit and Escalation Rules

Stop evaluating a field when sufficient evidence has already been found. Escalate only when a field
is high priority, has conflicting evidence, or has reviewer-critical ambiguity. Low-priority
missing/blank fields should not consume the same budget as clinical support questions.

### 6. Configuration and Observability

Add YAML-backed limits for field priority, max candidates per field, batch size, deterministic
matching behavior, early-exit thresholds, and per-priority tool/LLM budgets. Record performance
metadata in `crosswalk_evaluation_trace.json` without raw PHI.

### 7. CLI UAT and Regression Evidence

Use the existing `evaluate <source_path>` command as the Phase 6.5 UAT harness. Compare optimized
runtime, LLM call count, tool call count, skipped field count, and support-status distribution
against the Phase 6 baseline.

### 8. Production Output Mode Remediation

Define production-oriented output modes and artifact persistence policy. `production` mode should
optimize around `evaluated_form_evidence_crosswalk_index.json` and
`evaluated_form_evidence_crosswalk.md` and should not write the full evaluated crosswalk JSON or
evaluation trace. After a successful end-to-end production run, upstream digest, extraction,
crosswalk, workspace, page image, OCR, and text intermediates should be pruned from the active run
directory. `audit_minimal` should write those same review deliverables plus minimal audit metadata.
`uat_review` should preserve the current phase-exit inspection behavior.

## Sequencing

1. Add trace metadata for baseline and optimized performance counters.
2. Add deterministic blank/null field gate.
3. Add candidate ranking and configurable top-k limits.
4. Add structured-value deterministic matching.
5. Add priority-based evaluation ordering and budgets.
6. Add batched evaluation for compatible fields.
7. Add early-exit and escalation rules.
8. Define output modes and artifact persistence policy.
9. Add production-output remediation plan and documentation alignment.
10. Run focused tests, full tests, lint, config-check, and live CLI UAT.
11. Update documentation and record UAT findings.

## Migration and Removal

- Preserve all Phase 6 artifact names and schema intent.
- Do not remove full evaluated crosswalk detail; add compact performance metadata only where useful.
- Keep previous config defaults valid.
- Any new optimized behavior must be disableable or tunable through YAML for comparison.
- Keep `uat_review` behavior available while adding `production` and `audit_minimal` definitions.
- Keep `production` limited to the two evaluated crosswalk review deliverables.

## Security and Governance

- Optimization must not increase raw PHI exposure in logs, console output, or traces.
- Deterministic matching must use active-run artifacts only.
- Candidate ranking must not read arbitrary files or bypass active-run scope.
- Batching must not send full packet text by default.
- Any skipped field must be reviewer-visible and traceable.

## Test Strategy

- Unit tests for blank/null skip behavior.
- Unit tests for field priority ordering and budget enforcement.
- Unit tests for candidate page ranking.
- Unit tests for deterministic structured-value matching.
- Fake LLM tests for batched evaluation success, partial failure, malformed output, and fallback.
- Trace tests for performance counters and PHI-safe metadata.
- CLI tests for unchanged artifact reporting and optimized counters.
- Live UAT against the approved reference packet.

## CLI / UAT Strategy

Baseline command:

```bash
uv run benecard-pa --config config/app.example.yaml evaluate docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

The Phase 6.5 UAT should report the same core artifacts as Phase 6 and add or preserve enough
metadata to compare:

- elapsed runtime;
- evaluated item count;
- LLM call count;
- tool call count;
- skipped blank/null field count;
- deterministic match count;
- batched evaluation count;
- support-status counts;
- review flags and limit-pressure flags.

## Acceptance Criteria

- CLI UAT succeeds and writes the same Phase 6 artifact family.
- Configured administrative/contact/routing fields are excluded from the evaluated crosswalk and
  compact index.
- Blank/null fields do not consume full LLM evaluation budget.
- Candidate pages are ranked before LLM evaluation.
- Structured-value deterministic matches reduce avoidable LLM calls.
- Combined page analysis reduces page-level digest calls versus separate `page_classification` and
  `page_summary` execution while preserving existing digest artifact fields.
- Batch evaluation is bounded, schema-validated, and fallback-safe.
- `tool_use_count` no longer reaches the configured maximum for the approved reference packet under
  the default example config, unless a reviewer-visible limit reason explains why.
- Runtime improves against the Phase 6 baseline without weakening artifact completeness.
- Console output remains PHI-safe.
- Output modes are defined and production mode leaves only the compact crosswalk index plus Markdown
  review surface in the active run directory after success.
- Focused tests, full tests, lint, config-check, and git diff check pass.

## Documentation Close-Out

- Update `docs/project/testing/cli-uat-harness.md` with Phase 6.5 tuning counters after
  implementation.
- Update `docs/project/configuration/config_yaml_reference.md` for any new YAML settings.
- Update `docs/project/traceability/pa_document_intelligence_traceability_matrix.md` with Phase 6.5
  tests and UAT evidence.
- Record the before/after UAT comparison in the phase close-out notes.

## Risks

| Risk | Mitigation |
|---|---|
| Optimization hides missing evidence | Preserve one item per field and reviewer-visible skipped/unclear flags. |
| Deterministic matching overstates support | Require page provenance and conservative confidence defaults. |
| Batching reduces output quality | Keep batches small, schema-validate, and fallback to per-field evaluation. |
| Local model latency still dominates | Add observability counters and keep model/profile selection configurable. |
| New settings make behavior hard to understand | Document defaults and keep previous behavior reproducible through config. |

## Decisions Resolved During Tactical Planning

- Blank/null values keep the existing `unclear` status with explicit skip flags. New support
  statuses are deferred.
- Default field-priority tiers are defined in
  `docs/project/build-plan/phases/phase-6-5-tactical-implementation-plan.md`.
- Initial tuning target is at least 30% runtime reduction and at least 30% tool-call reduction
  against the Phase 6 approved reference-packet baseline, while avoiding configured tool-limit
  exhaustion.
- Deterministic supported findings may finalize low-risk structured values with provenance.
  High-priority ambiguous clinical fields should still receive LLM confirmation unless exact,
  page-supported deterministic finalization is explicitly configured.

## Accuracy Pass

- Included work is optimization of existing Phase 6 behavior, not new product scope.
- Deferred final review, persistence, lifecycle, watcher, and broader prompt tuning remain outside
  this phase.
- Acceptance criteria cover speed, tool budget, artifact completeness, tests, and governance.
- Tactical planning resolved the build-plan open decisions as reviewable implementation defaults.
