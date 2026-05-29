# Phase 4 Build Plan: PA Form Extraction, Hybrid Reconciliation, and Evidence Crosswalk

**Status:** Implemented and verified

**Date:** 2026-05-23

**Phase:** 4

**Source authority:** `docs/project/prd/pa_document_intelligence_prd.md`, `docs/project/architecture/pa_document_intelligence_architecture.md`, `docs/project/security-governance/governance-security-spec.md`, `docs/project/configuration/config_yaml_reference.md`, `docs/project/testing/cli-uat-harness.md`, `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`, `docs/project/build-plan/phase-roadmap.md`, `docs/project/build-plan/phases/phase-3-5-digest-review-analysis-index.md`

**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/phase-build-planner.md`

## Executive Summary

Phase 4 turns the Phase 3/3.5 packet inventory into the first field-level prior authorization
workflow artifact. It extracts structured fields, questions, answers, and required-evidence hints
from pages classified as `prior_authorization_form`, supports text-only, vision-only, and hybrid
field extraction, writes a reconciled standalone `pa_form_extraction.json` artifact, then creates an
initial system-owned form-to-evidence crosswalk for those extracted form items.

The phase must keep the PA form extraction artifact separate from the crosswalk. The extraction
artifact is the authoritative structured input for crosswalk construction and must be rebuildable
from `packet_digest.json`, `packet_analysis_index.json`, the classified PA form pages, and the
active `pa_form_extraction` prompt/schema configuration. Because PA form layout, checkbox state,
and field/value alignment may not survive Tesseract OCR, Phase 4 must support a hybrid extraction
mode that runs both the OCR/native-text path and the vision page-image path, normalizes both
outputs, reconciles conflicts, and preserves per-field provenance. The crosswalk may use
LLM-proposed matches, but the system owns crosswalk assembly, schema validation, provenance,
missing/unclear outcomes, and policy separation.

## Phase Objective

Answer the first field-level questions needed before final clinical review:

- What fields, questions, answers, checkboxes, and free-text responses are present on the PA form?
- Which original PA form page produced each extracted item?
- Did OCR/native text, vision, or hybrid reconciliation produce the final value?
- Where OCR/native text and vision disagree, what alternate candidates and review flags were
  preserved?
- Which extracted items require supporting evidence from physician notes or configured supporting
  documents?
- Which evidence pages appear to support, contradict, or fail to support each PA form item?
- Can every extracted PA form item produce a crosswalk entry, including missing or unclear support?
- Can the output be reviewed from file artifacts without requiring SQLite or a later final-review
  pipeline?

## In Scope

- Add a PA form extraction model with stable field IDs, labels/questions, answers/values, source
  page numbers, confidence, extraction method, and review flags.
- Add configurable PA form extraction modes: `text_only`, `vision_only`, and `hybrid`.
- Add a `pa_form_extraction` configuration section to control extraction mode, image inclusion,
  comparison, reconciliation, page/image limits, and fallback behavior.
- Use `llm.task_profiles` to identify the model profiles used by PA form extraction. The default
  model identity comes from `llm.task_profiles.pa_form_extraction`; hybrid mode may optionally use
  separate text and vision task names when configured.
- In `text_only` mode, extract field/value candidates from normalized PA form page text.
- In `vision_only` mode, extract field/value candidates from rendered PA form page images using a
  vision-capable LiteLLM profile.
- In `hybrid` mode, run both text and vision extraction, normalize both outputs, match candidate
  fields, reconcile field values, preserve alternate candidates, and flag conflicts.
- In hybrid mode, prefer vision candidates for checkbox state, signature/mark detection,
  handwritten values, and layout-sensitive field alignment unless configuration says otherwise.
- In hybrid mode, prefer text candidates for long free text, medication names, diagnosis codes, and
  clean OCR/native text values unless configuration says otherwise.
- Require a vision-capable `pa_form_extraction` profile when `vision_only` or `hybrid` mode needs
  page images; unsupported capability must fail closed or follow an explicit configured fallback.
- Write `pa_form_extraction.json` as a standalone machine-readable artifact in the same run
  directory as `packet_digest.json` and `packet_analysis_index.json`.
- Write `form_extraction_index.json` as a derived scan-friendly index of PA form field labels,
  values, confidence, source pages, extraction sources, answer types, and review flags.
- Treat `pa_form_extraction.json` as rebuildable from the digest, analysis index, PA form page text
  artifacts, and active prompt/schema configuration.
- Add or finalize structured schema definitions for the `pa_form_extraction` task.
- Route PA form extraction through the configured `llm.task_profiles.pa_form_extraction` profile by
  default. When configured, hybrid mode may route text and vision passes through separate
  task-profile mappings such as `pa_form_extraction_text` and `pa_form_extraction_vision`.
- Preserve task metadata: prompt key/version, profile name, model name, deployment scope, status,
  confidence, and failure details without logging raw PHI to console.
- Use classified `prior_authorization_form` pages from the digest as the only PA form source pages.
- Use the rendered page image artifacts and normalized text artifacts for the same original PA form
  pages so text and vision candidates can be compared page by page.
- Record extraction provenance per field, including final `extraction_source`, text candidate,
  vision candidate, selected value, confidence, artifact paths, and reconciliation review flags.
- Include reviewer flags for missing PA form pages, failed extraction, invalid structured output,
  unsupported field shapes, low confidence, blank values, duplicate/conflicting fields, and
  ambiguous checkbox states.
- Build an initial crosswalk artifact or section that creates one crosswalk item for every extracted
  PA form field/question.
- Support crosswalk statuses: `supported`, `contradicted`, `missing`, and `unclear`.
- Use `packet_analysis_index.json` for candidate evidence page lookup.
- Restrict evidence search to configured supporting component types, starting with
  `physician_notes`, `lab_results`, and `medication_history` unless YAML says otherwise.
- Include original page citations for every supported or contradicted item.
- Include evidence provenance fields that distinguish source text from summary-only navigation.
- Write bounded human-readable review output sufficient for CLI UAT.
- Extend the CLI UAT digest/review path or add a clearly bounded Phase 4 command that reports
  `pa_form_extraction.json` and crosswalk artifact paths.

## Out of Scope

- Final clinical review narrative.
- Approval, denial, or payer policy interpretation.
- Broad tool-calling loops or open-ended agentic analysis.
- Broad vision analysis outside PA form pages and configured PA form extraction modes.
- Sending full packets or full PDFs to vision models.
- Arbitrary filesystem, shell, database, network, or secret access by LLM tools.
- Source lifecycle movement, watcher behavior, SFTP intake, queueing, or reprocess/status commands.
- SQLite persistence as the required source of truth.
- Full Phase 5 evidence workspace orchestration.
- Full Phase 6 tool-calling and final-review LLM behavior.
- Phase 7 final output package and optional SQLite indexing.

## Required Artifacts

| Artifact | Purpose | Authority |
|---|---|---|
| `packet_digest.json` | Canonical packet inventory from Phase 3 | Existing source of page/component truth |
| `packet_analysis_index.json` | Derived lookup index from Phase 3.5 | Rebuildable, non-canonical retrieval helper |
| `pa_form_extraction.json` | Structured PA form fields/questions/answers | Authoritative structured input to crosswalk |
| `form_extraction_index.json` | Scan-friendly field/value/confidence index | Derived rebuildable review and crosswalk helper |
| `form_evidence_crosswalk.json` or equivalent section | Initial support mapping for each extracted PA form item | System-owned, validated crosswalk output |
| Phase 4 Markdown/UAT output | Human review of extracted fields and crosswalk status | Reviewer-facing convenience artifact |

## Required Configuration Model

Phase 4 must preserve the project-wide LiteLLM routing pattern. The `llm.task_profiles` section
selects the model profile. The `pa_form_extraction` section controls how PA form extraction runs.

Recommended default configuration:

```yaml
pa_form_extraction:
  mode: "hybrid"  # text_only | vision_only | hybrid
  llm_task: "pa_form_extraction"
  include_page_images: true
  max_pages_per_request: 2
  max_images_per_request: 2
  compare_outputs: true
  require_reconciliation: true
  fallback_when_vision_unavailable: "fail"  # fail | text_only
```

The default profile is resolved through:

```yaml
llm:
  task_profiles:
    pa_form_extraction: "pa_form_extraction_vision"
  profiles:
    pa_form_extraction_vision:
      model: "openai/<lm-studio-vision-model>"
      base_url: "http://127.0.0.1:1234/v1"
      deployment_scope: "local"
      api_key_env:
      structured_outputs: true
      supports_vision: true
      max_images_per_request: 2
```

Hybrid mode may use one vision-capable profile for both text and image inputs, or separate task
profiles when different models are desired:

```yaml
pa_form_extraction:
  mode: "hybrid"
  text_llm_task: "pa_form_extraction_text"
  vision_llm_task: "pa_form_extraction_vision"

llm:
  task_profiles:
    pa_form_extraction_text: "pa_form_extraction_text_local"
    pa_form_extraction_vision: "pa_form_extraction_vision_local"
```

Configuration validation must require:

- `mode` is one of `text_only`, `vision_only`, or `hybrid`.
- `text_only` resolves a structured-output-capable text profile.
- `vision_only` resolves a structured-output-capable profile with `supports_vision: true` and
  `max_images_per_request > 0`.
- `hybrid` resolves both a structured-output-capable text path and a structured-output-capable
  vision path.
- `hybrid` vision path has `supports_vision: true` and enough image capacity for configured
  `max_images_per_request`.
- If vision is unavailable, behavior follows `fallback_when_vision_unavailable` and records a
  review flag.
- `vision_only` requires `include_page_images: true`; `hybrid` requires page images unless
  `fallback_when_vision_unavailable: text_only` is explicitly configured.
- `max_pages_per_request` and `max_images_per_request` are hard request limits. If detected PA form
  pages exceed a limit, the artifact must record an omitted-page review flag rather than implying
  that every PA form page was processed.

## Proposed `pa_form_extraction.json` Shape

```json
{
  "artifact_type": "pa_form_extraction",
  "artifact_version": "1.0",
  "derived_from": {
    "packet_digest_json": "doc_.../packet_digest.json",
    "packet_analysis_index_json": "doc_.../packet_analysis_index.json",
    "pa_form_pages": [1, 2]
  },
  "extraction_method": "litellm",
  "extraction_mode": "hybrid",
  "reconciliation_method": "text_vision_candidate_merge",
  "llm_task": {
    "task_name": "pa_form_extraction",
    "profile_name": "clinical_reviewer_local",
    "prompt_key": "pa_form_extraction",
    "prompt_version": "..."
  },
  "form_components": [
    {
      "component_id": "prior_authorization_form:1-2",
      "component_type": "prior_authorization_form",
      "pages": [1, 2]
    }
  ],
  "fields": [
    {
      "field_id": "requested_medication",
      "label": "Medication Requested",
      "question": null,
      "value": "TREMFYA 100 mg/mL",
      "source_page": 1,
      "source_component_id": "prior_authorization_form:1-2",
      "answer_type": "text",
      "required_evidence_hint": "clinical notes supporting diagnosis and prior therapy",
      "extraction_source": "hybrid_agreed",
      "confidence": 0.91,
      "extraction_method": "litellm",
      "source_text_artifact_path": "doc_.../text/page-0001.normalized.txt",
      "source_image_artifact_path": "doc_.../pages/page-0001.png",
      "candidates": [
        {
          "source": "ocr_text",
          "value": "TREMFYA 100 mg/mL",
          "confidence": 0.88,
          "artifact_path": "doc_.../text/page-0001.normalized.txt"
        },
        {
          "source": "vision",
          "value": "TREMFYA 100 mg/mL",
          "confidence": 0.96,
          "artifact_path": "doc_.../pages/page-0001.png"
        }
      ],
      "review_flags": []
    }
  ],
  "review_flags": []
}
```

## Proposed Crosswalk Shape

Each crosswalk item should be created from one extracted PA form field. Missing evidence is still an
item, not an omitted record.

```json
{
  "form_field_id": "requested_medication",
  "form_field": "Medication Requested",
  "form_question": null,
  "form_value": "TREMFYA 100 mg/mL",
  "form_page": 1,
  "support_status": "supported",
  "supporting_pages": [3, 6, 12],
  "supporting_component_types": ["physician_notes"],
  "evidence_summary": "Physician notes describe PsA and planned Tremfya therapy.",
  "source_span_refs": [
    {
      "page_number": 6,
      "text_artifact_path": "doc_.../text/page-0006.normalized.txt",
      "start_char": null,
      "end_char": null
    }
  ],
  "evidence_provenance": {
    "retrieval_method": "analysis_index_component_scan",
    "validated_against_source": true,
    "used_summary_only": false
  },
  "confidence": 0.82,
  "review_flags": []
}
```

## Workstreams

### 1. PA Form Extraction Schema and Models

- Define models for `PaFormExtractionArtifact`, form components, form fields, and extraction task
  audit metadata.
- Define field candidate models for OCR/native-text candidates and vision candidates.
- Define reconciliation metadata including `extraction_mode`, `reconciliation_method`,
  `extraction_source`, selected candidate source, alternate candidates, and conflict flags.
- Define controlled answer types such as `text`, `checkbox`, `date`, `number`, `multi_select`,
  `signature`, and `unknown`.
- Define review flags for ambiguous, missing, duplicate, conflicting, low-confidence, and invalid
  field extraction.
- Validate that every extracted field has a stable `field_id`, source page, value field, confidence,
  and extraction method.

### 2. Configuration and Capability Validation

- Add `PaFormExtractionSettings` to YAML-backed settings.
- Validate extraction mode, fallback behavior, page/image limits, task mappings, and profile
  capabilities at config-check time.
- Preserve the existing LiteLLM task-profile model: task names resolve to profiles; profiles carry
  model identity, endpoint, deployment scope, structured-output support, vision support, and image
  limits.
- Require a vision-capable profile for `vision_only` and the vision pass of `hybrid`.
- Support optional separate `text_llm_task` and `vision_llm_task` mappings for hybrid mode.

### 3. Artifact Path and Rebuild Rules

- Add deterministic artifact paths for `pa_form_extraction.json`, `form_extraction_index.json`,
  and crosswalk output.
- Keep artifacts under the active run directory.
- Record `derived_from.packet_digest_json`, `derived_from.packet_analysis_index_json`, PA form pages,
  prompt version, and model profile.
- Ensure a new run writes a new artifact instead of overwriting prior run artifacts.

### 4. PA Form Extraction Service

- Load `packet_digest.json` and `packet_analysis_index.json`.
- Locate PA form pages from component inventory and `pages_by_type.prior_authorization_form`.
- Retrieve bounded normalized text and rendered page images for PA form pages from artifact paths.
- For `text_only`, call `pa_form_extraction` with normalized PA form text only.
- For `vision_only`, call `pa_form_extraction` with rendered PA form page images only.
- For `hybrid`, call the text extraction path and the vision extraction path, then reconcile the
  structured candidate outputs into one field list.
- Do not use digest page summaries as extraction input. If normalized PA form text is unavailable,
  send empty page text for that page and flag missing normalized text for reviewer attention.
- Validate structured output against schema.
- The schema may allow omitted optional strings for labels, questions, values, and evidence hints;
  visible-but-blank values should be represented as an empty string and later flagged
  `blank_form_value`.
- Fail with reviewer-facing artifact flags when the PA form is missing, extraction fails, or schema
  validation fails.

### 5. Hybrid Candidate Reconciliation

- Normalize OCR/native-text and vision field candidates to stable `field_id` values using label,
  question text, page number, and configured synonym rules where available.
- Match candidate fields by `field_id`, normalized label similarity, source page, and nearby
  question text.
- If text and vision agree, accept the shared value with `extraction_source = "hybrid_agreed"`.
- If text is blank and vision has a value, accept vision with `ocr_missing_value`.
- If vision is blank and text has a value, accept text when confidence and OCR quality are adequate
  with `vision_missing_value`.
- If text and vision disagree, preserve both candidates and either select the stronger candidate
  with a conflict flag or mark the final field as `needs_review` when confidence is insufficient.
- Never discard alternate candidates from the final artifact.
- Record reconciliation decisions and review flags without exposing raw prompts or full LLM
  responses to console output.

### 6. Initial Crosswalk Builder

- Use `pa_form_extraction.json` as input.
- Use `packet_analysis_index.json` to select candidate evidence pages from configured components.
- Create one crosswalk item for each extracted field.
- If an extracted field has a blank or null form value, create an `unclear` item with
  `blank_form_value`, no supporting pages, and no source-validated evidence claim.
- Support `supported`, `contradicted`, `missing`, and `unclear`.
- Require original page citations for supported and contradicted entries.
- Mark summary-only matches as not source-validated.
- Keep payer policy interpretation out of the output.

### 7. CLI UAT Surface

- Add a Phase 4 CLI UAT command or extend the current digest command only if the command name and
  output stay clear.
- Console output should report artifact paths, counts, missing/unclear counts, and review flags.
- Console output must not print raw extracted document text, full prompts, or full LLM responses.
- The command must work in file-only mode.

### 8. Tests and Fixtures

- Add synthetic PA form extraction fixtures.
- Add tests for the approved non-PHI clinical sample once expected field IDs are reviewed.
- Add schema validation tests for `pa_form_extraction.json`.
- Add tests proving `form_extraction_index.json` is written and summarizes each field label, value,
  confidence, source page, extraction source, answer type, and review flags.
- Add tests for `text_only`, `vision_only`, and `hybrid` extraction modes.
- Add config validation tests for `pa_form_extraction` mode, task mappings, vision capability,
  structured-output capability, image limits, and fallback behavior.
- Add reconciliation tests for agreement, OCR missing value, vision missing value, conflicting
  values, ambiguous checkbox state, and preserved alternate candidates.
- Add crosswalk completeness tests proving every extracted field creates one crosswalk item.
- Add missing PA form, malformed LLM output, low-confidence extraction, and missing evidence tests.
- Add negative tests proving Phase 4 does not invoke Phase 5/6 tool loops, final review, lifecycle,
  watcher, SFTP, or SQLite-only persistence.

## Acceptance Criteria

- `pa_form_extraction.json` is written for packets with a detected PA form.
- `form_extraction_index.json` is written as a derived compact index for quick machine-readable
  review of field/value/confidence pairs.
- The artifact includes stable field IDs, labels/questions, values, source PA form pages,
  confidence, extraction method, and review flags.
- The artifact records `extraction_mode` and per-field `extraction_source`.
- Hybrid mode preserves OCR/native-text and vision candidates and records reconciliation decisions.
- Vision-only and hybrid modes require a vision-capable `pa_form_extraction` profile or fail
  according to explicit configured fallback behavior.
- Request limits that omit detected PA form pages create review flags.
- Checkbox, signature, handwritten, and layout-sensitive fields can be sourced from the vision path.
- Missing PA form pages produce a reviewer-facing failure/flag rather than an unsupported crosswalk.
- Every extracted PA form field creates exactly one initial crosswalk item.
- Blank or null PA form values do not receive supporting pages and are flagged `blank_form_value`.
- Crosswalk items use only `supported`, `contradicted`, `missing`, or `unclear`.
- Supported and contradicted items cite original evidence page numbers.
- The crosswalk distinguishes source-validated evidence from summary-only navigation.
- The CLI UAT output reports `pa_form_extraction.json`, `form_extraction_index.json`, and crosswalk
  artifact paths.
- The Phase 4 Markdown output includes bounded field values in the extracted-field and crosswalk
  review tables.
- File-only mode remains valid.
- Tests cover schema validation, artifact writing, missing components, missing evidence, and
  no-scope-leakage boundaries.

## Key Risks and Mitigations

| Risk | Mitigation |
|---|---|
| PA form layouts vary by PBM or drug | Use generic field extraction with stable normalized IDs; defer template-specific profiles until known. |
| Tesseract misses checkboxes or field alignment | Use hybrid extraction with rendered page images and preserve vision candidates. |
| Vision and OCR disagree | Preserve both candidates, apply deterministic reconciliation rules, and flag unresolved conflicts. |
| LLM extracts plausible but unsupported fields | Require source page, confidence, structured schema validation, and review flags. |
| Crosswalk treats summaries as evidence | Require source page citations and provenance flag `used_summary_only`. |
| Phase 4 drifts into broad agentic analysis | Keep tool loops, evidence workspace orchestration, and final review deferred to Phase 5/6. |
| Long local-model runtimes | Keep context bounded to PA form pages and candidate evidence pages; expose limits through YAML. |
| Crosswalk omits difficult fields | Require one crosswalk item per extracted field, including missing or unclear outcomes. |

## Documentation Updates Required During Implementation

- Update PRD only for requirement corrections, not scope expansion.
- Update architecture with any finalized artifact model fields.
- Update traceability after implementation evidence exists.
- Update CLI UAT harness with the final Phase 4 command and expected output fields.
- Update configuration reference if new YAML options are added for extraction limits, prompt
  selection, or crosswalk output behavior.

## Phase Exit

Phase 4 exits when the CLI UAT path can process an approved packet, write the PA form extraction
artifact, write the initial crosswalk artifact, and prove each extracted PA form item has a
crosswalk outcome with source page provenance or an explicit missing/unclear status.

See `docs/project/testing/cli-uat-harness.md` for the running UAT findings log. The Phase 4 UAT for
`doc08294920260513101420.pdf` identified an upstream page-classification issue in which pages 2 and
7 were classified as PA form pages even though reviewer inspection confirmed they are physician
notes. Prompt/model tuning is deferred until additional sample packets are available.
