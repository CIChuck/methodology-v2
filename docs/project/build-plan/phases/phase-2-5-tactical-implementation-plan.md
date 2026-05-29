# Phase 2.5 Tactical Implementation Plan: Digest Review Path

**Status:** Implemented and verified  
**Date:** 2026-05-22  
**Phase:** 2.5  
**Source authority:** `docs/project/build-plan/phases/phase-2-5-digest-review-path.md`, `docs/project/testing/cli-uat-harness.md`, `docs/project/prd/pa_document_intelligence_prd.md`, `docs/project/architecture/pa_document_intelligence_architecture.md`, `docs/project/security-governance/governance-security-spec.md`, `docs/project/configuration/config_yaml_reference.md`, `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`, `docs/project/build-plan/phase-roadmap.md`  
**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/tactical-implementation-planner.md`

## Implementation Objective

Implement the Phase 2.5 digest review path: a user can run one CLI command against one supported
PDF/image file and receive a reviewable `packet_digest.json` plus a metadata-only
`packet_digest.md`. The command must exercise the real Phase 1 parser and Phase 2 image-to-text
services, write artifacts under the current run-scoped artifact prefix, and keep console output
PHI-safe.

This phase is a UAT bridge, not production intake. It must not classify pages, decompose packets,
summarize pages, extract PA form fields, build a crosswalk, call LiteLLM, write SQLite rows, move
source files, use SFTP, or run watcher behavior.

## Source Authority Precedence

1. Governance/security specification for PHI-safe console output and artifact handling.
2. Phase 2.5 build plan for scope and tactical decisions.
3. CLI UAT harness reference for command behavior and phase-exit evidence.
4. Architecture for CLI/service boundaries and object ownership.
5. PRD and configuration reference for digest and artifact requirements.
6. Traceability matrix and phase roadmap for placement.

If implementation pressure conflicts with Phase 2.5 scope, defer the feature.

## Assumptions

- Phase 1 parser and Phase 2 image-to-text services are implemented and verified.
- Approved non-PHI clinical samples under `docs/project/reference/clinical-samples/` are valid
  CLI UAT inputs.
- The current `CanonicalDocument.processing_run_id` can be used for run-scoped artifact layout.
- True `document_id` remains deferred; the current `doc_<source-hash-prefix>` prefix is provisional.
- `packet_digest.md` is metadata-only and written by default.
- Source document name/path are allowed in CLI UAT JSON and Markdown for approved non-PHI test
  inputs, while artifact folder prefixes must remain source-filename-safe.
- No new Python dependency is expected.

## Non-Goals

- Do not modify methodology documents.
- Do not implement page classification, decomposition, summaries, PA form extraction, crosswalk, or
  clinical review output.
- Do not add `--no-ocr`.
- Do not add SQLite persistence, lifecycle movement, watcher, SFTP, network, LiteLLM, tool calling,
  LLM vision, hybrid, or compare execution.
- Do not change source files or move them to processed/failed/archive folders.
- Do not make `process-once` production-ready in this phase.

## Workstream 1: Digest Review Workflow Service

**Purpose:** Create a reusable application service that performs parse -> image-to-text -> digest
build -> artifact write without putting workflow logic in the CLI.

**Implementation tasks:**

- Add a service module, recommended `src/benecard_pa/digest_review.py`.
- Define a small result dataclass, for example `DigestReviewResult`, with:
  - `source_path`;
  - `source_name`;
  - `status`;
  - `page_count`;
  - `review_flags`;
  - `output_dir`;
  - `digest_json_path`;
  - `digest_markdown_path`;
  - `message`.
- Parse the source with `PyMuPDFDocumentParser(settings.parsing)`.
- Hash the source with `sha256_file`.
- Process the parsed document through `ImageTextRouter(settings)`.
- Build the digest with `build_provisional_packet_digest`.
- Write digest artifacts through the artifact writer workstream.
- Treat page-level OCR/render failures as digest content when a digest can still be produced.
- Return failed status only when the source is missing, unsupported, unparseable, or digest artifact
  writing fails.

**Affected areas:** `src/benecard_pa/digest_review.py`,
`src/benecard_pa/document/parser.py`, `src/benecard_pa/document/image_text.py`,
`src/benecard_pa/document/digest.py`, `tests/test_digest_review.py`.

**Required tests:**

- Native-text PDF produces success with one digest page.
- Image-text-required PDF or image with mocked OCR produces OCR-enriched digest metadata.
- Missing source produces failed result with PHI-safe message.
- Unsupported source type produces failed result with PHI-safe message.
- OCR page failures do not prevent digest artifact creation when parsing succeeds.

**Acceptance criteria:** The workflow can produce a digest JSON and Markdown path from a supported
source without CLI-specific logic.

**Dependencies:** Phase 1 parser, Phase 2 image-to-text router, digest builder, atomic artifact
writer.

## Workstream 2: Run-Scoped Digest Artifact Paths

**Purpose:** Write digest artifacts beside Phase 2 page artifacts under the same current
run-scoped prefix.

**Implementation tasks:**

- Add a helper for digest artifact paths, either in `src/benecard_pa/document/artifact_paths.py` or
  a narrow service-local helper.
- Use current layout:
  `output/doc_<source-hash-prefix>/runs/run_<processing-run-id>/packet_digest.json`.
- Write `packet_digest.md` to the same directory.
- Use `atomic_write_json` for JSON.
- Use `atomic_write_text` for Markdown.
- Keep source filenames out of generated artifact path prefixes.
- Write digest artifacts even when `packet_digest.include_artifact_paths` is false; that setting
  controls embedded page artifact references, not the acceptance artifact destinations.

**Affected areas:** `src/benecard_pa/document/artifact_paths.py` or
`src/benecard_pa/digest_review.py`, `src/benecard_pa/output/artifacts.py`,
`tests/test_digest_review.py`.

**Required tests:**

- Digest JSON path is run-scoped and source-filename-safe.
- Markdown digest path is run-scoped and source-filename-safe.
- Reprocessing the same source creates a different run folder.
- Paths remain relative to configured output directory.
- Digest JSON includes explicit run metadata, including processing run id, document artifact id,
  run artifact id, and relative digest artifact paths.

**Acceptance criteria:** Digest artifacts are colocated with page artifacts for the same run and do
not overwrite prior runs.

**Dependencies:** Current `document_artifact_id`, `run_artifact_id`, and `CanonicalDocument.processing_run_id`.

## Workstream 3: Metadata-Only Markdown Digest

**Purpose:** Provide a human-readable inventory for UAT without creating a clinical summary or
printing extracted text.

**Implementation tasks:**

- Add a renderer, recommended `render_packet_digest_markdown(digest)`, near digest review service
  or output helpers.
- Include:
  - digest version;
  - source document name and path for approved non-PHI UAT inputs;
  - page count;
  - source hash prefix;
  - run metadata;
  - digest-level review flags;
  - one row per page with page number, extraction method, text status, selected text source,
    image-text strategy, OCR status, OCR confidence, review flags, and artifact path keys.
- Do not include raw text, normalized text, OCR text, page summaries, snippets, or clinical
  interpretations.

**Affected areas:** `src/benecard_pa/digest_review.py` or `src/benecard_pa/output/artifacts.py`,
`tests/test_digest_review.py`.

**Required tests:**

- Markdown includes page inventory metadata.
- Markdown excludes raw and normalized document text.
- Markdown includes review flags and artifact path names when present.

**Acceptance criteria:** A reviewer can inspect page-level processing status without seeing
extracted text in the Markdown artifact.

**Dependencies:** Provisional packet digest model.

## Workstream 4: CLI Digest Command

**Purpose:** Expose the Phase 2.5 UAT harness command.

**Implementation tasks:**

- Add `digest` subcommand to `src/benecard_pa/cli.py`.
- Required argument: `source_path`.
- Invoke the digest review workflow service.
- Print PHI-safe output:
  - success/failure status;
  - approved source document name;
  - page count;
  - configured output directory;
  - digest JSON path;
  - digest Markdown path;
  - review flags count or names if they are non-PHI operational flags.
- Do not print source text, OCR text, normalized text, source snippets, or patient identifiers.
- Return `0` on success and `1` on workflow failure.

**Affected areas:** `src/benecard_pa/cli.py`, `tests/test_cli.py`, possibly
`tests/test_digest_review.py`.

**Required tests:**

- CLI success writes digest artifacts and returns `0`.
- CLI output includes approved source document name, configured output directory, digest artifact
  paths, and page count.
- CLI output does not include extracted text from the fixture.
- CLI missing source returns nonzero with PHI-safe message.

**Acceptance criteria:** The documented command can serve as the Phase 2.5 phase-exit UAT harness.

**Dependencies:** Workstreams 1 through 3.

## Workstream 5: Scope Boundary and Negative Tests

**Purpose:** Prevent Phase 2.5 from becoming Phase 3, 4, 6, 7, 8, or 9 by accident.

**Implementation tasks:**

- Add tests that guard imports/calls for deferred modules from the digest workflow path.
- Block or assert no use of:
  - `benecard_pa.document.classifier`;
  - `benecard_pa.llm`;
  - `benecard_pa.db`;
  - `benecard_pa.lifecycle`;
  - `benecard_pa.watcher`;
  - SFTP/network libraries;
  - crosswalk/analysis modules if introduced later.
- Assert `process-once` remains unchanged except if tests need to document its scaffold status.

**Affected areas:** `tests/test_digest_review.py`, `tests/test_cli.py`.

**Required tests:**

- Digest workflow does not import or call classifier/decomposer/LLM/SQLite/lifecycle/watcher code.
- No source file movement occurs.
- No SQLite file is created by `digest`.

**Acceptance criteria:** Phase 2.5 proves digest review without scope leakage.

**Dependencies:** Workstreams 1 through 4.

## File and Module Ownership Expectations

Primary edit scope:

- `src/benecard_pa/digest_review.py`
- `src/benecard_pa/cli.py`
- `src/benecard_pa/document/artifact_paths.py`
- `src/benecard_pa/output/artifacts.py` only if a reusable Markdown renderer or path-safe writer
  helper is needed
- `tests/test_digest_review.py`
- `tests/test_cli.py`
- `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`
- Phase 2.5 build/tactical docs for close-out only

Use cautiously:

- `src/benecard_pa/pipeline.py` only if a thin call-through is helpful; do not make `process-once`
  production-ready.
- `config/app.example.yaml` only if a documented default must be added.

Avoid editing:

- `src/benecard_pa/llm/**`
- `src/benecard_pa/db/**`
- `src/benecard_pa/lifecycle.py`
- `src/benecard_pa/watcher/**`
- `src/benecard_pa/document/classifier.py`
- final review schema files, unless a test import requires no-op protection.

## Data and Schema Changes

Allowed:

- New `DigestReviewResult` dataclass.
- New path helper for run-scoped digest artifact paths.
- Markdown digest artifact content shape.

Not allowed:

- Database schema changes.
- Final review schema changes.
- Packet component schema additions.
- Page classification or summary fields beyond what already exists.
- True `document_id` model migration.

## API, CLI, and Config Changes

CLI:

```bash
uv run benecard-pa --config config/app.example.yaml digest <source_path>
```

Expected success output shape:

```text
source: <source-document-name>
output_dir: <configured-output-dir>
digest written: <digest_json_path>
pages: <count>
markdown: <digest_markdown_path>
review_flags: <count-or-safe-list>
```

Config:

- No new config key is expected.
- The `digest` command requires JSON output because `packet_digest.json` is the phase acceptance
  artifact. If `packet_digest.write_json_artifact` is false, the command should fail closed with a
  PHI-safe configuration message rather than silently omitting JSON.
- `packet_digest.include_artifact_paths` may suppress embedded page artifact references but must not
  suppress `packet_digest.json` or `packet_digest.md` writing.
- `parsing.save_raw_text`, `parsing.save_normalized_text`, and `parsing.save_page_images` continue
  to govern page-level artifacts.

## Migration Order

1. Confirm current `git status`, `config-check`, `uv run pytest`, and `ruff check .`.
2. Add digest artifact path tests.
3. Add digest review workflow tests.
4. Implement path helper and digest review service.
5. Add Markdown renderer tests.
6. Implement Markdown renderer.
7. Add CLI command tests.
8. Implement CLI command.
9. Add negative scope tests.
10. Run verification commands.
11. Update traceability and mark Phase 2.5 docs as implemented/verified only after review.

## Security and Governance Work

- Treat digest JSON, Markdown digest, page images, OCR text, and OCR metadata as PHI-bearing.
- Keep CLI output metadata-only.
- Allow source document name/path in UAT JSON and Markdown for approved non-PHI fixtures and
  samples.
- Ensure workflow errors are PHI-safe.
- Ensure generated artifact paths are source-filename-safe.
- Ensure no source movement, SQLite write, network, SFTP, LLM provider, or tool call occurs.
- Ensure Markdown digest excludes raw text and normalized text.

## Tests by Workstream

| Workstream | Test File | Required Coverage |
|---|---|---|
| Workflow service | `tests/test_digest_review.py` | Success, parse failure, unsupported file, OCR failure retained in digest. |
| Artifact paths | `tests/test_digest_review.py` or artifact path tests | Run-scoped digest JSON/Markdown paths, no source filename leakage, retry creates a new run path. |
| Markdown digest | `tests/test_digest_review.py` | Source identity for approved non-PHI inputs, metadata included, extracted text excluded, review flags included. |
| CLI command | `tests/test_cli.py` | `digest` success/failure, exit codes, PHI-safe output. |
| Scope control | `tests/test_digest_review.py`, `tests/test_cli.py` | No classifier, LLM, SQLite, lifecycle, watcher, SFTP, or crosswalk behavior. |

## Negative Tests

- Missing source file fails without source content leakage.
- Unsupported file type fails without source content leakage.
- Corrupt/unparseable supported source fails without source content leakage.
- CLI output does not include extracted fixture text.
- Markdown output does not include extracted raw or normalized text.
- `digest` does not import/call LiteLLM.
- `digest` does not import/call page classifier or decomposer.
- `digest` does not initialize SQLite or create a SQLite file.
- `digest` does not move/copy/delete/archive the source file.
- `digest` does not run watcher/reconciliation/SFTP/network behavior.
- Multi-frame TIFF/image packets fail closed until frame-aware parsing is explicitly implemented.

## CLI, API, and UAT Checks

Primary UAT command:

```bash
uv run benecard-pa --config config/app.example.yaml digest docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

Primary UAT input pool:

- `docs/project/reference/clinical-samples/`

UAT checks:

- Command returns `0`.
- Console output identifies the approved source document name.
- Console output identifies configured output directory plus digest JSON and Markdown artifact
  paths.
- `packet_digest.json` exists.
- `packet_digest.md` exists.
- Digest page count equals source page count.
- Every original page appears once.
- Digest JSON includes `document` and `artifact_run` metadata blocks.
- OCR/image-text-required pages carry OCR status or review flags.
- No page type/component classification is expected.
- No source file movement occurs.

## Verification Commands

```bash
uv run benecard-pa --config config/app.example.yaml config-check
uv run pytest
ruff check .
git diff --check
```

If OS Tesseract is unavailable, report skipped real-OCR checks and rely on mocked OCR coverage for
deterministic CI.

## Acceptance Criteria

| Area | Acceptance Criteria |
|---|---|
| Workflow | Service parses, routes image-to-text, builds digest, and writes artifacts. |
| CLI | `digest <source_path>` is available and returns correct exit codes. |
| JSON artifact | `packet_digest.json` is written atomically under run-scoped output. |
| Markdown artifact | `packet_digest.md` is written by default and excludes extracted text. |
| Page retention | Every original page appears exactly once in the digest. |
| OCR integration | Image-text-required pages use Phase 2 routing and preserve failures as digest metadata. |
| PHI safety | Console output identifies configured output directory and artifact paths but does not expose extracted text or source snippets. |
| Scope control | No classification, decomposition, summary, crosswalk, LLM, SQLite, lifecycle, watcher, SFTP, or network behavior is introduced. |
| Verification | `config-check`, tests, Ruff, and diff checks pass. |

## Documentation Close-Out

- Traceability matrix was updated with Phase 2.5 CLI UAT evidence.
- Phase 2.5 build plan and tactical plan were marked implemented/verified after code generation.
- Actual CLI command and artifact path pattern were recorded in as-built notes.
- Record residual identity risk: true `document_id` remains deferred.

## As-Built Notes

- Implemented `DigestReviewService` and `DigestReviewResult`.
- Implemented run-scoped `packet_digest.json` and metadata-only `packet_digest.md` writing.
- Implemented PHI-safe `digest <source_path>` CLI output including `output_dir`.
- Added tests in `tests/test_digest_review.py` and `tests/test_cli.py`.
- Verified UAT command:

```bash
uv run benecard-pa --config config/app.example.yaml digest docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

- UAT output directory: `data/output`.
- Residual identity risk remains: true `document_id` is deferred.

## Deferred Items

- Page classification, decomposition, and digest summaries: Phase 3.
- PA form field extraction and crosswalk: Phase 4.
- Analysis orchestration: Phase 5.
- LiteLLM-backed page classification and digest summaries: Phase 3.
- LiteLLM tool/vision-gated workflows and final review: Phase 6.
- Durable final review package and SQLite indexing: Phase 7.
- Source lifecycle and reprocessing commands: Phase 8.
- Watcher/reconciliation: Phase 9.
- True `document_id` model and persistence identity alignment: future persistence/identity phase.

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| CLI grows business logic | Harder future orchestration and testing | Keep CLI as a thin adapter over `digest_review` service. |
| Markdown digest becomes summary output | Phase 3/7 leakage and PHI risk | Metadata-only Markdown; no extracted text. |
| Digest command mistaken for production processing | Premature lifecycle/persistence assumptions | Document as UAT harness; no source movement or SQLite. |
| Tesseract missing in UAT | OCR pages may show failures | Preserve failed OCR in digest and document OS prerequisite. |
| Provisional source-hash identity persists too long | Future artifact migration cost | Keep residual risk documented; do not claim true `document_id`. |

## Accuracy Pass

- **Missing implementation steps:** Workflow, paths, Markdown, CLI, tests, and docs are enumerated.
- **Vague ownership:** Primary file/module ownership is explicit.
- **Missing tests:** Unit, CLI, integration, and negative tests are specified.
- **Missing negative tests:** Deferred modules, PHI-safe output, SQLite, lifecycle, watcher, SFTP,
  and LLM boundaries are covered.
- **Missing migration steps:** `process-once` remains scaffolded; true `document_id` migration is
  deferred.
- **Missing security/governance verification:** PHI artifact, console, and no-deferred-provider
  rules are explicit.
- **Missing CLI/UAT evidence:** Primary command, configured output directory visibility, approved
  clinical sample source, and UAT checks are specified.
- **Documentation close-out gaps:** Traceability and as-built updates are required.
- **Contradictions with source authority:** None identified; Phase 2.5 remains a digest review path
  and does not enter Phase 3 classification or Phase 7 final output packaging.
