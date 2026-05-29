# Phase 2 AI Construction Directive: Image-to-Text Execution and Page Artifacts

**Status:** Executed for Phase 2 implementation  
**Date:** 2026-05-21  
**Phase:** 2  
**Directive type:** AI construction directive  
**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/ai-construction-directive-builder.md`

## AI Builder Role

You are the implementation agent for Phase 2 of the BeneCard PA Document Intelligence project. Your
job is to implement the bounded image-to-text execution and page artifact layer exactly as
authorized here. Do not infer or add later-phase behavior.

## Source Authority and Precedence

Use these documents in this order:

1. `docs/project/build-plan/phases/phase-2-tactical-implementation-plan.md`
2. `docs/project/build-plan/phases/phase-2-image-text-execution-page-artifacts.md`
3. `docs/project/security-governance/governance-security-spec.md`
4. `docs/project/architecture/pa_document_intelligence_architecture.md`
5. `docs/project/prd/pa_document_intelligence_prd.md`
6. `docs/project/configuration/config_yaml_reference.md`
7. `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`
8. `docs/project/build-plan/phase-roadmap.md`
9. `AGENTS.md`

If these documents conflict, follow the higher-precedence document and report the conflict in the
implementation summary. Do not silently change architecture, requirements, or security behavior.

## Implementation Objective

Build Phase 2's page-level image-to-text layer:

- render PDF pages that require image-to-text extraction;
- run local Tesseract OCR through `pytesseract`;
- process standalone images through the same Tesseract path;
- write page-level extraction artifacts when configured;
- enrich page and digest metadata with image-to-text strategy, OCR status, confidence, selected
  text source, artifact paths, and review flags;
- preserve Phase 1 page identity and no-page-drop guarantees.

The implementation is page-text infrastructure only. It must not perform clinical interpretation.

## Allowed Scope

You may edit:

- `src/benecard_pa/document/models.py`
- `src/benecard_pa/document/ocr.py`
- `src/benecard_pa/document/parser.py`
- `src/benecard_pa/document/digest.py`
- `src/benecard_pa/document/rendering.py` if introduced
- `src/benecard_pa/document/image_text.py` if introduced
- `src/benecard_pa/document/artifact_paths.py` if introduced
- `src/benecard_pa/document/__init__.py` only if exports are needed
- `src/benecard_pa/output/artifacts.py` only for reusable atomic write helpers
- `src/benecard_pa/settings.py` only if existing Phase 2 settings are insufficient
- `tests/test_ocr.py`
- `tests/test_page_rendering.py`
- `tests/test_image_text_router.py`
- `tests/test_image_text_artifacts.py`
- `tests/test_document_parser.py`
- `tests/test_provisional_digest.py`
- Phase 2 documentation close-out files only when implementation reveals an actual schema, scope,
  or status correction.

Keep edits narrow. Do not refactor unrelated scaffolds.

## Explicit Non-Goals

Do not implement or invoke:

- LiteLLM calls;
- public model APIs or local model endpoints;
- production `llm_vision`, `hybrid`, or `compare` execution;
- LLM tool calling or tool registry behavior;
- page classification;
- packet decomposition;
- page or component summaries;
- PA form field extraction;
- evidence workspace or crosswalk generation;
- final review JSON or Markdown output;
- SQLite tables, migrations, indexing, or persistence;
- Dropbox watcher runtime behavior;
- source lifecycle movement into `processed`, `failed`, `archive`, or quarantine folders;
- new production processing CLI commands.

Preserve `config-check`. Phase 2 may write page-level extraction artifacts, but it must not build
the final output package owned by Phase 7.

## Required Workstreams

### 1. Image-to-Text Models

Extend the page and digest contracts to carry OCR metadata without breaking Phase 1 behavior.

Represent, directly or through companion dataclasses:

- `image_text_strategy`;
- `ocr_engine`;
- `ocr_languages`;
- `ocr_status`;
- `ocr_confidence`;
- optional PHI-safe `ocr_error` or `image_text_error`;
- selected text source;
- page image, raw text, normalized text, and OCR metadata artifact paths;
- review flags.

Recommended selected text source values:

- `native_pdf_text`;
- `tesseract_ocr`;
- `None` when no selected text is available.

Keep page type as `unknown`. Do not add PA component or evidence fields.

### 2. Rendering and Artifact Path Helpers

Implement page rendering and deterministic path helpers.

Requirements:

- use PyMuPDF for rendering;
- use `ParsingSettings.render_dpi`;
- render image-text-required PDF pages;
- preserve original page numbers;
- use document hash/document ID prefixes, not source filename prefixes;
- write durable page images only when `parsing.save_page_images` is true;
- allow temporary OCR images when durable page images are disabled;
- return PHI-safe render failures without exposing raw page text or chained source-path-bearing
  library exceptions.

### 3. Tesseract OCR Service

Implement a concrete Tesseract OCR engine in `src/benecard_pa/document/ocr.py` while preserving the
`OcrEngine` protocol.

Requirements:

- call `pytesseract` package APIs, not ad hoc shell commands;
- use configured `parsing.ocr_languages`;
- prefer `image_to_data` when extracting confidence;
- return raw OCR text, normalized OCR text, average confidence when available, engine name,
  languages, status, and PHI-safe error details;
- convert missing binary and `pytesseract` failures into page-level failures and review flags;
- do not log raw OCR text by default.

### 4. Image-to-Text Router

Add a document-layer router, preferably `src/benecard_pa/document/image_text.py`, that centralizes
strategy behavior.

Requirements:

- execute only `image_text_extraction.strategy == "tesseract"` in Phase 2;
- skip OCR for native pages with sufficient selected native text;
- route image-text-required PDF pages and standalone images through Tesseract;
- for `llm_vision`, `hybrid`, and `compare`, fail closed or return a controlled deferred result
  before any model import or call;
- never import or call `litellm` in Phase 2 executable paths;
- do not change selected text for deferred non-Tesseract strategies.

### 5. Page-Level Artifact Writing and Digest Enrichment

Write only page-level extraction artifacts.

Requirements:

- write raw OCR text only when `parsing.save_raw_text` is true;
- write normalized OCR text only when `parsing.save_normalized_text` is true;
- write OCR metadata JSON for attempted OCR pages;
- add `ocr_metadata` to artifact paths when available;
- enrich digest pages with image-to-text strategy, OCR status, OCR confidence, selected text source,
  artifact paths, and review flags;
- retain every page, including blank pages, OCR-failed pages, low-confidence pages, unknown pages,
  and image-only pages;
- use atomic write helpers where appropriate;
- do not implement final review/output packaging or SQLite indexing.

### 6. Verification and Documentation Close-Out

Keep Phase 1 tests passing. Add Phase 2 tests and update traceability only for behavior actually
implemented and verified. Do not mark deferred behavior as implemented.

## Migration and Removal Instructions

- Preserve Phase 1 parser behavior for native PDFs, standalone image recognition, low-text flags,
  and provisional digest page identity.
- Do not rename public YAML keys.
- Do not introduce database migrations.
- Do not change final review schema.
- Do not remove existing prompt, schema, database, output, lifecycle, classifier, watcher, or LLM
  scaffolds.
- If artifact path schema changes from current placeholders, update tests and source-authority docs
  in the same implementation pass.
- Leave unrelated user-created or untracked files alone. Do not delete notes, scratch files, or
  generated-looking documents without explicit user approval.

## Security and Governance Requirements

- Treat rendered images, OCR text, normalized text, OCR metadata, temporary OCR images, and digest
  artifacts as PHI-bearing by convention.
- Files under `docs/project/reference/clinical-samples/` are approved non-PHI reference samples and
  may be used for unit tests, integration tests, and UAT.
- Artifact paths must use document/run identity and must not use source filenames as layout keys.
- OCR, rendering, and router errors must be PHI-safe and must not include raw page text, raw OCR
  text, command output, patient identifiers, or chained source-path-bearing third-party exceptions.
- Tesseract execution is local only.
- Do not call external APIs, LiteLLM, local model endpoints, arbitrary tools, watcher runtime,
  lifecycle movement, or SQLite persistence.
- Do not weaken any setting, security, or governance behavior described in
  `docs/project/security-governance/governance-security-spec.md`.
- Any fixture-only LLM vision comparison requires an explicit build-plan remediation before
  implementation. It is not authorized by this directive.

## Testing Requirements

Add or update tests covering:

- existing Phase 1 parser and digest tests still pass;
- model/digest metadata for OCR status, confidence, selected source, and artifact paths;
- PDF page rendering preserves page numbers and uses configured DPI;
- rendering failures are PHI-safe;
- mocked `pytesseract` success returns raw text, normalized text, and confidence;
- mocked missing Tesseract or OCR failure returns PHI-safe failure metadata;
- real Tesseract smoke test is skipped cleanly when the OS binary is unavailable;
- `tesseract` strategy executes mocked OCR for image-text-required pages;
- native pages with sufficient selected text are not OCRed;
- standalone images route through Tesseract;
- raw and normalized text artifacts honor config flags;
- OCR metadata JSON is deterministic and JSON serializable;
- OCR-failed pages remain in canonical document and digest records;
- artifact paths do not include source filenames;
- `llm_vision`, `hybrid`, and `compare` do not import or call `litellm`;
- no classification, decomposition, summarization, crosswalk, watcher, lifecycle, SQLite, final
  review, or tool-calling side effects occur.

Existing tests must continue to pass.

## Verification Commands

Run:

```bash
uv run benecard-pa --config config/app.example.yaml config-check
uv run pytest
ruff check .
```

If the OS Tesseract binary is unavailable, report which real-OCR integration checks were skipped.
Do not claim verification passed unless it actually passed. Mocked OCR unit tests remain mandatory.

## CLI, API, and UAT Requirements

Phase 2 does not add a production processing CLI.

UAT/inspection is library- and artifact-driven:

1. Use approved non-PHI clinical samples or generated synthetic fixtures.
2. Render image-text-required pages in test/temp artifact locations.
3. Run Tesseract OCR or mocked OCR depending on test layer.
4. Inspect page image, raw OCR text, normalized OCR text, OCR metadata JSON, and digest metadata.
5. Run `config-check`, tests, and Ruff.

No SFTP, Dropbox watcher, lifecycle movement, model provider, SQLite persistence, or final review
output setup is required for Phase 2.

## Documentation Close-Out

After implementation:

- Update `docs/project/traceability/pa_document_intelligence_traceability_matrix.md` only for rows
  directly implemented or verified by Phase 2.
- Update `docs/project/build-plan/phases/phase-2-image-text-execution-page-artifacts.md` or
  `docs/project/build-plan/phases/phase-2-tactical-implementation-plan.md` only if implementation
  discovers a real schema, scope, or sequencing correction.
- Update PRD, architecture, configuration reference, or governance/security only if a documented
  contract changes.
- Keep `AGENTS.md` accurate if commands, methodology paths, or fixture-safety guidance change.
- Do not mark deferred features as implemented.

## Reporting Requirements

In the implementation summary, report:

- files changed;
- what Phase 2 behavior was implemented;
- what tests were added or updated;
- verification command results;
- any Tesseract integration checks skipped and why;
- any documentation close-out performed;
- any source-authority conflict found;
- any deferred feature intentionally left unimplemented;
- any residual risk or follow-up needed before Phase 3.

## Stop Conditions

Stop and ask for direction before proceeding if:

- implementation appears to require live LiteLLM, public model APIs, or local model endpoints;
- `llm_vision`, `hybrid`, or `compare` must execute live behavior to satisfy a test;
- artifact requirements appear to require final review output packaging or SQLite indexing;
- source lifecycle movement becomes necessary;
- public YAML keys or final output schemas appear to require renaming;
- PHI-bearing fixtures outside the approved non-PHI reference corpus would need to be committed;
- parser/OCR behavior would require changing PRD, architecture, or governance authority beyond a
  minor schema reconciliation;
- required Python dependencies are missing from `pyproject.toml` and cannot be resolved through the
  existing `uv` workflow.

## Anti-Drift Instructions

- Do not broaden scope.
- Do not implement deferred features.
- Do not silently change architecture.
- Do not weaken security/governance behavior.
- Do not remove unrelated code.
- Do not delete untracked/user-created files without explicit approval.
- Do not mark planned behavior as implemented unless it is implemented and verified.
- Keep Phase 2 focused on local Tesseract image-to-text execution, page-level artifacts, and digest
  enrichment.

## Accuracy Pass

- **Tactical workstreams represented:** Models, rendering, OCR service, image-to-text router,
  page-level artifact writing, digest enrichment, verification, and documentation close-out are all
  included.
- **Required tests represented:** Positive, negative, scope-control, skipped-integration, and
  UAT-style checks are included.
- **Non-goals explicit:** Live LLM vision, hybrid/compare execution, tool calling, classification,
  decomposition, summaries, crosswalk, final output packaging, persistence, watcher, lifecycle, and
  new production CLI commands are prohibited.
- **Migration behavior explicit:** No database migrations, no public config renames, no final schema
  changes, and no unrelated scaffold removal.
- **Security/governance included:** Derived PHI handling, source-filename-safe paths, PHI-safe
  errors, no external/model/tool execution, and no source lifecycle movement are required.
- **Reporting clear:** Builder must report files changed, verification, skipped OCR integration
  checks, documentation close-out, conflicts, deferred behavior, and residual risks.
