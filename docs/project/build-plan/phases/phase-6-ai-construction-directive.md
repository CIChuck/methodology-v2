# Phase 6 AI Construction Directive: LLM-Assisted Crosswalk Evaluation

**Status:** Draft for review

**Date:** 2026-05-24

**Phase:** 6

**Directive type:** AI construction directive

**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/ai-construction-directive-builder.md`

## AI Builder Role

You are the implementation agent for Phase 6 of the BeneCard PA Document Intelligence project. Your
job is to implement bounded LLM-assisted crosswalk evaluation from the Phase 5 evidence workspace.
You must preserve active-run scope, PHI-safe output, system-owned artifact assembly, and all
configured LiteLLM/tool/vision capability gates.

## Source Authority and Precedence

Use these documents in this order:

1. `docs/project/build-plan/phases/phase-6-tactical-implementation-plan.md`
2. `docs/project/build-plan/phases/phase-6-llm-assisted-crosswalk-evaluation.md`
3. `docs/project/security-governance/governance-security-spec.md`
4. `docs/project/architecture/pa_document_intelligence_architecture.md`
5. `docs/project/prd/pa_document_intelligence_prd.md`
6. `docs/project/configuration/config_yaml_reference.md`
7. `docs/project/testing/cli-uat-harness.md`
8. `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`
9. `docs/project/build-plan/phase-roadmap.md`
10. `AGENTS.md`

If these documents conflict, follow the higher-precedence document and report the conflict. Do not
silently change architecture, phase boundaries, or security behavior.

## Implementation Objective

Add a bounded Phase 6 workflow that can process an approved packet through existing upstream stages
and produce an evaluated form-to-evidence crosswalk. The workflow must:

- consume Phase 5 `evidence_workspace.json` and `analysis_trace.json`;
- evaluate every PA form field against selected physician-note/supporting-document context;
- call LiteLLM through the `crosswalk_evaluation` task only;
- validate structured LLM output before artifact writing;
- write `evaluated_form_evidence_crosswalk.json` under the active run directory;
- write `evaluated_form_evidence_crosswalk.md` under the active run directory;
- write `evaluated_form_evidence_crosswalk_index.json` under the active run directory;
- write `crosswalk_evaluation_trace.json` without logging raw PHI;
- expose `evaluate <source_path>` as the CLI UAT path with PHI-safe counts and artifact paths.

## Allowed Scope

You may edit or create:

- `src/benecard_pa/analysis/` Phase 6 evaluator, models, tool adapter, artifact writers, trace
  helpers, and tests.
- `src/benecard_pa/document/artifact_paths.py` for Phase 6 artifact path generation.
- `src/benecard_pa/llm/tasks.py` only if task allowlist metadata needs a Phase 6-safe adjustment.
- `src/benecard_pa/llm/prompts.py` only for prompt/schema validation helpers.
- `src/benecard_pa/settings.py` only for required Phase 6 validation.
- `src/benecard_pa/cli.py` for the Phase 6 CLI UAT surface.
- `config/prompts.example.yaml` for `crosswalk_evaluation_v1` schema and prompt wiring.
- `config/app.example.yaml` only if real Phase 6 config defaults are missing.
- `tests/` for Phase 6 unit, negative, CLI, and integration coverage.
- Project docs required for Phase 6 close-out after implementation.

Use cautiously:

- `src/benecard_pa/pa_form/` only as a source of upstream Phase 4 artifacts/models.
- `src/benecard_pa/digest_review.py` only through existing upstream workflow composition.
- `src/benecard_pa/db/` is out of scope unless tests prove no SQLite changes are made.

## Explicit Non-Goals

Do not implement:

- approval, denial, adjudication, triage, or payer-policy outcome language;
- final review package or durable final review summary;
- `final_review` prompt execution;
- broad autonomous agent loops;
- arbitrary LLM tool access;
- provider-native LiteLLM model tool-call loops;
- source lifecycle movement, watcher, SFTP, reprocess/status commands, or daemon behavior;
- SQLite-required persistence or schema changes;
- prompt/model tuning for page classification;
- full packet text, full PDFs, or full packet image sets sent to an LLM by default;
- raw prompt/request/response logging by default;
- public-provider approval decisions.

## Required Workstreams

### 1. Phase 6 Artifact Paths and Models

Implement deterministic Phase 6 artifact paths and model objects.

Requirements:

- add the Phase 6 run-relative artifact path `evaluated_form_evidence_crosswalk.json`;
- add the Phase 6 run-relative artifact path `evaluated_form_evidence_crosswalk.md`;
- add the Phase 6 run-relative artifact path `evaluated_form_evidence_crosswalk_index.json`;
- add the Phase 6 run-relative artifact path `crosswalk_evaluation_trace.json`;
- define stable artifact models for evaluated crosswalk, evaluated item, citation/span refs, LLM
  metadata, validation flags, and summary counts;
- include `source_sha256`, `processing_run_id`, `derived_from`, artifact version, requested mode,
  execution mode, fallback reason, and review flags;
- preserve every extracted PA form field;
- do not mutate Phase 4 initial crosswalk or Phase 5 candidate workspace semantics.

### 2. Crosswalk Evaluation Prompt and Schema

Implement strict prompt/schema wiring for the `crosswalk_evaluation` task.

Requirements:

- add `crosswalk_evaluation_v1` schema to `config/prompts.example.yaml`;
- require controlled support statuses: `supported`, `contradicted`, `missing`, `unclear`;
- require citations for `supported` and `contradicted`;
- allow explicit missing/unclear rationale and review flags;
- validate Phase 6 prompt/schema wiring during `config-check`;
- reject malformed or incomplete LLM output before artifact writing.

### 3. Active-Run Tool Adapter

Create an orchestrator-owned tool adapter over Phase 5 active-run retrieval helpers.

Requirements:

- scope all tool operations to one active document/run;
- enforce configured allowed tool names;
- enforce max tool calls per field and max total tool calls;
- reject unknown tools, cross-run references, absolute paths, traversal, and arbitrary resource
  access;
- return bounded text or artifact/page refs according to configured context limits;
- audit metadata only: tool name, active run, page/component refs, status, count, duration, and
  selected model profile where applicable;
- use the adapter to assemble bounded context before calling LiteLLM;
- do not expose raw helper functions directly as LLM tools;
- do not implement provider-native model tool-call loops in Phase 6;
- `record_evidence_match` may write only Phase 6 evaluated artifact or trace data and must not
  mutate Phase 5 `evidence_workspace.json`.

### 4. LLM Crosswalk Evaluation Service

Implement the service that evaluates candidate context.

Requirements:

- read upstream artifacts through active-run validated refs;
- assemble bounded field-specific context from Phase 5 workspace, Phase 4 field data, summaries,
  selected page refs, and crosswalk hints;
- call `LlmTaskClient.complete_structured()` with `task_name="crosswalk_evaluation"`;
- include selected page numbers and scope metadata in LLM task metadata;
- validate schema and system-owned postconditions after response;
- convert failed or incomplete evaluations into explicit unclear/failure items with review flags;
- write metadata-only evaluation trace entries to `crosswalk_evaluation_trace.json`;
- never treat LLM output as autonomous approval or denial.

### 5. Capability and Vision Gates

Enforce model capability and YAML gates before LLM calls.

Requirements:

- require structured output support for `crosswalk_evaluation`;
- do not require provider-native tool support for the Phase 6 orchestrator-owned adapter;
- fail closed or emit a configured deferred/fallback flag if YAML requests provider-native model
  tool-call interaction;
- require vision support and sufficient image capacity before sending selected page images;
- enforce `analysis.context.max_page_images_per_llm_call`;
- add reviewer-facing flags for omitted image refs, unsupported tools, fallback modes, and deferred
  behavior.

### 6. Trace and Audit Metadata

Write Phase 6 evaluation trace metadata without PHI leakage.

Requirements:

- write `crosswalk_evaluation_trace.json` with evaluated field counts, status counts, selected
  pages, tool-use counts, LLM task metadata, prompt key/version, fallback reason, schema validation
  status, timeout flags, and review flags;
- do not store raw prompts, raw page text, raw context, or raw LLM responses by default;
- preserve run-relative artifact provenance;
- preserve Phase 5 `analysis_trace.json` fields and semantics.

### 7. CLI UAT Surface

Add the CLI command for Phase 6.

Requirements:

- implement `evaluate <source_path>`;
- command delegates to service code and contains no business logic;
- output includes status, source, output directory, upstream artifact paths, evaluated crosswalk
  path, item counts, status counts, LLM task profile, execution mode, fallback reason, tool-use
  count, and review flags;
- output does not include form values, snippets, raw page text, prompts, or raw model responses;
- exit code `0` only when required Phase 6 artifact is written.

## Data and Schema Requirements

- Add `evaluated_form_evidence_crosswalk.json`.
- Add `evaluated_form_evidence_crosswalk.md`.
- Add `evaluated_form_evidence_crosswalk_index.json`.
- Add `crosswalk_evaluation_trace.json`.
- Add `crosswalk_evaluation_v1` prompt schema.
- Do not change SQLite schema in Phase 6.
- Do not remove existing Phase 4 or Phase 5 artifacts.

## Security and Governance Requirements

- Treat all source documents, page text, images, digests, workspaces, LLM requests, LLM responses,
  and output artifacts as PHI unless explicitly approved non-PHI fixtures.
- Route all normal LLM calls through LiteLLM.
- Never grant LLMs arbitrary filesystem, shell, database, network, secret, or config access.
- Restrict orchestrator-owned tools to active-run document-analysis operations.
- Do not expose provider-native model tool-call loops in Phase 6.
- Do not log raw PHI, raw prompts, raw request context, or raw model responses by default.
- Enforce no full-packet-by-default context.
- Enforce model capability gates before LLM calls.
- Do not produce approval/denial language.

## Testing Requirements

Add or update tests for:

- Phase 6 artifact path generation;
- evaluated crosswalk model serialization;
- one evaluated item per extracted PA form field;
- controlled support statuses;
- citation enforcement for supported/contradicted results;
- missing and unclear outcomes;
- prompt/schema validation in config-check;
- malformed LLM response rejection;
- fake LLM supported/contradicted/missing/unclear paths;
- denied unknown tools;
- denied cross-run/path traversal access;
- tool-call count limits;
- provider-native model tool-call requests are deferred or fail closed;
- result-size limits;
- unsupported structured-output profile;
- unsupported provider-native tool-calling fallback/failure;
- unsupported vision and image-capacity overflow;
- PHI-safe CLI output;
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

The live CLI UAT must use an approved non-PHI sample from
`docs/project/reference/clinical-samples/`. It must write the evaluated crosswalk artifact and
crosswalk evaluation trace artifact, then report PHI-safe counts and paths. The UAT result should
be reviewed for:

- expected artifact paths;
- item counts;
- status counts;
- no raw field values or evidence snippets in console output;
- expected fallback/tool-use/vision flags;
- model task profile reporting.

## Documentation Close-Out

After implementation and verification:

- update `docs/project/testing/cli-uat-harness.md`;
- update `docs/project/configuration/config_yaml_reference.md` for actual config semantics;
- update `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`;
- update Phase 6 build/tactical/directive statuses;
- log UAT findings and known limitations;
- do not mark final review or Phase 7 behavior implemented.

## Reporting Requirements

Final implementation report must include:

- files changed;
- artifact(s) added;
- test and lint results;
- CLI UAT command and outcome;
- any skipped verification;
- any deferred Phase 7+ behavior;
- any known prompt/model limitations.

## Stop Conditions

Stop and report before implementing if:

- the selected artifact strategy would overwrite Phase 4 or Phase 5 semantics;
- `crosswalk_evaluation` prompt/schema cannot be validated;
- the implementation requires arbitrary tool access;
- the implementation requires provider-native model tool-call loops;
- the implementation requires raw PHI logging;
- a public model profile would be required without deployment approval;
- final approval/denial behavior appears necessary to satisfy a test.

## Accuracy Pass

- Every tactical workstream is represented.
- Non-goals are explicit.
- Security and governance boundaries are enforceable.
- Required tests include positive, negative, CLI, and governance coverage.
- Final review, persistence, lifecycle, watcher, and SFTP behavior remain deferred.
