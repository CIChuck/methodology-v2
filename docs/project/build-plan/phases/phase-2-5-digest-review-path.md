# Phase 2.5 Build Plan: Digest Review Path

**Status:** Implemented and verified  
**Date:** 2026-05-22  
**Phase:** 2.5  
**Source authority:** `docs/project/prd/pa_document_intelligence_prd.md`, `docs/project/architecture/pa_document_intelligence_architecture.md`, `docs/project/security-governance/governance-security-spec.md`, `docs/project/configuration/config_yaml_reference.md`, `docs/project/testing/cli-uat-harness.md`, `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`, `docs/project/build-plan/phase-roadmap.md`, `docs/project/build-plan/phases/phase-2-image-text-execution-page-artifacts.md`  
**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/phase-build-planner.md`

## Executive Summary

Phase 2.5 creates a narrow, user-acceptance-testable path for presenting one approved PDF or image
file to the application and receiving a reviewable packet digest. It wires the already-built Phase 1
parser and Phase 2 image-to-text services into an explicit digest-generation workflow, writes the
digest as a durable JSON artifact, and writes a small metadata-only digest Markdown report for review
convenience.

This phase establishes the project's CLI UAT harness pattern described in
`docs/project/testing/cli-uat-harness.md`: the CLI proves phase acceptance by invoking application
services and writing reviewable artifacts while keeping console output PHI-safe.

This is not full Phase 3. Page type remains `unknown` unless already known from prior metadata.
The workflow must not classify pages, group packet components, summarize pages, extract PA form
fields, build a crosswalk, call LiteLLM, move source files, write SQLite rows, or run the watcher.

## Phase Objective

Provide a command or application service path that answers:

- Can the user submit one packet PDF or image?
- Did the parser inventory every original page?
- Which pages required OCR or image-to-text handling?
- What OCR/text artifacts were generated?
- What selected text source, OCR status, confidence, and review flags were recorded?
- Which configured output directory contains the run artifacts?
- Which approved source document was processed?
- Where is the resulting `packet_digest.json` for review?

## In Scope

- Add a bounded digest workflow behind the existing application service boundary.
- Add the phase-exit CLI UAT command `digest <source_path>`.
- Parse one PDF or image file using the existing parser.
- Run Phase 2 image-to-text routing according to YAML configuration.
- Build the enriched packet digest from the processed canonical document.
- Write `packet_digest.json` under the configured output directory using source-filename-safe paths.
- Write `packet_digest.md` by default as a concise human-readable inventory with no extracted page
  text.
- Print only PHI-safe command output: approved source document name, status, configured output
  directory, and artifact paths, not extracted text.
- Preserve page number identity and no-page-drop behavior.
- Keep file-only mode valid; SQLite is not required.
- Add integration tests using approved non-PHI clinical samples or synthetic fixtures.
- Update traceability and phase docs for behavior actually implemented.

## Out of Scope

- Page classification into PA form, physician notes, labs, fax cover, or other components.
- Packet decomposition or component records.
- Page summaries or component summaries.
- PA form field extraction.
- Evidence workspace or evidence crosswalk.
- LiteLLM calls, LLM tool calling, LLM vision extraction, hybrid mode, or compare execution.
- Final review JSON, clinical summary output, or reviewer recommendation.
- SQLite persistence or artifact indexing.
- Source lifecycle movement to processed/failed/archive folders.
- Dropbox watcher, reconciliation loop, queueing, or long-running service behavior.
- SFTP intake or remote file retrieval.

## Deferred Items

| Deferred Item | Target |
|---|---|
| Page classification and component grouping | Phase 3 |
| Digest page/component summaries | Phase 3 |
| PA form extraction and evidence crosswalk | Phase 4 |
| Digest-driven analysis orchestration | Phase 5 |
| LiteLLM-backed page classification and digest summaries | Phase 3 |
| LiteLLM tool/vision-gated analysis and final review | Phase 6 |
| Final review package, durable output package, SQLite indexing | Phase 7 |
| Source lifecycle and reprocessing commands | Phase 8 |
| Dropbox watcher and reconciliation | Phase 9 |

## Dependencies

- Phase 1 parser, canonical document model, and provisional digest builder.
- Phase 2 Tesseract OCR, image-to-text router, artifact writer, and enriched digest metadata.
- `config/app.example.yaml` path and parsing/image-text configuration.
- Approved non-PHI clinical reference samples under `docs/project/reference/clinical-samples/`.
- Existing atomic JSON writer.
- OS Tesseract binary for real OCR UAT; mocked OCR remains valid for unit tests.

## Assumptions

- The digest review path is a local operator/developer UAT workflow, not production intake.
- Digest JSON is PHI-bearing and must be stored only under configured output paths.
- CLI console output must avoid extracted page text and source document content.
- Real clinical reference samples in `docs/project/reference/clinical-samples/` are approved
  non-PHI and may be used for UAT.
- Source document name/path may appear in UAT JSON and Markdown for approved non-PHI inputs, while
  artifact directory prefixes must remain source-filename-safe.
- `document_id` remains deferred; Phase 2.5 may continue the current source-hash/run-scoped
  artifact layout while documenting that identity is provisional.

## Workstreams

### 1. Digest Workflow Service

- Add a small service that orchestrates parse -> image-text route -> digest build -> artifact write.
- Return a structured result with status, page count, review flags, digest path, and any PHI-safe
  error message.
- Preserve page-level failures inside the digest whenever possible.

### 2. CLI Digest Command

- Add `digest <source_path>` to the existing CLI.
- Load YAML configuration using existing settings behavior.
- Print concise PHI-safe output including `source: <source-document-name>`,
  `output_dir: <configured-output-dir>`, and `digest written: <path>`.
- Return nonzero only when the workflow cannot produce a digest.

### 3. Digest Artifact Writing

- Write `packet_digest.json` atomically.
- Use the same current run-scoped artifact prefix used by Phase 2 page artifacts:
  `output/doc_<source-hash-prefix>/runs/run_<processing-run-id>/`.
- Ensure the digest includes only actual written page artifacts.
- Write required digest artifacts even when embedded page artifact paths are disabled.
- Include explicit source identity and run metadata in `packet_digest.json`.
- Write `packet_digest.md` by default with page number, text status, OCR status, selected source,
  review flags, and artifact references. Do not include raw extracted page text.

### 4. Tests and UAT Fixture Path

- Add unit tests for workflow success and failure.
- Add CLI tests for `digest`.
- Add integration coverage using synthetic fixtures and at least one approved non-PHI reference
  sample when practical.
- Add negative tests proving no classification, decomposition, LLM, SQLite, lifecycle, watcher, or
  SFTP behavior is invoked.

## Sequencing

1. Confirm current `config-check`, tests, Ruff, and clean Phase 2 baseline.
2. Add digest workflow service tests.
3. Implement digest workflow service.
4. Add CLI command tests.
5. Implement `digest` CLI command.
6. Add artifact assertion tests for JSON and metadata-only Markdown.
7. Add phase-boundary negative tests.
8. Run verification commands.
9. Update traceability and close out this plan with as-built notes.

## Migration and Removal Requirements

- Do not remove `process-once`; it remains a scaffold for later production processing.
- Do not promote digest review to lifecycle movement or watcher behavior.
- Do not introduce new dependencies unless the tactical implementation plan proves they are needed.
- If an inspection helper is added, it must remain part of the bounded digest workflow and not a
  general-purpose artifact browser.

## Security and Governance Implications

- Digest JSON, OCR text, page images, and Markdown digest output are PHI-bearing unless generated
  from approved non-PHI fixtures.
- Console output must not include raw page text, OCR text, patient identifiers, or source snippets.
- Errors must be PHI-safe and should not expose source content or third-party command output.
- No LLM provider, local model endpoint, arbitrary tool, network, SFTP, SQLite, watcher, or
  lifecycle action is allowed in this phase.

## Test Strategy

Required tests:

- `digest` workflow writes `packet_digest.json` for a native-text PDF.
- `digest` workflow writes enriched digest metadata for image-text-required pages with mocked OCR.
- CLI returns success and reports the digest path without raw document text.
- Missing or unsupported source file fails with PHI-safe messaging.
- Corrupt/unparseable supported source fails with PHI-safe messaging.
- Digest preserves every original page exactly once.
- Artifact paths do not include source filenames.
- Negative boundary tests prove no classifier, decomposer, LiteLLM, SQLite persistence, lifecycle,
  watcher, SFTP, or crosswalk path is invoked.

Verification commands:

```bash
uv run benecard-pa --config config/app.example.yaml config-check
uv run pytest
ruff check .
```

## CLI, API, and UAT Strategy

Required CLI UAT command:

```bash
uv run benecard-pa --config config/app.example.yaml digest docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

Expected UAT artifacts:

- `packet_digest.json`
- `packet_digest.md`
- configured page image artifacts when `parsing.save_page_images` is true
- configured raw/normalized OCR text artifacts
- OCR metadata JSON artifacts

UAT success means a reviewer can inspect the digest and understand page count, original page
numbers, OCR/image-text status, selected text source, confidence/review flags, and artifact
locations. It does not require knowing whether a page is the PA form or physician notes; that is
Phase 3.

## Acceptance Criteria

| Area | Acceptance Criteria |
|---|---|
| Input | User can pass one supported PDF/image path to the digest workflow. |
| Parsing | Every original page is represented exactly once. |
| OCR | Image-text-required pages route through Phase 2 image-to-text behavior. |
| Digest JSON | `packet_digest.json` is written atomically under configured output. |
| Human Review | `packet_digest.md` is written by default, concise, page-oriented, and excludes extracted text. |
| Metadata | Digest includes page number, extraction method, selected source, OCR status/confidence, review flags, and actual written artifact paths. |
| Console Safety | CLI output contains approved source document name, status, configured output directory, and artifact paths only, not extracted document text. |
| Scope Control | No classification, decomposition, summary, crosswalk, LLM, SQLite, lifecycle, watcher, or SFTP behavior is introduced. |
| Verification | `config-check`, tests, Ruff, and diff checks pass. |

## Documentation Close-Out

- Traceability matrix rows for CLI UAT and digest artifact behavior were updated after
  implementation.
- Tactical implementation plan and AI construction directive were created before code generation.
- Phase 2.5 was verified with config check, tests, Ruff, diff check, and CLI UAT.
- Record residual identity risk: true `document_id` remains deferred to the persistence/identity
  phase.

## As-Built Notes

- Added `DigestReviewService` in `src/benecard_pa/digest_review.py`.
- Added `digest <source_path>` to `src/benecard_pa/cli.py`.
- Added run-scoped digest artifact path helpers in `src/benecard_pa/document/artifact_paths.py`.
- Added metadata-only `packet_digest.md` rendering.
- Verified UAT command:

```bash
uv run benecard-pa --config config/app.example.yaml digest docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

- UAT output directory: `data/output`.
- UAT artifact pattern:
  `data/output/doc_<source-hash-prefix>/runs/run_<processing-run-id>/packet_digest.json` and
  `packet_digest.md`.

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Digest CLI becomes production processing by accident | Phase leakage into lifecycle/watcher/persistence | Keep command named and documented as digest review only. |
| Markdown digest exposes too much extracted text | PHI handling risk | Keep Markdown to inventory metadata and artifact refs by default. |
| Tesseract unavailable in UAT environment | Real OCR path cannot be exercised | Provide clear prerequisite and keep mocked tests deterministic. |
| Current source-hash artifact identity is mistaken for final document identity | Future migration confusion | Document identity as provisional and defer real `document_id` model work. |

## Tactical Decisions

- Write `packet_digest.md` by default. It is an inventory report, not a clinical summary, and must
  not include extracted page text.
- Write digest artifacts under the same current run-scoped prefix used by Phase 2 page artifacts:
  `output/doc_<source-hash-prefix>/runs/run_<processing-run-id>/`.
- Do not add `--no-ocr` in Phase 2.5. The CLI UAT path should exercise parse + Phase 2
  image-to-text + digest generation together.

## Accuracy Pass

- **Scope ambiguity:** Keep this phase to digest review only; classification and summaries remain
  Phase 3.
- **Deferred items that look included:** Markdown digest must not become clinical summary output.
- **Included items without acceptance criteria:** CLI, JSON artifact, metadata, console safety, and
  boundary tests are covered.
- **Missing test strategy:** Unit, CLI, integration, and negative boundary tests are specified.
- **Missing migration work:** `process-once` remains untouched; identity migration is deferred.
- **Missing security/governance work:** PHI artifact and console-output limits are explicit.
- **Resolved tactical decisions:** Markdown is default, digest artifacts use the current
  run-scoped prefix, and parser-only `--no-ocr` is deferred.
