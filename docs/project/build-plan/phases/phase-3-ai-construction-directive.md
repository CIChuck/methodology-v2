# Phase 3 AI Construction Directive: LiteLLM Page Classification, Decomposition, and Digest Summaries

**Status:** Approved for Phase 3 implementation

**Date:** 2026-05-22

**Phase:** 3

**Directive type:** AI construction directive

**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/ai-construction-directive-builder.md`

## AI Builder Role

You are the implementation agent for Phase 3 of the BeneCard PA Document Intelligence project. Your
job is to implement the narrow LiteLLM-backed document-understanding slice authorized here:
page classification, packet decomposition, page summaries, component summaries, enriched digest
artifacts, and CLI UAT output. Implement only the approved Phase 3 scope.

## Source Authority and Precedence

Use these documents in this order:

1. `docs/project/build-plan/phases/phase-3-tactical-implementation-plan.md`
2. `docs/project/build-plan/phases/phase-3-page-classification-decomposition-digest-summaries.md`
3. `docs/project/security-governance/governance-security-spec.md`
4. `docs/project/architecture/pa_document_intelligence_architecture.md`
5. `docs/project/prd/pa_document_intelligence_prd.md`
6. `docs/project/configuration/config_yaml_reference.md`
7. `docs/project/testing/cli-uat-harness.md`
8. `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`
9. `docs/project/build-plan/phase-roadmap.md`
10. `AGENTS.md`

If these documents conflict, follow the higher-precedence document and report the conflict. Do not
silently change architecture, requirements, phase boundaries, or security behavior.

## Implementation Objective

Extend the existing Phase 2.5 `digest <source_path>` path so it produces a Phase 3 enriched packet
digest:

- classify every original page through the configured `page_classification` LiteLLM task;
- group classified pages into logical required and optional packet components;
- mark missing required `prior_authorization_form` and `physician_notes` components;
- retain unknown, blank, low-confidence, and invalid-output pages;
- generate bounded page summaries through the configured `page_summary` task;
- generate bounded component summaries through the configured `component_summary` task;
- write enriched `packet_digest.json` and `packet_digest.md` artifacts under the configured
  run-scoped output directory;
- keep CLI output PHI-safe and metadata-only;
- preserve every original page exactly once.

## Allowed Scope

You may edit:

- `src/benecard_pa/llm/client.py`
- `src/benecard_pa/llm/prompts.py`
- `src/benecard_pa/llm/tasks.py`
- `src/benecard_pa/document/page_classifier.py`
- `src/benecard_pa/document/decomposer.py`
- `src/benecard_pa/document/summarizer.py`
- `src/benecard_pa/document/models.py`
- `src/benecard_pa/document/digest.py`
- `src/benecard_pa/digest_review.py`
- `src/benecard_pa/cli.py`
- `src/benecard_pa/settings.py`
- `config/prompts.example.yaml`
- `config/app.example.yaml` only if Phase 3 validation/defaults require it
- tests for prompts, LiteLLM client, settings, classifier, decomposer, summarizer, digest, digest
  review, and CLI
- Phase 3 planning/traceability docs only for close-out after implementation

Use cautiously:

- `src/benecard_pa/document/classifier.py` only to preserve or migrate legacy prompt catalog code.
  Do not keep broad keyword classification as the primary Phase 3 classifier.
- `src/benecard_pa/output/artifacts.py` only for reusable artifact helpers.
- `config/review_schema.example.json` only if Phase 3 structured-output schema definitions belong
  there; do not alter final review schema semantics.

## Explicit Non-Goals

Do not implement or invoke:

- PA form field extraction;
- evidence crosswalks;
- support-status decisions such as `supported`, `contradicted`, `missing`, or `unclear`;
- digest-driven retrieval or evidence workspace behavior;
- LLM tool calling;
- active-run retrieval tools;
- page-image or crop vision input to LLMs;
- `llm_vision`, `hybrid`, or `compare` execution beyond existing Phase 2 guardrails;
- final review JSON or final review Markdown;
- approval, denial, policy interpretation, or clinical recommendation language;
- SQLite persistence or schema changes;
- source lifecycle movement, copy, delete, archive, quarantine, or processed/failed behavior;
- Dropbox watcher, reconciliation, queueing, SFTP, remote file retrieval, or production
  `process-once` behavior;
- true `document_id` migration.

## Required Workstreams

### 1. Prompt Catalog and Task Prompt Loading

Implement a task-oriented prompt loader, preferably `src/benecard_pa/llm/prompts.py`.

Requirements:

- load `settings.prompts.file_path`;
- parse prompt `version`, `tasks`, `task_prompt_map`, task prompt text, optional `output_schema`,
  optional `few_shots`, and task metadata;
- support `page_classification`, `page_summary`, and `component_summary`;
- fail closed with PHI-safe errors when required Phase 3 task prompts are missing or malformed;
- update `config/prompts.example.yaml` with Phase 3 few-shot page-classification examples and
  output schema names.

### 2. LiteLLM Task Router and Structured Call Boundary

Refactor `src/benecard_pa/llm/client.py` into a task-oriented boundary while preserving compatibility
where needed.

Requirements:

- resolve profiles by task name using `settings.llm.profile_for_task(task_name)`;
- support only the Phase 3 tasks from this directive in the digest path;
- call LiteLLM through the project LLM client boundary for live calls;
- support injected fake clients for unit tests;
- parse structured JSON object responses;
- return task/profile/model/prompt metadata;
- fail closed for missing profile, missing prompt, missing required secret, unsupported structured
  output, or malformed model response;
- do not expose tool calling, vision images, arbitrary tools, retrieval, or final review routing.

### 3. Page Classification Service

Add `src/benecard_pa/document/page_classifier.py`.

Requirements:

- classify each page using the `page_classification` task;
- use selected normalized text and page extraction/OCR metadata;
- support configured component labels and `unknown`;
- require structured output with page type, confidence, rationale/signals, and review flags;
- convert invalid page types, malformed output, low confidence, model refusal, and no-text pages to
  `unknown` with appropriate review flags;
- do not use a broad keyword/signal classifier as the main implementation.

### 4. Packet Component Decomposer

Add `src/benecard_pa/document/decomposer.py`.

Requirements:

- group classified pages into logical components using original page numbers;
- use required and optional component lists from YAML settings;
- mark `prior_authorization_form` and `physician_notes` missing when absent;
- retain unknown pages;
- record component type, required/optional status, presence, pages, confidence, evidence role, and
  review flags;
- do not physically split PDFs.

### 5. Digest Schema Enrichment

Extend digest models and builders.

Requirements:

- preserve existing Phase 2.5 digest fields;
- add page classification fields, page signals, summary fields, component records,
  required-component status, review flags, and Phase 3 LLM task metadata;
- preserve `document` and `artifact_run` metadata;
- keep every original page represented exactly once;
- honor `include_page_signals`, `include_page_summaries`, `include_component_summaries`,
  `include_unknown_pages`, and `include_artifact_paths`;
- keep file-only mode valid.

### 6. Page and Component Summary Services

Add `src/benecard_pa/document/summarizer.py`.

Requirements:

- route page summaries through `page_summary`;
- route component summaries through `component_summary`;
- use bounded selected text, not full packet text by default;
- enforce `page_summary_max_chars` and `component_summary_max_chars`;
- record method, confidence, max-char metadata, task/profile/prompt metadata, and review flags;
- preserve inventory if summary generation fails;
- omit summaries cleanly when disabled.

### 7. Digest Review Workflow and CLI UAT Extension

Extend `DigestReviewService` and the existing CLI command.

Requirements:

- orchestrate parse -> image-to-text -> classify -> decompose -> summarize -> enriched digest write;
- keep CLI as a thin adapter;
- update Markdown digest to include source document, page count, component count,
  required-component status, review flags, Phase 3 task profiles, component inventory, and page
  table;
- do not print extracted text, summaries, prompts, model responses, snippets, or patient
  identifiers to console;
- report task profiles in CLI output.

### 8. Configuration Validation and Examples

Update configuration validation and examples.

Requirements:

- validate Phase 3 task profiles and prompt mappings;
- require structured-output capability for Phase 3 profiles;
- enforce public-provider governance flags;
- keep raw request/response storage disabled unless explicitly approved;
- do not store API keys in YAML.

### 9. Scope Boundary and Negative Tests

Add tests proving Phase 3 does not invoke deferred behavior.

Forbidden from the `digest` path:

- `pa_form_extraction`;
- `crosswalk_evaluation`;
- `final_review`;
- tool calling;
- page-image or crop vision input;
- SQLite writes;
- source movement;
- watcher, SFTP, lifecycle, queue, or reprocess behavior.

## Migration and Removal Instructions

- Preserve the existing `digest <source_path>` command and evolve it into the Phase 3 UAT path.
- Preserve run-scoped artifact paths.
- Preserve source-filename-safe artifact directory prefixes.
- Preserve existing Phase 1, Phase 2, and Phase 2.5 tests unless behavior is intentionally enriched
  and tests are updated accordingly.
- Do not remove user-created files or unrelated repository content.
- Do not refactor unrelated modules for style.
- Do not mark planned behavior implemented unless it is implemented and verified.

## Security and Governance Requirements

- Treat prompts, selected page text, model outputs, summaries, classifications, digest JSON,
  Markdown, OCR text, and page artifacts as PHI-bearing unless generated from approved non-PHI
  fixtures.
- Console output must remain metadata-only.
- Do not log raw page text, prompt text, model request content, model response content, summaries,
  patient identifiers, or source snippets by default.
- Secrets must be read from environment variables only.
- Public provider routing requires explicit configuration approval.
- Unsupported or missing model/prompt capability must fail closed or create reviewer-facing flags
  according to task criticality.
- LLM outputs are advisory labels/summaries. The system owns digest assembly, validation, provenance,
  and artifact writing.

## Testing Requirements

Add or update tests for:

- task prompt loading and few-shot parsing;
- missing/malformed prompt failures;
- Phase 3 task profile resolution;
- structured output parsing and malformed output handling;
- missing secret/profile failures;
- page classification success and unknown fallback;
- required and optional component grouping;
- missing required component review flags;
- page and component summary bounds;
- summary-disabled and summary-failure behavior;
- digest enrichment and Phase 2 metadata preservation;
- CLI PHI-safe output and task profile reporting;
- negative scope boundaries for field extraction, crosswalk, final review, tool calling, vision,
  SQLite, lifecycle, watcher, SFTP, and source movement.

Unit tests must use fake/mocked LLM clients and must not require network access.

## Verification Commands

The implementation should be ready for these commands, but if the user asks to pause before
verification, do not run them:

```bash
uv run benecard-pa --config config/app.example.yaml config-check
uv run pytest
ruff check .
git diff --check
```

## CLI and UAT Requirements

Primary UAT command:

```bash
uv run benecard-pa --config config/app.example.yaml digest docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

Expected success output shape:

```text
status: success
source: <source-document-name>
output_dir: <configured-output-dir>
digest_json: <digest_json_path>
digest_markdown: <digest_markdown_path>
pages: <count>
components: <count>
missing_required_components: <component-list-or-none>
review_flags: <flag-list-or-none>
llm_tasks: page_classification=<profile>, page_summary=<profile>, component_summary=<profile>
```

## Documentation Close-Out

**Status:** Implemented and verified.

**Verification evidence:**

- `ruff check .`
- `uv run pytest` (`118 passed`)
- `uv run benecard-pa --config config/app.example.yaml config-check`

**As-built notes:**

- Implemented only `page_classification`, `page_summary`, and `component_summary`.
- Added local JSON Schema validation for structured LLM outputs.
- Added provider/profile/model/prompt/capability/inference metadata to LLM audit records.
- Added stable component IDs for future crosswalk/tool references.
- Kept PA form extraction, crosswalk evaluation, final review, tool calling, vision input, SQLite,
  lifecycle movement, watcher, and SFTP out of Phase 3.

Post-implementation updates completed:

- Phase 3 build plan status/evidence;
- Phase 3 tactical plan as-built notes;
- traceability matrix evidence;
- CLI UAT harness final command/output shape;
- known limitations and deferred Phase 6 scope.

## Reporting Requirements

Final implementation report must include:

- files changed;
- summary of Phase 3 behavior implemented;
- tests added or updated;
- verification commands run or explicitly skipped;
- known residual risks;
- confirmation that deferred features were not implemented.

## Stop Conditions

Stop and report rather than guessing if:

- implementation appears to require PA form extraction, crosswalk, final review, tool calling,
  vision input, SQLite, lifecycle movement, watcher, or SFTP;
- task routing cannot be implemented without bypassing LiteLLM;
- prompt or schema behavior would require hard-coded clinical prompt text in Python;
- security requirements would require logging raw PHI, prompts, or model outputs;
- source documents would need to be moved, deleted, or modified;
- unrelated user-created files would need to be removed or overwritten.

## Accuracy Pass

- Every tactical workstream is represented.
- Required test categories and negative tests are included.
- Non-goals and deferred phase boundaries are explicit.
- Migration and preservation rules are explicit.
- Security/governance behavior is explicit.
- CLI UAT and reporting expectations are specified.
