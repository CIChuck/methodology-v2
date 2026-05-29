# Phase 3 Build Plan: Page Classification, Packet Decomposition, and Digest Summaries

**Status:** Approved for implementation

**Date:** 2026-05-22

**Phase:** 3

**Source authority:** `docs/project/prd/pa_document_intelligence_prd.md`, `docs/project/architecture/pa_document_intelligence_architecture.md`, `docs/project/security-governance/governance-security-spec.md`, `docs/project/configuration/config_yaml_reference.md`, `docs/project/testing/cli-uat-harness.md`, `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`, `docs/project/build-plan/phase-roadmap.md`, `docs/project/build-plan/phases/phase-2-5-digest-review-path.md`

**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/phase-build-planner.md`

## Executive Summary

Phase 3 turns the Phase 2.5 reviewable packet digest into a richer packet inventory. It introduces
a narrow LiteLLM-backed document-understanding slice for page classification, page summaries, and
component summaries. Each original page is classified through configurable task prompts, including
few-shot examples when configured, then grouped into logical packet components with required
component status, unknown-page retention, and bounded digest summaries.

This phase is still document inventory work. It does not extract PA form fields, evaluate whether
physician notes support PA form answers, build a crosswalk, perform autonomous analysis, call
general LLM tools, move source files, or persist SQLite rows. LiteLLM is used only through the
approved Phase 3 tasks: `page_classification`, `page_summary`, and `component_summary`. The output
remains an enriched `packet_digest.json` plus human-readable digest Markdown produced through the
CLI UAT harness.

## Phase Objective

Answer the reviewer-facing inventory questions that must be settled before form extraction and
evidence matching:

- What does each original packet page appear to contain?
- Which logical packet components are present?
- Are the required PA form and physician notes components present?
- Which optional supporting components are present?
- Which pages remain unknown or low confidence?
- What compact summaries help a reviewer navigate the packet without treating summaries as final
  evidence?
- Can the configured LiteLLM profile and prompt set classify and summarize pages through a bounded,
  auditable task interface?

## In Scope

- Extend the packet digest with page classification fields: likely page type, confidence, signals,
  and classification method.
- Support the configured component labels:
  `prior_authorization_form`, `physician_notes`, `fax_cover_sheet`, `lab_results`,
  `medication_history`, `prescription_record`, `insurance_or_member_info`,
  `other_supporting_document`, and `unknown`.
- Implement logical packet decomposition using original page numbers, without physically splitting
  the PDF.
- Treat `prior_authorization_form` and `physician_notes` as required components.
- Treat fax cover sheets, labs, medication history, prescription records, insurance/member pages,
  and other configured supporting documents as optional components.
- Mark missing required components through digest `required_component_status` and review flags.
- Retain blank, separator, low-confidence, and unknown pages in the digest.
- Add LiteLLM task-profile resolution for `page_classification`, `page_summary`, and
  `component_summary`.
- Load task-specific prompts from YAML, including few-shot examples for page classification.
- Request and validate structured output for page classification and summaries.
- Add bounded page summaries through the configured `page_summary` task when native or
  image-derived text is available and `packet_digest.include_page_summaries` is enabled.
- Add bounded component summaries through the configured `component_summary` task when components
  exist and `packet_digest.include_component_summaries` is enabled.
- Record summary method, summary confidence when available, and configured max-length metadata.
- Record model profile, prompt key/version, and task metadata needed for audit without logging raw
  prompts or full page text to console output.
- Preserve approved source document identity in JSON and Markdown for non-PHI UAT inputs.
- Extend the existing `digest <source_path>` CLI UAT path so Phase 3 acceptance is reviewable from
  the configured output directory.
- Add tests using synthetic fixtures and approved non-PHI clinical samples under
  `docs/project/reference/clinical-samples/`.

## Out of Scope

- PA form field, question, answer, or required-evidence extraction.
- Form-to-evidence crosswalk generation.
- Evidence support decisions such as `supported`, `contradicted`, `missing`, or `unclear`.
- Digest-driven LLM analysis orchestration, evidence workspace behavior, and tool-call loops.
- General-purpose LLM task routing for workflow tasks outside `page_classification`, `page_summary`,
  and `component_summary`.
- LLM tool calling, arbitrary tool registry behavior, and active-run retrieval tools.
- LLM vision extraction, hybrid image-to-text execution, or compare execution beyond the existing
  Phase 2 guardrails.
- Final review JSON, clinical recommendation text, or approval/denial language.
- SQLite indexing.
- Source lifecycle movement, watcher behavior, SFTP intake, queueing, or reprocess/status commands.

## Deferred Items

| Deferred Item | Target |
|---|---|
| PA form field extraction | Phase 4 |
| Form-to-evidence crosswalk | Phase 4 |
| Digest-driven retrieval and evidence workspace | Phase 5 |
| PA form extraction LLM task routing and prompts | Phase 4 or Phase 6, depending on the approved implementation plan |
| Crosswalk evaluation LLM task routing and prompts | Phase 4 or Phase 6, depending on the approved implementation plan |
| Evidence workspace, retrieval tools, and tool-call loops | Phase 5/6 |
| LLM vision-gated analysis and image-to-text vision execution | Phase 6 |
| Final review LLM task routing, structured review generation, and review validation | Phase 6 |
| Final durable review package and optional SQLite indexing | Phase 7 |
| Source lifecycle and operator process/reprocess/status commands | Phase 8 |
| Watcher and reconciliation loop | Phase 9 |

## Dependencies

- Phase 1 parser and canonical page model.
- Phase 2 image-to-text execution, page artifacts, selected text source metadata, and OCR status.
- Phase 2.5 digest review service, run-scoped artifact layout, and CLI `digest` command.
- `PacketDecompositionSettings` and `PacketDigestSettings` in YAML configuration.
- `llm.task_profiles` entries for `page_classification`, `page_summary`, and `component_summary`.
- Prompt YAML entries for Phase 3 classification and summary tasks.
- Approved non-PHI reference samples under `docs/project/reference/clinical-samples/`.
- Existing JSON and Markdown artifact writing behavior.
- Local model endpoint, LiteLLM proxy, or remote provider credentials configured through YAML and
  environment variables for UAT when live model calls are exercised.

## Assumptions

- Phase 3 page classification and summaries use LiteLLM as the primary path. Deterministic logic is
  limited to nonclinical mechanics such as blank/no-text page handling, schema validation failures,
  fail-closed configuration behavior, and unit-test doubles.
- Prompt design, few-shot examples, model profile selection, and fallback behavior are configuration
  concerns, not hard-coded classifier logic.
- Summaries are PHI-bearing derived data and are stored only in configured artifacts.
- Summaries are navigation aids only; future crosswalk evidence must cite original page numbers and
  source text or image context.
- The PA form is often one or two pages but must not be assumed to be the first page or first two
  pages.

## Workstreams

### 1. Page Classification

- Add a page classifier service that accepts selected page text, extraction metadata, original page
  number, configured component labels, and the configured `page_classification` prompt.
- Route classification through LiteLLM using the `page_classification` task profile.
- Support configurable few-shot examples in prompt YAML so the classifier can be tuned without code
  changes.
- Require structured output with page type, confidence, concise rationale/signals, and review flags.
- Use `unknown` when confidence is below threshold, structured output is invalid, the model refuses,
  or signals are materially conflicting.
- Use mocked LiteLLM responses for deterministic tests while retaining live-model UAT capability.

### 2. Packet Decomposition

- Add a decomposer that groups classified pages into logical `PacketComponent` records.
- Preserve original page numbers and page order.
- Record required/optional status, presence, confidence, evidence role, and member pages.
- Mark missing PA form or physician notes components through required-component status and review
  flags.

### 3. LiteLLM Task and Prompt Boundary

- Add the minimal LiteLLM client/task-router behavior needed for Phase 3 tasks.
- Resolve model profiles by task name, not a single global model.
- Validate that each Phase 3 task has a configured profile or a capability-compatible fallback.
- Load task prompts from YAML and record prompt key/version metadata.
- Enforce structured-output requirements for classification and summaries.
- Fail closed with PHI-safe errors when profiles, prompts, secrets, or structured responses are
  invalid.
- Do not expose tool calling, retrieval tools, vision images, or arbitrary provider behavior.

### 4. Digest Summaries

- Add page-summary and component-summary generation behind the digest builder/service boundary.
- Route page summaries through the configured `page_summary` task profile.
- Route component summaries through the configured `component_summary` task profile.
- Respect `packet_digest.page_summary_max_chars` and
  `packet_digest.component_summary_max_chars`.
- Record summary method and confidence when available.
- Keep summaries out of console output.
- Ensure summary failures do not drop pages or components.

### 5. CLI UAT Extension

- Extend `uv run benecard-pa --config config/app.example.yaml digest <source_path>` to write the
  enriched Phase 3 digest.
- Console output should remain metadata-only: source document name, status, output directory, digest
  paths, page count, component count, missing required components, review-flag names, and selected
  Phase 3 task profile names.
- The command must not print extracted text, summaries, patient identifiers, or source snippets.

### 6. Documentation and Traceability

- Update traceability rows for FR-054-FR-060, FR-066, FR-070-FR-084, and FR-102-FR-106 after
  implementation.
- Update traceability rows for FR-023-FR-031 and FR-032-FR-037/FR-125-FR-130 to show the Phase 3
  narrow LiteLLM slice and the remaining deferred Phase 6 scope.
- Update CLI UAT documentation if the command shape or expected artifacts change.
- Record any Phase 3 LiteLLM limitations and future Phase 6 expansion points clearly in the
  tactical plan.

## Sequencing

1. Verify the current Phase 2.5 baseline with `uv run pytest`, `ruff check .`, and a CLI digest UAT
   run.
2. Add failing tests for Phase 3 task-profile resolution, prompt loading, and structured-output
   validation.
3. Implement the minimal LiteLLM client/task-router path for `page_classification`, `page_summary`,
   and `component_summary`.
4. Add failing tests for page classification, unknown retention, and required component flags using
   mocked LiteLLM responses.
5. Implement page classification and digest enrichment.
6. Add failing tests for component grouping and missing required components.
7. Implement packet decomposition and required-component status.
8. Add failing tests for bounded page and component summaries using mocked LiteLLM responses.
9. Implement summary generation and Markdown/JSON rendering updates.
10. Add CLI UAT tests for enriched digest output, selected task profile metadata, and forbidden
    side effects.
11. Run verification commands and perform documentation close-out.

## Migration and Removal Requirements

- Do not remove the Phase 2.5 digest command; evolve it into the Phase 3 enriched digest path.
- Preserve existing run-scoped output paths and artifact identity behavior.
- Preserve source-filename-safe artifact directory prefixes.
- Preserve file-only operation; do not require SQLite.
- Preserve existing Phase 1/2 parser and image-to-text tests.
- Avoid schema churn that would make existing page inventory fields disappear; add fields
  compatibly where possible.
- Do not hard-code model names, prompt text, provider credentials, or few-shot examples in Python
  modules.

## Security and Governance Implications

- Page classifications, component labels, page summaries, and component summaries are derived PHI
  unless generated from approved non-PHI fixtures.
- Console output must remain metadata-only and must not include extracted page text, summaries,
  patient identifiers, prompt content, or LLM responses.
- Missing required components should create reviewer-facing flags, not triage routing or
  approval/denial recommendations.
- Phase 3 live LLM calls require LiteLLM routing, task-profile capability checks, prompt selection,
  PHI-safe logging, environment-variable secrets, and provider/local-model approval.
- Raw LLM request/response storage remains disabled by default unless explicitly approved in
  configuration.
- Tool calling, page-image vision input, arbitrary retrieval tools, and final review generation
  remain unauthorized in this phase.
- No lifecycle movement is allowed in this phase.

## Test Strategy

Required tests:

- Every original page receives exactly one classification record.
- Phase 3 LLM tasks resolve through `llm.task_profiles` or a capability-compatible fallback.
- Prompt YAML supports configurable classification instructions and few-shot examples without code
  changes.
- Invalid model profile, missing prompt, missing secret, or malformed structured output fails closed
  or marks the affected page/component as `unknown` with a reviewer-facing flag.
- Low-confidence or conflicting pages are retained as `unknown`.
- PA form pages are detected when they are not first in the packet.
- Fax cover sheets are optional and do not satisfy required PA form or physician notes status.
- Missing PA form creates a required-component review flag.
- Missing physician notes creates a required-component review flag.
- Optional labs, medication history, prescription records, and insurance/member pages can be
  grouped when signals are present.
- Component page ranges preserve original page numbers and order.
- Page summaries honor `page_summary_max_chars`.
- Component summaries honor `component_summary_max_chars`.
- Summary-disabled configuration omits summaries without failing classification/decomposition.
- Summary failures preserve the page/component inventory.
- CLI output includes source document identity for approved UAT inputs and artifact locations, but
  not extracted text, prompts, model responses, or summaries.
- Negative boundary tests prove no PA field extraction, crosswalk, SQLite write, lifecycle
  movement, watcher, SFTP, tool calling, image vision input, or final-review behavior is invoked.

Verification commands:

```bash
uv run benecard-pa --config config/app.example.yaml config-check
uv run pytest
ruff check .
```

Live-model UAT requires a configured local model, LiteLLM proxy, or approved remote provider profile
for the three Phase 3 tasks. Unit tests should use mocked LiteLLM responses and must not require
network access.

## CLI, API, and UAT Strategy

Primary CLI UAT command:

```bash
uv run benecard-pa --config config/app.example.yaml digest docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

Expected console shape:

```text
status: success
source: doc08294920260513101420.pdf
output_dir: data/output
digest_json: data/output/doc_<id>/runs/run_<id>/packet_digest.json
digest_markdown: data/output/doc_<id>/runs/run_<id>/packet_digest.md
pages: <n>
components: <n>
missing_required_components: <component-list-or-none>
review_flags: <flag-list-or-none>
llm_tasks: page_classification=<profile>, page_summary=<profile>, component_summary=<profile>
```

Expected artifacts:

- `packet_digest.json` containing page classification, components, required-component status,
  review flags, and bounded summaries when enabled.
- `packet_digest.md` containing a human-readable page/component inventory without raw extracted
  text.
- Existing page images, OCR metadata, raw text, and normalized text artifacts when enabled by
  configuration.

Forbidden side effects:

- No source file movement.
- No SQLite persistence.
- No watcher, queue, SFTP, or lifecycle behavior.
- No LLM task outside `page_classification`, `page_summary`, and `component_summary`.
- No tool calling or page-image vision input.
- No final review, crosswalk, or approval/denial output.

## Acceptance Criteria

| Area | Acceptance Criteria |
|---|---|
| Page Inventory | Every original page remains represented exactly once in JSON and Markdown. |
| Classification | Each page has a configured page type or `unknown`, confidence, method, and signals. |
| LiteLLM Routing | Classification and summary calls resolve task-specific profiles through LiteLLM configuration. |
| Prompt Configurability | Classification and summary prompts, including few-shot examples, are configurable outside code. |
| Unknown Retention | Unknown, blank, separator, and low-confidence pages are retained and flagged when configured. |
| Decomposition | Components group original page numbers logically without physical PDF splitting. |
| Required Components | Missing PA form or physician notes components create required-component status and review flags. |
| Optional Components | Optional supporting components are recorded when detected but are not required for digest success. |
| Summaries | Page and component summaries are bounded, configurable, and marked as navigation aids. |
| Source Identity | Approved non-PHI UAT artifacts identify the source document name for reviewer usability. |
| CLI UAT | The `digest` command writes enriched JSON/Markdown artifacts under the configured output directory. |
| Governance | Console output excludes extracted text, summaries, patient identifiers, snippets, prompts, and LLM responses. |
| Phase Boundary | Tests prove no PA field extraction, crosswalk, lifecycle, SQLite, watcher, SFTP, tool calling, image vision input, or final-review behavior is invoked. |

## Documentation Close-Out

**Status:** Implemented and verified.

**Verification evidence:**

- `ruff check .`
- `uv run pytest` (`118 passed`)
- `uv run benecard-pa --config config/app.example.yaml config-check`

**As-built notes:**

- Phase 3 implements exactly three executable LLM tasks:
  `page_classification`, `page_summary`, and `component_summary`.
- LiteLLM task calls use task-specific profiles, explicit prompt mappings, strict schema requests,
  and local schema validation before accepting model output.
- Page classification and summaries use configured bounded input windows; full packet text, page
  images, tools, crosswalk behavior, PA form extraction, and final review remain deferred.
- Digest components now include stable `component_id` values for future crosswalk/tool references.
- Summary generation honors `packet_digest.summary_method`, summary include flags, and unknown
  component handling configuration.

- The Phase 3 tactical implementation plan and AI construction directive are complete.
- Traceability matrix evidence has been updated for Phase 3 requirements.
- `docs/project/testing/cli-uat-harness.md` already defines the digest command shape extended by
  Phase 3.
- Remaining Phase 6 LiteLLM/tooling scope includes tool calling, selected-page vision input,
  final-review routing, crosswalk evaluation, and analysis orchestration.

## Risks

| Risk | Mitigation |
|---|---|
| Model classification is imperfect | Keep confidence, rationale/signals, unknown retention, and reviewer flags explicit. |
| Summaries are mistaken for evidence | Label summaries as navigation aids and exclude them from future final evidence rules. |
| PA form position is overfit to samples | Test PA form pages outside page 1-2 and use placement as a hint only. |
| Component grouping drops pages | Require every page to remain in the page inventory and belong to at most one primary component or remain unknown. |
| Phase leaks into crosswalk analysis | Add negative tests and keep form extraction/evidence matching out of the service boundary. |
| LiteLLM slice grows into Phase 6 scope | Limit Phase 3 to three named tasks and add negative tests for tools, vision inputs, final review, and crosswalk behavior. |
| Provider configuration blocks local development | Support mocked unit tests and a local/proxy profile path for UAT while keeping remote providers configurable. |

## Open Decisions

| Decision | Status |
|---|---|
| Which local/proxy/remote profile should be the default Phase 3 UAT profile? | Open for tactical implementation/configuration. |
| What few-shot examples should be included in the first page-classification prompt set? | Open for tactical implementation. |
| Should component summaries be generated only from member page summaries, or directly from normalized member page text under configured limits? | Open for tactical implementation. |
| Should Markdown include a component-first section before the page table? | Recommended, but final layout can be set in tactical planning. |
| Should low-confidence classification always raise a review flag, or only when below `packet_digest.confidence_threshold_for_review_flag`? | Recommended to use the configured threshold. |

## Accuracy Pass

- **Scope ambiguity:** LiteLLM classification and summaries are included only for
  `page_classification`, `page_summary`, and `component_summary`.
- **Deferred item control:** Field extraction, crosswalk, analysis orchestration, tool calling,
  image vision input, final review, SQLite, lifecycle, watcher, and SFTP are excluded.
- **Acceptance coverage:** Each included feature has acceptance criteria and tests.
- **Migration coverage:** Existing digest command and artifact layout are preserved.
- **Security coverage:** PHI-safe console output, prompt/model metadata limits, summary handling,
  source identity policy, and no lifecycle movement are called out.
- **Tactical readiness:** Workstreams and sequencing are specific enough to become a tactical
  implementation plan.
