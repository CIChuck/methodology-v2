# Phase 6.5 Tactical Implementation Plan: Tuning and Optimization

**Status:** Draft for review

**Date:** 2026-05-25

**Phase:** 6.5

**Source authority and precedence:** `docs/project/build-plan/phases/phase-6-5-tuning-and-optimization.md`, `docs/project/build-plan/phases/phase-6-tactical-implementation-plan.md`, `docs/project/build-plan/phases/phase-6-llm-assisted-crosswalk-evaluation.md`, `docs/project/security-governance/governance-security-spec.md`, `docs/project/architecture/pa_document_intelligence_architecture.md`, `docs/project/prd/pa_document_intelligence_prd.md`, `docs/project/configuration/config_yaml_reference.md`, `docs/project/testing/cli-uat-harness.md`, `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`, `docs/project/build-plan/phase-roadmap.md`

**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/tactical-implementation-planner.md`

## Implementation Objective

Optimize the existing Phase 6 `evaluate <source_path>` workflow so it produces the same evaluated
crosswalk artifact family with fewer avoidable LLM/tool operations, clearer performance telemetry,
and better YAML-controlled behavior. Phase 6.5 must not change the support-status contract or
introduce final review, approval, denial, lifecycle, watcher, or persistence scope.

The remediation objective is to add a production-output optimization plan. In production, the
primary deliverables are `evaluated_form_evidence_crosswalk_index.json` and
`evaluated_form_evidence_crosswalk.md`; intermediate artifacts are supporting machinery and should
be persisted, minimized, or kept in memory according to an explicit output mode policy.

## Assumptions

- The Phase 6 artifact family is implemented and remains the output contract.
- The Phase 6 UAT baseline is `840.85s`, `tool_use_count: 200`, and `tool_limit_or_scope_denial`
  for `doc08294920260513101420.pdf` under `config/app.example.yaml`.
- Approved clinical samples under `docs/project/reference/clinical-samples/` remain non-PHI UAT
  fixtures.
- LiteLLM remains the only LLM route.
- Configuration must remain YAML-backed and backward compatible.

## Non-Goals

- Do not implement final review packaging, approval, denial, adjudication, triage, lifecycle,
  watcher, SFTP, SQLite indexing, or provider-native LiteLLM tool-call loops.
- Do not add a new support status in Phase 6.5.
- Do not rewrite Phase 4 extraction or Phase 5 workspace semantics.
- Do not remove full evaluated crosswalk detail or make compact artifacts authoritative.
- Do not print form values, evidence snippets, prompts, raw page text, or raw model responses to
  console output.
- Do not eliminate logical stages such as packet inventory, PA form extraction, candidate evidence
  selection, or evidence evaluation.

## Implementation Defaults for Review

- Blank/null values keep support status `unclear` and add explicit flags such as
  `blank_form_value` and `crosswalk_evaluation_skipped_blank_value`.
- Field priority tiers:
  - `critical`: diagnosis, requested medication, dose, directions, current therapy, failed therapy,
    required clinical criteria, and required-evidence fields with extracted values.
  - `standard`: prescriber, patient, date, quantity, day supply, administration, and operational
    fields with extracted values.
  - `low`: blank values, informational labels, empty evidence-detail fields, and fields whose value
    is only a pointer such as "see addendum" unless linked evidence is available.
- Target acceptance threshold: default UAT should avoid exhausting `max_total_tool_calls` and should
  reduce runtime materially against the Phase 6 baseline. The initial target is at least 30% runtime
  reduction and at least 30% tool-call reduction on the approved reference packet.
- Deterministic structured matches may finalize low-risk structured values with provenance. Critical
  clinical fields should still receive LLM confirmation unless the match is exact, page-supported,
  and configured to allow deterministic finalization.

## File and Module Ownership Expectations

| Area | Expected Work |
|---|---|
| `src/benecard_pa/analysis/evaluation.py` | Add optimization pipeline stages: field triage, candidate ranking, deterministic prechecks, batching, early exit, and performance counters. |
| `src/benecard_pa/analysis/models.py` | Add trace/performance metadata models if needed without changing evaluated item status values. |
| `src/benecard_pa/analysis/artifacts.py` | Preserve artifact writing behavior; add optimized metadata only where appropriate. |
| `src/benecard_pa/analysis/tools.py` | Preserve active-run scope while making tool budget usage observable and enforceable. |
| `src/benecard_pa/settings.py` | Add YAML-backed tuning settings with validation and backward-compatible defaults. |
| `src/benecard_pa/cli.py` | Report new PHI-safe tuning counters if the result object exposes them. |
| `config/app.example.yaml` | Add Phase 6.5 tuning defaults under existing analysis/tool-call configuration. |
| `docs/project/` | Update config reference, CLI UAT harness, and traceability after implementation is verified. |
| `tests/` | Add focused Phase 6.5 unit, fake LLM, CLI, config, and regression tests. |

## Output Mode Definitions

Phase 6.5 remediation should define these output modes:

| Mode | Purpose | Primary Behavior |
|---|---|---|
| `debug_full` | Development and troubleshooting | Persist all current intermediate, trace, page, and review artifacts. |
| `uat_review` | Phase-exit and client acceptance testing | Preserve current artifact-rich UAT behavior and console counters. |
| `production` | Normal reviewer workflow | Retain only the compact evaluated crosswalk index and Markdown review surface in the active run directory after success. |
| `audit_minimal` | Defensible low-noise audit | Write review deliverables plus minimal trace/manifest metadata without verbose debug detail. |

`uat_review` should remain the default until production mode is implemented and verified.

## Workstream 0: Combined Page Analysis Gate

**Purpose:** Reduce digest-stage LLM calls by combining page classification and bounded page summary
into one configurable `page_analysis` task.

**Implementation tasks:**

- Add `packet_digest.page_analysis_mode` with `combined` and `separate` modes.
- Add `page_analysis` prompt/profile routing and schema validation.
- In combined mode, map the single response back to existing page classification and page summary
  artifact fields so downstream phases remain unchanged.
- Preserve separate mode for debug and A/B testing.

**Acceptance criteria:** Combined mode emits `page_analysis` diagnostics instead of separate
`page_classification` and `page_summary` rows, and generated digest artifacts retain page type and
page summary fields.

## Workstream 1: Performance Telemetry Baseline

**Purpose:** Make optimization measurable before changing behavior.

**Implementation tasks:**

- Add elapsed-time, LLM-call, tool-call, skipped-field, deterministic-match, batch, fallback, and
  limit-pressure counters to the Phase 6 result/trace path.
- Keep trace metadata PHI-safe.
- Preserve existing artifact names and CLI command shape.

**Affected areas:** `analysis/evaluation.py`, `analysis/models.py`, `cli.py`, tests.

**Required tests:** trace contains counters; CLI output remains PHI-safe; existing Phase 6 artifacts
are still reported.

**Acceptance criteria:** Baseline and optimized runs can be compared from CLI output and
`crosswalk_evaluation_trace.json`.

**Dependencies:** Existing Phase 6 workflow.

**Non-goals:** No status model changes.

## Workstream 2: Blank and Low-Value Field Gate

**Purpose:** Prevent empty fields from consuming LLM/tool budget.

**Implementation tasks:**

- Detect blank/null/empty extracted values before candidate retrieval and LLM calls.
- Produce one evaluated item per field with status `unclear`, confidence `null`, no supporting
  pages, and explicit skip flags.
- Count skipped blank fields in trace and CLI metadata.

**Affected areas:** `analysis/evaluation.py`, tests.

**Required tests:** blank fields skip LLM calls; one item per field remains; compact index still
contains blank fields.

**Acceptance criteria:** Blank fields do not consume full evaluation budget.

**Dependencies:** Evaluated item assembly.

**Non-goals:** No new support status.

## Workstream 3: Candidate Evidence Ranking

**Purpose:** Send the LLM only the most relevant bounded evidence context.

**Implementation tasks:**

- Rank candidate pages by component type, Phase 4 hint match, page summary relevance, exact/fuzzy
  text match, Phase 5 observation, and configured required-support components.
- Enforce configurable top-k candidate pages and snippets per field.
- Trace selected and omitted candidate counts without raw text.

**Affected areas:** `analysis/evaluation.py`, possible helper module in `analysis/`, settings,
tests.

**Required tests:** ranking order, top-k enforcement, omitted candidate flags, active-run-safe reads.

**Acceptance criteria:** Candidate pages are ranked before LLM evaluation and omitted pages are
reviewer-visible through flags/trace.

**Dependencies:** Packet analysis index and evidence workspace.

**Non-goals:** Do not change Phase 5 workspace artifact semantics.

## Workstream 4: Deterministic Structured-Value Matching

**Purpose:** Reduce avoidable LLM calls for values that can be verified directly.

**Implementation tasks:**

- Add exact and conservative fuzzy match checks for diagnosis codes, medication names, dose,
  directions, dates, phone/fax numbers, NPI-like identifiers, height/weight values, and simple
  boolean values.
- Require page provenance for any deterministic support finding.
- Add conservative confidence defaults and review flags indicating deterministic evaluation.
- Allow YAML control over which structured matchers are enabled.

**Affected areas:** `analysis/evaluation.py`, possible helper module in `analysis/`, settings,
tests.

**Required tests:** exact match support, no-match missing/unclear behavior, provenance enforcement,
fuzzy threshold behavior, disabled matcher behavior.

**Acceptance criteria:** Structured deterministic matches reduce LLM calls without overstating
support.

**Dependencies:** Ranked candidate text refs.

**Non-goals:** Do not replace LLM judgment for ambiguous clinical reasoning.

## Workstream 5: Priority Budgets and Early Exit

**Purpose:** Spend evaluation budget on fields that matter most.

**Implementation tasks:**

- Assign field priority tiers through YAML patterns and safe defaults.
- Evaluate higher-priority fields first.
- Enforce per-priority max fields, max candidates, max LLM calls, and max tool calls where
  configured.
- Stop evaluating a field once sufficient supported/contradicted evidence is found.
- Escalate only for high-priority ambiguity, contradiction, or insufficient deterministic evidence.

**Affected areas:** `settings.py`, `analysis/evaluation.py`, tests.

**Required tests:** priority ordering, budget enforcement, early exit, high-priority escalation,
low-priority skip behavior.

**Acceptance criteria:** Low-priority fields cannot exhaust the budget before critical fields are
evaluated.

**Dependencies:** Field triage and candidate ranking.

**Non-goals:** Do not suppress fields from final artifacts.

## Workstream 6: Batched LLM Evaluation

**Purpose:** Evaluate compatible fields together when the same evidence context applies.

**Implementation tasks:**

- Group compatible fields by shared ranked candidate pages and field category.
- Enforce configurable max fields per batch, max pages per batch, and context size estimate.
- Validate batched structured output and map results back to one evaluated item per field.
- Fallback to per-field evaluation or explicit unclear outcomes when batch output is malformed.

**Affected areas:** `analysis/evaluation.py`, prompt/schema handling if needed, tests.

**Required tests:** successful batch mapping, partial batch failure, malformed batch fallback,
schema validation, one item per field.

**Acceptance criteria:** Batch evaluation lowers LLM-call count while preserving item-level
validation.

**Dependencies:** Ranking and priority ordering.

**Non-goals:** Do not introduce autonomous multi-step agent loops.

## Workstream 7: Configuration, CLI, and Documentation Close-Out

**Purpose:** Make tuning configurable and phase-exit testable.

**Implementation tasks:**

- Add YAML settings for blank-field gate, priority tiers, top-k candidates, structured matchers,
  early-exit thresholds, batching limits, and performance counters.
- Validate positive numeric limits and known matcher names.
- Add PHI-safe CLI output for tuning counters.
- Update config reference, CLI UAT harness, traceability, and close-out notes after verification.

**Affected areas:** `settings.py`, `config/app.example.yaml`, `cli.py`, docs, tests.

**Required tests:** config defaults, invalid config rejection, CLI counters, docs alignment review.

**Acceptance criteria:** Tuned behavior is configurable, documented, and reproducible.

**Dependencies:** All prior workstreams.

**Non-goals:** No environment-variable secret changes.

## Workstream 8: Production Output Mode and Artifact Policy

**Purpose:** Optimize production around the two primary reviewer deliverables.

**Implementation tasks:**

- Add allowed output modes: `debug_full`, `uat_review`, `production`, and `audit_minimal`.
- Define a centralized artifact persistence policy for each mode.
- Keep `evaluated_form_evidence_crosswalk_index.json` and
  `evaluated_form_evidence_crosswalk.md` required in `production`.
- Do not write the full evaluated crosswalk JSON or evaluation trace in `production`.
- Prune upstream digest, extraction, crosswalk, workspace, page image, OCR, and text intermediates
  from the production active run directory after successful deliverable creation.
- Define `audit_minimal` trace/manifest fields: source identity, hashes, run ID,
  prompt/model metadata, status counts, performance counters, artifact refs, and review flags.
- Add active-run page-text caching as a production optimization requirement.
- Define adaptive hybrid PA extraction behavior for a later implementation pass.

**Affected areas:** future output policy helper, `settings.py`, `analysis/evaluation.py`,
workflow artifact writers, config docs, CLI UAT docs, tests.

**Required tests:** output-mode config validation, production artifact policy, `audit_minimal`
trace contents, required deliverables written, debug artifacts omitted or retained according to
mode, page-text cache behavior.

**Acceptance criteria:** Production mode can generate the compact index and Markdown deliverables,
then leave only those two files in the active run directory.

**Dependencies:** Existing Phase 6.5 evaluated crosswalk object and artifact rendering.

**Non-goals:** Do not remove the ability to run `debug_full` or `uat_review`.

## Data and Schema Changes

- Preserve existing Phase 6 artifact names:
  - `evaluated_form_evidence_crosswalk.json`
  - `evaluated_form_evidence_crosswalk.md`
  - `evaluated_form_evidence_crosswalk_index.json`
  - `crosswalk_evaluation_trace.json`
- Add optional PHI-safe performance metadata to result/trace structures.
- Do not add SQLite schema changes.
- Do not add new support-status values in Phase 6.5.

## API / CLI / Config Changes

- CLI remains `evaluate <source_path>`.
- CLI may add PHI-safe counters: elapsed runtime, LLM call count, skipped blank fields, skipped
  administrative fields, deterministic match count, batch count, and limit-pressure flags.
- Config additions should live under existing `analysis` / `tool_calling` shape unless a clearly
  named `analysis.optimization` section is cleaner.
- Add `analysis.output_mode` with values `debug_full`, `uat_review`, `production`, and
  `audit_minimal`; default to `uat_review` during MVP development.
- New config defaults must keep existing behavior valid and make optimized behavior reproducible.

## Migration Order

1. Add telemetry counters without behavioral change.
2. Add blank/null gate.
3. Add candidate ranking and top-k limits.
4. Add deterministic structured matchers.
5. Add priority ordering and budgets.
6. Add early-exit rules.
7. Add batching and fallback behavior.
8. Add production output-mode artifact policy.
9. Add active-run page-text caching.
10. Update CLI output and config docs.
11. Run verification and live UAT comparison.

## Security and Governance Work

- Keep console output PHI-safe.
- Keep raw prompts, context, page text, and LLM responses out of traces by default.
- Preserve active-run path resolution and deny arbitrary resource access.
- Ensure deterministic matching reads only active-run artifacts.
- Ensure batching does not send full packet text by default.
- Ensure `audit_minimal` traces do not store raw prompts, raw responses, or unnecessary page text.
- Preserve no approval/denial/adjudication language.

## Negative Tests

- Blank field does not trigger LLM call.
- Unknown priority tier or matcher name fails config validation.
- Candidate ranking cannot read path-traversing refs.
- Top-k candidate limit is enforced.
- Deterministic support without page provenance is rejected or downgraded.
- Batch output missing a field falls back safely.
- Batch output with unknown status is rejected.
- Budget exhaustion produces reviewer-visible flags.
- CLI does not print field values or snippets.

## CLI / UAT Checks

Run the approved reference sample with:

```bash
uv run benecard-pa --config config/app.example.yaml evaluate docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

Compare against the Phase 6 baseline:

- runtime: `840.85s`;
- `tool_use_count: 200`;
- `tool_limit_or_scope_denial` present;
- evaluated item count: `73`;
- support distribution: `supported 16`, `contradicted 2`, `missing 15`, `unclear 40`.

The Phase 6.5 run should preserve artifact completeness and improve runtime/tool-limit pressure.

## Verification Commands

```bash
uv run benecard-pa --config config/app.example.yaml config-check
uv run pytest tests/test_analysis_phase6.py tests/test_cli.py tests/test_settings.py tests/test_prompts.py -q
uv run pytest -q
ruff check .
git diff --check
uv run benecard-pa --config config/app.example.yaml evaluate docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

## Acceptance Criteria

- Existing Phase 6 artifacts are still written and reported.
- Configured administrative/contact/routing fields are excluded from the evaluated crosswalk and
  compact index.
- Blank/null fields do not consume LLM/tool evaluation budget.
- Candidate pages are ranked and bounded before LLM evaluation.
- Deterministic structured matching is conservative, provenance-backed, and configurable.
- Priority budgets protect critical clinical/medication fields.
- Batching is bounded, schema-validated, and fallback-safe.
- `tool_use_count` does not hit the configured maximum for the default approved reference UAT unless
  a reviewer-visible reason explains why.
- Runtime and tool-call counts improve materially against the Phase 6 baseline.
- Output modes and artifact persistence policy are documented before implementation.
- `production` mode is defined around `evaluated_form_evidence_crosswalk_index.json` and
  `evaluated_form_evidence_crosswalk.md`.
- Full tests, focused tests, lint, config-check, git diff check, and live CLI UAT pass.

## Documentation Close-Out

- Update `docs/project/testing/cli-uat-harness.md` with Phase 6.5 counters and UAT expectations.
- Update `docs/project/configuration/config_yaml_reference.md` for new settings.
- Update `docs/project/traceability/pa_document_intelligence_traceability_matrix.md` with
  implementation and UAT evidence.
- Record before/after UAT results in the appropriate phase close-out or findings log.

## Deferred Items

- New support statuses.
- Broader corpus prompt/model tuning.
- Provider-native model tool-call loops.
- Final review artifact assembly.
- SQLite indexing of evaluated crosswalk metadata.
- Lifecycle, watcher, SFTP, and reprocess/status workflows.

## Risks

- Deterministic matching may overstate support; mitigate with provenance requirements,
  conservative confidence, and flags.
- Batching may reduce output quality; mitigate with small batches and per-field fallback.
- Runtime may remain dominated by local model latency; mitigate with counters and configurable
  profiles.
- Added YAML settings may become complex; mitigate with documented defaults and validation.

## Accuracy Pass

- Workstreams map to the approved Phase 6.5 build plan.
- Scope does not add final review, adjudication, persistence, lifecycle, watcher, or provider-native
  tool loops.
- Tests include positive, negative, CLI, config, and governance coverage.
- Migration order starts with observability and preserves rollback/comparison.
- Documentation close-out is included and gated on verified behavior.
