# Phase 2.5 AI Construction Directive: Digest Review Path

**Status:** Executed for Phase 2.5 implementation  
**Date:** 2026-05-22  
**Phase:** 2.5  
**Directive type:** AI construction directive  
**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/ai-construction-directive-builder.md`

## AI Builder Role

You are the implementation agent for Phase 2.5 of the BeneCard PA Document Intelligence project.
Your job is to implement the bounded digest review path exactly as authorized here. This phase
creates a CLI-based UAT bridge over the Phase 1 parser and Phase 2 image-to-text services. Do not
infer or add Phase 3 or later behavior.

## Source Authority and Precedence

Use these documents in this order:

1. `docs/project/build-plan/phases/phase-2-5-tactical-implementation-plan.md`
2. `docs/project/build-plan/phases/phase-2-5-digest-review-path.md`
3. `docs/project/testing/cli-uat-harness.md`
4. `docs/project/security-governance/governance-security-spec.md`
5. `docs/project/architecture/pa_document_intelligence_architecture.md`
6. `docs/project/prd/pa_document_intelligence_prd.md`
7. `docs/project/configuration/config_yaml_reference.md`
8. `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`
9. `docs/project/build-plan/phase-roadmap.md`
10. `AGENTS.md`

If these documents conflict, follow the higher-precedence document and report the conflict in the
implementation summary. Do not silently change architecture, requirements, or security behavior.

## Implementation Objective

Implement the Phase 2.5 digest review path:

- add a `digest <source_path>` CLI command;
- parse one supported PDF or image through the existing Phase 1 parser;
- run Phase 2 image-to-text routing according to YAML configuration;
- build the enriched provisional packet digest;
- write `packet_digest.json` and metadata-only `packet_digest.md` under the configured output
  directory using the current run-scoped artifact prefix;
- print CLI UAT output that identifies the approved source document name, configured output
  directory, page count, digest JSON path, digest Markdown path, and review flag count or safe
  operational names;
- preserve every original page exactly once.

This phase proves that a user can present a PDF/image to the application and receive a reviewable
digest artifact set. It is not production intake.

## Allowed Scope

You may edit:

- `src/benecard_pa/digest_review.py`
- `src/benecard_pa/cli.py`
- `src/benecard_pa/document/artifact_paths.py`
- `src/benecard_pa/output/artifacts.py` only for reusable atomic text/write or Markdown helpers
- `tests/test_digest_review.py`
- `tests/test_cli.py`
- existing parser, image-text, digest, or artifact tests only when needed to integrate the digest
  review path
- `docs/project/traceability/pa_document_intelligence_traceability_matrix.md` for Phase 2.5
  close-out only
- Phase 2.5 build/tactical docs for as-built corrections only

Use cautiously:

- `src/benecard_pa/pipeline.py` only if a thin call-through is needed; do not make `process-once`
  production-ready.
- `config/app.example.yaml` only if a documented default must be corrected.

Keep edits narrow. Do not refactor unrelated scaffolds.

## Explicit Non-Goals

Do not implement or invoke:

- page classification;
- packet decomposition or component records;
- page summaries, component summaries, or clinical summaries;
- PA form field extraction;
- evidence workspace or crosswalk generation;
- LiteLLM calls;
- LLM tool calling;
- LLM vision, hybrid, or compare execution;
- public model APIs or local model endpoints;
- final review JSON, final Markdown output package, or reviewer recommendation;
- SQLite persistence, indexing, or database schema changes;
- source lifecycle movement to processed, failed, archive, quarantine, or any other lifecycle folder;
- Dropbox watcher, reconciliation loop, queueing, or long-running service behavior;
- SFTP or remote file retrieval;
- `--no-ocr`;
- production-ready `process-once` behavior.

Preserve existing commands. Phase 2.5 adds the UAT-focused `digest` command only.

## Required Workstreams

### 1. Digest Review Workflow Service

Create a reusable service, preferably `src/benecard_pa/digest_review.py`, that orchestrates:

1. source validation;
2. source hashing with `sha256_file`;
3. parsing through `PyMuPDFDocumentParser(settings.parsing)`;
4. image-to-text processing through `ImageTextRouter(settings)`;
5. digest construction with `build_provisional_packet_digest`;
6. digest JSON and Markdown artifact writing.

Define a small result dataclass, for example `DigestReviewResult`, with:

- `source_path`;
- `source_name`;
- `status`;
- `page_count`;
- `review_flags`;
- `output_dir`;
- `digest_json_path`;
- `digest_markdown_path`;
- `message`.

Return failed status only when the source is missing, unsupported, unparseable, misconfigured, or
when required digest artifact writing fails. Preserve page-level OCR/render failures as digest
metadata when a digest can still be produced.

### 2. Run-Scoped Digest Artifact Paths

Write digest artifacts beside the Phase 2 page artifacts under the current run-scoped prefix:

```text
<paths.output_dir>/doc_<source-hash-prefix>/runs/run_<processing-run-id>/packet_digest.json
<paths.output_dir>/doc_<source-hash-prefix>/runs/run_<processing-run-id>/packet_digest.md
```

Requirements:

- use atomic JSON writing for `packet_digest.json`;
- use atomic text writing for `packet_digest.md`;
- keep source filenames out of generated artifact path prefixes;
- ensure paths remain rooted under the configured `paths.output_dir`;
- avoid overwriting prior runs for the same source.
- write required digest artifacts even when `packet_digest.include_artifact_paths` is false; that
  setting controls embedded page artifact references, not the digest artifact destination.

Do not introduce the true `document_id` model migration in this phase.

### 3. Metadata-Only Markdown Digest

Render `packet_digest.md` by default as a human-readable inventory, not a clinical summary.

Include:

- digest version;
- source document name and source path for approved non-PHI UAT inputs;
- page count;
- source hash prefix;
- run metadata including `processing_run_id`, document artifact id, run artifact id, and relative
  digest artifact paths;
- digest-level review flags;
- one row per page with page number, extraction method, text status, selected text source,
  image-text strategy, OCR status, OCR confidence, review flags, and artifact path keys.

Do not include:

- raw text;
- normalized text;
- OCR text;
- source snippets;
- patient identifiers;
- page summaries;
- component summaries;
- clinical interpretations.

### 4. CLI Digest Command

Add `digest <source_path>` to `src/benecard_pa/cli.py`.

Expected command:

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

Requirements:

- invoke the digest review workflow service;
- keep CLI logic thin;
- return `0` on success;
- return `1` on workflow failure;
- fail closed with a PHI-safe configuration message if `packet_digest.write_json_artifact` is false;
- do not print source text, OCR text, normalized text, source snippets, patient identifiers, prompt
  content, LLM response content, or third-party command output.
- printing the source document name is allowed for approved non-PHI CLI UAT inputs; artifact folder
  prefixes must still avoid source filenames.

### 5. Scope Boundary Tests

Add tests proving the digest workflow does not import, call, initialize, or trigger deferred
subsystems:

- classifier/decomposer;
- LiteLLM or LLM modules;
- SQLite/database initialization or SQLite file creation;
- lifecycle movement;
- watcher/reconciliation;
- SFTP/network behavior;
- crosswalk/analysis modules if present.

Also assert no source file is moved, copied, deleted, archived, or quarantined by `digest`.

## Migration and Removal Instructions

- Preserve Phase 1 parser behavior and Phase 2 image-to-text behavior.
- Preserve `config-check`, `init-db`, and `process-once` behavior unless a narrow test compatibility
  adjustment is required.
- Do not rename public YAML keys.
- Do not introduce database migrations.
- Do not change final review schemas.
- Do not remove existing prompt, schema, database, output, lifecycle, classifier, watcher, or LLM
  scaffolds.
- Leave unrelated user-created or untracked files alone. Do not delete notes, scratch files, or
  generated-looking documents without explicit user approval.

## Security and Governance Requirements

- Treat digest JSON, Markdown digest, rendered page images, OCR text, normalized text, OCR metadata,
  and temporary extraction artifacts as PHI-bearing by convention.
- Files under `docs/project/reference/clinical-samples/` are approved non-PHI reference samples and
  may be used for unit tests, integration tests, CLI UAT, and operator review.
- Console output must remain metadata-only and PHI-safe.
- Errors must not expose raw document text, OCR text, source snippets, patient identifiers, prompt
  content, LLM response content, command output, or chained source-path-bearing third-party
  exceptions.
- Artifact paths must use document/run identity and must not use source filenames as layout keys.
- Do not call external APIs, LiteLLM, local model endpoints, arbitrary tools, watcher runtime,
  lifecycle movement, SFTP, network, or SQLite persistence.
- Do not weaken any behavior described in
  `docs/project/security-governance/governance-security-spec.md`.

## Testing Requirements

Add or update tests covering:

- native-text PDF digest success;
- image-text-required PDF or standalone image success with mocked OCR;
- missing source failure with PHI-safe output;
- unsupported source failure with PHI-safe output;
- parse failure with PHI-safe output;
- approved multi-page sample or fixture preserves every page exactly once;
- OCR page failure retained in digest metadata when parsing succeeds;
- `packet_digest.include_artifact_paths == false` still writes required digest JSON and Markdown;
- `packet_digest.write_json_artifact == false` fails closed for `digest`;
- digest JSON path is run-scoped and source-filename-safe;
- Markdown digest path is run-scoped and source-filename-safe;
- reprocessing the same source creates a different run folder;
- output paths remain rooted under configured `paths.output_dir`;
- Markdown includes inventory metadata and review flags;
- Markdown includes approved source document identity and run metadata;
- Markdown excludes raw text, normalized text, OCR text, snippets, summaries, and clinical
  interpretations;
- CLI success writes artifacts and returns `0`;
- CLI output includes approved source document name, configured output directory, page count, digest
  JSON path, Markdown path, and review flag count or safe names;
- CLI output does not include extracted fixture text;
- CLI missing source returns nonzero with PHI-safe message;
- no classifier, decomposer, LiteLLM, SQLite, lifecycle, watcher, SFTP, network, crosswalk, or
  later-phase behavior is invoked;
- no source file movement occurs.

Existing Phase 1 and Phase 2 tests must continue to pass.

## CLI, API, and UAT Requirements

Primary CLI UAT command:

```bash
uv run benecard-pa --config config/app.example.yaml digest docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

Primary UAT input pool:

- `docs/project/reference/clinical-samples/`

Expected UAT evidence:

- command returns `0`;
- console output identifies the approved source document name;
- console output includes configured `paths.output_dir`;
- console output identifies `packet_digest.json`;
- console output identifies `packet_digest.md`;
- `packet_digest.json` exists under the run-scoped output path;
- `packet_digest.md` exists under the same run-scoped output path;
- `packet_digest.json` includes a top-level `document` block and `artifact_run` block;
- digest page count equals source page count;
- every original page appears exactly once;
- OCR/image-text-required pages carry OCR status or review flags;
- no page type/component classification is expected;
- no source file movement occurs.
- multi-frame TIFF/image packets are explicitly deferred unless frame-aware parsing is implemented.

## Verification Commands

Run:

```bash
uv run benecard-pa --config config/app.example.yaml config-check
uv run pytest
ruff check .
git diff --check
```

If OS Tesseract is unavailable, report any skipped real-OCR checks and rely on mocked OCR coverage
for deterministic tests. Do not claim verification passed unless it actually passed.

## Documentation Close-Out

After implementation:

- Update `docs/project/traceability/pa_document_intelligence_traceability_matrix.md` only for Phase
  2.5 behavior actually implemented or verified.
- Update `docs/project/build-plan/phases/phase-2-5-digest-review-path.md` or
  `docs/project/build-plan/phases/phase-2-5-tactical-implementation-plan.md` only if implementation
  discovers a real schema, scope, or sequencing correction.
- Update PRD, architecture, configuration reference, governance/security, or CLI UAT harness only
  if a documented contract changes.
- Record the actual CLI command and artifact paths in as-built notes.
- Record residual identity risk: true `document_id` remains deferred.
- Do not mark deferred features as implemented.

## Reporting Requirements

In the implementation summary, report:

- files changed;
- what Phase 2.5 behavior was implemented;
- the exact CLI UAT command used;
- the configured output directory printed by the CLI;
- the created digest JSON and Markdown artifact paths;
- what tests were added or updated;
- verification command results;
- any Tesseract integration checks skipped and why;
- any documentation close-out performed;
- any source-authority conflict found;
- any deferred feature intentionally left unimplemented;
- any residual risk or follow-up needed before Phase 3.

## Stop Conditions

Stop and ask for direction before proceeding if:

- implementation appears to require page classification, decomposition, summaries, crosswalk, or
  clinical interpretation;
- implementation appears to require live LiteLLM, public model APIs, local model endpoints, LLM tool
  calling, LLM vision, hybrid, or compare execution;
- artifact requirements appear to require final review output packaging, SQLite indexing, or true
  `document_id` migration;
- source lifecycle movement becomes necessary;
- public YAML keys or final output schemas appear to require renaming;
- PHI-bearing fixtures outside the approved non-PHI reference corpus would need to be committed;
- required Python dependencies are missing from `pyproject.toml` and cannot be resolved through the
  existing `uv` workflow;
- satisfying a test would require changing PRD, architecture, or governance authority beyond a
  minor documentation reconciliation.

## Anti-Drift Instructions

- Do not broaden scope.
- Do not implement deferred features.
- Do not silently change architecture.
- Do not weaken security/governance behavior.
- Do not remove unrelated code.
- Do not delete untracked/user-created files without explicit approval.
- Do not mark planned behavior as implemented unless it is implemented and verified.
- Keep Phase 2.5 focused on CLI UAT digest review, run-scoped digest artifacts, metadata-only
  Markdown, and PHI-safe console output.

## Accuracy Pass

- **Tactical workstreams represented:** Digest workflow service, run-scoped artifact paths,
  metadata-only Markdown, CLI command, scope-boundary tests, and documentation close-out are all
  included.
- **Required tests represented:** Workflow, artifact paths, Markdown content, CLI behavior,
  PHI-safe failures, configuration failure, negative scope, and no-source-movement tests are
  included.
- **Non-goals explicit:** Classification, decomposition, summaries, crosswalk, LLM, SQLite,
  lifecycle, watcher, SFTP, production intake, and `process-once` production behavior are
  prohibited.
- **Migration behavior explicit:** No database migrations, public config renames, final schema
  changes, true `document_id` migration, or unrelated scaffold removal.
- **Security/governance included:** PHI artifact handling, approved sample corpus, PHI-safe console
  output, source-filename-safe paths, and no external/model/tool/network execution are required.
- **CLI/UAT evidence clear:** The directive requires `output_dir`, digest JSON path, Markdown path,
  page count, review flags, and approved clinical sample input.
- **Reporting clear:** Builder must report files changed, CLI command, output directory, artifact
  paths, tests, verification, skipped checks, documentation close-out, conflicts, deferred behavior,
  and residual risks.
