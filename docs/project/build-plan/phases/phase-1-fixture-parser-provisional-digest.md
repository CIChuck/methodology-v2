# Phase 1 Build Plan: Fixture Manifest, Parser Foundation, and Provisional Packet Digest

**Status:** Implemented and verified  
**Date:** 2026-05-21  
**Phase:** 1  
**Source authority:** `docs/project/vision/pa_document_intelligence_vision.md`, `docs/project/prd/pa_document_intelligence_prd.md`, `docs/project/architecture/pa_document_intelligence_architecture.md`, `docs/project/security-governance/governance-security-spec.md`, `docs/project/configuration/config_yaml_reference.md`, `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`, `docs/project/build-plan/phase-roadmap.md`  
**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/phase-build-planner.md`

## Executive Summary

Phase 1 builds the first testable vertical slice of the PA document intelligence pipeline. It
establishes fixture metadata, recognizes supported file types, extracts native PDF text through
PyMuPDF, preserves page identity, marks pages that require later image-to-text extraction, and emits
a provisional packet digest containing one inventory record per original page.

This phase is intentionally narrow. It does not run Tesseract, invoke LLM vision, call LiteLLM,
classify packet components, decompose PA packets, summarize pages, extract form fields, build
crosswalk evidence, move source files, or run the Dropbox watcher. Its purpose is to make page
identity, parser ownership, fixture expectations, and provisional digest shape stable enough for
Phase 2 image-to-text execution and Phase 3 component classification.

## Phase Objective

Create a parser/digest foundation that can answer four questions for each supported fixture:

- What source file was processed?
- How many original pages does it contain?
- Which pages produced native text?
- Which pages require configured image-to-text extraction in a later phase?

The output of this phase is a page-aware canonical document plus a provisional packet digest. The
digest is not yet the final clinical packet digest; it is the phase-safe inventory scaffold that
later phases enrich with image-to-text metadata, page classification, components, summaries,
evidence, and final review output.

## In Scope

- Create or finalize fixture support for generated synthetic files, test-local files, and approved
  non-PHI clinical reference samples.
- Create `tests/fixtures/document_manifest.yaml` for fixture metadata.
- Add a manifest loader used by tests without importing long-running pipeline behavior.
- Support manifest fields for fixture path, file type, expected page count, expected processing
  eligibility, expected native-text hints, expected image-text-needed pages, and fixture notes.
- Recognize supported input extensions: PDF, JPEG, PNG, TIFF, and common image aliases supported by
  the local imaging stack.
- Reject unsupported file types with PHI-safe errors.
- Compute or preserve source file hash metadata for parser/digest identity.
- Use PyMuPDF for native PDF page enumeration and text extraction.
- Represent standalone images as one-page canonical documents that require later image-to-text
  extraction.
- Detect low-text PDF pages using `parsing.min_text_chars_per_page`.
- Mark low-text/image pages as `image_text_required` or equivalent naming chosen by the tactical
  implementation plan.
- Preserve original page numbers starting from 1.
- Store raw native text and normalized native text separately where available.
- Normalize native text conservatively without altering clinical facts.
- Build a provisional packet digest with one page record per original page.
- Include provisional digest fields for page number, extraction method, text status,
  image-to-text-required status, selected text source when available, artifact path placeholders,
  unknown page type, nullable summary fields, and review flags.
- Keep page/component classification values as `unknown` or empty placeholders.
- Keep `config-check`, tests, and Ruff passing.

## Out of Scope

- Running Tesseract OCR.
- Running LLM vision extraction.
- Running `hybrid` or `compare` image-to-text strategies.
- Rendering page images for production OCR/vision artifacts except where a test fixture helper
  creates synthetic files.
- Calling LiteLLM.
- LLM tool calling or tool registry implementation.
- Page classification into PA form, physician notes, labs, fax cover, or other components.
- Packet decomposition.
- Page or component summarization.
- PA form field extraction.
- Evidence workspace or crosswalk generation.
- Final review JSON/Markdown output.
- SQLite persistence beyond preserving existing config compatibility.
- Runtime Dropbox watcher behavior.
- Source lifecycle movement into `processed`, `failed`, `archive`, or quarantine folders.
- Production retention, encryption, public model approval, or access-control implementation.

## Deferred Items

| Deferred Item | Target |
|---|---|
| Tesseract image-to-text execution and confidence extraction | Phase 2 |
| LLM vision image-to-text extraction boundary | Phase 2 if fixture-evaluation ready; otherwise Phase 6 before non-fixture use |
| Hybrid and compare strategy execution | Phase 2 for fixture evaluation; production use gated by governance and Phase 6 LiteLLM boundary |
| Page image artifact generation | Phase 2 |
| LiteLLM-backed page classification and packet decomposition | Phase 3 |
| LiteLLM-backed digest page/component summaries | Phase 3 |
| PA form extraction and evidence crosswalk | Phase 4 |
| Digest-driven evidence analysis | Phase 5 |
| LiteLLM review expansion, tool calling, and vision-gated analysis | Phase 6 |
| Durable output artifacts and optional SQLite indexing | Phase 7 |
| Source lifecycle, CLI status/reprocess, and processed/failed movement | Phase 8 |
| Dropbox watcher and reconciliation loop | Phase 9 |

## Dependencies

- Python 3.13.
- `uv` environment management.
- PyMuPDF available through `pyproject.toml`.
- Pillow available for image fixture recognition where needed.
- Current application config: `config/app.example.yaml`.
- Current settings loader: `src/benecard_pa/settings.py`.
- Canonical governance/security constraints in
  `docs/project/security-governance/governance-security-spec.md`.
- Synthetic fixtures, generated test files, or approved non-PHI clinical reference samples. New
  PHI-bearing packets must not be committed.

## Assumptions

- Files under `docs/project/reference/clinical-samples/` are an approved non-PHI clinical reference
  corpus. They may be used for unit tests, integration tests, and user acceptance testing.
- Additional committed fixture files must be synthetic, formally de-identified, or explicitly
  approved as non-PHI reference samples.
- Phase 1 can mark pages as needing image-to-text extraction without performing that extraction.
- The provisional digest may include placeholder fields for later image-to-text metadata, but those
  fields remain null/empty until Phase 2.
- The tactical implementation plan may choose exact Python class names, but must preserve the
  architecture terms: `Document`, `ProcessingRun`, `CanonicalDocument`, `Page`, and `PacketDigest`.

## Workstreams

### 1. Fixture Manifest Foundation

- Add `tests/fixtures/document_manifest.yaml`.
- Add fixture folders with `.gitkeep` files where needed.
- Define a simple manifest shape that can describe native PDF, low-text PDF, standalone image, and
  unsupported-file fixtures.
- Implement a test-focused manifest loader.
- Fail clearly when enabled fixture paths are missing.
- Document that PHI-bearing files, patient identifiers, extracted PHI, and raw LLM responses
  containing PHI must not be committed as fixtures. Approved non-PHI clinical reference samples
  under `docs/project/reference/clinical-samples/` are valid test inputs.

### 2. Parser and File-Type Dispatch

- Add or refine file-type dispatch for supported PDFs and images.
- Return PHI-safe parser errors for unsupported files.
- Extract source hash and source metadata required by downstream audit.
- Keep parser logic independent from Dropbox watcher and source lifecycle movement.

### 3. Native PDF Extraction

- Use PyMuPDF to enumerate pages in original page order.
- Extract native text page by page.
- Preserve page numbers starting at 1.
- Store raw native text and normalized native text separately where available.
- Mark pages with sufficient native text as not requiring image-to-text extraction.

### 4. Image and Low-Text Page Signaling

- Recognize standalone images as one-page canonical documents.
- Mark standalone images as requiring image-to-text extraction in Phase 2.
- Use `parsing.min_text_chars_per_page` to flag low-text PDF pages.
- Record `image_text_required` or equivalent metadata without invoking Tesseract or LLM vision.
- Add review flags for low-text/image-text-required pages in the provisional digest.

### 5. Provisional Packet Digest

- Build one digest page record per original page.
- Preserve page number, extraction method, text status, image-to-text-required status, selected text
  source when available, and deterministic artifact path placeholders.
- Set page type to `unknown`.
- Keep component records absent or placeholder-only; do not infer PA packet components.
- Include `digest_version`, `page_count`, digest-level review flags, and artifact layout metadata.
- Ensure unknown, blank, and low-text pages are retained rather than dropped.

### 6. Phase Verification

- Add focused unit tests for fixture manifest loading, parser dispatch, native PDF extraction,
  image shell behavior, low-text signaling, unsupported files, and provisional digest completeness.
- Keep existing tests stable.
- Run `config-check`, `pytest`, and Ruff.

## Sequencing

1. Finalize fixture directory and manifest shape.
2. Add manifest loader tests.
3. Define parser/page/digest model changes needed for the phase.
4. Implement supported/unsupported file dispatch.
5. Implement PyMuPDF native PDF extraction.
6. Implement standalone image one-page shell behavior.
7. Implement low-text and image-to-text-needed signaling.
8. Implement provisional digest builder.
9. Add digest completeness and no-page-drop tests.
10. Run verification and update documentation close-out notes.

## Migration and Removal Requirements

- Preserve existing config loading and `config-check` behavior.
- Do not remove existing prompt, schema, database, output, lifecycle, classifier, or LiteLLM
  scaffolds unless the tactical plan identifies dead code directly blocking Phase 1.
- If existing provisional parser/digest code conflicts with this plan, adjust it narrowly rather
  than refactoring unrelated modules.
- Rename no public config keys in Phase 1 without updating PRD, architecture, config reference,
  traceability, tests, and `config/app.example.yaml`.

## Security and Governance Implications

- Phase 1 must not call external APIs, LiteLLM, local model endpoints, Tesseract subprocesses, or
  arbitrary tools.
- Fixture guidance must prohibit committed PHI.
- Parser errors, manifest errors, and test output must not print raw document text.
- Source hashes, source filenames, page counts, and artifact paths are allowed metadata, but should
  still be treated as potentially sensitive in production.
- Generated raw/normalized text artifacts are PHI-bearing by convention even when fixtures are
  synthetic.
- The phase must preserve the governance rule that source files are not moved to `processed` until
  later lifecycle phases authorize completion gates.

## Test Strategy

Required automated tests:

- Manifest loader accepts a valid manifest.
- Manifest loader reports missing enabled fixture files clearly.
- Unsupported files fail with PHI-safe errors.
- Native PDF fixture produces one `Page` record per original page.
- Page numbers are preserved starting at 1.
- Native text pages record extraction method and normalized text.
- Low-text PDF pages are marked as requiring image-to-text extraction.
- Standalone images produce one-page documents requiring image-to-text extraction.
- Provisional digest contains one page inventory record per original page.
- Provisional digest retains unknown pages and low-text pages.
- Provisional digest includes `digest_version`, `page_count`, page artifact placeholders, unknown
  page type, selected text source metadata where available, image-to-text-required status, and
  review flags.
- Config validation still accepts `config/app.example.yaml`.

Verification commands:

```bash
uv run benecard-pa --config config/app.example.yaml config-check
uv run pytest
uv run ruff check .
```

## CLI / API / UAT Strategy

Phase 1 does not add a production parser CLI or runtime watcher. CLI scope is limited to preserving
`config-check`.

Manual UAT should be test-driven:

1. Add, generate, or select an approved non-PHI clinical reference PDF fixture.
2. Add or generate a synthetic image fixture when image-shell behavior is under test.
3. Run the parser/digest tests.
4. Inspect test assertions or generated temporary outputs.
5. Confirm every original page is represented exactly once and low-text/image pages are flagged for
   later image-to-text extraction.

## Acceptance Criteria

| Area | Acceptance Criteria |
|---|---|
| Fixture structure | Fixture folders and manifest exist and are covered by tests. |
| Fixture safety | Manifest validation requires every enabled fixture to be explicitly marked `approved_non_phi` or `synthetic`; approved non-PHI clinical reference samples are valid unit, integration, and UAT inputs. |
| Manifest loader | Tests load fixture metadata without starting the runtime pipeline and reject malformed enabled fixture definitions. |
| Supported dispatch | PDF and supported image inputs, including common JPEG and fax-image aliases, dispatch into parser paths. |
| Unsupported dispatch | Unsupported files and corrupt supported files fail with PHI-safe errors. |
| Native PDF parsing | Native PDFs produce page-aware records with preserved page numbers and native text metadata. |
| Image shell handling | Standalone images are represented as one-page documents requiring image-to-text extraction. |
| Low-text signaling | Low-text PDF pages are marked using configured threshold. |
| No image-to-text execution | No Tesseract, LLM vision, hybrid, or compare extraction is run in Phase 1. |
| Provisional digest | Digest includes one inventory record per original page and drops no unknown/blank/low-text pages. |
| Artifact placeholders | Digest includes deterministic artifact path placeholders for later page/text artifacts. |
| Scope control | No classification, decomposition, summaries, crosswalk, LiteLLM calls, tool calling, watcher loop, or source lifecycle movement is introduced. |
| Config guardrails | `config-check` validates Phase 1-relevant thresholds, image-to-text strategy shape, task-profile references, public model approvals, raw response storage approvals, and digest artifact layout. |
| Verification | `config-check`, tests, and Ruff pass. |

## Documentation Close-Out

Phase 1 is not complete until:

- This build plan reflects the implemented phase scope.
- `docs/project/build-plan/phases/phase-1-tactical-implementation-plan.md` is reconciled with this
  build plan.
- The traceability matrix status is updated for Phase 1 rows that become implemented or verified.
- Any parser/digest schema decisions discovered during implementation are reconciled into the PRD,
  architecture, configuration reference, or governance spec when they affect build authority.
- `AGENTS.md` remains accurate for commands, methodology paths, package boundaries, and PHI fixture
  guidance.

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Fixture files accidentally include PHI. | Compliance and trust risk. | Use generated synthetic fixtures, formally de-identified files, or approved non-PHI clinical reference samples only. |
| Phase 1 accidentally runs OCR or LLM vision. | Phase boundary drift and unplanned governance exposure. | Tests should assert image-to-text-needed status without extraction artifacts or model calls. |
| Parser assumes PA form location. | Later decomposition may inherit false assumptions. | Keep page type `unknown`; do not classify packet components in Phase 1. |
| Digest shape becomes too final. | Later phases may be constrained by premature fields. | Version digest and keep later fields nullable/placeholders. |
| Exact PDF text assertions are brittle. | Tests may fail across PyMuPDF versions or fixture generation. | Prefer page counts, flags, metadata, and small stable keyword assertions. |

## Open Decisions

| Decision | Status |
|---|---|
| Final fixture corpus size | Open until test data aggregation completes. |
| Whether fixture PDFs/images are generated in tests or committed as static synthetic assets | Tactical plan recommends generated fixtures where practical, with small committed synthetic files only when needed. |
| Exact Python model class names | Tactical plan recommends `ProvisionalPacketDigest` and `DigestPage`, constrained by architecture terminology. |
| Exact provisional digest field names for image-to-text-required status | Tactical plan standardizes on `image_text_required` unless implementation discovers a reason to reconcile a different public name. |

## Remediation Pass

This pass remediates the previous Phase 1 plan against the current documentation authority.

| Finding | Severity | Remediation |
|---|---|---|
| Source authority did not include the canonical governance/security specification or configuration reference. | High | Added both documents to source authority and security/governance sections. |
| Phase language still centered on legacy OCR-only page signaling rather than the current image-to-text strategy model. | High | Reframed Phase 1 around image-to-text-needed signaling while keeping actual Tesseract/LLM vision execution deferred. |
| Deferred scope did not explicitly mention `llm_vision`, `hybrid`, or `compare` strategies. | Medium | Added strategy-specific deferred items and Phase 2/Phase 6 boundaries. |
| Provisional digest fields did not account for selected text source or future image-to-text metadata. | Medium | Added selected text source, image-to-text-required status, comparison placeholders, and later artifact placeholders. |
| Documentation paths reflected the older docs layout. | Medium | Updated all source authority paths to the `docs/project/` and `docs/methodology/` layout. |
| Governance implications did not explicitly deny external API, LiteLLM, Tesseract subprocess, and arbitrary tool execution in Phase 1. | Medium | Added explicit Phase 1 governance denial rules. |
| Acceptance criteria did not directly test no scope leakage for the new image-to-text strategies. | Medium | Added no-image-to-text-execution and no-scope-leakage acceptance criteria. |
| Documentation close-out did not reference the new documentation structure and config/governance authority. | Low | Updated close-out to include PRD, architecture, configuration reference, governance spec, traceability, tactical plan, and `AGENTS.md`. |

## Accuracy Pass

- **Scope clarity:** Phase 1 is parser, fixture, page identity, image-to-text-needed signaling, and
  provisional digest only.
- **Deferred-feature control:** Tesseract execution, LLM vision, hybrid/compare extraction,
  classification, decomposition, summaries, crosswalk, tool calling, watcher, and source lifecycle
  behavior are explicitly deferred.
- **Traceability:** Included requirements map primarily to FR-009-FR-017, FR-070-FR-084, and the
  Phase 1 portions of FR-131-FR-142.
- **Security coverage:** PHI fixture handling, no external calls, no raw document logging, and no
  source lifecycle movement are explicit.
- **Testability:** Every included workstream has a corresponding test or acceptance criterion.
- **Implementation readiness:** This build plan has been converted into
  `docs/project/build-plan/phases/phase-1-tactical-implementation-plan.md` and
  `docs/project/build-plan/phases/phase-1-ai-construction-directive.md`; Phase 1 implementation is
  complete and remediation findings are being closed before Phase 2 planning.
