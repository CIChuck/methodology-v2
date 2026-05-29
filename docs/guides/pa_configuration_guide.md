# PA Configuration Guide

**Status:** Draft  
**Source of truth:** `config/app.example.yaml`, `config/prompts.example.yaml`  
**Validation command:** `uv run benecard-pa --config config/app.example.yaml config-check`

## Purpose

This guide explains the prior authorization configuration options by category.
Use it when tuning the PA workflow for local UAT, production review output,
model routing, OCR behavior, packet digest generation, PA form extraction, and
crosswalk evaluation.

Do not place secrets or API keys in YAML. Reference secrets through environment
variable names such as `OPENAI_API_KEY`.

## Runtime Settings

| Setting | Example | Effect |
|---|---:|---|
| `app.environment` | `dev` | Identifies the runtime environment for logs and diagnostics. |
| `app.log_level` | `INFO` | Controls application logging verbosity. |
| `app.timezone` | `America/New_York` | Sets the timezone used for timestamps and lifecycle naming. |

## Path Settings

| Setting | Example | Effect |
|---|---:|---|
| `paths.dropbox_dir` | `data/dropbox` | Folder watched or used for inbound packets. |
| `paths.processed_dir` | `data/dropbox/processed` | Destination for successfully handled inbound files. |
| `paths.failed_dir` | `data/dropbox/failed` | Destination for files that fail processing. |
| `paths.output_dir` | `data/output` | Root folder for run artifacts and review deliverables. |
| `paths.archive_dir` | `data/archive` | Optional archive destination. |
| `paths.temp_dir` | `data/tmp` | Temporary working directory. |

Production output mode prunes intermediate run artifacts after final review
deliverables are written. UAT and debug modes retain more files for inspection.

## Watcher Settings

| Setting | Example | Effect |
|---|---:|---|
| `watcher.provider` | `watchfiles` | File watcher implementation. |
| `watcher.recursive` | `false` | Controls whether nested inbound folders are watched. |
| `watcher.ignored_subfolders` | `processed`, `failed` | Prevents lifecycle folders from being reprocessed. |
| `watcher.stability_wait_seconds` | `10` | Wait time before treating a file as stable. |
| `watcher.stability_checks` | `3` | Number of stability checks before processing. |
| `watcher.reconciliation_interval_seconds` | `300` | Interval for reconciling watched/dropbox state. |

## Database Settings

| Setting | Example | Effect |
|---|---:|---|
| `database.enabled` | `true` | Enables SQLite-backed tracking where implemented. |
| `database.sqlite_path` | `data/pa_pipeline.sqlite` | SQLite database location. |

For the MVP, JSON artifacts remain the primary review and integration contract.

## PDF Parsing and OCR Settings

| Setting | Example | Effect |
|---|---:|---|
| `parsing.min_text_chars_per_page` | `50` | Pages below this text count are treated as needing OCR/image text. |
| `parsing.render_dpi` | `300` | DPI used when rendering PDF pages to images. Higher DPI can improve OCR/vision clarity but increases runtime and payload size. |
| `parsing.ocr_engine` | `tesseract` | Baseline OCR engine. |
| `parsing.ocr_languages` | `["eng"]` | Tesseract language packs to use. |
| `parsing.low_ocr_confidence_threshold` | `0.50` | Confidence threshold for low-quality OCR flags. |
| `parsing.save_page_images` | `true` | Writes rendered page images for downstream review or vision tasks. |
| `parsing.save_raw_text` | `true` | Stores raw extracted/OCR text. |
| `parsing.save_normalized_text` | `true` | Stores normalized text used by retrieval and extraction. |

Tesseract is the default image-to-text path. Vision model extraction is
configured separately under `image_text_extraction` and LLM profiles.

## Image-to-Text Extraction

| Setting | Example | Effect |
|---|---:|---|
| `image_text_extraction.strategy` | `tesseract` | Selects `tesseract`, `llm_vision`, `hybrid`, or `compare`. |
| `image_text_extraction.default_engine` | `tesseract` | Baseline OCR engine for non-LLM extraction. |
| `image_text_extraction.llm_task` | `image_text_extraction` | LLM task used when image-to-text invokes a vision model. |
| `selected_text_rule` | `prefer_tesseract_unless_low_confidence` | Determines which text source becomes canonical when multiple outputs exist. |
| `use_llm_when.min_tesseract_confidence_below` | `0.70` | Invokes LLM vision in hybrid mode when OCR confidence is low. |
| `use_llm_when.min_text_chars_below` | `50` | Invokes LLM vision when OCR/native text is too sparse. |
| `use_llm_when.page_types` | `prior_authorization_form`, `lab_results` | Restricts hybrid escalation to high-value page types. |
| `compare_mode.enabled` | `false` | Runs comparison behavior when supported. |
| `compare_mode.store_comparison_artifact` | `true` | Preserves comparison metadata. |
| `compare_mode.flag_material_disagreement` | `true` | Adds flags when OCR and LLM text materially differ. |

Current UAT runs use Tesseract for packet image text. PA form vision extraction
is a separate Phase 4 feature and does not mean every packet page is sent to a
vision model.

## Packet Decomposition

| Setting | Example | Effect |
|---|---:|---|
| `required_components` | `prior_authorization_form`, `physician_notes` | Components that must be present for the packet to continue through later phases. |
| `optional_components` | `fax_cover_sheet`, `lab_results`, etc. | Recognized supporting document categories. |
| `pa_form_page_count_hint` | `[1, 2]` | Heuristic only; the PA form is detected by page analysis, not fixed page position. |
| `require_form_to_evidence_crosswalk` | `true` | Requires PA form fields to be connected to supporting packet evidence. |

Fax cover sheets may be present but are not mandatory. The PA form and physician
notes are mandatory packet components.

## Packet Digest

| Setting | Example | Effect |
|---|---:|---|
| `packet_digest.enabled` | `true` | Enables digest creation. |
| `digest_version` | `1.0` | Version marker for digest artifacts. |
| `write_json_artifact` | `true` | Writes `packet_digest.json` in non-pruned modes. |
| `include_page_signals` | `true` | Stores classification signals by page. |
| `include_page_summaries` | `true` | Stores bounded page summaries for review and retrieval. |
| `include_component_summaries` | `true` | Stores summaries for page groups/components. |
| `include_artifact_paths` | `true` | Includes links to text/image artifacts in digest outputs. |
| `include_unknown_pages` | `true` | Keeps unknown pages in the inventory. |
| `store_full_digest_in_sqlite` | `false` | Avoids duplicating full digest content in SQLite for MVP. |
| `artifact_layout` | `document_id` | Uses PHI-safer document-id folders instead of source filenames. |
| `page_analysis_mode` | `combined` | Uses one LLM call per page for classification plus summary. Use `separate` for independent classification and summary calls. |
| `page_analysis_input_max_chars` | `6000` | Bounds per-page text sent to the `page_analysis` prompt. |
| `page_summary_max_chars` | `500` | Bounds page summary length in artifacts. |
| `page_classification_input_max_chars` | `6000` | Bounds page text sent to the separate `page_classification` prompt. |
| `page_summary_input_max_chars` | `6000` | Bounds page text sent to the separate `page_summary` prompt. |
| `component_summary_max_chars` | `1000` | Bounds component summary length. |
| `component_summary_input_max_chars` | `8000` | Bounds text sent to component summary prompts. |
| `component_summary_max_pages` | `4` | Limits pages included in component summary calls. |
| `summarize_unknown_components` | `false` | Avoids spending LLM calls on unknown components. |
| `summary_method` | `llm` | Uses LLM-backed summaries. |
| `confidence_threshold_for_review_flag` | `0.65` | Adds review flags below this classification confidence. |

The digest is the packet inventory. It should identify each original page,
classify page type, preserve review flags, and provide enough page/component
context for later crosswalk evaluation.

## Analysis and Crosswalk Evaluation

| Setting | Example | Effect |
|---|---:|---|
| `analysis.mode` | `tool_assisted` | Selects analysis orchestration mode. Current Phase 6 uses app-owned tools, not provider-native tool loops. |
| `analysis.output_mode` | `production` | Controls artifact retention. `production` keeps only final review deliverables. |
| `use_packet_digest` | `true` | Uses the digest and analysis index as retrieval sources. |
| `send_full_packet_by_default` | `false` | Prevents sending the whole packet to the LLM by default. |

### Context Limits

| Setting | Example | Effect |
|---|---:|---|
| `context.max_pages_per_llm_call` | `4` | Bounds pages included in one evidence-evaluation context. |
| `context.max_tokens_per_llm_call` | `12000` | Token budget for evidence-evaluation prompts. |
| `context.max_candidate_pages_per_field` | `6` | Upper bound before optimization/ranking trims candidates. |
| `context.max_page_images_per_llm_call` | `2` | Image count limit if analysis image context is enabled. |
| `context.include_page_images` | `false` | Keeps crosswalk evaluation text-only unless explicitly enabled. |
| `context.include_page_text` | `true` | Includes page text in evidence context. |
| `context.include_component_summaries` | `true` | Includes component summaries to orient the model. |
| `context.summarize_intermediate_findings` | `true` | Allows bounded intermediate summaries. |

### Loop Limits

| Setting | Example | Effect |
|---|---:|---|
| `loop_limits.max_tool_calls_per_field` | `8` | Per-field active-run tool budget. |
| `loop_limits.max_total_tool_calls` | `200` | Total active-run tool budget. |
| `loop_limits.max_total_analysis_seconds` | `600` | Total analysis runtime budget. |
| `loop_limits.max_analysis_passes` | `3` | Max passes through analysis. |
| `loop_limits.max_retries_per_step` | `2` | Retry budget for individual steps. |

### Retrieval

| Setting | Example | Effect |
|---|---:|---|
| `retrieval.strategy` | `digest_keyword_search` | Candidate page selection strategy. |
| `restrict_evidence_search_to_components` | `physician_notes`, `lab_results`, `medication_history` | Limits evidence retrieval to supporting clinical/document components. |
| `allow_optional_components_as_support` | `true` | Allows optional components such as labs to support PA form values. |

### Tool Calling

| Setting | Example | Effect |
|---|---:|---|
| `tool_calling.enabled` | `true` | Enables app-owned context assembly tools. |
| `tool_calling.allowed_tools` | `get_packet_digest`, `get_page_text`, etc. | Defines the only document tools available to the analysis workflow. |
| `tool_calling.audit_tool_calls` | `true` | Records tool-use trace information in review/audit modes. |
| `tool_calling.fail_when_unsupported` | `false` | Allows deterministic/staged fallback when provider-native tool calling is unavailable. |

### Review Flags

| Setting | Example | Effect |
|---|---:|---|
| `review_flags.confidence_threshold` | `0.70` | Adds flags for low-confidence findings. |
| `review_flags.require_page_citations` | `true` | Requires evidence to cite packet pages. |
| `review_flags.flag_context_exhaustion` | `true` | Flags when limits prevent full context review. |
| `review_flags.flag_missing_required_components` | `true` | Flags packets missing mandatory components. |

## Analysis Optimization

| Setting | Example | Effect |
|---|---:|---|
| `optimization.enabled` | `true` | Enables Phase 6.5 optimization behavior. |
| `skip_blank_values` | `true` | Avoids LLM calls for blank/null form values while retaining them as skipped/unclear items. |
| `skip_administrative_fields` | `true` | Excludes administrative/contact fields from evidence evaluation. |
| `administrative_field_patterns` | `patient name`, `dob`, `fax number` | Field-label patterns treated as administrative noise. |
| `max_ranked_candidate_pages_per_field` | `2` | Trims candidate evidence pages after ranking. |
| `deterministic_matching_enabled` | `true` | Allows exact/structured matchers to finalize low-risk values without LLM calls. |
| `deterministic_matchers` | `diagnosis_code`, `medication`, etc. | Supported deterministic matcher families. |
| `deterministic_confidence` | `0.88` | Confidence assigned to deterministic matches. |
| `allow_deterministic_finalization_for_critical` | `true` | Allows exact, page-supported critical fields to skip LLM confirmation. |
| `batch_evaluation_enabled` | `false` | Reserved for future batching once model behavior is proven. |
| `max_fields_per_batch` | `3` | Future batch size bound. |
| `max_pages_per_batch` | `4` | Future batch page bound. |
| `critical_field_patterns` | `diagnosis`, `medication`, `criteria` | Patterns used to identify higher-priority clinical fields. |
| `standard_field_patterns` | `prescriber`, `quantity`, `height` | Patterns used to classify standard-priority fields. |

Production optimization should reduce avoidable crosswalk calls without hiding
skipped fields. Reviewer-facing artifacts should explain skipped fields and
plain-English review flags.

## PA Form Extraction

| Setting | Example | Effect |
|---|---:|---|
| `pa_form_extraction.mode` | `hybrid` | Runs OCR-text and vision extraction, then reconciles the candidates. Valid values: `text_only`, `vision_only`, `hybrid`. |
| `llm_task` | `pa_form_extraction` | Default task name when text/vision-specific task names are not configured. |
| `text_llm_task` | unset | Optional override for text extraction task. |
| `vision_llm_task` | unset | Optional override for vision extraction task. |
| `include_page_images` | `true` | Required for vision extraction paths. |
| `max_pages_per_request` | `2` | Caps PA form pages included in extraction. |
| `max_images_per_request` | `2` | Caps images sent to the vision model. |
| `compare_outputs` | `true` | Requires text and vision outputs to be compared in hybrid mode. |
| `require_reconciliation` | `true` | Requires candidate reconciliation before writing the extraction artifact. |
| `fallback_when_vision_unavailable` | `fail` | Fails closed when vision cannot run. Use `text_only` only for approved fallback behavior. |

Current hybrid mode makes one text extraction call and one vision extraction
call for the selected PA form pages. It does not make one vision call per page.

## LLM Routing

| Setting | Example | Effect |
|---|---:|---|
| `llm.provider` | `litellm` | Routes model calls through LiteLLM. |
| `llm.default_profile` | `clinical_reviewer_local` | Fallback profile when a task-specific profile is not configured. |
| `llm.task_profiles.*` | `page_analysis: fast_text_classifier` | Maps each workflow task to a named model profile. |
| `llm.profiles.*.model` | `openai/gpt-oss-20b-mlx` | LiteLLM model identifier. |
| `llm.profiles.*.base_url` | `http://127.0.0.1:1234/v1` | Local/proxy OpenAI-compatible endpoint. |
| `deployment_scope` | `local`, `private_proxy`, `public_api` | Governs security validation and routing policy. |
| `api_key_env` | `OPENAI_API_KEY` | Environment variable name for credentials. Empty is acceptable for approved local endpoints. |
| `temperature` | `0.0` | Keeps extraction/classification deterministic. |
| `max_tokens` | `4000` | Caps response length. |
| `timeout_seconds` | `240` | Per-call timeout. |
| `retries` | `2` | LiteLLM retry count. |
| `structured_outputs` | `true` | Requests provider-enforced structured output when supported. Local prompt-only JSON is allowed for selected local/private proxy Phase 3 tasks. |
| `supports_vision` | `true` | Required for vision/image tasks. |
| `supports_tool_calling` | `true` | Capability flag for future provider-native tool use. |
| `max_images_per_request` | `2` | Capability limit for image requests. |

Typical task routing:

| Task | Purpose | Model characteristics |
|---|---|---|
| `page_analysis` | Classify and summarize each page. | Fast text model, reliable JSON, 8k+ context. |
| `component_summary` | Summarize packet components. | Fast text model, reliable JSON. |
| `pa_form_extraction_text` | Extract form fields from OCR text. | Text model with strong structured output. |
| `pa_form_extraction_vision` | Extract form fields from PA form images. | Vision model with structured output. |
| `crosswalk_evaluation` | Judge support for form values from packet evidence. | Strong reasoning/instruction model, reliable JSON. |

## Prompt Routing

| Setting | Example | Effect |
|---|---:|---|
| `prompts.file_path` | `config/prompts.example.yaml` | Prompt catalog path. |
| `prompts.schema_path` | `config/review_schema.example.json` | Final review schema path. |
| `default_prompt_key` | `unknown_prior_authorization` | Fallback document-type prompt. |
| `reload_on_change` | `false` | Controls prompt reload behavior. |
| `prompt_profile_map` | `glp1_prior_authorization` | Maps known PA profiles to prompts. |
| `task_prompt_map` | `page_analysis: page_analysis` | Maps workflow tasks to prompt definitions. |

Prompt details, expected outputs, and task-by-task behavior are documented in
`docs/guides/prompting_guide.md`.

## File Lifecycle

| Setting | Example | Effect |
|---|---:|---|
| `move_successful_files` | `true` | Moves successfully processed files. |
| `move_failed_files` | `true` | Moves failed files. |
| `processed_naming` | `date_prefix` | Naming pattern for processed files. |
| `failed_naming` | `date_prefix` | Naming pattern for failed files. |
| `create_date_subfolders` | `true` | Organizes lifecycle folders by date. |
| `verify_hash_after_move` | `true` | Verifies moved file integrity. |
| `delete_original_after_verified_move` | `true` | Deletes source only after hash verification. |
| `collision_strategy` | `append_document_id` | Avoids overwriting lifecycle files. |

## Security and Governance

| Setting | Example | Effect |
|---|---:|---|
| `security.redact_logs` | `true` | Keeps logs PHI-safe. |
| `store_llm_raw_response` | `false` | Prevents raw model output storage unless approved. |
| `store_llm_request_text` | `false` | Prevents raw prompt/request text storage unless approved. |
| `require_output_encryption` | `false` | Deployment control for encrypted outputs. |
| `allow_public_llm_profiles` | `false` | Blocks public API model routing unless explicitly approved. |
| `allow_raw_llm_response_storage` | `false` | Approval gate for raw response persistence. |

Security-sensitive behavior is governed by
`docs/project/security-governance/governance-security-spec.md`. Public model
routing and raw LLM storage must remain disabled unless deployment approval
explicitly allows them.

## Output Modes

| Mode | Effect |
|---|---|
| `debug_full` | Retains full intermediate artifacts for developer debugging. |
| `uat_review` | Retains review artifacts plus detailed trace files for UAT. |
| `production` | Writes only `evaluated_form_evidence_crosswalk_index.json` and `evaluated_form_evidence_crosswalk.md` in the active run folder. |
| `audit_minimal` | Keeps final review deliverables plus a minimal trace. |

Use `production` for reviewer deliverable timing and artifact-clutter testing.
Use `uat_review` when investigating model behavior, prompt failures, or evidence
selection.

## Common Commands

Validate configuration:

```bash
uv run benecard-pa --config config/app.example.yaml config-check
```

Run a production-mode UAT evaluation when `analysis.output_mode` is already
`production`:

```bash
uv run benecard-pa --config config/app.example.yaml evaluate docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

Review the final production deliverables in the printed run directory:

```text
evaluated_form_evidence_crosswalk_index.json
evaluated_form_evidence_crosswalk.md
```
