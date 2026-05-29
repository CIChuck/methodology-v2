# Configuration YAML Reference

**Status:** Draft  
**Date:** 2026-05-19  
**Related files:** `config/app.example.yaml`, `config/prompts.example.yaml`
**Governance authority:** `docs/project/security-governance/governance-security-spec.md`

## Purpose

The application should be reconfigured through YAML wherever practical. Runtime paths,
image-to-text behavior, packet decomposition rules, prompt routing, schemas, and LiteLLM model
selection should not require code changes. Security-sensitive defaults and deployment approvals are
governed by the canonical governance/security specification.

## Required Top-Level Sections

| Section | Purpose |
|---|---|
| `app` | Environment, logging level, and timezone. |
| `paths` | Dropbox, processed, failed, output, archive, and temp directories. |
| `watcher` | File watching provider, ignored lifecycle folders, stability checks, and reconciliation interval. |
| `database` | SQLite enablement and database path. |
| `parsing` | PDF/image parsing settings, text threshold, render DPI, baseline OCR engine, and raw/normalized text retention. |
| `image_text_extraction` | Strategy selection for Tesseract, LLM vision extraction, hybrid fallback, and compare mode. |
| `packet_decomposition` | Required and optional packet components, PA form hints, and crosswalk requirement. |
| `packet_digest` | Page inventory artifact behavior, page/component summaries, page signals, artifact path inclusion, and confidence threshold. |
| `analysis` | Analysis mode, digest-driven retrieval, context limits, loop limits, retrieval strategy, and reviewer-flag behavior. |
| `pa_form_extraction` | Phase 4 PA form extraction mode, hybrid reconciliation, image limits, and fallback behavior. |
| `llm` | LiteLLM provider, named model profiles, task-to-profile map, fallback profile, and capability flags. |
| `prompts` | Prompt YAML path, schema path, fallback prompt key, reload behavior, document-type prompt map, and task prompt map. |
| `file_lifecycle` | Successful/failed movement behavior, date folders, hash verification, and collision handling. |
| `security` | PHI-safe logging, prompt/request storage rules, raw response storage, and encryption flags. |

## Parsing

```yaml
parsing:
  min_text_chars_per_page: 50
  render_dpi: 300
  ocr_engine: "tesseract"
  ocr_languages: ["eng"]
  low_ocr_confidence_threshold: 0.50
  save_page_images: true
  save_raw_text: true
  save_normalized_text: true
```

`low_ocr_confidence_threshold` uses normalized OCR confidence on a `0.0`-`1.0` scale. Tesseract raw
confidence may be retained separately on its native `0`-`100` scale for audit diagnostics.
Phase 4 vision and hybrid PA form extraction require rendered page images for PA form pages. If
`save_page_images` is false, the Phase 4 workflow may render the selected PA form pages into the run
artifact directory, but it must not send full PDFs or non-PA-form pages to the model.

## LiteLLM Profiles

`llm.profiles` defines available LiteLLM-backed model profiles. `llm.task_profiles` maps workflow
tasks to those profiles so page analysis, extraction, crosswalk evaluation, and final review can use
different models. Phase 3 can use the combined `page_analysis` task to classify and summarize a page
in one call, or the separate `page_classification` and `page_summary` tasks when
`packet_digest.page_analysis_mode: "separate"`. `llm.default_profile` is the
fallback only when a task does not define a profile and the default profile satisfies the task
capability requirements.

```yaml
llm:
  provider: "litellm"
  default_profile: "clinical_reviewer_local"
  task_profiles:
    image_text_extraction: "clinical_reviewer_local"
    page_analysis: "clinical_reviewer_local"
    page_classification: "clinical_reviewer_local"
    page_summary: "clinical_reviewer_local"
    component_summary: "clinical_reviewer_local"
    pa_form_extraction: "clinical_reviewer_local"
    pa_form_extraction_text: "clinical_reviewer_local"
    pa_form_extraction_vision: "clinical_reviewer_local"
    crosswalk_evaluation: "clinical_reviewer_local"
    final_review: "clinical_reviewer_local"
  profiles:
    fast_text_classifier:
      model: "openai/gpt-4.1-mini"
      base_url:
      api_key_env: "OPENAI_API_KEY"
      temperature: 0.0
      max_tokens: 1000
      timeout_seconds: 60
      retries: 2
      structured_outputs: true
      supports_vision: false
      supports_tool_calling: false
      max_images_per_request: 0
    clinical_reviewer_local:
      model: "clinical-reviewer-local"
      base_url:
      api_key_env: "LITELLM_API_KEY"
      temperature: 0.0
      max_tokens: 4000
      timeout_seconds: 120
      retries: 2
      structured_outputs: true
      supports_vision: false
      supports_tool_calling: true
      max_images_per_request: 0
    openai_frontier:
      model: "openai/gpt-4.1"
      api_key_env: "OPENAI_API_KEY"
      supports_vision: true
      supports_tool_calling: true
      max_images_per_request: 4
    anthropic_frontier:
      model: "anthropic/claude-sonnet-4"
      api_key_env: "ANTHROPIC_API_KEY"
      supports_vision: true
      supports_tool_calling: true
      max_images_per_request: 4
    local_openai_compatible:
      model: "openai/local-clinical-reviewer"
      base_url: "http://localhost:8000/v1"
      api_key_env: "LOCAL_LLM_API_KEY"
      supports_vision: false
      supports_tool_calling: false
      max_images_per_request: 0
```

Secrets must be referenced by environment variable name only. Do not place API keys in YAML.

## PA Form Extraction

Phase 4 uses `pa_form_extraction` to control field extraction from pages classified as
`prior_authorization_form`. The mode can be text-only, vision-only, or hybrid. Hybrid mode runs text
and vision extraction, normalizes both outputs, reconciles candidates, and preserves conflicts in
`pa_form_extraction.json`.

```yaml
pa_form_extraction:
  mode: "hybrid" # text_only | vision_only | hybrid
  llm_task: "pa_form_extraction"
  text_llm_task:
  vision_llm_task:
  include_page_images: true
  max_pages_per_request: 2
  max_images_per_request: 2
  compare_outputs: true
  require_reconciliation: true
  fallback_when_vision_unavailable: "fail" # fail | text_only
```

`text_llm_task` and `vision_llm_task` are optional. If omitted, the workflow uses `llm_task` for the
selected extraction path. `vision_only` and the vision path of `hybrid` require a task profile with
`structured_outputs: true`, `supports_vision: true`, and enough `max_images_per_request` capacity.
If vision is unavailable, `fallback_when_vision_unavailable: text_only` permits an explicit text-only
fallback; `fail` keeps the workflow fail-closed.

`vision_only` requires `include_page_images: true`. `hybrid` also requires page images unless
`fallback_when_vision_unavailable: text_only` is configured. `compare_outputs` and
`require_reconciliation` must remain true for Phase 4 hybrid mode. Page and image limits are hard
per-request bounds; omitted PA form pages must be surfaced as review flags in Phase 4 artifacts.

## Image-to-Text Extraction

Tesseract remains the default baseline for scanned/faxed pages and standalone images. LLM vision
extraction is available only through configured LiteLLM task profiles that support vision.

```yaml
image_text_extraction:
  strategy: "tesseract" # tesseract | llm_vision | hybrid | compare
  default_engine: "tesseract"
  llm_task: "image_text_extraction"
  selected_text_rule: "prefer_tesseract_unless_low_confidence"
  use_llm_when:
    min_tesseract_confidence_below: 0.70
    min_text_chars_below: 50
    page_types:
      - "prior_authorization_form"
      - "lab_results"
  compare_mode:
    enabled: true
    store_comparison_artifact: true
    flag_material_disagreement: true
```

`hybrid` mode runs Tesseract first and invokes LLM vision only for configured low-confidence or
high-value pages. `compare` mode preserves both outputs for evaluation and should record comparison
metadata rather than silently changing the selected text source. `config-check` must reject
unsupported strategy values, an `llm_task` that is not present in `llm.task_profiles`, and
`llm_vision`, `hybrid`, or `compare` strategies when the selected task profile does not declare
`supports_vision: true`.

## Analysis Configuration

The analysis pipeline should use the packet digest as its retrieval index and should not send full
packet text to the LLM by default. Tool-assisted analysis must remain bounded by YAML limits.
Phase 5 implements this section as deterministic workspace orchestration: it reads the packet
digest, packet analysis index, PA form extraction, and initial crosswalk artifacts; writes
`evidence_workspace.json` and `analysis_trace.json`; and records any staged fallback. Broad LLM
tool-loop execution remains deferred. Phase 6 uses an orchestrator-owned active-run tool adapter for
crosswalk context assembly and does not require provider-native model tool-call loops.

```yaml
analysis:
  mode: "tool_assisted"
  output_mode: "uat_review"
  use_packet_digest: true
  send_full_packet_by_default: false
  context:
    max_pages_per_llm_call: 4
    max_tokens_per_llm_call: 12000
    max_candidate_pages_per_field: 6
    max_page_images_per_llm_call: 2
    include_page_images: false
    include_page_text: true
    include_component_summaries: true
    summarize_intermediate_findings: true
  loop_limits:
    max_tool_calls_per_field: 8
    max_total_tool_calls: 200
    max_total_analysis_seconds: 600
    max_analysis_passes: 3
    max_retries_per_step: 2
  retrieval:
    strategy: "digest_keyword_search"
    restrict_evidence_search_to_components:
      - "physician_notes"
      - "lab_results"
      - "medication_history"
    allow_optional_components_as_support: true
  tool_calling:
    enabled: true
    allowed_tools:
      - "get_packet_digest"
      - "list_component_pages"
      - "get_page_text"
      - "get_page_image"
      - "search_packet_text"
      - "get_component_text"
      - "record_evidence_match"
    audit_tool_calls: true
    fail_when_unsupported: false
  review_flags:
    confidence_threshold: 0.70
    require_page_citations: true
    flag_context_exhaustion: true
    flag_missing_required_components: true
  optimization:
    enabled: true
    skip_blank_values: true
    skip_administrative_fields: true
    administrative_field_patterns:
      - "patient name"
      - "patient first name"
      - "patient last name"
      - "date of birth"
      - "dob"
      - "member id"
      - "patient id"
      - "prescriber name"
      - "prescriber phone"
      - "prescriber fax"
      - "office contact"
      - "phone number"
      - "fax number"
      - "patient address"
      - "patient city"
      - "patient state"
      - "patient zip"
      - "prescriber address"
      - "prescriber city"
      - "prescriber state"
      - "prescriber zip"
      - "npi"
      - "tax id"
      - "dea"
      - "signature"
      - "date signed"
      - "request date"
    max_ranked_candidate_pages_per_field: 2
    deterministic_matching_enabled: true
    deterministic_matchers:
      - "diagnosis_code"
      - "medication"
      - "dose"
      - "directions"
      - "date"
      - "phone"
      - "fax"
      - "identifier"
      - "measurement"
    deterministic_confidence: 0.88
    allow_deterministic_finalization_for_critical: true
    batch_evaluation_enabled: false
    max_fields_per_batch: 3
    max_pages_per_batch: 4
```

Tool use and vision input are capability-gated. `analysis.tool_calling.enabled` allows the
orchestrator to use configured active-run tools for bounded context assembly. Phase 6 does not
expose provider-native model tool-call loops; if a later phase enables provider-native model tool
calling, the selected task profile's `llm.profiles.*.supports_tool_calling` flag must allow it.
Page images are sent only when `analysis.context.include_page_images` is true, the selected task
profile has `supports_vision: true`, and configured image limits are respected.

Phase 6.5 uses `analysis.optimization` to reduce avoidable crosswalk evaluation work. Blank or null
form values are kept in the evaluated crosswalk as `unclear` with explicit skip flags instead of
consuming LLM calls. Administrative/contact/routing fields matching
`administrative_field_patterns` are excluded from crosswalk evaluation so the evaluated crosswalk
focuses on evidence-bearing fields. Candidate pages are ranked before text retrieval and LLM
evaluation, then bounded by `max_ranked_candidate_pages_per_field`. Deterministic structured
matchers may finalize low-risk page-supported values such as diagnosis codes, medication names,
directions, dates, phone or fax values, identifiers, and measurements.
`allow_deterministic_finalization_for_critical` controls whether exact, page-supported critical
fields can skip LLM confirmation. Batch evaluation remains configurable and is disabled by default
until live UAT proves the schema and model behavior are stable.

Internal diagnostic review flags remain in full evaluated crosswalk and trace artifacts. Reviewer
surfaces, including the compact evaluated crosswalk index and Markdown, normalize those internal
flags into generic labels and include plain-English definitions.

Valid `analysis.mode` values are `single_pass`, `staged`, and `tool_assisted`. In Phase 5,
`tool_assisted` checks the `crosswalk_evaluation` profile capability but falls back to deterministic
staged workspace creation when evaluation is unavailable or deferred and `fail_when_unsupported` is
false. In Phase 6, `tool_assisted` uses the orchestrator-owned active-run adapter to assemble
bounded context for `crosswalk_evaluation`; provider-native model tool-call loops remain deferred.
Valid `analysis.output_mode` values are `debug_full`, `uat_review`, `production`, and
`audit_minimal`. `uat_review` remains the default and writes the full evaluated crosswalk, compact
index, Markdown review surface, and full evaluation trace. `production` writes only the two primary
review deliverables: `evaluated_form_evidence_crosswalk_index.json` and
`evaluated_form_evidence_crosswalk.md`. `audit_minimal` writes those same review deliverables plus
a minimal trace without full tool-use detail.
In Phase 6.5, a successful end-to-end `production` run prunes the active run directory after the
final review deliverables are written so upstream digest, extraction, crosswalk, workspace, page
image, OCR, and text intermediates are not retained in the production output folder.
`analysis.tool_calling.allowed_tools` is restricted to the active-run document access operations
listed in `config/app.example.yaml`; arbitrary filesystem, shell, network, database, secret, or
configuration access is not allowed.

Phase 5 artifacts distinguish the configured request from the executed behavior with `mode`,
`execution_mode`, `fallback_mode`, and `fallback_reason`. Because Phase 5 does not yet perform final
evidence evaluation, the workspace stores selected candidate context pages and context refs, not
final evidence judgments. `EvidenceObservation` entries remain empty until a later phase performs
LLM-supported evidence evaluation.

## Prompt Configuration

Prompt behavior should remain externalized.

```yaml
prompts:
  file_path: "config/prompts.example.yaml"
  schema_path: "config/review_schema.example.json"
  default_prompt_key: "unknown_prior_authorization"
  reload_on_change: false
  prompt_profile_map:
    glp1_prior_authorization: "glp1_prior_authorization"
    unknown_prior_authorization: "unknown_prior_authorization"
  task_prompt_map:
    image_text_extraction: "image_text_extraction"
    page_analysis: "page_analysis"
    page_classification: "page_classification"
    page_summary: "page_summary"
    component_summary: "component_summary"
    pa_form_extraction: "pa_form_extraction"
    crosswalk_evaluation: "crosswalk_evaluation"
    final_review: "glp1_prior_authorization"
```

Prompt YAML should define document-type prompts, task-scoped prompts, few-shot examples for page
classification when useful, classifier hints, required evidence, and prompt version. Schema files
should define the structured output contract expected from the LLM.

Phase 3 page-analysis prompts should be few-shot capable. In optimized mode, `page_analysis`
returns both classification and bounded summary fields in one model call. A prompt file may
represent those examples as structured metadata adjacent to the task prompt:

```yaml
tasks:
  page_analysis:
    output_schema: "page_analysis_v1"
    few_shots:
      - name: "prior_authorization_form"
        input_excerpt: "Prior Authorization Request Form. Patient information. Prescriber information. Drug requested."
        output:
          page_type: "prior_authorization_form"
          confidence: 0.92
          signals:
            - "contains prior authorization form title"
            - "contains patient and prescriber fields"
          summary: "Prior authorization form page with patient, prescriber, and requested drug fields."
          summary_confidence: 0.86
  page_classification:
    output_schema: "page_classification_v1"
    few_shots:
      - name: "prior_authorization_form"
        input_excerpt: "Prior Authorization Request Form. Patient information. Prescriber information. Drug requested."
        output:
          page_type: "prior_authorization_form"
          confidence: 0.92
          signals:
            - "contains prior authorization form title"
            - "contains patient and prescriber fields"
      - name: "physician_notes"
        input_excerpt: "Assessment and Plan. History of present illness. Current medications."
        output:
          page_type: "physician_notes"
          confidence: 0.88
          signals:
            - "contains clinical note sections"
            - "contains assessment and plan language"
    prompt: |
      Classify the selected packet page using the configured component labels.
      Return structured output with page type, confidence, and brief signals.
```

## Security Configuration

Security flags are configuration, but deployment approval and allowed values are governed by
`docs/project/security-governance/governance-security-spec.md`.

```yaml
security:
  redact_logs: true
  store_llm_raw_response: false
  store_llm_request_text: false
  require_output_encryption: false
  allow_public_llm_profiles: false
  allow_raw_llm_response_storage: false
```

`redact_logs` should remain true for PHI-bearing environments. Raw request text, raw responses,
public model routing, and encryption-disabled output require explicit deployment approval before
live PHI use. `config-check` rejects public task-profile routing and raw LLM response storage unless
the corresponding approval flag is explicitly enabled.

## Packet Decomposition Configuration

The PA form and physician notes are required. Fax cover sheets and other supporting documents are
optional. Page-count hints are heuristics only and must not be treated as hard page positions.

```yaml
packet_decomposition:
  required_components:
    - "prior_authorization_form"
    - "physician_notes"
  optional_components:
    - "fax_cover_sheet"
    - "lab_results"
    - "medication_history"
    - "prescription_record"
    - "insurance_or_member_info"
    - "other_supporting_document"
  pa_form_page_count_hint: [1, 2]
  require_form_to_evidence_crosswalk: true
```

## Packet Digest Configuration

The packet digest is the auditable page inventory used by decomposition, crosswalk, and review
steps. It should include every original page, including unknown or low-confidence pages.

```yaml
packet_digest:
  enabled: true
  digest_version: "1.0"
  write_json_artifact: true
  include_page_signals: true
  include_page_summaries: true
  include_component_summaries: true
  include_artifact_paths: true
  include_unknown_pages: true
  store_full_digest_in_sqlite: false
  artifact_layout: "document_id"
  page_summary_max_chars: 500
  page_analysis_mode: "combined"
  page_analysis_input_max_chars: 6000
  component_summary_max_chars: 1000
  summary_method: "llm"
  confidence_threshold_for_review_flag: 0.65
```

`artifact_layout` must remain `document_id` until a future PHI-safe layout is specified and
validated. Source filenames must not be used for generated artifact path prefixes.

`page_analysis_mode: "combined"` uses the `page_analysis` prompt to classify and summarize each
page in one LLM call. Use `"separate"` to restore the debug baseline that calls
`page_classification` and `page_summary` independently.

The full digest JSON should be the canonical nested representation. SQLite should store the digest
artifact path, digest version, page count, required component status, review flags, and any indexed
component rows needed for search/status views.

Page and component summaries are retrieval aids. They should help identify candidate components and
supporting evidence pages, but final evidence matches must still cite original packet page numbers
and source text or image context when available.

Recommended artifact layout:

```text
output/
  doc_<document_id>/
    packet_digest.json
    review.json
    summary.md
    pages/
      page_001.png
      page_001.raw.txt
      page_001.normalized.txt
      page_001.ocr.json
    components/
      prior_authorization_form.json
      physician_notes.json
```

## Configuration Validation

The CLI should reject invalid configuration early:

```bash
uv run benecard-pa --config config/app.example.yaml config-check
```

Validation should confirm that the default LiteLLM profile exists, every configured task profile
references a defined model profile, `parsing.min_text_chars_per_page` is greater than zero,
`parsing.low_ocr_confidence_threshold` is between `0.0` and `1.0`, image-to-text strategy values are
supported, the image-to-text LLM task is mapped, vision strategies select a vision-capable model
profile, prompt/schema paths are well-formed, lifecycle paths are configured, and mandatory packet
components are defined. Public task-profile routing and raw LLM response storage require explicit
approval flags.
