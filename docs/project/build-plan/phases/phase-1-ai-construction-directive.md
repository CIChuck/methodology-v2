# Phase 1 AI Construction Directive: Fixture Manifest, Parser Foundation, and Provisional Packet Digest

**Status:** Executed for Phase 1 implementation  
**Date:** 2026-05-21  
**Phase:** 1  
**Directive type:** AI construction directive  
**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/ai-construction-directive-builder.md`

## AI Builder Role

You are the implementation agent for Phase 1 of the BeneCard PA Document Intelligence project. Your
job is to implement the bounded parser and provisional digest foundation exactly as authorized here.
Do not infer or add later-phase behavior.

## Source Authority and Precedence

Use these documents in this order:

1. `docs/project/build-plan/phases/phase-1-tactical-implementation-plan.md`
2. `docs/project/build-plan/phases/phase-1-fixture-parser-provisional-digest.md`
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

Build the first testable vertical slice of the document pipeline:

- fixture manifest support;
- supported file dispatch for PDFs and common image formats;
- native PDF text extraction through PyMuPDF;
- standalone image shell handling without OCR or vision extraction;
- low-text page signaling through `image_text_required`;
- provisional packet digest construction with one inventory record per original page.

The implementation must stabilize page identity and digest inventory only. It must not perform
clinical interpretation.

## Allowed Scope

You may edit:

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
- Phase 1 documentation close-out files only when implementation reveals an actual schema or
  status decision that must be reconciled.

Keep edits narrow. Do not refactor unrelated scaffolds.

## Explicit Non-Goals

Do not implement or invoke:

- Tesseract OCR execution;
- `pytesseract` image extraction;
- LiteLLM calls;
- LLM vision extraction;
- hybrid or compare image-to-text strategies;
- LLM tool calling or tool registry behavior;
- page classification;
- packet decomposition;
- page or component summaries;
- PA form field extraction;
- evidence workspace or crosswalk generation;
- final review JSON or Markdown output;
- SQLite digest persistence;
- Dropbox watcher runtime behavior;
- source lifecycle movement into `processed`, `failed`, `archive`, or quarantine folders;
- new production parser CLI commands.

Preserve `config-check`; do not add runtime operator commands in Phase 1.

## Required Workstreams

### 1. Fixture Manifest Foundation

Create `tests/fixtures/document_manifest.yaml` and fixture support for synthetic or formally
de-identified test files. The manifest must support at least:

- `id`
- `path`
- `file_type`
- `enabled`
- `expected_page_count`
- `expected_native_text_pages`
- `expected_image_text_required_pages`
- `expected_supported`
- `notes`

Add a test-focused manifest loader that does not import watcher, lifecycle, database, output, or
pipeline runtime behavior. Disabled fixtures must not block tests. Missing enabled fixture paths
must fail clearly.

### 2. Document Models and Parser Contracts

Extend the current document model without breaking existing tests. Preserve
`CanonicalDocument.normalized_text` compatibility unless a source-authority document is updated.

Represent, directly or through companion models:

- original page number starting at 1;
- raw native text;
- normalized native text;
- extraction method;
- text status;
- `image_text_required`;
- selected text source;
- artifact path placeholders;
- review flags.

Prefer `ProvisionalPacketDigest` and `DigestPage` for digest model names unless existing code makes
a cleaner name obvious. Any public field-name change must be reconciled in documentation.

### 3. Parser Dispatch and Native PDF Extraction

Replace the placeholder parser with a concrete Phase 1 parser while retaining the `DocumentParser`
protocol. Implement:

- PDF dispatch through PyMuPDF;
- native text extraction per original page;
- conservative text normalization through `normalize_extracted_text`;
- supported image dispatch for JPEG, PNG, TIFF, and common aliases such as `.jpe` and `.jfif`;
- unsupported-extension and corrupt supported-file errors that are PHI-safe, do not include raw
  document text, and do not expose source-path-bearing library exception chains;
- low-text detection using `ParsingSettings.min_text_chars_per_page`.

The parser may accept `source_sha256` as currently modeled. Use existing helpers such as
`src/benecard_pa/io.py` where appropriate.

### 4. Standalone Image Shell Handling

Represent standalone images as one-page canonical documents. For image pages:

- do not fabricate text;
- mark `image_text_required` as `true`;
- set selected text source to `None` or an explicit none value;
- set text status to an image-text-needed value;
- retain the page in downstream digest output.

No OCR, Tesseract subprocess, LLM call, or vision extraction may occur.

### 5. Provisional Packet Digest Builder

Create a provisional digest builder, preferably in `src/benecard_pa/document/digest.py`.

The digest must include:

- `digest_version`;
- `source_path`;
- `source_sha256`;
- `page_count`;
- `artifact_layout`;
- digest-level review flags;
- one page record per original page.

Each page record must include:

- `page_number`;
- `page_type` set to `unknown`;
- `extraction_method`;
- `text_status`;
- `image_text_required`;
- `selected_text_source`;
- raw/normalized text presence flags;
- artifact path placeholders when configured;
- review flags.

Do not write durable digest JSON in Phase 1 except inside temporary test directories. Durable
artifact writing belongs to Phase 7.

## Migration and Removal Instructions

- Do not remove existing prompt, schema, database, output, lifecycle, classifier, watcher, or LLM
  scaffolds.
- Do not rename public YAML keys.
- Do not introduce database migrations.
- Do not change final review schema.
- If existing code conflicts with Phase 1, adjust the smallest relevant document module surface.
- Leave unrelated user or scaffold changes intact.

## Security and Governance Requirements

- Do not commit PHI-bearing source files, patient identifiers, extracted PHI, or LLM responses
  containing PHI as test fixtures.
- Files under `docs/project/reference/clinical-samples/` are an approved non-PHI clinical reference
  corpus and may be used for unit tests, integration tests, and user acceptance testing.
- Treat source files, raw text, normalized text, page images, digest JSON, and temporary extraction
  artifacts as PHI-bearing by convention.
- Parser, manifest, and test errors must not include raw extracted document text.
- Phase 1 must not call external APIs, LiteLLM, local model endpoints, Tesseract subprocesses,
  arbitrary tools, watcher runtime behavior, lifecycle movement, or SQLite persistence.
- Source files must not be moved, deleted, archived, quarantined, or copied as a success/failure
  lifecycle action.
- Do not weaken any setting, security, or governance behavior described in
  `docs/project/security-governance/governance-security-spec.md`.

## Testing Requirements

Add or update tests covering:

- valid fixture manifest loading;
- missing enabled fixture path failure;
- disabled fixture behavior;
- supported PDF dispatch;
- supported image dispatch;
- unsupported file rejection with PHI-safe errors;
- native PDF page count preservation;
- original page numbers starting at 1;
- raw and normalized native text separation;
- low-text PDF page `image_text_required` signaling;
- standalone image one-page shell behavior;
- no fabricated image text;
- provisional digest page count matching canonical document page count;
- no dropped blank, unknown, low-text, or image pages;
- digest page fields and digest-level fields;
- deterministic artifact placeholders;
- no OCR, LLM, watcher, lifecycle, database, or output side effects.

Existing tests must continue to pass.

## Verification Commands

Run:

```bash
uv run benecard-pa --config config/app.example.yaml config-check
uv run pytest
ruff check .
```

If any command cannot be run, report why. Do not claim verification passed unless it actually
passed.

## CLI, API, and UAT Requirements

Phase 1 does not add a production parser CLI. UAT is test-driven:

1. Generate a synthetic native PDF fixture or load an approved non-PHI clinical reference PDF.
2. Generate or load a synthetic image fixture.
3. Run parser tests for page count, text status, and `image_text_required`.
4. Run digest tests and confirm every original page appears exactly once.
5. Run `config-check` against `config/app.example.yaml`.

No SFTP, Dropbox watcher, lifecycle movement, model provider, or OCR setup is required for Phase 1.

## Documentation Close-Out

After implementation:

- Update `docs/project/traceability/pa_document_intelligence_traceability_matrix.md` only for rows
  directly implemented or verified by Phase 1.
- Update `docs/project/build-plan/phases/phase-1-fixture-parser-provisional-digest.md` or
  `docs/project/build-plan/phases/phase-1-tactical-implementation-plan.md` only if implementation
  discovers a real schema, scope, or sequencing correction.
- Keep `AGENTS.md` accurate if commands, methodology paths, or fixture-safety guidance change.
- Do not mark deferred features as implemented.

## Reporting Requirements

In the implementation summary, report:

- files changed;
- what Phase 1 behavior was implemented;
- what tests were added or updated;
- verification command results;
- any documentation close-out performed;
- any skipped verification with reason;
- any source-authority conflict found;
- any deferred feature that was intentionally left unimplemented.

## Stop Conditions

Stop and ask for direction before proceeding if:

- implementation requires committing or generating PHI-bearing fixtures outside the approved
  non-PHI clinical reference corpus;
- a required behavior appears to require OCR, LLM, tool calling, classification, decomposition, or
  lifecycle movement;
- public YAML keys or final output schemas appear to require renaming;
- database persistence becomes necessary for Phase 1 behavior;
- parser behavior would require changing PRD, architecture, or governance authority beyond a minor
  schema reconciliation;
- required dependencies are missing from `pyproject.toml` and cannot be resolved through the
  existing `uv` workflow.

## Anti-Drift Instructions

- Do not broaden scope.
- Do not implement deferred features.
- Do not silently change architecture.
- Do not weaken security/governance behavior.
- Do not remove unrelated code.
- Do not mark planned behavior as implemented unless it is implemented and verified.
- Keep Phase 1 focused on fixture metadata, parser foundation, page identity, low-text signaling,
  and provisional digest inventory.

## Accuracy Pass

- **Tactical workstreams represented:** Fixture manifest, models/contracts, parser dispatch,
  native PDF extraction, image shell handling, provisional digest, verification, and documentation
  close-out are all included.
- **Required tests represented:** Positive, negative, scope-control, and UAT-style checks are
  included.
- **Non-goals explicit:** OCR, LLM, tool calling, classification, decomposition, summaries,
  crosswalk, persistence, watcher, lifecycle, and new runtime CLI commands are prohibited.
- **Migration behavior explicit:** No database migrations, no public config renames, no unrelated
  scaffold removal.
- **Security/governance included:** PHI-safe fixtures/errors, no external/model/tool execution, and
  no source lifecycle movement are required.
- **Reporting clear:** Builder must report files changed, verification, documentation close-out,
  conflicts, skipped checks, and deferred behavior.
