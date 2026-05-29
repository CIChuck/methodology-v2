# Phase 4 AI Construction Directive: PA Form Extraction, Hybrid Reconciliation, and Evidence Crosswalk

**Status:** Implemented and verified

**Date:** 2026-05-23

**Phase:** 4

**Directive type:** AI construction directive

**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/ai-construction-directive-builder.md`

## AI Builder Role

You are the implementation agent for Phase 4 of the BeneCard PA Document Intelligence project. Your
job is to implement the approved Phase 4 field-level workflow: extract structured PA form fields,
support text-only, vision-only, and hybrid extraction, reconcile text and vision candidates, write
`pa_form_extraction.json`, and create an initial form-to-evidence crosswalk artifact. Implement only
the Phase 4 scope authorized here.

## Source Authority and Precedence

Use these documents in this order:

1. `docs/project/build-plan/phases/phase-4-tactical-implementation-plan.md`
2. `docs/project/build-plan/phases/phase-4-pa-form-extraction-crosswalk.md`
3. `docs/project/security-governance/governance-security-spec.md`
4. `docs/project/architecture/pa_document_intelligence_architecture.md`
5. `docs/project/prd/pa_document_intelligence_prd.md`
6. `docs/project/configuration/config_yaml_reference.md`
7. `docs/project/testing/cli-uat-harness.md`
8. `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`
9. `docs/project/build-plan/phase-roadmap.md`
10. `AGENTS.md`

If these documents conflict, follow the higher-precedence document and report the conflict. Do not
silently change architecture, requirements, phase boundaries, or security behavior.

## Implementation Objective

Add a bounded Phase 4 CLI UAT workflow that can process an approved packet and produce:

- `packet_digest.json` and `packet_analysis_index.json` from the existing upstream digest path;
- `pa_form_extraction.json` containing extracted PA form fields, questions, values, source pages,
  candidates, extraction mode, extraction source, confidence, and review flags;
- `form_extraction_index.json` containing compact field labels, values, confidence, source pages,
  answer types, extraction sources, and review flags for quick scanning;
- `form_evidence_crosswalk.json` containing exactly one crosswalk item for every extracted PA form
  field;
- optional bounded Phase 4 Markdown review output;
- PHI-safe console output with artifact paths, counts, review flags, and model task profiles.

The implementation must preserve file-only mode and must remain rebuildable from the digest,
analysis index, classified PA form pages, text/image artifacts, prompt/schema configuration, and
active LiteLLM task-profile configuration.

## Allowed Scope

You may edit or create:

- `src/benecard_pa/settings.py`
- `src/benecard_pa/llm/client.py`
- `src/benecard_pa/llm/prompts.py`
- `src/benecard_pa/llm/tasks.py`
- `src/benecard_pa/document/artifact_paths.py`
- `src/benecard_pa/output/artifacts.py`
- `src/benecard_pa/cli.py`
- `src/benecard_pa/digest_review.py` only if orchestration reuse requires it
- `src/benecard_pa/pa_form/__init__.py`
- `src/benecard_pa/pa_form/models.py`
- `src/benecard_pa/pa_form/extraction.py`
- `src/benecard_pa/pa_form/reconciliation.py`
- `src/benecard_pa/pa_form/crosswalk.py`
- `src/benecard_pa/pa_form/output.py`
- `src/benecard_pa/pa_form/workflow.py`
- `config/app.example.yaml`
- `config/prompts.example.yaml`
- tests for settings, prompts, LiteLLM client, PA form models, extraction, reconciliation,
  crosswalk, artifacts, workflow, and CLI
- project docs required for Phase 4 close-out after implementation

Use cautiously:

- shared document models only when reuse is necessary for audit metadata;
- existing digest service only as an upstream dependency, not as the home for Phase 4 business
  logic;
- output helpers only for reusable atomic writing.

## Explicit Non-Goals

Do not implement or invoke:

- final clinical review narrative;
- approval, denial, medical necessity outcome, payer policy interpretation, or clinical
  recommendation language;
- broad agentic loops or general tool calling;
- Phase 5 evidence workspace orchestration;
- Phase 6 final-review LLM behavior;
- full packet, full PDF, or all-page image submission to an LLM;
- arbitrary filesystem, shell, database, network, or secret access by an LLM;
- SQLite-required persistence or schema changes;
- source lifecycle movement, copy, delete, archive, quarantine, processed/failed transitions, or
  retention behavior;
- Dropbox watcher, SFTP intake, process queues, reprocess/status commands, or daemon behavior;
- template-specific PA form packs unless used only as local synthetic test fixtures.

## Required Workstreams

### 1. Configuration and Capability Gates

Implement `PaFormExtractionSettings` and config validation.

Requirements:

- support `mode: text_only | vision_only | hybrid`;
- support `llm_task`, optional `text_llm_task`, optional `vision_llm_task`,
  `include_page_images`, `max_pages_per_request`, `max_images_per_request`, `compare_outputs`,
  `require_reconciliation`, and `fallback_when_vision_unavailable`;
- validate `fallback_when_vision_unavailable: fail | text_only`;
- require structured-output-capable profiles for all PA form extraction paths;
- require `supports_vision: true` and positive image capacity for `vision_only` and the vision path
  of `hybrid`;
- preserve existing Phase 3 task-profile validation;
- keep public-provider governance checks intact.

### 2. Prompt and Schema Contracts

Add Phase 4 prompt catalog support.

Requirements:

- add `pa_form_extraction` task prompt and schema metadata to `config/prompts.example.yaml`;
- support optional `pa_form_extraction_text` and `pa_form_extraction_vision` task prompts when split
  hybrid routing is configured;
- include expected extraction fields: `field_id`, `label`, `question`, `value`, `answer_type`,
  `source_page`, `confidence`, `required_evidence_hint`, and `review_flags`;
- add bounded `crosswalk_evaluation` prompt/schema only if the implementation uses LLM assistance
  for support evaluation;
- fail closed with PHI-safe errors when required prompts are missing or malformed.

### 3. Multimodal LiteLLM Boundary

Extend the existing LiteLLM structured call boundary narrowly for selected PA form page images.

Requirements:

- add image-capable structured calls or a narrow companion method;
- use OpenAI-compatible message content accepted by LiteLLM for local LM Studio or other compatible
  vision profiles;
- enforce configured page/image limits and profile capabilities before every call;
- reject image calls for profiles without `supports_vision`;
- preserve metadata for task name, profile, model, prompt key/version, scope, component ID, page
  numbers, status, and duration;
- keep raw prompts, raw selected text, image bytes, raw responses, and patient identifiers out of
  console output and logs;
- keep Phase 3 calls text-only unless invoked by the Phase 4 workflow.

### 4. PA Form Extraction Models

Create stable models for `pa_form_extraction.json`.

Requirements:

- define extraction artifact, derived-from metadata, form components, fields, candidates, task audit
  metadata, and reconciliation metadata;
- use controlled values for answer types, extraction modes, extraction sources, and review flags;
- require every field to carry stable `field_id`, `label` or `question`, `value`, `source_page`,
  `source_component_id`, `answer_type`, `confidence`, `extraction_method`, and `review_flags`;
- preserve text and vision candidates even when a final value is selected;
- include source text and source image artifact paths when available.

### 5. PA Form Extraction Service

Implement the extraction service under `src/benecard_pa/pa_form/`.

Requirements:

- load `packet_digest.json` and `packet_analysis_index.json`;
- locate PA form pages from digest components and `pages_by_type.prior_authorization_form`;
- gather bounded normalized text and rendered page images for the same PA form pages;
- in `text_only`, call the text extraction path with normalized PA form text only;
- in `vision_only`, call the vision extraction path with PA form page images only;
- in `hybrid`, call both paths and reconcile candidate outputs;
- validate LLM structured output before constructing artifacts;
- produce reviewer-facing flags for missing PA form pages, missing images, malformed output, low
  confidence, duplicate fields, conflicting fields, and extraction failure;
- do not assemble or send full packet text.

### 6. Hybrid Candidate Reconciliation

Implement deterministic reconciliation for text and vision candidates.

Requirements:

- normalize field IDs using `field_id`, label/question text, source page, and simple synonyms if
  configured;
- match by normalized field ID first, then label/page/question fallback;
- use `hybrid_agreed` when text and vision agree;
- accept vision with `ocr_missing_value` when text is blank and vision has a value;
- accept text with `vision_missing_value` when vision is blank and text quality is adequate;
- preserve both candidates on disagreement and either select the stronger candidate with conflict
  flags or mark the field as needing review;
- prefer vision for checkbox state, signatures/marks, handwriting, and layout-sensitive alignment;
- prefer text for long free text, medication names, diagnosis codes, and clean OCR/native text;
- never silently discard alternate candidates.

### 7. Initial Evidence Crosswalk Builder

Create one crosswalk item for every extracted PA form field.

Requirements:

- read `pa_form_extraction.json` and `packet_analysis_index.json`;
- restrict evidence search to configured supporting component types, starting with
  `physician_notes`, `lab_results`, and `medication_history`;
- if an extracted field has a blank or null value, create an `unclear` crosswalk item with no
  supporting pages, `blank_form_value`, and no source-validated evidence claim;
- support only `supported`, `contradicted`, `missing`, and `unclear`;
- require original page citations for supported and contradicted items;
- distinguish source-validated evidence from summary-only navigation;
- keep any LLM support judgment advisory;
- system code must own crosswalk assembly, schema validation, completeness, provenance, and policy
  separation.

### 8. Artifact Writing and Markdown Review Output

Persist Phase 4 artifacts under the active run directory.

Requirements:

- add deterministic paths for `pa_form_extraction.json`, `form_extraction_index.json`,
  `form_evidence_crosswalk.json`, and optional Phase 4 Markdown;
- use atomic writes;
- derive `form_extraction_index.json` from `pa_form_extraction.json`; do not treat the index as a
  second source of truth;
- include `derived_from.packet_digest_json`, `derived_from.packet_analysis_index_json`, PA form
  pages, prompt keys/versions, and model profile metadata;
- include the approved source document name in review artifacts and console output for UAT
  traceability;
- include bounded form values in the Phase 4 Markdown extracted-field and crosswalk tables;
- keep artifact directory prefixes document/run based, not source-filename based;
- do not overwrite prior run artifacts.

### 9. CLI UAT Surface

Add a bounded Phase 4 CLI command.

Requirements:

- prefer `crosswalk <source_path>` unless implementation uncovers a strong reason for a different
  name;
- the command may run the existing digest path first, then PA form extraction and crosswalk
  generation against the active run artifacts;
- console output must include status, source, output directory, digest path, analysis index path,
  PA form extraction path, crosswalk path, field count, crosswalk count, conflict count,
  missing/unclear count, review flags, and task profiles;
- exit code `0` requires required Phase 4 artifacts to be written;
- failures must be PHI-safe.

### 10. Documentation and Traceability Close-Out

Reconcile implemented behavior back into canonical docs.

Requirements:

- update `docs/project/configuration/config_yaml_reference.md` with final Phase 4 settings;
- update `docs/project/testing/cli-uat-harness.md` with the final command and console fields;
- update architecture only if final module or artifact fields differ from the current architecture;
- update traceability with implementation and test evidence after verification;
- update Phase 4 plan statuses during close-out.

## Migration and Removal Instructions

- Preserve `digest <source_path>` behavior and existing Phase 3/3.5 artifacts.
- Add Phase 4 as a clearly named workflow rather than silently broadening the digest command.
- Preserve run-scoped artifact paths and source-filename-safe artifact directory prefixes.
- Preserve file-only mode.
- Preserve existing tests unless Phase 4 intentionally enriches behavior and tests are updated
  accordingly.
- Do not remove user-created files, notes, or unrelated repository content.
- Do not refactor unrelated modules for style.
- Do not mark planned behavior implemented unless it is implemented and verified.

## Security and Governance Requirements

- Treat source documents, OCR text, normalized text, page images, prompts, selected context, LLM
  outputs, extraction artifacts, crosswalk artifacts, Markdown, logs, and SQLite rows as PHI unless
  explicitly approved as non-PHI fixtures.
- Console output must remain metadata-only.
- Do not log raw document text, prompt text, model request content, model response content, source
  snippets, patient identifiers, or image bytes.
- Secrets must come from environment variables or approved secret stores, never YAML values.
- Public model profiles must remain blocked unless `security.allow_public_llm_profiles` is
  explicitly enabled after deployment approval.
- Page images may be sent only when YAML enables the Phase 4 vision path and the selected profile
  supports vision with sufficient image capacity.
- Full packets and full PDFs must not be sent to an LLM by default.
- LLM outputs are advisory. System code owns extraction artifact construction, reconciliation,
  crosswalk completeness, validation, provenance, and policy separation.
- Outputs must not imply approval, denial, adjudication, medical necessity outcome, or payer-policy
  determination.

## Testing Requirements

Add or update tests for:

- `pa_form_extraction` settings loading and defaults;
- invalid extraction modes;
- missing task-profile mappings;
- non-structured profiles;
- vision profile capability failures;
- image-capacity failures;
- public-provider governance failures;
- Phase 4 prompt loading and missing/malformed prompt failures;
- text-only structured extraction with mocked LLM;
- vision-only structured extraction with mocked LLM;
- hybrid extraction invoking both paths;
- malformed LLM JSON and non-object responses;
- missing PA form component;
- missing page image in `vision_only`;
- missing page image in `hybrid` with `fallback_when_vision_unavailable: fail`;
- explicit text-only fallback when configured;
- hard request page/image limits with review flags when detected PA form pages are omitted;
- missing normalized PA form text without falling back to digest summaries as extraction input;
- reconciliation agreement;
- OCR/text missing value;
- vision missing value;
- conflicting values with alternate candidates preserved;
- ambiguous checkbox state;
- duplicate/conflicting field IDs;
- valid artifact serialization;
- derived `form_extraction_index.json` field count and compact field/value/confidence rows;
- Markdown extracted-field and crosswalk tables include bounded field values;
- crosswalk one item per extracted field;
- blank or null form values produce no supporting pages and include `blank_form_value`;
- crosswalk missing evidence still creates an item;
- unsupported support status rejected;
- supported/contradicted items require original page citations;
- summary-only navigation marked as not source validated;
- CLI success output with artifact paths and counts;
- CLI failure output that remains PHI-safe;
- negative scope boundaries for final review, broad tool calling, SQLite-required persistence,
  lifecycle movement, watcher, SFTP, and source mutation.

Unit tests must use fake or mocked LLM clients and must not require network access, LM Studio,
remote providers, API keys, or live model calls.

## Verification Commands

The implementation should be ready for these commands:

```bash
uv run benecard-pa --config config/app.example.yaml config-check
uv run pytest
uv run ruff check .
uv run benecard-pa --config config/app.example.yaml crosswalk docs/project/reference/clinical-samples/doc08294920260513101420.pdf
git diff --check
```

If the final Phase 4 command name differs from `crosswalk`, update the CLI UAT harness and use the
documented command in verification.

## CLI and UAT Requirements

Primary expected UAT command:

```bash
uv run benecard-pa --config config/app.example.yaml crosswalk docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

Expected success output shape:

```text
status: success
source: <source-document-name>
output_dir: <configured-output-dir>
digest_json: <packet_digest_path>
analysis_index_json: <packet_analysis_index_path>
pa_form_extraction_json: <pa_form_extraction_path>
form_extraction_index_json: <form_extraction_index_path>
form_evidence_crosswalk_json: <crosswalk_path>
fields: <count>
crosswalk_items: <count>
conflicts: <count>
missing_or_unclear: <count>
review_flags: <flag-list-or-none>
llm_tasks: pa_form_extraction=<profile>[, crosswalk_evaluation=<profile>]
```

## Documentation Close-Out

Phase 4 close-out completed:

- this directive status is updated after code and tests proved the implementation;
- the Phase 4 tactical plan status is updated;
- `docs/project/configuration/config_yaml_reference.md` is updated with Phase 4 settings;
- `docs/project/testing/cli-uat-harness.md` is updated with the `crosswalk` command;
- traceability is updated with implementation/test evidence;
- architecture did not require further revision for the implemented module boundaries;
- skipped verification must still be reported honestly in the final implementation report.

## Reporting Requirements

Final implementation report must include:

- files changed;
- artifact names produced;
- final CLI command;
- tests and verification commands run;
- any skipped checks and why;
- any deferred items that remain deferred;
- any security/governance implications;
- any follow-up recommendations before Phase 5.

## Stop Conditions

Stop and report rather than continuing if:

- source authority conflicts cannot be resolved by precedence;
- a required model capability cannot be configured or safely mocked;
- implementation would require sending full packets or full PDFs to an LLM;
- implementation would require public LLM routing without explicit approval;
- implementation would require source lifecycle movement or SQLite-required persistence;
- tests reveal possible approval/denial/adjudication language in outputs;
- completing the work would require deleting or reverting unrelated user-created files.

## Accuracy Pass

- Every Phase 4 tactical workstream is represented.
- Required positive and negative test categories are included.
- Explicit non-goals block Phase 5/6/7 scope leakage.
- Migration instructions preserve existing digest behavior, file-only mode, and user files.
- Security and governance requirements cover PHI handling, model routing, vision gating, context
  limits, provider approval, and policy separation.
- CLI/UAT evidence and reporting requirements are explicit.
