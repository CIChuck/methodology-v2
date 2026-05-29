# Phase 2 Tactical Implementation Plan: Image-to-Text Execution and Page Artifacts

**Status:** Implemented and verified  
**Date:** 2026-05-21  
**Phase:** 2  
**Source authority:** `docs/project/build-plan/phases/phase-2-image-text-execution-page-artifacts.md`, `docs/project/prd/pa_document_intelligence_prd.md`, `docs/project/architecture/pa_document_intelligence_architecture.md`, `docs/project/security-governance/governance-security-spec.md`, `docs/project/configuration/config_yaml_reference.md`, `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`, `docs/project/build-plan/phase-roadmap.md`  
**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/tactical-implementation-planner.md`

## Implementation Objective

Implement Phase 2's page-level image-to-text layer. The code should render image-text-required PDF
pages, run Tesseract OCR for selected pages and standalone images, write page-level extraction
artifacts, enrich page/digest metadata, and preserve Phase 1 page identity guarantees.

The implementation must not add clinical interpretation. Page classification, packet decomposition,
summaries, crosswalk generation, final review output, live LiteLLM vision, tool calling, SQLite
indexing, watcher behavior, and source lifecycle movement remain deferred.

## Source Authority Precedence

1. Governance/security specification for PHI handling, provider approval, and denial behavior.
2. Phase 2 build plan for scope boundaries.
3. Architecture for module ownership and object lifecycle.
4. PRD for functional and acceptance requirements.
5. Configuration reference for YAML behavior.
6. Traceability matrix and phase roadmap for phase placement.

If implementation pressure conflicts with phase scope, defer the feature rather than expanding the
phase.

## Assumptions

- `pyproject.toml` and `uv.lock` already include PyMuPDF, Pillow, and `pytesseract`.
- The OS Tesseract binary is an environment prerequisite, not a Python dependency.
- Tests may mock `pytesseract` for deterministic unit coverage and skip real-OCR integration checks
  when the OS binary is unavailable.
- Approved non-PHI clinical samples under `docs/project/reference/clinical-samples/` are valid
  test and UAT inputs.
- Page-level OCR artifacts are derived PHI and must use document-ID-safe paths.
- File-only operation remains valid; no SQLite work is required.

## Non-Goals

- Do not call LiteLLM or any model endpoint.
- Do not implement production `llm_vision`, `hybrid`, or `compare` execution.
- Do not classify page type or packet component type.
- Do not add page summaries, component summaries, PA form fields, evidence matches, or final review
  artifacts.
- Do not add a production processing CLI.
- Do not move source files or write lifecycle status.
- Do not add SQLite tables, migrations, or artifact indexing.

## Workstream 1: Image-to-Text Models

**Purpose:** Extend the typed page/digest contracts so OCR output can be carried without later
schema churn.

**Implementation tasks:**

- Extend `src/benecard_pa/document/models.py` with OCR-oriented metadata fields or dataclasses:
  `OcrResult`, `ImageTextStatus`, or equivalent.
- Add page-level metadata for `image_text_strategy`, `ocr_confidence`, `ocr_engine`,
  `ocr_languages`, `ocr_status`, and optional `image_text_error`.
- Preserve existing `PageText` compatibility for Phase 1 tests.
- Keep `page_type` as `unknown`; do not add component fields.
- Update digest page records to expose image-to-text strategy, OCR confidence/status, selected text
  source, and artifact paths.

**Affected areas:** `src/benecard_pa/document/models.py`,
`src/benecard_pa/document/digest.py`, `tests/test_provisional_digest.py`.

**Required tests:**

- Native-text pages remain selected as `native_pdf_text`.
- OCR pages can represent selected source `tesseract_ocr` or equivalent.
- Failed OCR pages retain page identity and review flags.

**Acceptance criteria:** Page and digest models carry Phase 2 metadata without breaking Phase 1
parser/digest assertions.

**Dependencies:** Phase 1 parser and digest models.

## Workstream 2: Rendering and Page Artifact Paths

**Purpose:** Render page images needed by OCR and produce deterministic page-level artifact paths.

**Implementation tasks:**

- Add `src/benecard_pa/document/rendering.py` for PyMuPDF page rendering.
- Add `src/benecard_pa/document/artifact_paths.py` or narrowly extend digest path helpers for
  page-level paths.
- Render only image-text-required PDF pages unless config requests retained page images.
- Use `ParsingSettings.render_dpi`.
- Write durable page images only when `parsing.save_page_images` is true.
- Allow temporary OCR images under configured temp/artifact paths when durable page images are
  disabled.
- Use document hash/document ID prefixes, not source filename prefixes.

**Affected areas:** `src/benecard_pa/document/rendering.py`,
`src/benecard_pa/document/artifact_paths.py`, `src/benecard_pa/document/digest.py`,
`tests/test_page_rendering.py`, `tests/test_provisional_digest.py`.

**Required tests:**

- Rendered images preserve original page numbers in metadata/path conventions.
- Artifact paths are deterministic and source-filename-safe.
- Rendering errors are PHI-safe and keep pages eligible for review flags.

**Acceptance criteria:** OCR can receive page images without losing original page identity or
leaking source filenames in artifact layout.

**Dependencies:** Workstream 1 model fields.

## Workstream 3: Tesseract OCR Service

**Purpose:** Implement local image-to-text execution through `pytesseract`.

**Implementation tasks:**

- Replace `OcrNotImplemented` in `src/benecard_pa/document/ocr.py` with a concrete
  `TesseractOcrEngine` while preserving the `OcrEngine` protocol.
- Use `pytesseract.image_to_data` when confidence is needed; fall back to `image_to_string` only if
  tactically justified.
- Use configured `parsing.ocr_languages`.
- Return structured OCR result data: raw text, average confidence where available, engine name,
  languages, status, and PHI-safe error details.
- Normalize OCR confidence to `0.0`-`1.0`; retain raw Tesseract confidence separately when
  available.
- Use `parsing.low_ocr_confidence_threshold` for low-confidence OCR review flags.
- Normalize OCR text through `normalize_extracted_text`.
- Convert missing binary and `pytesseract` errors into PHI-safe page-level failures.

**Affected areas:** `src/benecard_pa/document/ocr.py`,
`src/benecard_pa/document/normalizer.py`, `tests/test_ocr.py`.

**Required tests:**

- Mocked `pytesseract` success returns raw text, normalized text, and confidence.
- Mocked missing Tesseract path produces PHI-safe failure metadata.
- OCR errors do not include raw page text, source paths from third-party exceptions, or command
  output.
- Real Tesseract smoke test is skipped cleanly when binary is unavailable.

**Acceptance criteria:** Tesseract OCR is testable deterministically without requiring live external
services.

**Dependencies:** Workstream 2 page images or standalone image inputs.

## Workstream 4: Image-to-Text Router

**Purpose:** Centralize strategy selection while executing only Phase 2-approved behavior.

**Implementation tasks:**

- Add `src/benecard_pa/document/image_text.py` for `ImageTextRouter` or equivalent.
- Execute only `strategy == "tesseract"`.
- For `llm_vision`, `hybrid`, and `compare`, return a controlled deferred result or raise a
  PHI-safe unsupported strategy error before any model import/call.
- Route image-text-required PDF pages and standalone image pages through the same Tesseract path.
- Keep sufficient native text selected for native pages.
- Add review flags for OCR failures, empty OCR text, and deferred unsupported strategies.

**Affected areas:** `src/benecard_pa/document/image_text.py`,
`src/benecard_pa/document/parser.py`, `src/benecard_pa/document/models.py`,
`tests/test_image_text_router.py`.

**Required tests:**

- `tesseract` strategy executes mocked OCR for image-text-required pages.
- Native pages with sufficient text are not OCRed.
- `llm_vision`, `hybrid`, and `compare` do not import or call `litellm`.
- Deferred strategies do not change selected text.

**Acceptance criteria:** Strategy routing is explicit, bounded, and ready for later Phase 6
capability-gated LLM vision work.

**Dependencies:** Workstreams 1 through 3.

## Workstream 5: Artifact Writing and Digest Enrichment

**Purpose:** Write page-level extraction artifacts and reflect them in digest records.

**Implementation tasks:**

- Write raw OCR text only when `parsing.save_raw_text` is true.
- Write normalized OCR text only when `parsing.save_normalized_text` is true.
- Write OCR metadata JSON for attempted OCR pages.
- Use existing atomic write helpers when useful, but do not implement final review/output package
  assembly.
- Add `ocr_metadata` to artifact paths when available.
- Preserve every page in the digest, including OCR-failed pages.

**Affected areas:** `src/benecard_pa/document/image_text.py`,
`src/benecard_pa/document/digest.py`, possibly `src/benecard_pa/output/artifacts.py` for reusable
atomic helpers only, `tests/test_image_text_artifacts.py`, `tests/test_provisional_digest.py`.

**Required tests:**

- Raw and normalized text files are controlled by config flags.
- OCR metadata JSON is deterministic and JSON serializable.
- OCR-failed pages remain in the digest with failure/review flags.
- Artifact paths do not include source filenames.

**Acceptance criteria:** Digest records can lead a later phase to the page image, raw OCR text,
normalized OCR text, and OCR metadata generated for each OCR-attempted page.

**Dependencies:** Workstreams 1 through 4.

## Workstream 6: Verification and Documentation Close-Out

**Purpose:** Prove Phase 2 behavior and prevent phase leakage.

**Implementation tasks:**

- Keep Phase 1 tests passing.
- Add Phase 2-specific unit and integration tests.
- Add negative scope-control tests.
- Update traceability if implementation status changes.
- Update PRD, architecture, config reference, or governance/security only if implementation
  discovers a documented contract needs correction.

**Affected areas:** `tests/**`,
`docs/project/traceability/pa_document_intelligence_traceability_matrix.md`,
Phase 2 docs if scope/schema changes.

**Required tests:** All Workstream 1-5 tests plus existing repository tests.

**Acceptance criteria:** `config-check`, tests, and Ruff pass; documentation remains synchronized
with implemented behavior.

**Dependencies:** Workstreams 1 through 5.

## File and Module Ownership Expectations

Primary edit scope:

- `src/benecard_pa/document/models.py`
- `src/benecard_pa/document/ocr.py`
- `src/benecard_pa/document/parser.py`
- `src/benecard_pa/document/digest.py`
- `src/benecard_pa/document/rendering.py`
- `src/benecard_pa/document/image_text.py`
- `src/benecard_pa/document/artifact_paths.py`
- `src/benecard_pa/document/__init__.py` only if exports are needed
- `tests/test_ocr.py`
- `tests/test_page_rendering.py`
- `tests/test_image_text_router.py`
- `tests/test_image_text_artifacts.py`
- Existing parser/digest tests where Phase 2 metadata changes assertions

Use cautiously:

- `src/benecard_pa/output/artifacts.py` for reusable atomic write helpers only.
- `src/benecard_pa/settings.py` only if existing Phase 2 settings are insufficient.
- `config/app.example.yaml` only if a default must be corrected.

Avoid editing unless a documented blocker appears:

- `src/benecard_pa/llm/**`
- `src/benecard_pa/document/classifier.py`
- `src/benecard_pa/watcher/**`
- `src/benecard_pa/lifecycle.py`
- `src/benecard_pa/db/**`
- `src/benecard_pa/output/schema.py`
- `config/prompts.example.yaml`
- `config/review_schema.example.json`

## Data and Schema Changes

Allowed in-memory/page metadata additions:

- `image_text_strategy`
- `ocr_engine`
- `ocr_languages`
- `ocr_status`
- `ocr_confidence`
- `ocr_raw_confidence`
- `ocr_error`
- `selected_text_source`
- structured selected/alternate text extraction candidate metadata
- `artifact_paths["page_image"]`
- `artifact_paths["raw_text"]`
- `artifact_paths["normalized_text"]`
- `artifact_paths["ocr_metadata"]`

Recommended selected text source values:

- `native_pdf_text`
- `tesseract_ocr`
- `None` when no selected text is available

Recommended review flags:

- `image_text_required`
- `tesseract_ocr_failed`
- `empty_ocr_text`
- `low_ocr_confidence`
- `image_text_strategy_deferred`

No database migration or final review schema change is allowed in Phase 2.

## API, CLI, and Config Changes

- Preserve `uv run benecard-pa --config config/app.example.yaml config-check`.
- Do not add a new production CLI command.
- Do not rename YAML keys.
- Use existing config sections:
  `parsing`, `image_text_extraction`, `packet_digest`, `paths`, and `security`.
- Honor `parsing.render_dpi`, `parsing.ocr_languages`, `parsing.save_page_images`,
  `parsing.low_ocr_confidence_threshold`, `parsing.save_raw_text`, and
  `parsing.save_normalized_text`.
- Honor `image_text_extraction.strategy`, but execute only `tesseract` in Phase 2.
- Keep `packet_digest.artifact_layout == "document_id"`.

## Migration Order

1. Confirm current `config-check`, tests, and Ruff state.
2. Add/extend OCR and image-text model fields with compatibility tests.
3. Add deterministic artifact path helper tests.
4. Implement rendering with tests.
5. Implement mocked Tesseract OCR service tests and service code.
6. Implement image-text router tests and `tesseract` route.
7. Add deferred-strategy negative tests.
8. Add page artifact writing tests and implementation.
9. Enrich digest tests and implementation.
10. Add scope-leakage tests for no LiteLLM/classification/decomposition/lifecycle/watcher calls.
11. Run verification commands.
12. Update traceability and phase docs only for actual as-built changes.

## Security and Governance Work

- Treat rendered images, OCR text, normalized text, OCR metadata, and temporary OCR images as PHI.
- Keep artifact paths source-filename-safe.
- Ensure OCR/rendering errors are PHI-safe and do not chain source-path-bearing third-party
  exceptions into user-facing messages.
- Do not log raw OCR text by default.
- Do not store raw OCR text when `parsing.save_raw_text` is false.
- Do not call external APIs, LiteLLM, local model endpoints, arbitrary tools, watcher runtime,
  lifecycle movement, or SQLite persistence.
- Add tests proving deferred non-Tesseract strategies do not import/call `litellm`.
- Add tests proving Phase 2 image-text routing does not import or call classification,
  decomposition, watcher, lifecycle, SQLite persistence, tool-calling, or LLM workflow modules.

## Tests by Workstream

| Workstream | Test File | Required Coverage |
|---|---|---|
| Models | `tests/test_provisional_digest.py`, `tests/test_image_text_router.py` | OCR metadata fields, selected source, review flags. |
| Rendering | `tests/test_page_rendering.py` | DPI use, page number preservation, PHI-safe render errors, deterministic paths. |
| OCR service | `tests/test_ocr.py` | Mocked success, mocked failure, confidence handling, missing binary behavior. |
| Router | `tests/test_image_text_router.py` | Tesseract execution, native page skip, deferred strategy behavior, no LiteLLM or deferred module calls. |
| Artifacts | `tests/test_image_text_artifacts.py` | Raw/normalized text flags, OCR metadata JSON, page image flag behavior. |
| Digest enrichment | `tests/test_provisional_digest.py` | OCR metadata paths, selected source, no page drops after OCR. |
| Scope control | Dedicated negative tests or router/parser tests | No classification, decomposition, watcher, lifecycle, SQLite, tool calling, or LLM behavior. |

## Negative Tests

- `llm_vision`, `hybrid`, and `compare` do not import or call `litellm`.
- OCR failure does not drop the page from canonical document or digest output.
- Missing Tesseract does not expose raw command output, source path, or page text.
- Artifact paths do not include source filenames or patient identifiers from filenames.
- Native pages with sufficient text are not re-OCRed.
- Page type remains `unknown`; no PA form or physician note classification occurs.
- No source file is moved, copied to processed, archived, failed, or deleted.
- No SQLite write occurs.

## CLI, API, and UAT Checks

- Run `config-check` against `config/app.example.yaml`.
- Run library-level tests for OCR, rendering, router, artifacts, and digest enrichment.
- For UAT inspection, use approved non-PHI clinical samples to inspect temporary test artifacts:
  rendered page images, raw OCR text, normalized OCR text, OCR metadata JSON, and digest records.
- Do not add a production CLI for artifact inspection in Phase 2.

## Verification Commands

```bash
uv run benecard-pa --config config/app.example.yaml config-check
uv run pytest
ruff check .
```

If the OS Tesseract binary is unavailable, report which real-OCR integration checks were skipped
and keep mocked OCR unit tests mandatory.

## Acceptance Criteria

| Area | Acceptance Criteria |
|---|---|
| Rendering | Image-text-required PDF pages render at configured DPI with original page numbers preserved. |
| OCR | Tesseract OCR runs through `pytesseract` for selected pages/images under `strategy: tesseract`. |
| Text artifacts | Raw OCR text and normalized OCR text are written only when their config flags allow it. |
| Metadata | OCR metadata records engine, language, status, confidence when available, and PHI-safe errors. |
| Provenance | OCR metadata separates attempted text source from selected text source; failed/empty OCR does not claim Tesseract text was selected. |
| Selected text | Page records select native text when sufficient and Tesseract OCR text when OCR succeeds for image-text-required pages. |
| Alternate text | Native PDF text remains represented as an extraction candidate when OCR later becomes the selected text. |
| Digest | Digest pages include image-to-text strategy, selected source, OCR status/confidence, actual written artifact paths, and review flags. |
| Page retention | Blank, OCR-failed, low-confidence, unknown, and image-only pages remain represented exactly once. |
| Deferred strategies | Non-Tesseract strategies fail closed or return controlled deferred results without live LLM calls. |
| Scope control | No classification, decomposition, summarization, crosswalk, final review, watcher, lifecycle, SQLite, or tool-calling behavior is introduced. |
| Verification | `config-check`, tests, and Ruff pass, with any skipped Tesseract integration check explicitly reported. |

## Documentation Close-Out

Before Phase 2 is considered complete:

- Update this tactical plan if implementation discovers a necessary tactical correction.
- Update the Phase 2 build plan if scope changes.
- Update traceability rows for implemented/verified Phase 2 behavior.
- Update PRD, architecture, configuration reference, or governance/security only if contracts
  change.
- Keep `AGENTS.md` accurate if commands, methodology paths, or fixture policy changes.

## Implementation Close-Out

Implemented Phase 2 according to this tactical plan:

- image-to-text metadata fields on page and digest models;
- deterministic document-ID-safe page artifact path helpers;
- PyMuPDF page rendering;
- local `pytesseract` OCR service with PHI-safe failure metadata;
- Tesseract-only image-to-text router;
- page-level OCR artifacts and metadata JSON;
- digest enrichment for selected OCR source, strategy, status, confidence, artifact paths, and
  review flags;
- tests for OCR, rendering, router behavior, artifact flags, digest enrichment, and Phase 2 scope
  control.

Verification evidence:

- `uv run benecard-pa --config config/app.example.yaml config-check`
- `uv run pytest` (`56 passed`)
- `ruff check .`

## Deferred Items

- Live LiteLLM vision extraction.
- Hybrid strategy execution.
- Compare-mode execution with LLM vision.
- Page/component classification.
- Packet decomposition.
- Page/component summaries.
- PA form extraction and evidence crosswalk.
- Digest-driven analysis orchestration.
- Final review artifacts and SQLite indexing.
- Source lifecycle and watcher behavior.

## Risks

| Risk | Mitigation |
|---|---|
| Tesseract unavailable locally or in CI | Mock OCR for unit tests; skip real-OCR smoke tests with explicit reporting. |
| OCR output is weak on faxed packets | Preserve confidence/status/review flags and page image artifacts when configured. |
| Artifact paths leak source filenames | Centralize path construction and test with sensitive-looking filenames. |
| Phase 2 leaks into LLM vision | Negative tests block `litellm` imports/calls for non-Tesseract strategies. |
| Final output packaging sneaks into page artifact work | Keep artifact writes page-level only and leave final packaging to Phase 7. |

## Accuracy Pass

- **Implementation steps:** Workstreams cover model, rendering, OCR, routing, artifacts, digest, and
  verification.
- **Ownership:** Primary and avoided file scopes are explicit.
- **Tests:** Positive, negative, integration-skip, and scope-control tests are defined.
- **Migration:** The order preserves Phase 1 behavior before adding OCR execution.
- **Security:** Derived PHI handling, PHI-safe errors, source-filename-safe paths, and no live LLM
  behavior are explicit.
- **Documentation:** Traceability and source-authority updates are part of close-out, not optional.
- **Contradictions:** No contradiction with the Phase 2 build plan remains; executable scope is
  Tesseract-only.
