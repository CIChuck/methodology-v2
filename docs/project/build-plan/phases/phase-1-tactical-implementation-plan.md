# Phase 1 Tactical Implementation Plan: Fixture Manifest, Parser Foundation, and Provisional Packet Digest

**Status:** Implemented and verified  
**Date:** 2026-05-21  
**Phase:** 1  
**Source authority:** `docs/project/build-plan/phases/phase-1-fixture-parser-provisional-digest.md`, `docs/project/prd/pa_document_intelligence_prd.md`, `docs/project/architecture/pa_document_intelligence_architecture.md`, `docs/project/security-governance/governance-security-spec.md`, `docs/project/configuration/config_yaml_reference.md`, `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`, `docs/project/build-plan/phase-roadmap.md`  
**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/tactical-implementation-planner.md`

## Implementation Objective

Implement the first bounded vertical slice of the PA document intelligence system: fixture metadata,
supported-file dispatch, native PDF text extraction, standalone-image shell handling, low-text
page signaling, and a provisional packet digest with one inventory record per original page.

The implementation must make page identity stable without introducing OCR execution, LLM calls,
page classification, packet decomposition, summaries, crosswalk generation, watcher runtime
behavior, or source lifecycle movement.

## Questions and Assumptions

No blocking questions remain for implementation. The following assumptions should be treated as
tactical defaults unless later corrected by the user:

- Prefer generated synthetic fixtures in tests where practical; use committed static fixtures only
  when generation would make assertions brittle or hard to read.
- Use `image_text_required` as the Phase 1 field name for pages that require later Tesseract or
  LLM vision extraction.
- Treat PDFs under `docs/project/reference/clinical-samples/` as an approved non-PHI clinical
  reference corpus. They may be used for unit tests, integration tests, and user acceptance testing
  when assertions remain stable and appropriate for the test layer.
- Preserve existing public settings keys and CLI commands unless a source-authority document is
  updated in the same change.
- Reuse existing model names when they fit; add new dataclasses only where Phase 1 output needs a
  stable typed contract.

## Non-Goals

- Do not invoke Tesseract, `pytesseract`, LiteLLM, LLM vision extraction, hybrid extraction, or
  compare-mode extraction.
- Do not classify page type or packet component type.
- Do not split packets into physical files.
- Do not create page summaries, component summaries, PA form fields, evidence matches, or final
  review artifacts.
- Do not start the watcher, move source files, update lifecycle status, or persist digest rows to
  SQLite.
- Do not add a production parser CLI in Phase 1; preserve `config-check` only.

## Workstream 1: Fixture Manifest Foundation

**Purpose:** Provide safe, repeatable document fixtures and expectations for parser/digest tests.

**Implementation tasks:**

- Create `tests/fixtures/document_manifest.yaml`.
- Create fixture folders such as `tests/fixtures/documents/` and `tests/fixtures/unsupported/`.
- Add a small test helper, preferably `tests/fixtures/manifest.py` or `tests/conftest.py`, that
  loads the manifest without importing watcher or pipeline runtime behavior.
- Support manifest fields for `id`, `path`, `file_type`, `enabled`, `expected_page_count`,
  `expected_native_text_pages`, `expected_image_text_required_pages`, `expected_supported`, and
  `notes`.
- Add fixture guidance that committed fixtures must be synthetic, formally de-identified, or part
  of the approved non-PHI clinical reference corpus.

**Affected areas:** `tests/fixtures/**`, `tests/test_fixture_manifest.py`, optional
`tests/conftest.py`.

**Required tests:**

- Valid manifest loads and resolves enabled fixture paths.
- Missing enabled fixture path fails clearly.
- Disabled fixture entries do not block test execution.
- Fixture guidance rejects use of PHI-bearing files while allowing approved non-PHI clinical
  reference samples.

**Acceptance criteria:** Tests can enumerate fixture expectations without starting the application
pipeline or requiring Dropbox/runtime folders.

**Dependencies:** None.

## Workstream 2: Document Models and Parser Contracts

**Purpose:** Extend the current parser contract so every page can carry enough metadata for the
provisional digest.

**Implementation tasks:**

- Extend `src/benecard_pa/document/models.py` while preserving existing `CanonicalDocument` and
  `PageText` compatibility where practical.
- Add page fields or companion models for `image_text_required`, `text_status`,
  `selected_text_source`, `artifact_paths`, and review flags.
- Add digest dataclasses such as `ProvisionalPacketDigest` and `DigestPage` in
  `src/benecard_pa/document/models.py` or a new `src/benecard_pa/document/digest.py`.
- Keep `ExtractionMethod.NATIVE_PDF_TEXT` for native PDF text and add image-shell/unsupported
  status through enums or explicit fields without overloading OCR.

**Affected areas:** `src/benecard_pa/document/models.py`, optional
`src/benecard_pa/document/digest.py`, `src/benecard_pa/document/__init__.py`.

**Required tests:**

- Page records preserve original page numbers starting at 1.
- Digest records can represent text pages, low-text pages, and standalone image pages.
- Unknown page/component values remain explicit placeholders, not inferred classifications.

**Acceptance criteria:** The parser can return page-aware objects that the digest builder consumes
without lossy conversion.

**Dependencies:** Workstream 1 fixture expectations.

## Workstream 3: Parser Dispatch and Native PDF Extraction

**Purpose:** Replace the placeholder parser path with a safe Phase 1 parser for supported file
types.

**Implementation tasks:**

- Implement a concrete parser in `src/benecard_pa/document/parser.py`; retain the `DocumentParser`
  protocol.
- Dispatch PDFs to PyMuPDF native text extraction.
- Dispatch JPEG, PNG, TIFF, and common image aliases to standalone image shell handling.
- Reject unsupported extensions with PHI-safe errors that include metadata, not document content.
- Compute or accept `source_sha256` through the existing `src/benecard_pa/io.py` helper.
- Normalize native text through `src/benecard_pa/document/normalizer.py`.
- Apply `ParsingSettings.min_text_chars_per_page` for low-text detection.

**Affected areas:** `src/benecard_pa/document/parser.py`,
`src/benecard_pa/document/normalizer.py`, `src/benecard_pa/io.py`.

**Required tests:**

- Native PDF fixture returns one page object per original page.
- Native text is stored raw and normalized separately when available.
- Low-text PDF pages are flagged with `image_text_required`.
- Unsupported file type raises a PHI-safe parser error.
- Parser does not call OCR, LLM, watcher, lifecycle, database, or output modules.

**Acceptance criteria:** Supported inputs are parsed into canonical page records and unsupported
inputs fail safely without leaking raw text.

**Dependencies:** Workstream 2 model contract.

## Workstream 4: Standalone Image Shell Handling

**Purpose:** Allow images to enter the canonical document flow without running image-to-text
extraction in Phase 1.

**Implementation tasks:**

- Represent each standalone image as a one-page `CanonicalDocument`.
- Set `image_text_required` to `true`.
- Set selected text source to `null` or an explicit none value.
- Set text status to an image-text-needed value.
- Add deterministic placeholder artifact paths for future page image and text artifacts when
  packet digest settings request artifact paths.

**Affected areas:** `src/benecard_pa/document/parser.py`,
`src/benecard_pa/document/models.py`, optional `src/benecard_pa/document/digest.py`.

**Required tests:**

- PNG/JPEG/TIFF fixtures produce one-page documents.
- Image pages contain no fabricated text.
- Image pages are retained in the digest and flagged for later extraction.
- No `pytesseract` or LiteLLM import path is invoked during image shell handling.

**Acceptance criteria:** Image inputs are accepted as inventory pages and deferred to Phase 2 for
actual image-to-text processing.

**Dependencies:** Workstreams 2 and 3.

## Workstream 5: Provisional Packet Digest Builder

**Purpose:** Produce the first packet inventory artifact shape, without clinical interpretation.

**Implementation tasks:**

- Add a digest builder, preferably `src/benecard_pa/document/digest.py`.
- Generate `digest_version`, `source_path`, `source_sha256`, `page_count`, page records, review
  flags, and artifact layout metadata.
- Include one digest page per original page, even when text is empty, unknown, or low-confidence.
- Set `page_type` to `unknown`.
- Keep summary and component fields absent, empty, or null.
- Use deterministic artifact placeholders; do not write durable digest JSON in Phase 1 unless a
  test writes to a temporary directory.

**Affected areas:** `src/benecard_pa/document/digest.py`,
`src/benecard_pa/document/models.py`, `tests/test_provisional_digest.py`.

**Required tests:**

- Digest page count equals canonical document page count.
- Page numbers and source hash are preserved.
- Low-text and standalone-image pages produce review flags.
- Unknown pages are not dropped.
- Artifact placeholders are deterministic and relative to the configured output layout.

**Acceptance criteria:** The provisional digest can serve as a complete page inventory for later
image-to-text, classification, decomposition, summary, and crosswalk phases.

**Dependencies:** Workstreams 2 through 4.

## Workstream 6: Verification and Documentation Close-Out

**Purpose:** Prove Phase 1 scope is implemented and prevent drift into later phases.

**Implementation tasks:**

- Add focused unit tests for all Phase 1 workstreams.
- Keep existing tests stable.
- Run config validation, tests, and Ruff.
- Update traceability status only for rows directly implemented or verified by Phase 1.
- Update this tactical plan or the Phase 1 build plan if implementation discovers a schema decision
  that changes documented authority.

**Affected areas:** `tests/**`, `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`,
this file, and possibly `docs/project/build-plan/phases/phase-1-fixture-parser-provisional-digest.md`.

**Required tests:** All Workstream 1-5 tests plus existing repository tests.

**Acceptance criteria:** Verification commands pass and documentation reflects any implemented
schema decisions.

**Dependencies:** Workstreams 1 through 5.

## File and Module Ownership Expectations

Primary edit scope:

- `src/benecard_pa/document/models.py`
- `src/benecard_pa/document/parser.py`
- `src/benecard_pa/document/normalizer.py`
- `src/benecard_pa/document/digest.py` if introduced
- `src/benecard_pa/document/__init__.py` if exports are needed
- `tests/fixtures/**`
- `tests/test_fixture_manifest.py`
- `tests/test_document_parser.py`
- `tests/test_provisional_digest.py`
- `tests/conftest.py` only if shared fixture generation is needed

Avoid editing unless directly required:

- `src/benecard_pa/llm/**`
- `src/benecard_pa/watcher/**`
- `src/benecard_pa/lifecycle.py`
- `src/benecard_pa/db/**`
- `src/benecard_pa/output/**`
- `config/prompts.example.yaml`
- `config/review_schema.example.json`

Do not use this phase to refactor unrelated scaffolds.

## Data and Schema Changes

Phase 1 may introduce in-memory typed models for parser and digest output. It should not introduce
database migrations or final review schema changes.

Expected provisional digest page fields:

- `page_number`
- `page_type: "unknown"`
- `extraction_method`
- `text_status`
- `image_text_required`
- `selected_text_source`
- `raw_text_present`
- `normalized_text_present`
- `artifact_paths`
- `review_flags`

Expected digest-level fields:

- `digest_version`
- `source_path`
- `source_sha256`
- `page_count`
- `pages`
- `artifact_layout`
- `review_flags`

## API, CLI, and Config Changes

- Keep `uv run benecard-pa --config config/app.example.yaml config-check` passing.
- Do not add a new runtime CLI command in Phase 1.
- Do not rename existing YAML keys.
- Use `parsing.min_text_chars_per_page` for low-text detection and reject nonpositive values.
- Treat `packet_digest.digest_version`, `packet_digest.include_artifact_paths`, and
  `packet_digest.artifact_layout` as the relevant digest configuration inputs.
- Reject source-filename-based digest artifact layouts until a future PHI-safe layout is specified.
- Validate `image_text_extraction.strategy` shape and referenced LLM task/profile capabilities
  without executing image-to-text extraction in Phase 1.
- Do not use `image_text_extraction.strategy` to execute extraction in Phase 1; only mark pages
  requiring later extraction.

## Migration Order

1. Add fixture manifest and fixture helper tests.
2. Add or extend parser/digest models.
3. Implement parser dispatch and PHI-safe parser errors.
4. Implement native PDF extraction.
5. Implement standalone image shell behavior.
6. Implement low-text signaling.
7. Implement provisional digest builder.
8. Add negative scope-leakage tests.
9. Run verification commands.
10. Update documentation close-out and traceability if implementation status changes.

## Security and Governance Work

- Confirm no test fixture contains PHI-bearing source material, patient identifiers, extracted PHI,
  or raw LLM responses containing PHI. Approved non-PHI clinical samples under
  `docs/project/reference/clinical-samples/` are valid test inputs.
- Ensure parser and manifest errors do not print raw document text.
- Ensure corrupt supported-file parser errors do not expose source paths through chained library
  exceptions in user-facing paths.
- Treat raw text, normalized text, page images, digest JSON, and temporary artifacts as PHI-bearing
  by convention.
- Add tests or assertions proving Phase 1 does not call external APIs, LiteLLM, local model
  endpoints, Tesseract subprocesses, arbitrary tools, watcher runtime, lifecycle movement, or
  SQLite persistence.
- Keep source files in place; do not move, delete, archive, or quarantine source documents.

## Tests by Workstream

| Workstream | Test File | Required Coverage |
|---|---|---|
| Fixture manifest | `tests/test_fixture_manifest.py` | Valid load, missing enabled file, disabled fixture behavior, PHI-safe fixture guidance. |
| Models/contracts | `tests/test_document_parser.py`, `tests/test_provisional_digest.py` | Page number preservation, page metadata, unknown page placeholders. |
| PDF parser | `tests/test_document_parser.py` | Native PDF page count, raw/normalized text, low-text flag, unsupported-file error. |
| Image shell | `tests/test_document_parser.py` | One-page image document, no fabricated text, `image_text_required` flag. |
| Digest builder | `tests/test_provisional_digest.py` | One digest page per original page, review flags, deterministic artifact placeholders. |
| Scope control | `tests/test_document_parser.py` or dedicated test | No OCR, LLM, watcher, lifecycle, database, or output side effects. |

## Negative Tests

- Unsupported extension fails with a PHI-safe error.
- Missing enabled fixture path fails clearly.
- A blank or low-text PDF page is retained and flagged, not dropped.
- Standalone image parsing does not call Tesseract or LiteLLM.
- Parser does not import or invoke watcher/lifecycle movement.
- Digest builder does not infer PA form, physician notes, labs, fax cover, or any clinical page
  type.
- Parser errors and manifest errors do not include raw extracted text.

## CLI, API, and UAT Checks

Phase 1 UAT is test-driven rather than operator-driven:

1. Generate or load a synthetic native PDF fixture.
2. Generate or load a synthetic image fixture.
3. Run parser tests and inspect assertions for page count, text status, and
   `image_text_required` behavior.
4. Run digest tests and confirm every original page appears exactly once.
5. Run `config-check` to confirm current YAML remains valid.

No manual SFTP, Dropbox watcher, lifecycle movement, or LLM provider setup is required for Phase 1.

## Verification Commands

```bash
uv run benecard-pa --config config/app.example.yaml config-check
uv run pytest
ruff check .
```

## Acceptance Criteria

- Fixture manifest exists and is covered by tests.
- Supported PDF and image extensions dispatch into Phase 1 parser behavior.
- Unsupported files fail safely without raw document text in errors.
- Native PDF pages preserve original page numbers and raw/normalized text where available.
- Low-text PDF pages are marked `image_text_required`.
- Standalone images produce one canonical page and are marked `image_text_required`.
- Provisional digest contains one page record per original page.
- Digest records include page number, unknown page type, extraction/text status, selected text
  source, artifact placeholders, and review flags.
- No OCR, LLM, tool calling, classification, decomposition, summary, crosswalk, watcher, lifecycle,
  or SQLite persistence behavior is introduced.
- `config-check`, tests, and Ruff pass.

## Documentation Close-Out

Phase 1 implementation is not complete until:

- This tactical plan still matches the implemented module boundaries.
- `docs/project/build-plan/phases/phase-1-fixture-parser-provisional-digest.md` reflects any
  schema or sequencing changes discovered during implementation.
- `docs/project/traceability/pa_document_intelligence_traceability_matrix.md` marks only verified
  Phase 1 rows as `implemented` or `verified`.
- `AGENTS.md` remains accurate for commands, methodology paths, fixture safety, and PHI guidance.
- Any public field-name changes are reconciled into PRD, architecture, configuration reference, and
  traceability documents.

## Deferred Items

- Tesseract OCR execution, confidence extraction, and page image rendering.
- LLM vision extraction, hybrid strategy, compare strategy, and selected-text adjudication.
- Page classification and packet decomposition.
- Page/component summaries.
- PA form extraction and crosswalk evidence generation.
- LiteLLM task routing, tool calling, and LLM review.
- Durable output artifact writing and optional SQLite indexing.
- Source lifecycle movement, reprocessing, watcher runtime, and reconciliation.

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Fixture corpus changes during implementation. | Tests may churn. | Keep manifest flexible and prefer generated fixtures for parser basics. |
| Model changes break existing classifier tests. | Regression outside Phase 1 parser path. | Preserve existing `CanonicalDocument.normalized_text` behavior. |
| Low-text thresholds cause brittle assertions. | Tests fail across fixture generation changes. | Assert flag behavior with controlled synthetic fixtures. |
| Digest schema becomes too final. | Later phases are constrained by premature assumptions. | Use versioned provisional digest fields and nullable placeholders. |
| Scope drifts into OCR or LLM execution. | Governance and phase-boundary risk. | Add negative tests proving no OCR/LLM/tool calls occur. |

## Open Decisions

| Decision | Current Recommendation |
|---|---|
| Static versus generated synthetic fixtures | Generate fixtures in tests where stable; commit small synthetic files only if needed. |
| Final fixture corpus size | Keep open until test data aggregation completes. |
| Exact digest class names | Prefer `ProvisionalPacketDigest` and `DigestPage` unless implementation finds cleaner existing names. |
| Exact no-text status enum values | Use clear internal values such as `native_text`, `low_text`, `image_text_required`, and `unsupported`; reconcile if public. |
| Durable digest JSON in Phase 1 | Do not write durable JSON outside temporary tests; durable artifact writing belongs to Phase 7. |

## Accuracy Pass

- **Missing implementation steps:** Covered fixture manifest, models, parser dispatch, native PDF,
  image shell, low-text signaling, digest builder, verification, and documentation close-out.
- **Vague ownership:** Primary and avoided file scopes are explicitly listed.
- **Missing tests:** Positive, negative, scope-control, and UAT checks are defined.
- **Missing migration steps:** Ordered implementation sequence is included; no database migration is
  allowed.
- **Security/governance verification:** PHI fixture rules, safe errors, and no external execution
  checks are included.
- **CLI/API/UAT evidence:** `config-check`, parser/digest test UAT, and verification commands are
  included.
- **Documentation gaps:** Close-out requires build plan, traceability, AGENTS, and public field-name
  reconciliation.
- **Contradictions:** No contradictions found with the Phase 1 build plan, PRD, architecture,
  governance spec, configuration reference, traceability matrix, or phase roadmap.
