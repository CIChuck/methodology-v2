# Phase 6.5 AI Construction Directive: Tuning and Optimization

**Status:** Draft for review

**Date:** 2026-05-25

**Phase:** 6.5

**Directive type:** AI construction directive

**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/ai-construction-directive-builder.md`

## AI Builder Role

You are the implementation agent for Phase 6.5 of the BeneCard PA Document Intelligence project.
Your job is to optimize the existing Phase 6 evaluated crosswalk workflow. Implement only the
approved tuning scope. Preserve artifact contracts, security boundaries, PHI-safe output, and
LiteLLM routing.

## Source Authority and Precedence

Use these documents in this order:

1. `docs/project/build-plan/phases/phase-6-5-tactical-implementation-plan.md`
2. `docs/project/build-plan/phases/phase-6-5-tuning-and-optimization.md`
3. `docs/project/build-plan/phases/phase-6-tactical-implementation-plan.md`
4. `docs/project/build-plan/phases/phase-6-llm-assisted-crosswalk-evaluation.md`
5. `docs/project/security-governance/governance-security-spec.md`
6. `docs/project/architecture/pa_document_intelligence_architecture.md`
7. `docs/project/prd/pa_document_intelligence_prd.md`
8. `docs/project/configuration/config_yaml_reference.md`
9. `docs/project/testing/cli-uat-harness.md`
10. `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`
11. `docs/project/build-plan/phase-roadmap.md`
12. `AGENTS.md`

If these documents conflict, follow the higher-precedence document and report the conflict. Do not
silently change architecture, phase boundaries, artifact contracts, or security behavior.

## Implementation Objective

Tune the Phase 6 `evaluate <source_path>` workflow so the same artifact family is produced with
less avoidable LLM/tool work:

- preserve `evaluated_form_evidence_crosswalk.json`;
- preserve `evaluated_form_evidence_crosswalk.md`;
- preserve `evaluated_form_evidence_crosswalk_index.json`;
- preserve `crosswalk_evaluation_trace.json`;
- add PHI-safe performance metadata;
- add configurable combined `page_analysis` so page classification and bounded summary can share
  one LLM call per page;
- skip full LLM evaluation for blank/null fields;
- rank candidate evidence before LLM calls;
- apply conservative deterministic structured-value matching;
- evaluate high-priority fields before low-priority fields;
- use bounded batching and early exits where safe;
- keep CLI output PHI-safe and reviewer useful.

The remediation objective is to add production-output optimization guidance. In `production` mode,
the two primary deliverables are `evaluated_form_evidence_crosswalk_index.json` and
`evaluated_form_evidence_crosswalk.md`. Other artifacts are supporting or audit/debug artifacts and
must be governed by an explicit output-mode policy.

## Allowed Scope

You may edit or create:

- `src/benecard_pa/analysis/evaluation.py`
- `src/benecard_pa/analysis/models.py`
- `src/benecard_pa/analysis/artifacts.py`
- `src/benecard_pa/analysis/tools.py`
- new helper modules under `src/benecard_pa/analysis/` for ranking, matching, batching, or
  optimization only if they reduce complexity;
- new helper modules under `src/benecard_pa/document/` for combined page analysis when the existing
  classifier/summarizer split would otherwise duplicate page-level LLM calls;
- `src/benecard_pa/settings.py`
- `src/benecard_pa/cli.py`
- `config/app.example.yaml`
- tests required for Phase 6.5 behavior;
- project documentation required for Phase 6.5 close-out after implementation and verification.

Use cautiously:

- `src/benecard_pa/llm/` only if existing structured-output or task-call metadata cannot support
  batched evaluation safely.
- `config/prompts.example.yaml` only for task-scoped prompt/schema additions such as
  `page_analysis`, or if the existing `crosswalk_evaluation` schema must be extended to support
  batched input/output.

## Explicit Non-Goals

Do not implement:

- final review package generation;
- approval, denial, adjudication, triage, or medical necessity outcome language;
- new support statuses;
- provider-native LiteLLM model tool-call loops;
- broad autonomous agent loops;
- SQLite indexing or schema changes;
- lifecycle movement, watcher, SFTP, reprocess/status commands, or daemon behavior;
- prompt/model tuning against a broader corpus;
- full packet text, full PDFs, or full image sets sent to an LLM by default;
- raw prompt/request/response logging by default;
- changes that make compact artifacts authoritative over the full evaluated crosswalk.
- removal of logical stages required to produce defensible review deliverables.

## Required Workstreams

### 1. Performance Telemetry

Add PHI-safe counters to result and trace data.

Requirements:

- record elapsed time, LLM call count, tool call count, skipped blank fields, skipped
  administrative fields, deterministic matches, batch count, fallback count, and
  limit-pressure flags;
- preserve existing artifact names and CLI command;
- do not store raw field values, snippets, prompts, raw page text, or raw model responses in traces
  or console output.

### 2. Blank/Null Field Gate

Skip full LLM evaluation for empty values.

Requirements:

- detect blank, null, and empty-string field values before retrieval and LLM calls;
- still write exactly one evaluated item per field;
- use support status `unclear`;
- include explicit flags such as `blank_form_value` and
  `crosswalk_evaluation_skipped_blank_value`;
- count skipped fields in telemetry.

### 3. Candidate Evidence Ranking

Rank and bound evidence before LLM evaluation.

Requirements:

- rank pages using component type, Phase 4 hints, page summaries, exact/fuzzy matches, Phase 5
  observations, and configured supporting-document rules;
- enforce YAML top-k candidate limits;
- trace selected and omitted candidate counts without raw PHI;
- preserve active-run safe artifact resolution.

### 4. Deterministic Structured Matching

Add conservative non-LLM checks for structured values.

Requirements:

- support exact and conservative fuzzy checks for diagnosis codes, medication names, dose,
  directions, dates, phone/fax numbers, identifiers, height/weight, and simple boolean values;
- require page provenance for deterministic support;
- add review flags indicating deterministic evaluation;
- keep confidence conservative;
- allow YAML disablement by matcher type;
- use LLM confirmation for high-priority ambiguous clinical fields unless config explicitly allows
  deterministic finalization.

### 5. Priority Budgets and Early Exit

Protect evaluation budget for important fields.

Requirements:

- implement configurable priority tiers;
- default critical tier includes diagnosis, medication requested, dose, directions, current therapy,
  failed therapy, required clinical criteria, and extracted required-evidence fields;
- evaluate critical fields before standard and low-priority fields;
- enforce per-priority budgets where configured;
- stop evaluating a field after sufficient evidence is found;
- keep blank skipped fields in final artifacts, but exclude configured administrative/contact/routing
  fields from evaluated crosswalk artifacts.

### 6. Bounded Batched Evaluation

Batch compatible fields safely.

Requirements:

- group fields only when they share candidate evidence context and compatible category;
- enforce max fields per batch, max pages per batch, and context size estimates;
- validate batched structured output;
- map batched results back to individual evaluated items;
- fall back to per-field evaluation or explicit unclear outcomes on malformed batch responses.

### 7. Configuration, CLI, Tests, and Documentation

Make tuning behavior configurable and auditable.

Requirements:

- add YAML defaults for optimization gates, priority tiers, top-k candidates, structured matchers,
  batching, early exit, and counters;
- validate positive limits and known matcher names;
- add PHI-safe CLI counters when available;
- update docs only after behavior is implemented and verified;
- keep previous config valid.

### 8. Production Output Mode Remediation

Define output modes and artifact policy for production tuning.

Requirements:

- define allowed modes: `debug_full`, `uat_review`, `production`, and `audit_minimal`;
- keep `uat_review` as the default until production behavior is implemented and verified;
- require `evaluated_form_evidence_crosswalk_index.json` and
  `evaluated_form_evidence_crosswalk.md` in `production`;
- do not write the full evaluated crosswalk JSON or evaluation trace in `production`;
- after a successful `production` run, prune upstream digest, extraction, crosswalk, workspace,
  page image, OCR, and text intermediates from the active run directory;
- preserve a minimal trace or manifest in `audit_minimal` with source identity, hashes, run ID,
  model/profile metadata, prompt key/version, status counts, performance counters, artifact refs,
  and reviewer flags;
- do not store raw prompts, raw responses, full page text, or verbose tool traces in
  `audit_minimal` mode by default;
- include active-run page text caching in the remediation implementation plan;
- define `adaptive_hybrid` PA extraction behavior as a planned optimization, not as an automatic
  code requirement unless explicitly approved.

## Migration and Removal Instructions

- Preserve Phase 6 artifact names and schema intent.
- Do not remove or mutate Phase 4 `form_evidence_crosswalk.json`.
- Do not mutate Phase 5 `evidence_workspace.json`.
- Keep `evaluate <source_path>` as the UAT command.
- Do not remove `debug_full` or `uat_review`; production optimization must be additive and
  configurable.
- Add optimization incrementally in this order:
  1. telemetry;
  2. blank/null gate;
  3. candidate ranking;
  4. deterministic structured matching;
  5. priority budgets and early exit;
  6. batching;
  7. output-mode artifact policy;
  8. active-run page-text caching;
  9. CLI/config/docs close-out.
- Ensure new optimized behavior is configurable and reproducible.

## Security and Governance Requirements

- Treat source documents, page text, prompts, LLM responses, digests, workspaces, and output
  artifacts as PHI unless explicitly approved non-PHI fixtures.
- Route all normal LLM calls through LiteLLM.
- Do not grant LLMs arbitrary filesystem, shell, database, network, secret, or config access.
- Preserve active-run tool scope.
- Do not log raw PHI, raw prompts, raw request context, raw page text, or raw model responses by
  default.
- Do not send full packet text by default.
- Ensure batching does not broaden context beyond configured limits.
- Ensure production output mode does not store raw prompts, raw responses, or unnecessary page text
  by default.
- Do not produce approval or denial language.

## Testing Requirements

Add or update tests for:

- telemetry counters and PHI-safe trace metadata;
- blank/null field gate and skipped-field counts;
- blank skipped fields remain represented;
- configured administrative/contact/routing fields are excluded from evaluated artifacts;
- candidate ranking order and top-k enforcement;
- path traversal and cross-run denial remain enforced;
- deterministic exact match with provenance;
- deterministic support without provenance is rejected or downgraded;
- fuzzy threshold behavior and disabled matcher behavior;
- priority ordering and budget enforcement;
- early exit behavior;
- batched evaluation success;
- batched partial failure and malformed-output fallback;
- unknown priority tier or matcher name config rejection;
- CLI output remains PHI-safe and reports tuning counters;
- output-mode config validation and artifact policy behavior;
- production mode required deliverables and `audit_minimal` trace/manifest behavior;
- page-text caching reduces repeated active-run text reads;
- no approval/denial language.

## Verification Commands

Run:

```bash
uv run benecard-pa --config config/app.example.yaml config-check
uv run pytest tests/test_analysis_phase6.py tests/test_cli.py tests/test_settings.py tests/test_prompts.py -q
uv run pytest -q
ruff check .
git diff --check
uv run benecard-pa --config config/app.example.yaml evaluate docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

## CLI / UAT Requirements

The live UAT must use the approved reference packet:

```bash
uv run benecard-pa --config config/app.example.yaml evaluate docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

Compare the optimized run against the Phase 6 baseline:

- runtime: `840.85s`;
- `tool_use_count: 200`;
- `tool_limit_or_scope_denial` present;
- evaluated items: `73`;
- support distribution: `supported 16`, `contradicted 2`, `missing 15`, `unclear 40`.

The optimized run must preserve artifact completeness and should avoid exhausting the configured
tool-call maximum under the default example config.

## Documentation Close-Out

After implementation and verification:

- update `docs/project/testing/cli-uat-harness.md` with Phase 6.5 counters and UAT expectations;
- update `docs/project/configuration/config_yaml_reference.md` for new YAML settings;
- update `docs/project/traceability/pa_document_intelligence_traceability_matrix.md` with
  implemented tests and UAT evidence;
- record before/after UAT results in the phase close-out or UAT findings log;
- do not mark behavior implemented until tests and live UAT support it.

## Reporting Requirements

The implementation report must include:

- files changed;
- settings added or changed;
- tests added or changed;
- verification commands and results;
- live UAT artifact paths;
- before/after runtime and tool-call comparison;
- output mode used and artifact policy applied;
- any skipped verification and reason;
- any residual risks or deferred tuning items.

## Stop Conditions

Stop and report before proceeding if:

- implementing Phase 6.5 requires changing support-status values;
- preserving every field in evaluated artifacts becomes impossible;
- active-run scope or PHI-safe output would be weakened;
- provider-native model tool-call loops appear necessary;
- new configuration would break existing example config compatibility;
- live UAT cannot be run or cannot reach the configured local/remote LLM.

## Accuracy Pass

- Every tactical workstream is represented.
- Non-goals explicitly prevent final review, adjudication, persistence, lifecycle, watcher, and
  provider-native tool-call scope.
- Security/governance requirements preserve Phase 6 boundaries.
- Required tests cover positive, negative, config, CLI, batching, and PHI-safe behavior.
- Reporting requirements include before/after performance evidence.
