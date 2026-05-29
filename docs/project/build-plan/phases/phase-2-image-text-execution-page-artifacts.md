# Phase 2 Build Plan: Image-to-Text Execution and Page Artifact Generation

**Status:** Implemented and verified  
**Date:** 2026-05-21  
**Phase:** 2  
**Source authority:** `docs/project/vision/pa_document_intelligence_vision.md`, `docs/project/prd/pa_document_intelligence_prd.md`, `docs/project/architecture/pa_document_intelligence_architecture.md`, `docs/project/security-governance/governance-security-spec.md`, `docs/project/configuration/config_yaml_reference.md`, `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`, `docs/project/build-plan/phase-roadmap.md`  
**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/phase-build-planner.md`

## Executive Summary

Phase 2 turns Phase 1's image-text-needed signals into executable image-to-text processing. It adds
page rendering for PDFs, Tesseract OCR execution for scanned/faxed pages and standalone images,
page-level text artifacts, OCR metadata, selected text-source metadata, and enriched packet digest
records while preserving original page identity.

This phase remains focused on page text availability. It does not classify pages, decompose packets,
summarize pages, extract PA form fields, build the evidence crosswalk, run final LLM review, expose
LLM tool calling, move source files, or run the Dropbox watcher. Live LiteLLM vision extraction is
deferred to Phase 6 unless a later remediation pass explicitly narrows a fixture-only evaluation
path with governance approval and no production routing.

Phase 2 may write page-level extraction artifacts needed to make OCR output auditable. It must not
turn those artifacts into the final review package, durable run index, or operator-facing output
workflow; those responsibilities remain Phase 7 and later.

## Phase Objective

Create a reliable page-level image-to-text layer that can answer:

- Which pages required image-to-text extraction?
- Which page image artifact was used for extraction?
- What raw and normalized text was produced?
- What method produced the selected text?
- What confidence or review flags should downstream phases see?

The output of this phase is an enriched canonical document and packet digest. Downstream phases
should be able to classify, summarize, decompose, and analyze packet pages without re-rendering or
re-running OCR unless explicitly reprocessed.

## In Scope

- Render PDF pages that require image-to-text extraction using configured DPI.
- Treat standalone images as page 1 and route them through image-to-text execution.
- Run Tesseract through the configured Python package and local OS Tesseract binary.
- Preserve original page numbers for every rendered page and OCR result.
- Store page image artifacts when configured.
- Store raw OCR text and normalized OCR text when configured.
- Add OCR metadata artifacts, including engine, language, status, confidence when available, and
  error/review flags.
- Record normalized OCR confidence on a `0.0`-`1.0` scale and retain raw Tesseract confidence
  separately when available.
- Update page records with `selected_text_source`, extraction method, image-to-text strategy, text
  status, artifact paths, and review flags.
- Separate `attempted_text_source` from `selected_text_source` in OCR metadata so failed or empty
  OCR attempts do not claim Tesseract text was selected.
- Keep native PDF text selected when it is sufficient.
- Use Tesseract as the default `image_text_extraction.strategy`.
- Add an image-to-text router interface that can represent `tesseract`, `llm_vision`, `hybrid`, and
  `compare` strategy decisions without executing deferred live LLM behavior.
- Add deterministic artifact paths under the document-ID layout already required by Phase 1.
- Keep page-level artifacts limited to extraction support: rendered page image, raw OCR text,
  normalized OCR text, and OCR metadata.
- Preserve `config-check`, tests, and Ruff.

## Out of Scope

- Live LiteLLM vision calls.
- Production `llm_vision`, `hybrid`, or `compare` execution.
- LLM tool calling.
- Page classification into PA form, physician notes, labs, fax covers, or other components.
- Packet decomposition.
- Page or component summarization.
- PA form field extraction.
- Evidence workspace or crosswalk construction.
- Final review JSON or Markdown output.
- SQLite persistence, final artifact indexing, and final output packaging beyond preserving existing
  optional config compatibility.
- Source lifecycle movement.
- Dropbox watcher and reconciliation loop.
- UI, work queue, triage workflow, or adjudication behavior.

## Deferred Items

| Deferred Item | Target |
|---|---|
| Live LiteLLM vision extraction for `image_text_extraction` | Phase 6 unless separately approved for fixture-only evaluation |
| Hybrid fallback execution using OCR confidence/page-type rules | Phase 6 after task routing and capability gating |
| Compare-mode execution that runs both Tesseract and LLM vision | Phase 6 or controlled evaluation harness |
| Page classification and logical packet decomposition | Phase 3 |
| Digest page and component summaries | Phase 3 |
| PA form extraction and form-to-evidence crosswalk | Phase 4 |
| Digest-driven analysis orchestration | Phase 5 |
| Durable final output artifacts and SQLite indexing | Phase 7 |
| Source lifecycle and operator process/reprocess commands | Phase 8 |
| Dropbox watcher and reconciliation loop | Phase 9 |

## Dependencies

- Phase 1 parser, canonical document, fixture manifest, and provisional digest foundation.
- Python dependencies already managed by `uv`.
- PyMuPDF for rendering PDF pages.
- Pillow for image validation and artifact handling.
- `pytesseract` Python package.
- Tesseract installed on the operating system.
- Existing `pyproject.toml` and `uv.lock` entries for PyMuPDF, Pillow, and `pytesseract`.
- Approved non-PHI reference samples under `docs/project/reference/clinical-samples/`.
- Existing YAML configuration for `parsing`, `image_text_extraction`, `packet_digest`, `paths`, and
  `security`.

## Assumptions

- Tesseract is available locally for developer and test environments that run OCR integration
  tests.
- Tests that require the OS Tesseract binary may be skipped or marked with a clear reason when the
  binary is unavailable.
- Page images, OCR text, normalized text, and OCR metadata are PHI-bearing artifacts even when test
  inputs are approved non-PHI.
- File-only mode remains valid; SQLite is not required for Phase 2 acceptance.
- Phase 2 may introduce module boundaries needed by later LLM vision extraction, but must not call
  public model APIs or local model endpoints.
- OCR artifacts produced in this phase are page-level extraction artifacts, not final review output
  artifacts.

## Workstreams

### 1. Image-to-Text Domain Model

- Extend page text/extraction models to represent OCR outputs, OCR confidence, extraction errors,
  selected text source, alternate extraction placeholders, and strategy metadata.
- Ensure model names align with the architecture terms `CanonicalDocument`, `Page`, and
  `PacketDigest`.
- Avoid adding PA component or evidence fields that belong to later phases.

### 2. Page Rendering and Image Artifact Paths

- Render only pages that require image-to-text extraction unless configuration explicitly requests
  retained page images for all pages.
- Use `parsing.render_dpi`.
- Write deterministic paths under the document-ID artifact layout.
- Preserve original page numbers in filenames, metadata, and digest records.
- Avoid source-filename-derived output folders.

### 2.1 Artifact Ownership Boundary

- Phase 2 may create page-level artifacts required to audit image-to-text extraction.
- Phase 2 may update digest page records with deterministic artifact paths.
- Phase 2 must not implement final review artifact assembly, final human-readable summaries, run
  status indexing, or SQLite-backed artifact discovery.
- Phase 7 remains responsible for durable output packaging, optional SQLite indexing, and final
  review artifacts.

### 3. Tesseract OCR Service

- Add a focused OCR service that calls `pytesseract` for selected page images.
- Use configured languages from `parsing.ocr_languages`.
- Capture raw OCR text, normalized OCR text, confidence when available, engine metadata, and
  PHI-safe errors.
- Apply `parsing.low_ocr_confidence_threshold` to normalized confidence values for
  low-confidence review flags.
- Do not shell out directly if the package API provides the needed behavior.
- Fail the page with review flags when Tesseract is missing, errors, or returns unusable text.

### 4. Image-to-Text Router

- Route Phase 2 executable work through a strategy boundary.
- Implement `tesseract` execution.
- For `llm_vision`, `hybrid`, and `compare`, validate configuration and return a controlled
  unsupported/deferred result unless a later plan explicitly authorizes fixture-only execution.
- If fixture-only LLM vision comparison is later authorized, it must be added by a scoped
  remediation to this build plan before tactical implementation begins.
- Keep full packet PDFs and full packet image sets out of all extraction requests.

### 5. Digest Enrichment

- Update the provisional digest with image-to-text strategy, selected text source, OCR status,
  confidence, actual written page image path, raw text path, normalized text path, OCR metadata
  path, and image-to-text failure/review flags.
- Retain every original page, including blank, low-text, failed OCR, and unknown pages.
- Keep page type as `unknown` until Phase 3.

### 6. Test and Fixture Coverage

- Add generated synthetic image fixtures where possible.
- Use approved non-PHI clinical samples for scanned/faxed packet coverage.
- Add tests for OCR success, OCR failure, missing Tesseract behavior, artifact path generation,
  digest enrichment, and no page drops.
- Add negative tests proving Phase 2 does not import or call LiteLLM, page classification,
  decomposition, crosswalk, watcher, lifecycle movement, or tool-calling modules.

## Sequencing

1. Confirm current Phase 1 tests remain green.
2. Add or refine image-to-text model fields.
3. Add deterministic artifact path helpers for page images and OCR outputs.
4. Implement page rendering for image-text-required PDF pages.
5. Implement standalone image artifact normalization/copy behavior.
6. Implement Tesseract OCR service.
7. Implement router behavior for `tesseract` and deferred strategy outcomes for non-Tesseract modes.
8. Enrich canonical document pages with OCR outputs and selected text metadata.
9. Enrich packet digest records with artifact paths and OCR metadata.
10. Add automated tests and fixture assertions.
11. Run `config-check`, `pytest`, and Ruff.
12. Reconcile documentation and traceability.

## Migration and Removal Requirements

- Preserve Phase 1 parser behavior for native PDFs and standalone image recognition.
- Do not rename public YAML keys.
- Do not remove existing LiteLLM, prompt, database, lifecycle, output, or watcher scaffolds unless
  they directly block Phase 2 and the tactical implementation plan calls it out.
- If artifact path schema changes from Phase 1 placeholders, update PRD, architecture,
  configuration reference, traceability, and tests in the same phase.
- Keep legacy tests for parser/digest page identity passing.

## Security and Governance Implications

- Page images, OCR text, normalized text, and OCR metadata are derived PHI.
- Artifact paths must use document/run identity, not source filenames.
- OCR and rendering errors must be PHI-safe and must not expose raw page text.
- Tesseract execution is local only; no external API or LiteLLM call is authorized in this phase.
- Raw OCR text storage must honor `parsing.save_raw_text`.
- Normalized text storage must honor `parsing.save_normalized_text`.
- Page image storage must honor `parsing.save_page_images`, except temporary images required for
  Tesseract execution may be created under configured temp/artifact paths and handled as PHI.
- Missing Tesseract or OCR failure must create auditable page-level review flags rather than
  silently dropping pages.
- Any fixture-only LLM vision comparison would require an explicit plan update, provider approval,
  capability-gated task profile, selected-page-only inputs, no raw response storage by default, and
  tests proving no full packet image/PDF submission.

## Test Strategy

Required automated tests:

- Existing Phase 1 parser and digest tests still pass.
- PDF page rendering preserves page count and original page numbers.
- Image-only PDF pages run through Tesseract when strategy is `tesseract`.
- Standalone JPEG/PNG/TIFF and common aliases can produce OCR attempts.
- Raw OCR text and normalized OCR text are separated when configured.
- Artifact paths are deterministic and source-filename-safe.
- Digest records include selected text source and OCR metadata paths after OCR.
- OCR failures keep pages in the digest with review flags.
- Missing OS Tesseract produces a clear skipped integration test or PHI-safe failure path.
- Non-Tesseract strategies do not make live LLM calls in Phase 2.
- Deferred `llm_vision`, `hybrid`, and `compare` strategy paths fail closed or return controlled
  deferred results without changing selected text.
- No classification, decomposition, summarization, crosswalk, watcher, lifecycle movement, or LLM
  tool calling occurs.

Verification commands:

```bash
uv run benecard-pa --config config/app.example.yaml config-check
uv run pytest
ruff check .
```

## CLI, API, and UAT Strategy

- Preserve `config-check`.
- Do not add a new production processing CLI command in Phase 2 unless the tactical implementation
  plan proves it is needed for artifact inspection.
- Prefer library-level tests for parser/image-to-text services.
- UAT may use approved non-PHI clinical samples to inspect rendered page images, OCR text, OCR
  metadata, and enriched digest records.
- Any temporary inspection script must stay outside production CLI scope unless promoted by a later
  phase plan.

## Acceptance Criteria

| Area | Acceptance Criteria |
|---|---|
| Rendering | Image-text-required PDF pages can be rendered with configured DPI while preserving original page numbers. |
| Tesseract OCR | Tesseract runs for selected pages/images when `image_text_extraction.strategy` is `tesseract`. |
| Standalone images | Standalone supported image files are processed as page 1 through the Tesseract path. |
| Text separation | Raw OCR text and normalized OCR text are available separately according to config. |
| Selected source | Page records identify whether native text or Tesseract OCR text is selected. |
| Artifact paths | Page image, raw text, normalized text, and OCR metadata paths are deterministic and do not use source filenames as layout keys. |
| Digest enrichment | Packet digest page records include image-to-text strategy, selected text source, OCR status, confidence when available, artifact paths, and review flags. |
| Page retention | Blank, failed OCR, low-confidence, unknown, and image-only pages remain in the digest. |
| Failure handling | Missing Tesseract or OCR errors produce PHI-safe page/run errors and review flags. |
| Scope control | No live LiteLLM call, LLM tool call, classification, decomposition, summarization, crosswalk, watcher loop, or lifecycle movement is introduced. |
| Deferred strategies | `llm_vision`, `hybrid`, and `compare` do not execute live LLM behavior in this phase unless the build plan is explicitly remediated before tactical implementation. |
| Verification | `config-check`, tests, and Ruff pass. |

## Documentation Close-Out

Phase 2 is not complete until:

- This build plan reflects the implemented phase scope.
- A Phase 2 tactical implementation plan exists and is reconciled with this build plan.
- The Phase 2 AI construction directive is generated after tactical planning.
- The traceability matrix is updated for Phase 2 rows that become implemented or verified.
- PRD, architecture, configuration reference, and governance/security spec are updated if artifact
  schema, OCR metadata, or security behavior changes.
- `AGENTS.md` remains accurate for commands, methodology paths, and PHI fixture handling.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Tesseract unavailable in developer/CI environment | OCR tests may fail inconsistently. | Use explicit availability checks, focused integration markers, and PHI-safe failure tests. |
| Poor fax quality creates unusable OCR text | Downstream phases may classify or analyze weak text. | Preserve confidence/status metadata and review flags; keep page images for later review when configured. |
| Artifact storage leaks source names | PHI or patient identifiers may appear in paths. | Keep document-ID artifact layout and test path naming. |
| OCR execution accidentally expands into LLM vision | Scope drift and governance exposure. | Add negative tests blocking LiteLLM imports/calls in Phase 2 executable paths. |
| Text normalization alters clinical meaning | Evidence matching may later be wrong. | Keep normalization conservative and retain raw text when configured. |
| Digest drops OCR-failed pages | Packet inventory becomes incomplete. | Test no-page-drop behavior for OCR failures and blank pages. |

## Open Decisions

| Decision | Status |
|---|---|
| Exact OCR confidence aggregation method from Tesseract output | Tactical implementation decision. |
| Whether CI should require OS Tesseract or skip OCR integration tests when unavailable | Tactical implementation decision. |
| Whether Phase 2 should include a fixture-only LLM vision comparison harness | Deferred unless explicitly approved before tactical implementation. |
| Exact artifact file extensions and metadata schema for OCR JSON | Tactical implementation decision, must remain deterministic and traceable. |

## Remediation Pass

This pass reconciles the Phase 2 build plan against the current PRD, architecture, governance
specification, configuration reference, traceability matrix, phase roadmap, and Phase 1 closeout.

| Finding | Severity | Remediation |
|---|---|---|
| Phase roadmap allows LLM vision comparison in Phase 2 where governance permits, while Phase 6 owns the full LiteLLM vision boundary if deferred. | High | Kept Phase 2 executable scope to Tesseract only; recorded live LLM vision, hybrid, and compare execution as deferred unless this build plan is explicitly remediated before tactical implementation. |
| Page/OCR artifact generation could be confused with Phase 7 final output packaging and SQLite indexing. | High | Added an artifact ownership boundary: Phase 2 may create page-level extraction artifacts and digest paths; Phase 7 owns final review artifacts, output packaging, and optional SQLite indexing. |
| Dependency assumptions did not explicitly confirm that Python OCR/rendering packages are already managed by `uv`. | Medium | Added dependency language for existing `pyproject.toml` and `uv.lock` entries for PyMuPDF, Pillow, and `pytesseract`, while keeping OS Tesseract as an environment prerequisite. |
| Deferred strategy behavior lacked an acceptance criterion. | Medium | Added deferred strategy acceptance language requiring `llm_vision`, `hybrid`, and `compare` to remain controlled/deferred without live LLM calls. |
| Security requirements for a future fixture-only LLM vision comparison were implicit. | Medium | Added governance conditions that must be met before any fixture-only LLM vision comparison can enter Phase 2. |

## Implementation Close-Out

Phase 2 implementation is complete for the Tesseract-only executable scope. It added page-level
models, PDF page rendering, local `pytesseract` OCR execution, Tesseract-only image-to-text routing,
page-level artifact writing, OCR metadata, digest enrichment, and negative tests proving deferred
non-Tesseract strategies do not call LiteLLM.

Verification evidence:

- `uv run benecard-pa --config config/app.example.yaml config-check`
- `uv run pytest` (`56 passed`)
- `ruff check .`

Deferred behavior remains deferred: live LiteLLM vision, hybrid execution, compare execution,
classification, decomposition, summaries, crosswalk, final review artifacts, SQLite indexing,
source lifecycle, and watcher behavior.

## Accuracy Pass

- **Scope ambiguity:** Live LLM vision is intentionally deferred; Phase 2 builds the strategy
  boundary but executes only Tesseract.
- **Artifact boundary:** Phase 2 creates page-level OCR artifacts only; Phase 7 owns final output
  packaging and optional SQLite indexing.
- **Deferred-feature control:** Classification, decomposition, summaries, crosswalk, LLM review,
  tool calling, lifecycle movement, and watcher behavior are explicitly out of scope.
- **Acceptance coverage:** Every included workstream has an acceptance criterion and at least one
  test strategy item.
- **Security coverage:** Derived PHI artifacts, PHI-safe errors, local-only Tesseract execution, and
  source-filename-safe artifact paths are explicitly covered.
- **Implementation readiness:** A tactical implementation planner can convert this into bounded
  modules, tests, and sequencing without needing new product decisions.
