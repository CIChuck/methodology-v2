# Phase 6 Tactical Implementation Plan: LLM-Assisted Crosswalk Evaluation

**Status:** Draft for review

**Date:** 2026-05-24

**Phase:** 6

**Source authority and precedence:** `docs/project/build-plan/phases/phase-6-llm-assisted-crosswalk-evaluation.md`, `docs/project/prd/pa_document_intelligence_prd.md`, `docs/project/architecture/pa_document_intelligence_architecture.md`, `docs/project/security-governance/governance-security-spec.md`, `docs/project/configuration/config_yaml_reference.md`, `docs/project/testing/cli-uat-harness.md`, `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`, `docs/project/build-plan/phase-roadmap.md`

**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/tactical-implementation-planner.md`

## Implementation Objective

Implement Phase 6 as a bounded LLM-assisted evidence evaluation layer. The phase consumes Phase 5
workspace artifacts, calls the configured LiteLLM `crosswalk_evaluation` task over selected
field/page context, validates structured output, and writes a system-owned evaluated crosswalk
artifact. It must preserve active-run scope, PHI-safe output, configurable limits, and the
distinction between candidate context and evaluated evidence.

## Assumptions

- Phase 5 artifacts are present or can be produced by the CLI before evaluation.
- `crosswalk_evaluation` is the only new live LLM task required for this phase.
- `final_review` execution and final review artifact assembly remain wholly deferred to Phase 7.
- Approved reference samples under `docs/project/reference/clinical-samples/` are valid non-PHI UAT
  inputs.
- The evaluated crosswalk artifact should be rebuildable from upstream artifacts, prompt config, and
  model config.
- Phase 5 `evidence_workspace.json` remains immutable candidate context. Phase 6 writes evaluated
  findings to new Phase 6 artifacts only.
- Phase 6 uses an orchestrator-owned active-run tool adapter to assemble bounded context before LLM
  calls. Provider-native LiteLLM model tool-call loops are deferred.

## Non-Goals

- Do not implement final approval, denial, or payer-policy adjudication.
- Do not implement final review packaging or durable output bundle behavior.
- Do not require SQLite or change the SQLite schema.
- Do not implement watcher, SFTP, source lifecycle movement, reprocess, or status commands.
- Do not expose arbitrary LLM tools or raw helper functions to the model.
- Do not send full packet text, full PDFs, or all page images to any model by default.

## File and Module Ownership Expectations

| Area | Expected Work |
|---|---|
| `src/benecard_pa/analysis/` | Add Phase 6 evaluator, tool adapter, context assembly extensions, evaluated crosswalk models, artifact writers, trace updates. |
| `src/benecard_pa/document/artifact_paths.py` | Add Phase 6 run-relative artifact paths for evaluated crosswalk JSON, Markdown, compact index JSON, and evaluation trace JSON. |
| `src/benecard_pa/llm/` | Extend task allowlist and metadata handling only as needed for `crosswalk_evaluation`; keep LiteLLM boundary intact. |
| `src/benecard_pa/llm/prompts.py` | Validate Phase 6 prompt/schema wiring if not already covered by existing helpers. |
| `src/benecard_pa/cli.py` | Add `evaluate <source_path>` as a CLI UAT command that delegates to Phase 6 service code. |
| `src/benecard_pa/settings.py` | Add only necessary config validation for Phase 6 capability gates. |
| `config/prompts.example.yaml` | Add `crosswalk_evaluation` output schema and refine task prompt if needed. |
| `config/app.example.yaml` | Add only real Phase 6 defaults, if existing config is insufficient. |
| `tests/` | Add focused unit, negative, and CLI tests for Phase 6 behavior. |
| `docs/project/` | Update CLI UAT, config reference, and traceability after implementation is verified. |

## Workstream 1: Evaluated Crosswalk Artifact

**Purpose:** Create the durable Phase 6 output without mutating Phase 4 or Phase 5 semantics.

**Implementation tasks:**

- Add `phase6_artifact_paths()` for `evaluated_form_evidence_crosswalk.json`.
- Add `phase6_artifact_paths()` entries for `evaluated_form_evidence_crosswalk.md` and
  `evaluated_form_evidence_crosswalk_index.json`.
- Add models for evaluated crosswalk artifact, evaluated item, evidence citation/span ref, LLM
  evaluation metadata, validation flags, and summary counts.
- Add a compact index artifact with source/run header metadata and one simple row per form field:
  field ID, field label, field value, support status, confidence, supporting pages, and review
  flags.
- Add a human-readable Markdown crosswalk with summary counts, artifact pointers, review flags, and
  a reviewer-oriented table.
- Include `source_sha256`, `processing_run_id`, `derived_from`, `mode`, `execution_mode`,
  `fallback_reason`, and artifact version.
- Preserve every extracted field, even when evaluation fails or evidence is missing.
- Keep values/snippets out of CLI output; JSON artifacts may contain PHI-bearing values when
  necessary for reviewer evidence review.

**Affected areas:** `src/benecard_pa/analysis/`, `src/benecard_pa/document/artifact_paths.py`.

**Required tests:** serialization, artifact path safety, one item per field, supported/contradicted
metadata, missing/unclear outcomes, run-relative `derived_from`.

**Acceptance criteria:** A valid Phase 6 run writes a schema-stable evaluated crosswalk artifact in
the active run directory.

## Workstream 2: Prompt and Schema Wiring

**Purpose:** Ensure `crosswalk_evaluation` has a strict structured output contract.

**Implementation tasks:**

- Add `crosswalk_evaluation_v1` schema to `config/prompts.example.yaml`.
- Require controlled `support_status` values.
- Require citations for `supported` and `contradicted` results.
- Allow explicit `missing` and `unclear` items with review flags and rationale.
- Add prompt-catalog validation for Phase 6 tasks.
- Extend `config-check` to validate Phase 6 prompt/schema wiring.

**Affected areas:** `config/prompts.example.yaml`, `src/benecard_pa/llm/prompts.py`,
`src/benecard_pa/cli.py`.

**Required tests:** prompt schema exists, invalid schema fails config-check, unknown support status
is rejected, missing citations are rejected.

**Acceptance criteria:** Misconfigured Phase 6 prompt/schema cannot pass config-check.

## Workstream 3: Active-Run Tool Adapter

**Purpose:** Create a safe boundary between Phase 6 context assembly and Phase 5 retrieval helpers.

**Implementation tasks:**

- Add an active-run tool adapter object that owns `ActiveRunContext`, allowed tools, tool counts,
  result-size limits, audit records, and PHI-safe error handling.
- Expose only configured document-analysis operations:
  `get_packet_digest`, `list_component_pages`, `get_page_text`, `get_page_image`,
  `search_packet_text`, `get_component_text`, `record_evidence_match`.
- Reject unknown tools, cross-run refs, absolute paths, traversal, excessive calls, and disabled
  tools.
- Return bounded text or references according to context limits; do not return arbitrary files.
- Record metadata-only tool-call audit entries.
- Use the adapter inside the orchestrator before the LLM call; do not expose the adapter as a
  provider-native LiteLLM model tool-call loop in Phase 6.
- `record_evidence_match` may record only Phase 6 evaluated artifact or
  `crosswalk_evaluation_trace.json` data; it must not mutate Phase 5 `evidence_workspace.json`.

**Affected areas:** `src/benecard_pa/analysis/tools.py`, new analysis adapter module, tests.

**Required tests:** denied tool names, denied path traversal, denied cross-run access, call-count
limit, result truncation, metadata-only audit.

**Acceptance criteria:** Tool-like context assembly cannot escape the active run, cannot exceed
configured limits, and cannot mutate Phase 5 workspace semantics.

## Workstream 4: LLM Crosswalk Evaluator

**Purpose:** Convert candidate context into evaluated evidence findings through LiteLLM.

**Implementation tasks:**

- Add a `Phase6Evaluator` or equivalent service.
- Read Phase 5 workspace and upstream artifacts through active-run validated refs.
- For each field, assemble bounded context from selected candidate pages, summaries, component
  types, field label/question/value, and Phase 4 hints.
- Call `LlmTaskClient.complete_structured()` with task name `crosswalk_evaluation`.
- Validate response schema and system-owned rules after LLM output returns.
- Convert malformed/unsupported outputs into `unclear` or failed evaluation flags according to
  severity.
- Merge findings into the evaluated crosswalk artifact.
- Write the compact crosswalk index JSON and human-readable Markdown crosswalk.
- Write `crosswalk_evaluation_trace.json` with metadata-only evaluation trace details.

**Affected areas:** `src/benecard_pa/analysis/`, `src/benecard_pa/llm/`, tests.

**Required tests:** fake LLM supported/contradicted/missing/unclear, malformed response rejection,
low-confidence flag, page citation enforcement, no approval/denial text.

**Acceptance criteria:** Every field receives an evaluated result or explicit evaluation failure item.

## Workstream 5: Capability and Vision Gates

**Purpose:** Enforce structured output and selected-page vision rules before LLM calls.

**Implementation tasks:**

- Verify `crosswalk_evaluation` profile supports structured outputs.
- Do not require provider-native tool support for the Phase 6 orchestrator-owned adapter.
- If YAML requests provider-native model tool-call interaction, fail closed or emit a configured
  deferred/fallback flag because provider-native tool loops are outside Phase 6.
- If selected image context is enabled, require profile vision support and sufficient image capacity.
- Enforce `max_page_images_per_llm_call`.
- Add reviewer-facing flags for disabled, unsupported, omitted, or deferred tool/vision behavior.

**Affected areas:** `src/benecard_pa/settings.py`, `src/benecard_pa/analysis/`, tests.

**Required tests:** unsupported structured output, provider-native tool-loop request is deferred or
fails closed, unsupported vision, image-capacity overflow, fallback behavior.

**Acceptance criteria:** No LLM call is made when selected profile lacks required capabilities unless
the configured fallback path is executed and flagged.

## Workstream 6: Crosswalk Evaluation Trace

**Purpose:** Make Phase 6 behavior auditable without logging PHI.

**Implementation tasks:**

- Add `crosswalk_evaluation_trace.json` with evaluated field counts, LLM task profile metadata,
  prompt key/version, pages evaluated, tool-use counts, fallback reason, schema validation status,
  and review flags.
- Keep raw prompts, raw context, raw page text, and raw LLM responses out of trace by default.
- Preserve Phase 5 `analysis_trace.json` fields and semantics.

**Affected areas:** `src/benecard_pa/analysis/`, tests.

**Required tests:** trace metadata completeness, PHI-safe trace, validation failure trace, timeout
flag.

**Acceptance criteria:** A reviewer can tell what was evaluated and why analysis was incomplete
without seeing raw PHI in logs/console.

## Workstream 7: CLI UAT Surface

**Purpose:** Provide a phase-exit operator test path.

**Implementation tasks:**

- Add `evaluate <source_path>` as the Phase 6 CLI UAT command.
- Ensure command delegates to services and contains no business logic.
- Report artifact paths, item counts, status counts, selected LLM task profile, fallback reason,
  tool-use count, and review flags.
- Do not print field values, evidence snippets, prompts, raw page text, or raw model responses.

**Affected areas:** `src/benecard_pa/cli.py`, `docs/project/testing/cli-uat-harness.md`, tests.

**Required tests:** CLI success, CLI failure, PHI-safe console, artifact path reporting, fake LLM
integration.

**Acceptance criteria:** CLI UAT proves Phase 6 artifacts end to end against approved non-PHI input.

## Data and Schema Changes

- Add `evaluated_form_evidence_crosswalk.json`.
- Add `evaluated_form_evidence_crosswalk.md`.
- Add `evaluated_form_evidence_crosswalk_index.json`.
- Add `crosswalk_evaluation_v1` schema in prompt config.
- Add `crosswalk_evaluation_trace.json`.
- No SQLite schema change in Phase 6.

## API / CLI / Config Changes

- CLI: add `evaluate <source_path>` for Phase 6 UAT.
- Config: use existing `analysis`, `tool_calling`, `llm.task_profiles.crosswalk_evaluation`, and
  prompt mappings unless implementation discovers a real missing setting.
- Prompt config: add/validate `crosswalk_evaluation` schema.
- LLM task allowlist: ensure `crosswalk_evaluation` is supported; do not add `final_review` live
  execution in Phase 6.
- Provider-native LiteLLM tool-call loops remain deferred; do not add them in Phase 6.

## Migration Order

1. Add models/path/schema without changing CLI behavior.
2. Add prompt/config validation.
3. Add tool adapter and negative tests.
4. Add evaluator with fake LLM tests.
5. Wire CLI UAT command.
6. Run verification and live UAT.
7. Update documentation/traceability.

## Security and Governance Work

- Enforce active-run tool scope.
- Enforce no arbitrary filesystem/shell/network/database/secret/config access.
- Enforce no full-packet LLM context by default.
- Enforce PHI-safe logs and console output.
- Enforce model capability gates before LLM calls.
- Add negative tests for denied tool access, unsupported capabilities, and deferred
  provider-native tool-loop requests.
- Add policy separation tests proving no approval/denial language.

## Negative Tests

- Unknown tool name is rejected.
- Absolute/traversal artifact refs are rejected.
- Tool request for a page outside active run is rejected.
- Tool-call count limit is enforced.
- Vision enabled with non-vision profile fails/falls back.
- Image count over profile capacity fails/falls back.
- LLM output with unknown support status is rejected.
- Supported/contradicted output without page citation is rejected.
- Raw prompt/response storage remains disabled by default.
- CLI output does not print field values or snippets.

## Verification Commands

```bash
uv run benecard-pa --config config/app.example.yaml config-check
uv run pytest tests/test_analysis_phase6.py tests/test_cli.py tests/test_settings.py tests/test_prompts.py -q
uv run pytest -q
ruff check .
git diff --check
uv run benecard-pa --config config/app.example.yaml evaluate docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

## Acceptance Criteria

- Evaluated crosswalk artifact is written under the active run directory.
- Human-readable evaluated crosswalk Markdown is written under the active run directory.
- Compact evaluated crosswalk index JSON is written under the active run directory.
- Crosswalk evaluation trace artifact is written under the active run directory.
- Every extracted field has exactly one evaluated item.
- Controlled support statuses are enforced.
- Supported/contradicted items include citations.
- Missing/unclear items remain visible and reviewer-facing.
- Orchestrator-owned tool adapter denies unsafe access and audits metadata.
- Vision context is selected-page only and capability-gated.
- `crosswalk_evaluation_trace.json` records metadata needed to audit Phase 6 behavior.
- CLI UAT succeeds and prints only PHI-safe output.
- Full tests, lint, config-check, and git diff check pass.

## Documentation Close-Out

- Update Phase 6 build plan status after implementation.
- Update this tactical plan status after verification.
- Update `docs/project/testing/cli-uat-harness.md` with final command shape.
- Update `docs/project/configuration/config_yaml_reference.md` for real config semantics.
- Update traceability matrix with implementation/test/UAT evidence.
- Log UAT findings and known limitations.

## Deferred Items

- Final review package and human-readable final reviewer summary.
- Provider-native LiteLLM model tool-call loop.
- SQLite indexing of evaluated crosswalk.
- Persistence/audit bundle beyond file artifacts.
- Lifecycle/watcher/reprocess/status behavior.
- Golden corpus evaluation metrics.

## Risks

- Local LLM output may be inconsistent; use schema validation and explicit review flags.
- Tool adapter may drift into raw helper exposure; isolate adapter from internal helpers.
- Provider-native tool calling could be introduced accidentally; keep Phase 6 adapter
  orchestrator-owned and deny model-directed arbitrary tool access.
- Evaluated snippets may become PHI leakage in console or logs; keep snippets artifact-only.
- Phase 6 could overrun into final review; keep final review explicitly deferred.

## Accuracy Pass

- Every build-plan workstream is represented.
- File ownership is explicit.
- Tests include positive, negative, CLI, and governance cases.
- Migration and documentation close-out are first-class.
- Deferred final review, persistence, lifecycle, and watcher behavior remain outside Phase 6.
