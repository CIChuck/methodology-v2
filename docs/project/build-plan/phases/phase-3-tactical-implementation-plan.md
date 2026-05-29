# Phase 3 Tactical Implementation Plan: LiteLLM Page Classification, Decomposition, and Digest Summaries

**Status:** Implemented and verified

**Date:** 2026-05-22

**Phase:** 3

**Source authority:** `docs/project/build-plan/phases/phase-3-page-classification-decomposition-digest-summaries.md`, `docs/project/build-plan/phase-roadmap.md`, `docs/project/prd/pa_document_intelligence_prd.md`, `docs/project/architecture/pa_document_intelligence_architecture.md`, `docs/project/security-governance/governance-security-spec.md`, `docs/project/configuration/config_yaml_reference.md`, `docs/project/testing/cli-uat-harness.md`, `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`

**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/tactical-implementation-planner.md`

## Implementation Objective

Implement Phase 3 as the first narrow LiteLLM-backed document-understanding slice. The existing
`digest <source_path>` CLI workflow should parse/OCR the packet, classify every page through the
configured `page_classification` task, group pages into logical packet components, generate bounded
page and component summaries through configured summary tasks, and write an enriched
`packet_digest.json` plus digest Markdown.

This phase proves configurable model routing, prompt loading, structured response validation, page
type inventory, component inventory, required-component flags, and CLI UAT reviewability. It must
not implement PA form field extraction, crosswalk evaluation, evidence analysis, tool calling,
vision inputs, SQLite persistence, source lifecycle movement, watcher behavior, SFTP, or final
review output.

## As-Built Close-Out

Phase 3 has been implemented and verified with:

- `ruff check .`
- `uv run pytest` (`118 passed`)
- `uv run benecard-pa --config config/app.example.yaml config-check`

Implemented scope:

- configurable Phase 3 prompt loading with explicit task mappings and few-shot examples;
- LiteLLM task routing for `page_classification`, `page_summary`, and `component_summary` only;
- local JSON Schema validation for structured model responses;
- bounded classification and summary request text;
- logical packet decomposition with required/optional/unknown components and stable component IDs;
- page and component digest summaries marked as navigation aids;
- enriched JSON/Markdown digest artifacts and CLI UAT output;
- PHI-safe console output and negative tests for deferred phase leakage.

Deferred scope remains unchanged: PA form field extraction, crosswalk evaluation, final review,
tool calling, selected-page vision input, SQLite persistence, source lifecycle movement, watcher,
SFTP, and production analysis orchestration.

## Source Authority Precedence

1. Governance/security specification for PHI handling, LLM boundaries, prompt/request logging, and
   forbidden tool/vision behavior.
2. Phase 3 build plan for included and deferred scope.
3. Architecture for component ownership, LiteLLM routing, digest, and CLI boundaries.
4. PRD for functional IDs and acceptance expectations.
5. Configuration reference for YAML and prompt behavior.
6. CLI UAT harness for operator-facing evidence.
7. Traceability matrix and phase roadmap for phase placement.

If code-generation pressure conflicts with this plan, the feature must be deferred rather than
smuggled into Phase 3.

## Assumptions

- Phase 2.5 digest review service remains the entry point for CLI UAT.
- `litellm` is already a project dependency and is the only model-routing path for live model calls.
- Unit tests use mocked LiteLLM responses and must not require network access or live model
  credentials.
- Live-model UAT can use a local OpenAI-compatible endpoint, LiteLLM proxy, or approved remote
  provider profile configured through YAML and environment variables.
- Prompt text, few-shot examples, model names, and provider credentials must not be hard-coded in
  Python modules.
- Deterministic code is allowed for nonclinical mechanics only: blank/no-text handling, config
  validation, schema validation, safe fallbacks, and test doubles.
- Source document identity remains visible in approved non-PHI UAT artifacts.

## Non-Goals

- Do not implement PA form field extraction.
- Do not implement evidence crosswalks or support-status decisions.
- Do not build the analysis orchestrator, evidence workspace, retrieval tools, or tool-call loop.
- Do not send page images or crops to LLMs.
- Do not enable `llm_vision`, `hybrid`, or `compare` execution beyond existing Phase 2 guardrails.
- Do not implement final review JSON, clinical recommendation text, or approval/denial language.
- Do not write SQLite rows or modify `db/schema.sql`.
- Do not move, copy, delete, archive, or quarantine source files.
- Do not make `process-once`, watcher, SFTP, lifecycle, or reprocess/status production-ready.
- Do not create a broad keyword classifier as the primary classification path.

## Workstream 1: Prompt Catalog and Task Prompt Loading

**Purpose:** Make Phase 3 prompts and few-shot examples configurable through YAML.

**Implementation tasks:**

- Extend or replace the current prompt catalog in `src/benecard_pa/document/classifier.py` with a
  task-oriented prompt loader, preferably under `src/benecard_pa/llm/prompts.py`.
- Load `settings.prompts.file_path`.
- Parse `version`, `tasks`, `task_prompt_map`, task `prompt`, optional `output_schema`, optional
  `few_shots`, and task metadata.
- Add typed models or dataclasses for:
  - `TaskPrompt`;
  - `FewShotExample`;
  - `PromptCatalog`.
- Support the Phase 3 task names:
  - `page_classification`;
  - `page_summary`;
  - `component_summary`.
- Fail closed with PHI-safe errors when the prompt file is missing, malformed, or does not contain
  a required Phase 3 task.
- Update `config/prompts.example.yaml` with initial few-shot examples and output schema names for
  `page_classification`.

**Affected areas:** `src/benecard_pa/llm/prompts.py`, `src/benecard_pa/document/classifier.py` if
legacy code is reused, `config/prompts.example.yaml`, `tests/test_prompts.py`.

**Required tests:**

- Loads Phase 3 task prompts from YAML.
- Loads few-shot page-classification examples.
- Fails closed when `page_classification` is missing.
- Fails closed when prompt YAML is not a mapping.
- Does not require live LiteLLM to load prompts.

**Acceptance criteria:** Phase 3 prompt behavior can be changed from YAML without Python edits.

**Dependencies:** Existing `PromptSettings`, PyYAML dependency, PRD FR-129 and FR-143.

**Non-goals:** Do not implement final review prompt rendering or full review schema behavior.

## Workstream 2: LiteLLM Task Router and Structured Call Boundary

**Purpose:** Add the minimal model-call boundary needed for Phase 3 tasks only.

**Implementation tasks:**

- Refactor `src/benecard_pa/llm/client.py` away from the review-only `review()` shape toward a
  task-oriented method, for example:

```python
complete_structured(
    *,
    task_name: str,
    prompt: str,
    user_content: str,
    schema_name: str,
    schema: dict[str, object] | None,
) -> LlmTaskResult
```

- Resolve model profile using `settings.llm.profile_for_task(task_name)`.
- Return model/task metadata:
  - task name;
  - profile name;
  - model name;
  - prompt version/key;
  - structured-output requested;
  - capability flags;
  - status.
- Include `api_base`/`base_url`, timeout, retries, temperature, and max tokens according to the
  selected profile.
- Resolve secrets only from environment variable names.
- Fail closed when a required secret is missing for a live provider profile.
- Request structured output where the selected profile supports it.
- Parse JSON object responses only.
- Support injected/mock clients for unit tests.
- Preserve the old review method only as compatibility glue if needed; do not wire final review
  into Phase 3.

**Affected areas:** `src/benecard_pa/llm/client.py`, possible new
`src/benecard_pa/llm/tasks.py`, `src/benecard_pa/settings.py`, `tests/test_llm_client.py`,
`tests/test_settings.py`.

**Required tests:**

- Resolves `page_classification`, `page_summary`, and `component_summary` to configured profiles.
- Rejects an undefined task profile.
- Rejects missing required prompt/task mapping.
- Rejects malformed non-object LLM JSON.
- Does not call LiteLLM when using the mocked client.
- Does not expose tool-calling or vision options for Phase 3 calls.

**Acceptance criteria:** Phase 3 services can call three named LLM tasks through LiteLLM or a test
double with auditable metadata and structured output validation.

**Dependencies:** Workstream 1 prompt loading, existing `LlmSettings`.

**Non-goals:** Do not add retrieval tools, tool calling, vision input, image-capacity behavior, or
final review routing.

## Workstream 3: Page Classification Service

**Purpose:** Classify every original page into a configured packet page/component type using the
LiteLLM `page_classification` task.

**Implementation tasks:**

- Add `src/benecard_pa/document/page_classifier.py`.
- Define dataclasses or typed results:
  - `PageClassification`;
  - `PageSignal`;
  - `PageClassificationStatus`.
- Inputs:
  - original page number;
  - selected normalized text;
  - extraction/text/OCR metadata;
  - configured component labels;
  - prompt/few-shot context;
  - confidence threshold.
- Output fields:
  - `page_type`;
  - `confidence`;
  - `classification_method`;
  - `signals`;
  - `review_flags`;
  - model/profile/prompt metadata.
- Use `unknown` when:
  - no meaningful text exists;
  - model output is invalid;
  - model confidence is below `packet_digest.confidence_threshold_for_review_flag`;
  - model returns a page type outside configured labels;
  - the task fails and the run can continue.
- Add review flags for low-confidence, invalid output, missing text, and model task failure.
- Do not use a broad keyword/signal rules engine as the primary classifier.

**Affected areas:** `src/benecard_pa/document/page_classifier.py`,
`src/benecard_pa/document/models.py`, `tests/test_page_classifier.py`.

**Required tests:**

- Mocked PA form model output classifies a page as `prior_authorization_form`.
- Mocked physician note output classifies a page as `physician_notes`.
- Unknown model page type becomes `unknown`.
- Low-confidence output becomes `unknown` or is flagged according to configured threshold.
- Blank/no-text page becomes `unknown` without model call when appropriate.
- Every input page receives exactly one classification result.

**Acceptance criteria:** Page classification is model-backed, configuration-driven, and safe when
the model fails or produces invalid output.

**Dependencies:** Workstreams 1 and 2, existing `PageText` model.

**Non-goals:** Do not infer form fields or evidence support from page classification.

## Workstream 4: Packet Component Decomposer

**Purpose:** Group classified pages into logical packet components while preserving original page
numbers and required-component status.

**Implementation tasks:**

- Add `src/benecard_pa/document/decomposer.py`.
- Define component models:
  - `PacketComponent`;
  - `RequiredComponentStatus`;
  - `ComponentPresenceStatus`.
- Use `settings.packet_decomposition.required_components` and
  `settings.packet_decomposition.optional_components`.
- Group pages by primary classified page type.
- Preserve original page order within each component.
- Record:
  - component type;
  - required/optional;
  - present;
  - pages;
  - confidence;
  - evidence role;
  - component-level review flags.
- Required `prior_authorization_form` and `physician_notes` must be marked missing when absent.
- Unknown pages must remain in page inventory and may be represented as an `unknown` component or
  digest-level unknown-page flag.
- Do not physically split PDFs.

**Affected areas:** `src/benecard_pa/document/decomposer.py`,
`src/benecard_pa/document/models.py`, `src/benecard_pa/document/digest.py`,
`tests/test_decomposer.py`.

**Required tests:**

- PA form not on page 1 is still grouped as PA form.
- Physician notes component is present when pages classify as notes.
- Fax cover sheet is optional and does not satisfy required components.
- Missing PA form creates required-component status and review flag.
- Missing physician notes creates required-component status and review flag.
- Unknown pages are retained.
- Component pages preserve original page numbers and order.

**Acceptance criteria:** The digest can show required and optional packet components without losing
or reordering source pages.

**Dependencies:** Workstream 3 classification results.

**Non-goals:** Do not evaluate whether component text supports PA form answers.

## Workstream 5: Digest Schema Enrichment

**Purpose:** Extend the current provisional digest into the Phase 3 enriched packet digest while
preserving Phase 1/2/2.5 fields.

**Implementation tasks:**

- Extend `DigestPage` to include:
  - `page_type_confidence`;
  - `classification_method`;
  - `page_signals`;
  - `page_summary`;
  - `summary_method`;
  - `summary_confidence`;
  - `summary_max_chars`;
  - optional LLM task metadata.
- Extend `ProvisionalPacketDigest` or introduce `PacketDigest` with:
  - `components`;
  - `required_component_status`;
  - component summaries;
  - digest-level LLM task metadata;
  - review flags for missing required components, unknown pages, low confidence, and summary
    failures.
- Keep `digest_version` stable unless schema versioning is deliberately updated in config and tests.
- Preserve `document` and `artifact_run` metadata already written by Phase 2.5.
- Ensure every original page remains represented exactly once.
- Ensure `packet_digest.include_page_signals`, `include_page_summaries`,
  `include_component_summaries`, `include_unknown_pages`, and `include_artifact_paths` are honored.

**Affected areas:** `src/benecard_pa/document/models.py`, `src/benecard_pa/document/digest.py`,
`src/benecard_pa/digest_review.py`, `tests/test_provisional_digest.py`,
`tests/test_digest_review.py`.

**Required tests:**

- Enriched digest includes one page record per original page.
- Page records include classification fields.
- Component records include required/optional status.
- Required-component status is present.
- Existing Phase 2 OCR metadata remains intact.
- `include_artifact_paths=false` still writes digest artifacts but omits embedded page artifact
  paths.

**Acceptance criteria:** Phase 3 enrichment adds classification, components, and summaries without
breaking existing digest review behavior.

**Dependencies:** Workstreams 3, 4, and 6.

**Non-goals:** Do not add SQLite indexing or final review schema output.

## Workstream 6: Page and Component Summary Services

**Purpose:** Generate bounded summaries through LiteLLM for digest navigation only.

**Implementation tasks:**

- Add `src/benecard_pa/document/summarizer.py`.
- Route page summaries through the `page_summary` task.
- Route component summaries through the `component_summary` task.
- Use selected normalized page text as input; do not send full packet text by default.
- For component summaries, use member page summaries and/or bounded selected text according to the
  tactical implementation decision.
- Enforce:
  - `packet_digest.page_summary_max_chars`;
  - `packet_digest.component_summary_max_chars`.
- Mark summaries with:
  - summary method;
  - confidence when returned;
  - max char limit;
  - task/profile/prompt metadata.
- If summary generation fails, preserve classification/component inventory and add review flags.
- If summaries are disabled in config, omit them without failing classification/decomposition.

**Affected areas:** `src/benecard_pa/document/summarizer.py`,
`src/benecard_pa/document/models.py`, `src/benecard_pa/document/digest.py`,
`tests/test_digest_summarizer.py`.

**Required tests:**

- Page summary is bounded to `page_summary_max_chars`.
- Component summary is bounded to `component_summary_max_chars`.
- Summary-disabled config omits summary calls.
- Summary failure preserves page/component inventory.
- Summary text is not printed to CLI output.
- Summaries are marked as navigation aids in Markdown or digest metadata.

**Acceptance criteria:** Digest summaries help navigation while remaining bounded and non-evidence.

**Dependencies:** Workstreams 1 and 2, component grouping from Workstream 4.

**Non-goals:** Do not use summaries as final evidence or crosswalk support.

## Workstream 7: Digest Review Workflow and CLI UAT Extension

**Purpose:** Extend the existing Phase 2.5 digest workflow into the Phase 3 phase-exit UAT harness.

**Implementation tasks:**

- Update `DigestReviewService` to orchestrate:
  - parse;
  - image-to-text routing;
  - page classification;
  - packet decomposition;
  - page summaries;
  - component summaries;
  - enriched digest writing.
- Keep CLI business logic out of `src/benecard_pa/cli.py`.
- Update `render_packet_digest_markdown()` to include:
  - source document;
  - page count;
  - component count;
  - required-component status;
  - review flags;
  - selected Phase 3 task profile names;
  - component inventory;
  - page table with page type, confidence, summary status, and review flags.
- Do not include extracted page text, full summaries, prompts, model responses, source snippets, or
  patient identifiers in console output.
- CLI success output should include:
  - status;
  - source;
  - output directory;
  - digest JSON path;
  - digest Markdown path;
  - pages;
  - components;
  - missing required components;
  - review flags;
  - Phase 3 LLM task profile names.

**Affected areas:** `src/benecard_pa/digest_review.py`, `src/benecard_pa/cli.py`,
`tests/test_digest_review.py`, `tests/test_cli.py`.

**Required tests:**

- CLI digest writes enriched JSON and Markdown.
- CLI output includes task profile names but no extracted text, prompts, model responses, or
  summaries.
- CLI returns nonzero with PHI-safe error when required Phase 3 task config is missing.
- CLI UAT command works with mocked LiteLLM responses.

**Acceptance criteria:** The existing `digest` command becomes the Phase 3 UAT path for enriched,
model-backed packet inventory.

**Dependencies:** Workstreams 1 through 6.

**Non-goals:** Do not add a separate production processing command in Phase 3.

## Workstream 8: Configuration Validation and Examples

**Purpose:** Ensure Phase 3 fails early when model, prompt, or capability configuration is invalid.

**Implementation tasks:**

- Extend config validation to confirm:
  - `page_classification`, `page_summary`, and `component_summary` resolve to defined profiles;
  - selected profiles support structured outputs;
  - prompt task map points to prompt tasks that exist;
  - public provider profiles remain governed by `security.allow_public_llm_profiles`;
  - raw request/response storage remains disabled unless explicitly approved.
- Update `config/prompts.example.yaml` with:
  - few-shot page-classification examples;
  - explicit output schema names for Phase 3 tasks;
  - concise prompt language that forbids evidence support decisions.
- Update `config/app.example.yaml` only if current task profile defaults are insufficient.
- Do not put API keys in YAML.

**Affected areas:** `src/benecard_pa/settings.py`, `config/prompts.example.yaml`,
`config/app.example.yaml`, `tests/test_settings.py`, `tests/test_prompts.py`.

**Required tests:**

- `config-check` passes for example config.
- Missing Phase 3 task profile fails validation.
- Missing Phase 3 prompt mapping fails validation.
- Profile without structured output fails for Phase 3 tasks.
- Public profile routing fails unless explicitly approved.
- Secret value is never read from YAML.

**Acceptance criteria:** Configuration mistakes are caught before packet processing starts.

**Dependencies:** Workstreams 1 and 2.

**Non-goals:** Do not require a specific remote provider as the only valid UAT path.

## Workstream 9: Scope Boundary and Negative Tests

**Purpose:** Prevent the narrow Phase 3 LiteLLM slice from expanding into later phases.

**Implementation tasks:**

- Add negative tests that prove the Phase 3 `digest` path does not:
  - call `pa_form_extraction`;
  - call `crosswalk_evaluation`;
  - call `final_review`;
  - enable tool calling;
  - send page images or crops;
  - initialize SQLite persistence;
  - move/copy/delete source files;
  - run watcher, SFTP, queue, lifecycle, or reprocess behavior.
- Test that LLM calls are limited to:
  - `page_classification`;
  - `page_summary`;
  - `component_summary`.
- Keep network-free tests deterministic through injected fake LLM clients.

**Affected areas:** `tests/test_digest_review.py`, `tests/test_cli.py`,
`tests/test_llm_client.py`.

**Required tests:**

- Fake LLM client records only Phase 3 task names.
- No SQLite file is created by `digest`.
- Source file remains in place.
- No image payload appears in mocked model call input.
- No prompt/model raw content appears in console output.

**Acceptance criteria:** Phase 3 proves useful model-backed digest behavior without importing or
executing later analysis/review surfaces.

**Dependencies:** Workstreams 2 and 7.

**Non-goals:** Do not build test fixtures that require live provider availability.

## File and Module Ownership Expectations

Primary edit scope:

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
- `config/app.example.yaml` only if validation/defaults need adjustment
- `tests/test_llm_client.py`
- `tests/test_prompts.py`
- `tests/test_page_classifier.py`
- `tests/test_decomposer.py`
- `tests/test_digest_summarizer.py`
- `tests/test_digest_review.py`
- `tests/test_cli.py`
- `tests/test_settings.py`

Use cautiously:

- `src/benecard_pa/document/classifier.py` may be adapted or deprecated for prompt-catalog
  functionality, but do not preserve broad keyword classification as the main Phase 3 path.
- `src/benecard_pa/output/artifacts.py` only for reusable Markdown or JSON writing helpers.
- `config/review_schema.example.json` only if Phase 3 structured-output schema definitions are
  stored there; avoid altering final review schema semantics.

Avoid editing:

- `src/benecard_pa/db/**`
- `src/benecard_pa/lifecycle.py`
- `src/benecard_pa/watcher/**`
- SFTP or network intake modules if introduced later.
- Final review/crosswalk modules except for negative import tests.
- Methodology documents.

## Data and Schema Changes

Allowed:

- Add Phase 3 page classification fields to digest page records.
- Add component records to packet digest.
- Add required-component status to packet digest.
- Add page and component summary fields and metadata.
- Add LLM task metadata for Phase 3 task calls.
- Add prompt/few-shot metadata structures.
- Add Phase 3 structured-output validation schemas.

Not allowed:

- SQLite schema changes.
- Final review schema completion.
- Form field or evidence match schema implementation.
- Source lifecycle state-machine changes.
- True `document_id` migration unless separately approved.

## API, CLI, and Config Changes

CLI remains:

```bash
uv run benecard-pa --config config/app.example.yaml digest <source_path>
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

Config expectations:

- `llm.provider` remains `litellm`.
- `llm.task_profiles.page_classification`, `page_summary`, and `component_summary` must resolve to
  defined profiles.
- Phase 3 profiles must support structured output.
- Prompt YAML must contain mapped tasks for `page_classification`, `page_summary`, and
  `component_summary`.
- `packet_digest.include_page_summaries` and `include_component_summaries` control summary calls.
- `packet_digest.confidence_threshold_for_review_flag` controls low-confidence classification
  review flags unless a more specific threshold is later approved.
- API keys must be environment variables only.

## Migration Order

1. Confirm current working tree and protect unrelated user-created files.
2. Run baseline verification when practical:
   - `uv run benecard-pa --config config/app.example.yaml config-check`;
   - `uv run pytest`;
   - `ruff check .`.
3. Add prompt-loading tests and implement Phase 3 prompt catalog.
4. Add task-router tests and implement Phase 3 LiteLLM task client boundary.
5. Add settings/config validation tests and implement validation updates.
6. Add page-classifier tests and implement page classifier.
7. Add decomposer tests and implement component grouping and required-component status.
8. Add summary tests and implement page/component summarizer.
9. Add digest enrichment tests and update digest models/builders.
10. Add CLI/digest-review integration tests and update `DigestReviewService` and CLI output.
11. Add negative boundary tests.
12. Run verification commands.
13. Update traceability and as-built notes only after implementation is verified.

## Security and Governance Work

- Treat prompt inputs, model outputs, summaries, classifications, digest JSON, Markdown, OCR text,
  and page artifacts as PHI-bearing unless generated from approved non-PHI fixtures.
- Do not log raw page text, prompt text, model request content, model response content, summaries,
  patient identifiers, or source snippets by default.
- Store only metadata needed for audit: task name, profile name, model name, prompt key/version,
  capability flags, status, and artifact paths.
- Ensure missing model profile, missing prompt, missing secret, unsupported structured output, or
  malformed model response fails closed with PHI-safe messages.
- Ensure tool calling, page-image vision input, arbitrary filesystem access, DB access, shell
  access, and network retrieval tools are not exposed.
- Keep source files unmoved and unmodified.
- Keep file-only operation valid.

## Tests by Workstream

| Workstream | Test File | Required Coverage |
|---|---|---|
| Prompt catalog | `tests/test_prompts.py` | Task prompt loading, few-shot parsing, missing task failures, malformed YAML. |
| LiteLLM boundary | `tests/test_llm_client.py` | Task profile resolution, structured JSON parsing, missing secret/profile, no tool/vision options. |
| Config validation | `tests/test_settings.py` | Phase 3 task profiles, structured-output capability, public provider governance, prompt mapping. |
| Page classification | `tests/test_page_classifier.py` | PA form, physician notes, unknown, low-confidence, invalid output, blank page. |
| Decomposition | `tests/test_decomposer.py` | Required components, optional components, missing required flags, unknown retention, page order. |
| Summaries | `tests/test_digest_summarizer.py` | Bounded summaries, disabled summaries, failed summaries, metadata. |
| Digest enrichment | `tests/test_provisional_digest.py`, `tests/test_digest_review.py` | Page fields, component records, required status, review flags, Phase 2 metadata preservation. |
| CLI UAT | `tests/test_cli.py` | Enriched digest command, PHI-safe output, task profile names, exit codes. |
| Scope control | `tests/test_digest_review.py`, `tests/test_cli.py` | No crosswalk, final review, tool calling, vision input, SQLite, lifecycle, watcher, SFTP. |

## Negative Tests

- Missing `page_classification` prompt fails closed.
- Missing `page_summary` or `component_summary` prompt fails closed only when the corresponding
  summary feature is enabled.
- Missing task profile fails config validation.
- Missing provider secret fails live task call with PHI-safe error.
- Malformed JSON response becomes page/component flag or workflow failure according to task
  criticality.
- Model returns unsupported page type and page becomes `unknown`.
- Low-confidence model response is flagged.
- CLI output does not include extracted text, prompt text, raw model response, summaries, or source
  snippets.
- Markdown digest does not include raw extracted page text.
- `digest` does not call `pa_form_extraction`, `crosswalk_evaluation`, or `final_review`.
- `digest` does not send page images or crops to a model.
- `digest` does not invoke tool calling or retrieval tools.
- `digest` does not create SQLite files or write DB rows.
- `digest` does not move/copy/delete source files.
- `digest` does not run watcher, SFTP, lifecycle, queue, or reprocess logic.

## CLI, API, and UAT Checks

Primary UAT command:

```bash
uv run benecard-pa --config config/app.example.yaml digest docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

Approved UAT input pool:

- `docs/project/reference/clinical-samples/doc08294920260513101420.pdf`
- `docs/project/reference/clinical-samples/GLP1_WEIGHT_LOSS_VER01.PDF`
- `docs/project/reference/clinical-samples/GLP_1_AGONIST_VER09.PDF`

UAT checks:

- Command returns `0`.
- Console identifies approved source document name.
- Console identifies configured output directory and digest artifacts.
- Console identifies the three Phase 3 task profiles.
- `packet_digest.json` exists.
- `packet_digest.md` exists.
- Every original page appears once.
- Pages contain page type, confidence, method, and signals or `unknown`.
- Components include required/optional status and original page numbers.
- Missing required components, if any, appear as review flags.
- Page and component summaries are bounded when enabled.
- Unknown pages are retained.
- No source file movement occurs.

## Verification Commands

```bash
uv run benecard-pa --config config/app.example.yaml config-check
uv run pytest
ruff check .
git diff --check
```

Optional live-model UAT requires a configured local model, LiteLLM proxy, or approved remote
provider profile and the required environment variable for the selected profile.

## Acceptance Criteria

| Area | Acceptance Criteria |
|---|---|
| Prompt config | Phase 3 prompts and few-shot examples load from YAML. |
| LiteLLM routing | `page_classification`, `page_summary`, and `component_summary` resolve task-specific profiles. |
| Page classification | Every original page receives a page type or `unknown`, confidence, method, and signals. |
| Unknown retention | Low-confidence, blank, invalid, or unsupported pages remain in the digest. |
| Decomposition | Components group original page numbers logically without physical PDF splitting. |
| Required components | Missing PA form or physician notes create required-component status and review flags. |
| Summaries | Page and component summaries are bounded, configurable, and navigation-only. |
| Digest artifacts | JSON and Markdown artifacts are written under configured run-scoped output paths. |
| CLI UAT | `digest <source_path>` proves Phase 3 behavior and reports task profiles. |
| Governance | Console output excludes extracted text, prompts, responses, summaries, snippets, and patient identifiers. |
| Scope control | No field extraction, crosswalk, final review, tool calling, vision input, SQLite, lifecycle, watcher, SFTP, or source movement occurs. |
| Verification | Config check, tests, Ruff, and diff checks pass. |

## Documentation Close-Out

After implementation and verification:

- Update this tactical plan with as-built notes.
- Update the Phase 3 build plan status and evidence.
- Update traceability rows for Phase 3 implemented/verified evidence.
- Update CLI UAT harness with final console output shape and UAT command.
- Record any residual model/profile limitations.
- Record whether live-model UAT used local, proxy, or remote provider configuration.
- Create the Phase 3 remediation pass before Phase 4 planning.

## Deferred Items

- PA form field extraction: Phase 4.
- Evidence crosswalk and support statuses: Phase 4.
- Digest-driven retrieval/evidence workspace: Phase 5.
- Tool calling and active-run retrieval tools: Phase 6.
- LLM vision image inputs and image-to-text vision execution: Phase 6 unless separately approved.
- Final review LLM task and final review artifact: Phase 6/7.
- SQLite indexing and durable output package: Phase 7.
- Source lifecycle, process/reprocess/status, and watcher behavior: Phase 8/9.
- True `document_id` model alignment: future persistence/identity phase.

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Model output is inconsistent | Bad page/component labels | Enforce structured schema, confidence thresholds, `unknown` fallback, and review flags. |
| Phase 3 pulls in Phase 6 behavior | Scope creep and governance risk | Limit allowed task names and add negative tests for tools, vision, final review, and crosswalk. |
| Prompt changes break tests | Brittle implementation | Keep unit tests on structured behavior and fixtures, not exact natural language. |
| Provider credentials unavailable | UAT blocked | Keep mocked unit tests and support local/proxy/remote profile configuration. |
| Summaries are treated as evidence | Reviewer confusion | Mark summaries as navigation-only and exclude them from future crosswalk evidence rules. |
| Existing digest consumers break | Regression | Preserve Phase 2.5 fields and add enrichment compatibly. |

## Accuracy Pass

- **Missing implementation steps:** Prompt loading, LiteLLM routing, classification, decomposition,
  summaries, digest enrichment, CLI, config validation, and documentation close-out are specified.
- **Vague ownership:** Primary modules and tests are listed.
- **Missing tests:** Workstream tests and negative tests are defined.
- **Missing migration steps:** Phase 2.5 digest command is preserved and evolved.
- **Missing security/governance verification:** Prompt/model logging, secrets, provider approval,
  PHI-safe output, and forbidden tool/vision behavior are explicit.
- **Missing CLI/UAT evidence:** Command, sample inputs, console shape, output artifacts, and UAT
  checks are specified.
- **Documentation close-out gaps:** Traceability, build plan, CLI UAT, as-built notes, and
  remediation are required.
- **Contradictions with source authority:** None identified; Phase 3 owns only the narrow LiteLLM
  classification/summary slice and defers evidence analysis, tool calling, vision input, and final
  review.
