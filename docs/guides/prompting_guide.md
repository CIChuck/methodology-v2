# Prompting Guide

This guide describes the prompts currently configured for the PA Document Intelligence application,
where they live, how they are routed through LiteLLM, and what each prompt is expected to return.

## Configuration Sources

- Prompt text and inline schemas: `config/prompts.example.yaml`
- Final-review schema scaffold: `config/review_schema.example.json`
- Prompt file location and task mapping: `config/app.example.yaml` under `prompts`
- LLM profile routing: `config/app.example.yaml` under `llm.task_profiles`
- Prompt loader: `src/benecard_pa/llm/prompts.py`
- LiteLLM client: `src/benecard_pa/llm/client.py`

The active prompt catalog loads `version`, `schemas`, and `tasks` from
`config/prompts.example.yaml`. It also loads external schemas from
`config/review_schema.example.json`, then overlays inline schemas from the prompt YAML.

## Routing Model

Application code calls `PromptCatalog.task_for(task_name)`. The catalog first checks
`prompts.task_prompt_map`; if a task is mapped, it loads the mapped prompt key. Otherwise it uses the
task name directly.

The task prompt is sent as the system message. Runtime data is serialized as the user message.
`LiteLlmClient.complete_structured()` routes the request through LiteLLM using the LLM profile
selected by `llm.task_profiles[task_name]`.

When a prompt defines `output_schema`, LiteLLM receives a JSON schema response format and the
returned object is validated locally. If no schema is configured, the client requests a JSON object
but does not enforce a task-specific schema.

## Active Task Prompts

| Task name | Prompt key | Schema | Current status |
|---|---|---|---|
| `image_text_extraction` | `image_text_extraction` | none | Configured, but non-Tesseract image text strategies are deferred in current code. |
| `page_analysis` | `page_analysis` | `page_analysis_v1` | Active when `packet_digest.page_analysis_mode: combined`; classifies and summarizes each page in one call. |
| `page_classification` | `page_classification` | `page_classification_v1` | Active only when `packet_digest.page_analysis_mode: separate`. |
| `page_summary` | `page_summary` | `page_summary_v1` | Active only when `packet_digest.page_analysis_mode: separate`, page summaries are enabled, and `summary_method: llm`. |
| `component_summary` | `component_summary` | `component_summary_v1` | Active when component summaries are enabled and `summary_method: llm`. |
| `pa_form_extraction` | `pa_form_extraction` | `pa_form_extraction_v1` | Active in PA form extraction. |
| `pa_form_extraction_text` | usually `pa_form_extraction` | `pa_form_extraction_v1` | Routed by `pa_form_extraction.text_llm_task` or default extraction task. |
| `pa_form_extraction_vision` | usually `pa_form_extraction` | `pa_form_extraction_v1` | Routed by `pa_form_extraction.vision_llm_task` or default extraction task. |
| `crosswalk_evaluation` | `crosswalk_evaluation` | `crosswalk_evaluation_v1` | Active in Phase 6 evidence evaluation. |

## Prompt Details

### `image_text_extraction`

Purpose: Extract readable text from selected page images or crops.

Processing: The prompt is configured for future `llm_vision`, `hybrid`, or `compare` image-text
strategies. Current `ImageTextRouter` executes Tesseract when `strategy: tesseract`; other image
text strategies are deferred and do not call this prompt yet.

Expected output: Structured JSON containing extracted text, confidence, unreadable regions, and
page-reference metadata. No schema is currently enforced.

### `page_analysis`

Purpose: Classify each packet page and create a bounded, navigation-oriented page summary in a
single LLM call.

Processing: `PageAnalyzer` sends bounded normalized page text, allowed component labels, page
number, extraction metadata, and summary limits. The structured response is mapped back into the
existing `PageClassification` and `PageSummary` artifact fields so downstream phases keep the same
artifact contracts.

Expected output:

```json
{
  "page_type": "physician_notes",
  "confidence": 0.88,
  "signals": ["contains assessment and plan language"],
  "summary": "Clinical note documents current therapy and diagnosis.",
  "summary_confidence": 0.82,
  "review_flags": []
}
```

### `page_classification`

Purpose: Classify each packet page into a configured component type, such as
`prior_authorization_form`, `physician_notes`, `lab_results`, or `unknown`.

Processing: Used only in separate/debug mode. `PageClassifier` sends bounded normalized page text,
allowed component labels, page number, and input limits. Few-shot examples in the prompt are
appended to the system prompt. Unsupported or low-confidence page types are converted to `unknown`.

Expected output:

```json
{
  "page_type": "physician_notes",
  "confidence": 0.88,
  "signals": ["contains assessment and plan language"],
  "review_flags": []
}
```

### `page_summary`

Purpose: Create a bounded, navigation-oriented summary for each page in the packet digest.

Processing: Used only in separate/debug mode. `DigestSummarizer.summarize_page()` sends page
number, bounded page text, maximum input characters, and maximum summary characters. The result is
stored in `packet_digest.json`, `packet_digest.md`, and `packet_analysis_index.json`.

Expected output:

```json
{
  "summary": "Clinical note documents current therapy and diagnosis.",
  "confidence": 0.82,
  "review_flags": []
}
```

### `component_summary`

Purpose: Summarize a packet component assembled from one or more pages.

Processing: `DigestSummarizer.summarize_component()` sends component type, member pages, page
summaries, bounded page text, and configured page/input limits. Unknown components are skipped
unless `packet_digest.summarize_unknown_components` is true.

Expected output:

```json
{
  "summary": "Physician notes describe diagnosis, medication history, and current plan.",
  "confidence": 0.84,
  "review_flags": []
}
```

### `pa_form_extraction`

Purpose: Extract field labels, questions, values, source pages, answer types, and evidence hints
from the PA form pages.

Processing: `PaFormExtractor` can call this prompt over OCR text, page images, or both, depending
on `pa_form_extraction.mode`. In hybrid mode the text and vision candidates are reconciled into
`pa_form_extraction.json` and summarized into `form_extraction_index.json`.

Expected output:

```json
{
  "fields": [
    {
      "field_id": "requested_medication",
      "label": "Medication Requested",
      "question": "What medication is being requested?",
      "value": "TREMFYA",
      "source_page": 1,
      "answer_type": "text",
      "confidence": 0.9,
      "required_evidence_hint": "Medication should be supported by clinical notes.",
      "review_flags": []
    }
  ]
}
```

For visible blank fields, return an empty string for `value`. Do not return `null` for optional
strings; omit optional string fields when not visible.

### `crosswalk_evaluation`

Purpose: Evaluate one extracted PA form field against selected candidate evidence pages.

Processing: `Phase6Workflow` builds a field-specific context payload from the evidence workspace and
active-run page text. Configured administrative/contact/routing fields are excluded before
crosswalk evaluation. Blank form values may be skipped before the LLM call. Deterministic exact
matches may finalize selected low-risk fields. Remaining fields call this prompt once per field.

Expected output:

```json
{
  "support_status": "supported",
  "confidence": 0.86,
  "evidence_summary": "The medication is documented in the physician note.",
  "citations": [
    {
      "page_number": 7,
      "component_type": "physician_notes",
      "evidence_summary": "Clinical note lists the requested medication."
    }
  ],
  "review_flags": []
}
```

Allowed `support_status` values are `supported`, `contradicted`, `missing`, and `unclear`. Supported
or contradicted outputs must include citations to selected candidate pages. The prompt must not
approve or deny a PA request.

## Document-Type Prompts

`config/prompts.example.yaml` also includes `document_types` entries:

- `glp1_prior_authorization`
- `unknown_prior_authorization`

These contain higher-level review prompt text and required-evidence descriptions. They are useful
reference material for future final-review work, but the active `PromptCatalog` currently loads
`tasks`, not `document_types`. The `final_review` mapping in `config/app.example.yaml` is therefore
scaffolding and is not part of the current Phase 3-6 `complete_structured()` task set.

## Prompt Governance Rules

- Keep prompts task-scoped. `page_analysis` may combine page classification and bounded page
  summary because both are page-inventory tasks. Do not merge form extraction, evidence evaluation,
  or final review into that prompt.
- Return structured JSON only for active tasks.
- Do not ask the model to approve, deny, adjudicate, or recommend a coverage decision.
- Keep page citations tied to original packet page numbers.
- Keep prompt limits configurable through YAML settings rather than hard-coded prompt text.
- Treat summaries as navigation aids, not final evidence.
- Keep prompt changes paired with schema, test, and UAT updates.

## Updating or Adding a Prompt

1. Add or edit the prompt under `tasks` in `config/prompts.example.yaml`.
2. Add or update an inline schema under `schemas` when structured output is required.
3. Map the task in `config/app.example.yaml` under `prompts.task_prompt_map`.
4. Route the task to a model profile under `llm.task_profiles`.
5. Confirm the selected LLM profile supports required capabilities, especially structured outputs
   and vision.
6. Add or update tests that validate prompt loading and expected output handling.
7. Run `uv run benecard-pa --config config/app.example.yaml config-check`.
8. Run CLI UAT for the affected phase and inspect the generated artifacts.

## Current Caveats

- `image_text_extraction` is configured but not active while image-to-text strategies other than
  Tesseract remain deferred.
- `final_review` is configured as a future mapping but is not active in the current supported LLM
  task list.
- Production-mode `evaluate` output is intentionally pruned to
  `evaluated_form_evidence_crosswalk_index.json` and `evaluated_form_evidence_crosswalk.md`.
