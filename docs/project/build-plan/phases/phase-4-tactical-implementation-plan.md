# Phase 4 Tactical Implementation Plan: PA Form Extraction, Hybrid Reconciliation, and Evidence Crosswalk

**Status:** Implemented and verified

**Date:** 2026-05-23

**Phase:** 4

**Source authority:** `docs/project/build-plan/phases/phase-4-pa-form-extraction-crosswalk.md`, `docs/project/prd/pa_document_intelligence_prd.md`, `docs/project/architecture/pa_document_intelligence_architecture.md`, `docs/project/security-governance/governance-security-spec.md`, `docs/project/configuration/config_yaml_reference.md`, `docs/project/testing/cli-uat-harness.md`, `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`, `docs/project/build-plan/phase-roadmap.md`

**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/tactical-implementation-planner.md`

## Implementation Objective

Implement Phase 4 as the first field-level PA form understanding and evidence-linking workflow.
The CLI UAT path must process an approved packet, use existing digest and analysis-index outputs,
extract structured PA form fields into `pa_form_extraction.json`, reconcile OCR/native-text and
vision candidates when configured, write derived `form_extraction_index.json` for quick field/value
review, and write an initial `form_evidence_crosswalk.json` with one crosswalk item for every
extracted field.

This phase proves configurable LiteLLM task routing for PA form extraction, vision-capability
gating, hybrid candidate reconciliation, field-level provenance, crosswalk completeness, PHI-safe
console output, and file-only reviewability. It must not implement final clinical review,
approval/denial recommendations, broad agentic tool loops, lifecycle movement, watcher behavior,
SFTP, or SQLite-required persistence.

## Source Authority Precedence

1. Governance/security specification for PHI handling, model capability gates, prompt/request
   storage, provider approval, image limits, and policy separation.
2. Phase 4 build plan for included and deferred scope.
3. Architecture for artifact ownership, pipeline boundaries, LiteLLM routing, and crosswalk
   construction.
4. PRD for functional requirements and acceptance criteria.
5. Configuration reference for YAML behavior.
6. CLI UAT harness for operator-facing phase-exit evidence.
7. Traceability matrix and phase roadmap for phase placement.

If implementation pressure conflicts with this plan, defer the feature rather than expanding Phase
4 scope.

## Assumptions

- Phase 3/3.5 digest artifacts are the required upstream inputs.
- `packet_digest.json` identifies `prior_authorization_form` pages and includes page artifact paths.
- `packet_analysis_index.json` provides component/page lookup for evidence candidate selection.
- PA form page images exist when vision or hybrid extraction is enabled, or the configured fallback
  decides whether to fail or run text-only.
- LiteLLM remains the only normal model-call path.
- Unit tests use mocked LLM clients and do not require live LM Studio, remote providers, network
  access, or secrets.
- Approved non-PHI files under `docs/project/reference/clinical-samples/` may be used for
  integration and UAT checks.

## Non-Goals

- Do not generate final clinical review summaries.
- Do not recommend approval, denial, medical necessity outcome, or payer policy interpretation.
- Do not add open-ended agentic loops or general tool calling.
- Do not send full packets, full PDFs, or all packet images to a model.
- Do not require SQLite persistence.
- Do not move, archive, delete, quarantine, or mutate source documents.
- Do not implement watcher, SFTP intake, process queues, reprocess/status workflows, or lifecycle
  completion gates.
- Do not build template-specific PA form profiles unless needed only as test fixtures.

## File and Module Ownership

| Area | Ownership expectation |
|---|---|
| `src/benecard_pa/settings.py` | Add `PaFormExtractionSettings`, config loading, and capability validation. |
| `src/benecard_pa/llm/tasks.py` | Expand allowed task definitions for Phase 4 only: `pa_form_extraction`, optional text/vision variants, and bounded `crosswalk_evaluation` if used. |
| `src/benecard_pa/llm/client.py` | Add image-capable structured calls without exposing generic tool-calling or broad multimodal behavior. |
| `src/benecard_pa/llm/prompts.py` | Validate Phase 4 prompt tasks and schemas. |
| `src/benecard_pa/pa_form/` | New package for PA form models, extraction orchestration, hybrid reconciliation, and crosswalk construction. |
| `src/benecard_pa/document/artifact_paths.py` | Add deterministic run-relative paths for Phase 4 artifacts. |
| `src/benecard_pa/output/artifacts.py` | Reuse atomic artifact writing; add helpers only if needed. |
| `src/benecard_pa/cli.py` | Add or extend a bounded Phase 4 CLI UAT command. Keep business logic out of CLI. |
| `config/app.example.yaml` | Add Phase 4 YAML settings and task-profile examples. |
| `config/prompts.example.yaml` | Add PA form extraction and crosswalk task prompts/schemas. |
| `tests/` | Add unit, negative, schema, config, CLI, and UAT-style tests. |

## Workstream 1: Configuration and Capability Gates

**Purpose:** Make Phase 4 execution fully configurable and fail closed when model capabilities do
not satisfy the selected extraction mode.

**Implementation tasks:**

- Add `PaFormExtractionSettings` with `mode`, `llm_task`, `text_llm_task`, `vision_llm_task`,
  `include_page_images`, `max_pages_per_request`, `max_images_per_request`, `compare_outputs`,
  `require_reconciliation`, and `fallback_when_vision_unavailable`.
- Accept modes `text_only`, `vision_only`, and `hybrid`.
- Require structured-output-capable task profiles for all Phase 4 extraction paths.
- Require `supports_vision: true` and positive image capacity for `vision_only` and the vision path
  of `hybrid`.
- Support `fallback_when_vision_unavailable: fail | text_only`, and record the chosen fallback in
  artifacts when used.
- Add Phase 4 task-profile defaults without breaking Phase 3 mappings.

**Affected areas:** `src/benecard_pa/settings.py`, `config/app.example.yaml`,
`docs/project/configuration/config_yaml_reference.md`, `tests/test_settings.py`.

**Required tests:** Valid modes pass; unknown modes fail; missing task mappings fail; non-structured
profiles fail; vision modes fail without vision support; fallback behavior validates; public profile
approval rules still apply.

**Acceptance criteria:** `uv run benecard-pa --config config/app.example.yaml config-check` validates
Phase 4 settings and rejects unsafe or unsupported model routes.

**Dependencies:** Existing `LlmSettings`, governance public-provider checks.

**Non-goals:** Do not add deployment approval workflows beyond existing security settings.

## Workstream 2: Prompt and Structured Schema Contracts

**Purpose:** Define the model-facing contracts for PA form extraction and optional crosswalk
evaluation without hard-coding prompt behavior in Python.

**Implementation tasks:**

- Add `pa_form_extraction` prompt entry and output schema to `config/prompts.example.yaml`.
- Add optional `pa_form_extraction_text` and `pa_form_extraction_vision` prompt mappings for split
  hybrid profiles when configured.
- Define expected extraction output fields: `field_id`, `label`, `question`, `value`,
  `answer_type`, `source_page`, `confidence`, `required_evidence_hint`, and `review_flags`.
- Add or finalize a bounded `crosswalk_evaluation` prompt if LLM-assisted support evaluation is
  included in implementation; otherwise keep crosswalk matching deterministic and document that
  `crosswalk_evaluation` remains unused in this phase.
- Extend prompt catalog validation to check required Phase 4 tasks when the Phase 4 command runs.

**Affected areas:** `config/prompts.example.yaml`, `src/benecard_pa/llm/prompts.py`,
`tests/test_prompts.py`.

**Required tests:** Required Phase 4 prompt loads; missing extraction prompt fails closed; output
schema names resolve; malformed prompt YAML fails with PHI-safe error.

**Acceptance criteria:** PA form extraction prompt behavior can be changed from YAML without Python
edits.

**Dependencies:** Workstream 1 task names and settings.

**Non-goals:** Do not create final review prompts or payer-policy prompts.

## Workstream 3: Multimodal LiteLLM Boundary

**Purpose:** Extend the existing structured LiteLLM call boundary to support selected PA form page
images while preserving task/profile capability gates.

**Implementation tasks:**

- Generalize `complete_structured` or add a narrow companion method that accepts bounded text and
  selected image artifacts for configured Phase 4 tasks.
- Encode image inputs in an OpenAI-compatible message shape accepted by LiteLLM while preserving
  provider portability where practical.
- Enforce `max_images_per_request`, `max_pages_per_request`, `supports_vision`, and structured
  output before calling LiteLLM.
- Preserve task metadata: task name, profile, model, prompt key/version, scope type, component ID,
  page numbers, vision flag, and status.
- Keep raw prompts, source text, image bytes, and raw LLM responses out of console output and logs.
- Keep Phase 3 tasks text-only unless a Phase 4 command explicitly invokes the new image-capable
  path.

**Affected areas:** `src/benecard_pa/llm/client.py`, `src/benecard_pa/llm/tasks.py`,
`src/benecard_pa/document/models.py`, `tests/test_llm_client.py`.

**Required tests:** Text-only structured calls still work; image calls require vision support;
image-capacity overflow fails; unsupported task fails; response JSON is parsed from content or
reasoning fallback; empty/malformed responses fail safely.

**Acceptance criteria:** Phase 4 can call local LM Studio or another LiteLLM-compatible vision
profile when configured, while tests remain fully mocked.

**Dependencies:** Workstreams 1 and 2.

**Non-goals:** Do not expose arbitrary LLM tools or filesystem access.

## Workstream 4: PA Form Artifact Models

**Purpose:** Define stable internal and serialized models for `pa_form_extraction.json`.

**Implementation tasks:**

- Create `src/benecard_pa/pa_form/models.py`.
- Define dataclasses or typed models for extraction artifact, derived-from metadata, form
  components, fields, field candidates, reconciliation metadata, and task audit metadata.
- Use controlled values for `answer_type`, `extraction_mode`, `extraction_source`, and
  reconciliation flags.
- Require every field to include `field_id`, `label` or `question`, `value`, `source_page`,
  `source_component_id`, `answer_type`, `confidence`, `extraction_method`, and `review_flags`.
- Preserve text and vision candidates even when one candidate is selected as final.
- Include artifact paths for source text and source image when available.

**Affected areas:** `src/benecard_pa/pa_form/models.py`, `src/benecard_pa/document/models.py` only
if shared audit fields are reused, `tests/test_pa_form_models.py`.

**Required tests:** Valid artifact serializes; missing required field fails validation; unknown
controlled values fail or flag according to model policy; alternate candidates survive round trip.

**Acceptance criteria:** `pa_form_extraction.json` has a stable, test-covered schema suitable as the
authoritative structured input to the crosswalk.

**Dependencies:** Workstream 2 schema fields.

**Non-goals:** Do not make SQLite rows the authoritative extraction store.

## Workstream 5: PA Form Extraction Service

**Purpose:** Extract structured PA form fields from classified PA form pages using configured
text-only, vision-only, or hybrid mode.

**Implementation tasks:**

- Create `src/benecard_pa/pa_form/extraction.py`.
- Load upstream `packet_digest.json` and `packet_analysis_index.json` from the active run.
- Locate PA form pages from digest components and `pages_by_type.prior_authorization_form`.
- Gather bounded normalized text artifacts and rendered page images for the same PA form pages.
- In `text_only`, call the text extraction path with normalized page text only.
- In `vision_only`, call the vision extraction path with page images only.
- In `hybrid`, call both extraction paths and send their candidate outputs to reconciliation.
- Validate structured model output before constructing the artifact.
- Produce reviewer-facing artifact flags for missing PA form pages, missing images, malformed LLM
  output, low confidence, duplicate fields, and extraction failure.

**Affected areas:** `src/benecard_pa/pa_form/extraction.py`,
`src/benecard_pa/document/artifact_paths.py`, `tests/test_pa_form_extraction.py`.

**Required tests:** Missing PA form pages flags/fails safely; text-only extracts mocked fields;
vision-only extracts mocked fields; hybrid invokes both paths; malformed output produces flags; no
full packet text is assembled.

**Acceptance criteria:** Packets with detected PA form pages produce a valid
`pa_form_extraction.json` or a PHI-safe failure result with review flags.

**Dependencies:** Workstreams 1 through 4.

**Non-goals:** Do not search supporting documents for evidence in this service.

## Workstream 6: Hybrid Candidate Reconciliation

**Purpose:** Merge OCR/native-text and vision candidates into a single defensible field list with
explicit provenance and conflict handling.

**Implementation tasks:**

- Create `src/benecard_pa/pa_form/reconciliation.py`.
- Normalize candidate field IDs from model output using `field_id`, label/question text, source
  page, and simple configured synonym rules if available.
- Match candidates by normalized field ID first, then label similarity/page/question fallback.
- Accept agreement as `hybrid_agreed`.
- Accept vision when OCR/text is blank and vision has a value, flagging `ocr_missing_value`.
- Accept text when vision is blank and text confidence is adequate, flagging `vision_missing_value`.
- Preserve both candidates on disagreement and either choose the stronger candidate with a conflict
  flag or set the final field to `needs_review` when confidence is insufficient.
- Prefer vision for checkbox state, signature/mark detection, handwriting, and layout-sensitive
  alignment unless config later says otherwise.
- Prefer text for long free text, medication names, diagnosis codes, and clean OCR/native values
  unless config later says otherwise.

**Affected areas:** `src/benecard_pa/pa_form/reconciliation.py`,
`tests/test_pa_form_reconciliation.py`.

**Required tests:** Agreement; OCR missing; vision missing; conflict preserved; ambiguous checkbox;
duplicate field IDs; alternate candidates preserved; low-confidence final value flagged.

**Acceptance criteria:** Hybrid mode never silently discards disagreements or alternate candidates.

**Dependencies:** Workstream 4 candidate models.

**Non-goals:** Do not use LLM judgment to hide conflicts from reviewers.

## Workstream 7: Initial Evidence Crosswalk Builder

**Purpose:** Build one crosswalk item for every extracted PA form field and link it to supporting,
contradicting, missing, or unclear evidence pages.

**Implementation tasks:**

- Create `src/benecard_pa/pa_form/crosswalk.py`.
- Read `pa_form_extraction.json` and `packet_analysis_index.json`.
- Restrict candidate evidence to configured supporting component types, initially
  `physician_notes`, `lab_results`, and `medication_history`.
- Create one crosswalk item per extracted field, even when evidence is missing or unclear.
- For blank or null form values, create an `unclear` crosswalk item with no supporting pages,
  `blank_form_value`, and no source-validated evidence claim.
- Include support statuses `supported`, `contradicted`, `missing`, and `unclear`.
- Require original page citations for supported and contradicted entries.
- Distinguish source-validated matches from summary-only navigation.
- Keep any LLM-assisted support output advisory; system code owns schema validation, completeness,
  status normalization, and page citation checks.

**Affected areas:** `src/benecard_pa/pa_form/crosswalk.py`, `tests/test_pa_form_crosswalk.py`.

**Required tests:** One item per extracted field; missing evidence still creates item; unsupported
status rejected; source citations required for supported/contradicted; summary-only evidence marked
as not source-validated; configured evidence component restrictions are honored.

**Acceptance criteria:** `form_evidence_crosswalk.json` is complete, policy-separated, and cites
original pages for any support or contradiction claim.

**Dependencies:** Workstreams 4 and 5, existing `packet_analysis_index.json`.

**Non-goals:** Do not implement final review narrative or payer policy reasoning.

## Workstream 8: Artifact Writing and Markdown Review Output

**Purpose:** Persist machine-readable and human-reviewable Phase 4 outputs under the active run
directory.

**Implementation tasks:**

- Add deterministic artifact paths for `pa_form_extraction.json`,
  `form_extraction_index.json`, `form_evidence_crosswalk.json`, and optional Phase 4 Markdown.
- Write artifacts atomically using existing output helpers.
- Build `form_extraction_index.json` from `pa_form_extraction.json`; do not treat it as a second
  source of truth.
- Include `derived_from.packet_digest_json`, `derived_from.packet_analysis_index_json`, PA form
  pages, prompt keys/versions, and model profile metadata.
- Add a bounded Markdown review that lists source document, artifact paths, field counts,
  extraction mode, conflict counts, missing/unclear crosswalk counts, and page citations.
- Include bounded form values in the Markdown extracted-field and crosswalk tables.
- Do not print raw extracted document text, full prompts, or full LLM responses.

**Affected areas:** `src/benecard_pa/document/artifact_paths.py`,
`src/benecard_pa/output/artifacts.py`, `src/benecard_pa/pa_form/output.py`,
`tests/test_artifacts.py`, `tests/test_pa_form_output.py`.

**Required tests:** Artifact paths are run-relative; prior runs are not overwritten; JSON writes
atomically; Markdown is bounded and PHI-safe by console standards; source document name is included
for approved UAT review context.

**Acceptance criteria:** Reviewers can inspect Phase 4 results from file artifacts without SQLite.

**Dependencies:** Workstreams 4, 5, and 7.

**Non-goals:** Do not implement long-term retention or archive movement.

## Workstream 9: CLI UAT Surface

**Purpose:** Expose a bounded CLI command that proves Phase 4 end to end while preserving the CLI as
an integration harness only.

**Implementation tasks:**

- Add a command such as `crosswalk <source_path>` or `analyze-pa-form <source_path>`. Prefer a
  name that clearly signals Phase 4 outputs rather than silently expanding `digest`.
- The command may internally run the existing digest path first, then run PA form extraction and
  crosswalk generation against the active run artifacts.
- Console output must include status, source document name, output directory, digest path, analysis
  index path, PA form extraction path, crosswalk path, field count, crosswalk count, conflict count,
  missing/unclear counts, review flags, and task-profile summary.
- Exit code `0` requires required Phase 4 artifacts to be written.
- Nonzero exit codes must use PHI-safe failure messages.

**Affected areas:** `src/benecard_pa/cli.py`, `src/benecard_pa/digest_review.py` or a new
`src/benecard_pa/pa_form/workflow.py`, `docs/project/testing/cli-uat-harness.md`,
`tests/test_cli.py`.

**Required tests:** CLI success with mocked services; missing source file fails; invalid config
fails; console output contains artifact paths and counts; console output excludes raw extracted
field text unless explicitly bounded in artifact files; file-only mode works.

**Acceptance criteria:** A single CLI command can serve as Phase 4 UAT against approved samples.

**Dependencies:** Workstreams 1 through 8.

**Non-goals:** Do not add daemon, queue, watcher, or lifecycle commands.

## Workstream 10: Documentation and Traceability Close-Out

**Purpose:** Reconcile implemented behavior back into the canonical documentation stream.

**Implementation tasks:**

- Update `docs/project/configuration/config_yaml_reference.md` with final Phase 4 YAML options.
- Update `docs/project/testing/cli-uat-harness.md` with the final Phase 4 command, console fields,
  and expected artifacts.
- Update architecture only if implementation finalizes artifact fields or module boundaries not
  already captured.
- Update traceability rows with implementation/test evidence after verification.
- Update the Phase 4 tactical plan status during close-out.

**Affected areas:** project documentation only.

**Required tests:** Documentation references final command names and artifact names used by code.

**Acceptance criteria:** The AI construction directive and implemented code have no undocumented
Phase 4 behavior.

**Dependencies:** All implementation workstreams.

**Non-goals:** Do not revise methodology docs for project-specific CLI or artifact behavior.

## Data and Schema Changes

- Add `pa_form_extraction.json` as the authoritative field extraction artifact for Phase 4.
- Add `form_extraction_index.json` as a derived scan-friendly field/value/confidence index.
- Add `form_evidence_crosswalk.json` as the initial field-to-evidence support artifact.
- Do not change SQLite schema unless a later phase explicitly requires indexing these artifacts.
- Do not modify `packet_digest.json` schema except to consume existing fields.
- Do not modify `packet_analysis_index.json` schema unless a minimal backward-compatible helper
  field is required and documented.

## API, CLI, and Config Changes

- Add top-level YAML section `pa_form_extraction`.
- Add task-profile support for `pa_form_extraction`, optional `pa_form_extraction_text`, optional
  `pa_form_extraction_vision`, and optional `crosswalk_evaluation`.
- Add prompt task mapping for `pa_form_extraction`.
- Add a Phase 4 CLI command or clearly named extension that reports artifact paths and counts.
- Preserve existing `digest <source_path>` behavior and outputs.

## Migration Order

1. Add settings, task names, prompt examples, and config validation.
2. Add model/schema classes and artifact paths.
3. Extend LiteLLM boundary for bounded image-capable structured calls.
4. Implement extraction service with mocked LLM tests.
5. Implement reconciliation.
6. Implement crosswalk builder.
7. Add artifact writing and Markdown review output.
8. Add CLI UAT command.
9. Run full verification and update docs/traceability.

## Security and Governance Work

- Prove no full packet text or full PDF is sent to the LLM by default.
- Prove image calls are limited to classified PA form pages and configured image limits.
- Prove unsupported vision profiles fail closed or use explicit `text_only` fallback.
- Prove public model profiles remain blocked unless `security.allow_public_llm_profiles` is
  explicitly enabled.
- Prove console output excludes raw document text, full prompts, raw LLM responses, patient
  identifiers, and source snippets.
- Prove output schema cannot imply approval, denial, adjudication, or payer-policy determination.

## Negative Tests

- Missing PA form component.
- Missing `packet_analysis_index.json`.
- Missing rendered PA form image in `vision_only`.
- Missing rendered PA form image in `hybrid` with `fallback_when_vision_unavailable: fail`.
- Hybrid vision unavailable with `fallback_when_vision_unavailable: text_only`.
- Model profile lacks `supports_vision`.
- Model profile lacks structured output.
- Too many page images for configured max.
- Malformed LLM JSON.
- LLM output with duplicate/conflicting field IDs.
- Crosswalk output missing an item for an extracted field.
- Supported/contradicted crosswalk item without original page citation.
- Attempted unsupported final-review or lifecycle behavior.

## CLI UAT Check

Expected command shape:

```bash
uv run benecard-pa --config config/app.example.yaml crosswalk docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

Expected console fields:

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

The exact command name may be finalized during implementation, but it must be reflected in
`docs/project/testing/cli-uat-harness.md` before Phase 4 close-out.

## Verification Commands

```bash
uv run benecard-pa --config config/app.example.yaml config-check
uv run pytest
uv run ruff check .
uv run benecard-pa --config config/app.example.yaml crosswalk docs/project/reference/clinical-samples/doc08294920260513101420.pdf
git diff --check
```

If the final CLI command name differs, substitute the documented Phase 4 command.

## Acceptance Criteria

- `config-check` validates all Phase 4 extraction settings and rejects unsupported model routes.
- `pa_form_extraction.json` is written for packets with detected PA form pages.
- `form_extraction_index.json` is written and contains one compact field/value/confidence row per
  extracted PA form field.
- `pa_form_extraction.json` includes stable field IDs, labels/questions, values, answer types,
  source PA form pages, confidence, extraction mode, extraction source, candidates, and review
  flags.
- Hybrid mode preserves OCR/native-text and vision candidates and records reconciliation decisions.
- Vision-only and hybrid modes require a vision-capable profile or follow explicit configured
  fallback behavior.
- Hybrid mode requires `compare_outputs` and `require_reconciliation`; image-enabled modes enforce
  page-image availability or explicit text-only fallback.
- Request page/image limits that omit detected PA form pages are recorded as review flags.
- `form_evidence_crosswalk.json` contains exactly one item per extracted PA form field.
- Blank or null form values do not receive supporting pages and are flagged `blank_form_value`.
- Crosswalk statuses are limited to `supported`, `contradicted`, `missing`, and `unclear`.
- Supported and contradicted crosswalk items cite original evidence page numbers.
- Summary-only navigation is clearly marked and not treated as source-validated evidence.
- CLI UAT reports artifact paths, counts, and review flags without printing raw document content.
- Phase 4 Markdown includes bounded field values for extracted fields and crosswalk rows.
- File-only mode remains valid.
- Tests cover config validation, extraction schemas, hybrid reconciliation, artifact writing,
  crosswalk completeness, CLI output, missing components, missing evidence, and no-scope-leakage
  boundaries.

## Deferred Items

- Final clinical review narrative and final output package.
- Broad tool-assisted evidence workspace orchestration.
- Payer policy interpretation and adjudication.
- SQLite indexing of Phase 4 artifacts.
- Template-specific PA form extraction packs.
- Watcher, SFTP, process queue, reprocess/status, and lifecycle movement.
- Production retention and encryption-at-rest decisions.

## Risks

| Risk | Mitigation |
|---|---|
| Tesseract misses checkboxes or form layout | Hybrid mode sends selected PA form page images to a vision-capable profile. |
| Vision and text candidates disagree | Preserve both candidates and record deterministic reconciliation flags. |
| LLM invents fields | Require source page, schema validation, confidence, candidates, and review flags. |
| Crosswalk omits difficult fields | Test one crosswalk item per extracted field, including missing or unclear statuses. |
| Model call sends too much context | Use only classified PA form pages for extraction and configured component pages for evidence. |
| Output implies payer decision | Restrict schema/status language and add policy-separation tests. |

## Accuracy Pass

- **Scope ambiguity:** The command name is intentionally left finalizable during implementation, but
  the artifact obligations are fixed.
- **Ownership:** New PA form behavior belongs in `src/benecard_pa/pa_form/`, not the CLI or digest
  service.
- **Tests:** Each workstream has required positive and negative tests.
- **Migration:** Phase 4 builds on digest artifacts and does not alter lifecycle or SQLite behavior.
- **Security:** Vision input, public providers, prompt storage, raw responses, and console output are
  explicitly governed.
- **Contradictions:** No contradictions found with the approved Phase 4 build plan, PRD,
  architecture, security/governance spec, CLI UAT harness, or phase roadmap.
