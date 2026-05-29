# Phase 6 Build Plan: LLM-Assisted Crosswalk Evaluation

**Status:** Draft for review

**Date:** 2026-05-24

**Phase:** 6

**Source authority:** `docs/project/prd/pa_document_intelligence_prd.md`, `docs/project/architecture/pa_document_intelligence_architecture.md`, `docs/project/security-governance/governance-security-spec.md`, `docs/project/configuration/config_yaml_reference.md`, `docs/project/testing/cli-uat-harness.md`, `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`, `docs/project/build-plan/phase-roadmap.md`, `docs/project/build-plan/phases/phase-5-digest-driven-analysis-orchestration.md`

**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/phase-build-planner.md`

## Executive Summary

Phase 6 turns the Phase 5 candidate evidence workspace into evaluated field-level evidence findings.
It introduces bounded LiteLLM `crosswalk_evaluation` execution, orchestrator-owned active-run tool use,
optional selected-page vision context, structured output validation, and system-owned crosswalk
assembly. The phase writes a full `evaluated_form_evidence_crosswalk.json`, a succinct
`evaluated_form_evidence_crosswalk_index.json`, and a human-readable
`evaluated_form_evidence_crosswalk.md` without producing final approval, denial, final review,
lifecycle, watcher, or production persistence behavior.

## Phase Objective

For every extracted PA form field/question, evaluate candidate evidence from physician notes and
configured supporting documents, then assign a controlled support status:

- `supported`
- `contradicted`
- `missing`
- `unclear`

Each supported or contradicted item must cite original page numbers and component types, include
confidence, carry evidence summaries, and include snippet/span references when safely available.
The system owns final artifact assembly and validation; the LLM provides advisory structured
findings only.

## In Scope

- Use `evidence_workspace.json`, `analysis_trace.json`, `packet_digest.json`,
  `packet_analysis_index.json`, `pa_form_extraction.json`, and the Phase 4 crosswalk as inputs.
- Add bounded LiteLLM `crosswalk_evaluation` calls with task-specific prompt/schema routing.
- Validate `crosswalk_evaluation` prompt and schema configuration during `config-check`.
- Add `evaluated_form_evidence_crosswalk.json` under the active run directory.
- Add `evaluated_form_evidence_crosswalk_index.json` with source/run header metadata, summary
  counts, artifact refs, and one compact item per form field containing field ID, field label, field
  value, support status, confidence, supporting pages, and review flags.
- Add `evaluated_form_evidence_crosswalk.md` as the human-readable Phase 6 review surface.
- Add `crosswalk_evaluation_trace.json` under the active run directory with LLM task metadata,
  evaluated pages, tool-use metadata, capability fallback, validation results, and reviewer-facing
  flags.
- Implement a controlled, orchestrator-owned tool adapter boundary over Phase 5 active-run
  retrieval helpers. Provider-native model tool-call loops are deferred.
- Enforce YAML limits for pages, images, tool calls, total analysis passes, retries, and wall-clock
  duration.
- Support optional selected-page image refs only when `analysis.context.include_page_images` is true
  and the `crosswalk_evaluation` profile supports vision and configured image capacity.
- Preserve file-only operation. SQLite indexing remains optional and deferred.
- Add the CLI UAT command `evaluate <source_path>` for Phase 6 artifact generation and reporting.

## Out of Scope

- Autonomous agent loops.
- Final approval or denial decisions.
- Payer-policy adjudication or medical necessity determination.
- Final review packaging for a complete reviewer-ready report.
- SQLite-required persistence or schema changes.
- Watcher, SFTP, lifecycle movement, reprocess/status commands, or daemon behavior.
- Prompt/model tuning for page classification based on the current limited sample set.
- Sending full packet text, full PDFs, or full packet image sets to the LLM by default.
- Arbitrary filesystem, shell, database, network, secret, or runtime configuration access by tools.

## Deferred Items

- Final review artifact assembly and `final_review` prompt execution move to Phase 7.
- SQLite indexing of evaluated crosswalk metadata remains Phase 7.
- Source lifecycle and operator status workflow remain Phase 8.
- Watcher and reconciliation loop remain Phase 9.
- Evaluation harness and golden expected outputs remain Phase 10, though Phase 6 should add focused
  fixtures and UAT checks.

## Dependencies

- Phase 5 `evidence_workspace.json` and `analysis_trace.json` are the orchestration inputs.
- Phase 4 `pa_form_extraction.json` supplies field identity, labels/questions, values, form pages,
  confidence, and evidence hints.
- `packet_analysis_index.json` supplies page/component lookup and text artifact references.
- `config/prompts.example.yaml` must define a structured `crosswalk_evaluation` schema before live
  LLM execution.
- `llm.task_profiles.crosswalk_evaluation` must resolve to a profile with structured outputs and
  optionally vision support when selected page images are configured.
- Provider-native LiteLLM tool calling is not required for Phase 6. The Phase 6 tool adapter is an
  internal orchestrator boundary used to assemble bounded context and audit tool-like operations.

## Assumptions

- The approved clinical reference samples under `docs/project/reference/clinical-samples/` remain
  non-PHI and valid for UAT.
- Phase 6 can use deterministic fake LLM clients in unit tests and local LM Studio or another
  configured profile for live CLI UAT.
- The evaluated crosswalk should be rebuildable from upstream artifacts and active YAML/prompt
  configuration.
- Existing `form_evidence_crosswalk.json` remains the Phase 4 initial artifact. Phase 6 must not
  mutate it or silently change its meaning.
- Existing Phase 5 `evidence_workspace.json` remains immutable candidate context. Phase 6 must not
  rewrite it or reinterpret it as evaluated evidence.

## Workstreams

### 1. Evaluated Crosswalk Schema and Artifact

Define a durable evaluated crosswalk artifact with controlled support status, confidence,
supporting pages, component types, evidence summary, source span refs, LLM task metadata, validation
flags, and derivation from Phase 5 workspace inputs.

### 2. Crosswalk Evaluation Prompt and Schema

Add a JSON schema for `crosswalk_evaluation` output and validate it through the prompt catalog.
The schema must reject unknown support statuses, missing citations for supported/contradicted items,
and malformed confidence fields.

### 3. Active-Run Tool Adapter

Wrap Phase 5 retrieval helpers behind an orchestrator-owned tool adapter that enforces active-run
scope, allowed tool names, call counts, result-size limits, and metadata-only audit. The evaluator
uses this adapter to assemble bounded context before calling LiteLLM. Do not expose raw helper
functions directly to the model, and do not implement provider-native model tool-call loops in Phase
6.

### 4. LLM Evaluation Orchestrator

Create a Phase 6 evaluator that builds bounded per-field context, calls `crosswalk_evaluation`,
validates output, merges findings into `evaluated_form_evidence_crosswalk.json`, writes the compact
crosswalk index and Markdown review artifact, records `crosswalk_evaluation_trace.json`, and falls
back or fails according to configuration.

### 5. Vision-Gated Evidence Context

Allow selected page images or crops only when YAML enables images and the selected task profile
supports vision with enough image capacity. Full PDFs and full packet images remain forbidden.

### 6. CLI UAT Surface

Use `evaluate <source_path>` to produce and report the evaluated crosswalk JSON, compact index JSON,
Markdown review artifact, evaluation trace artifact, LLM task profile, tool/vision fallback status,
item counts, and review flags without printing PHI-bearing field values or evidence snippets to the
console.

### 7. Tests and Documentation Close-Out

Add tests for schema validation, tool denial, cross-run denial, unsupported capability fallback,
context limits, evaluated statuses, citations, PHI-safe output, and artifact derivation. Update CLI
UAT, config reference, traceability, and any Phase 6 status docs only after behavior exists.

## Sequencing

1. Define evaluated crosswalk models and artifact paths.
2. Add prompt schema and config validation for `crosswalk_evaluation`.
3. Build the active-run tool adapter and negative tests.
4. Implement deterministic evaluator plumbing with fake LLM tests.
5. Add LiteLLM-backed `crosswalk_evaluation` execution and structured output validation.
6. Add CLI UAT reporting.
7. Run focused tests, full suite, lint, config-check, and live CLI UAT.
8. Update traceability and close-out docs.

## Migration and Removal

- Do not remove Phase 4 initial crosswalk behavior.
- Do not mutate Phase 5 `evidence_workspace.json` semantics into final evidence conclusions.
- Keep evaluated findings in the distinct Phase 6 `evaluated_form_evidence_crosswalk.json` artifact.
- Preserve run-relative artifact paths and active-run validation added in Phase 5.

## Security and Governance

- All LLM calls must route through LiteLLM.
- LLM request context and responses are PHI-bearing; do not log or print raw content by default.
- Tools must be scoped to the active document/run and configured allowed tool names.
- Phase 6 tools are orchestrator-owned context assembly operations, not provider-native model
  tool-call loops.
- Deny arbitrary filesystem, shell, network, database, secret, and config access.
- Capability checks must gate structured output, tool-use configuration, vision input, and image
  capacity before any LLM call.
- Unsupported capabilities must fail closed or produce a configured staged fallback with
  reviewer-facing flags.
- The system must not approve or deny prior authorization requests.

## Test Strategy

- Unit tests for evaluated crosswalk model serialization and validation.
- Prompt/schema tests for `crosswalk_evaluation`.
- Fake LLM tests for supported, contradicted, missing, unclear, low-confidence, and malformed output.
- Tool adapter negative tests for unsupported tool names, cross-run refs, excessive calls, and raw
  path access attempts.
- Vision gating tests for disabled images, unsupported profiles, and image-capacity overflow.
- CLI tests for PHI-safe output and expected artifact paths.
- Integration/UAT with approved non-PHI sample packets.

## CLI / UAT Strategy

Recommended command shape:

```bash
uv run benecard-pa --config config/app.example.yaml evaluate docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

Expected Phase 6 console fields should include status, source, output directory, upstream artifact
paths, evidence workspace path, analysis trace path, evaluated crosswalk path, evaluated item count,
crosswalk evaluation trace path, supported/contradicted/missing/unclear counts, LLM task profile,
execution mode, fallback reason, tool-use count, and review flags. Console output must not include
form values, snippets, prompts, raw page text, or raw model responses.

## Acceptance Criteria

- Every extracted PA form field has an evaluated crosswalk item.
- Support status uses only `supported`, `contradicted`, `missing`, or `unclear`.
- Supported and contradicted items cite original evidence pages and component types.
- Missing and unclear items are explicit and reviewer-visible.
- Evaluated findings validate against schema before artifact writing.
- Tool access is active-run scoped and deny-tested.
- Vision input is selected-page only and capability-gated.
- `crosswalk_evaluation_trace.json` records task profile, prompt key/version, selected pages, tool
  counts, fallback reason, validation results, and review flags without raw PHI.
- CLI UAT writes the evaluated crosswalk artifact and reports PHI-safe counts/paths.

## Documentation Close-Out

- Update `docs/project/testing/cli-uat-harness.md` with the final Phase 6 command and output shape.
- Update `docs/project/configuration/config_yaml_reference.md` if any actual config semantics change.
- Update `docs/project/traceability/pa_document_intelligence_traceability_matrix.md` with verified
  Phase 6 evidence after implementation.
- Record UAT findings that affect prompt/model interpretation.
- Do not mark final review or Phase 7 artifacts implemented in Phase 6.

## Risks

| Risk | Mitigation |
|---|---|
| LLM turns candidate context into unsupported conclusions | Schema validation, provenance checks, and system-owned assembly. |
| Tool use broadens into arbitrary access | Orchestrator-owned active-run tool adapter, allowed tool list, denied-tool tests, and no provider-native model tool-call loop in Phase 6. |
| Vision context leaks full packet images | Selected-page image gating and image-count tests. |
| Phase 6 becomes final adjudication | Explicit no approval/denial rule and policy-separation tests. |
| Local model output is inconsistent | Fake LLM unit tests plus live UAT flags; prompt tuning deferred until more samples exist. |

## Locked Decisions

- Phase 6 adds the CLI command `evaluate <source_path>`.
- Phase 6 writes `evaluated_form_evidence_crosswalk.json`; it does not mutate
  `form_evidence_crosswalk.json`.
- Phase 6 writes `evaluated_form_evidence_crosswalk_index.json` for compact machine scanning and
  `evaluated_form_evidence_crosswalk.md` for human review.
- Phase 6 writes `crosswalk_evaluation_trace.json`; it does not rewrite Phase 5
  `analysis_trace.json` or `evidence_workspace.json` semantics.
- Phase 6 uses an orchestrator-owned active-run tool adapter. Provider-native LiteLLM model
  tool-call loops are deferred.
- Phase 6 requires page/span references for evaluated evidence. Evidence snippets are optional,
  artifact-only, and must never appear in console output or default logs.
- `final_review` prompt execution and final review artifact assembly remain wholly Phase 7.

## Accuracy Pass

- Included: bounded LLM crosswalk evaluation, tool adapter, vision gates, evaluated artifact, CLI
  UAT, tests, and docs close-out.
- Deferred: final review package, persistence, lifecycle, watcher, SFTP, golden evaluation harness.
- Acceptance criteria cover schema, status values, citations, tools, vision, trace, and CLI output.
- Security/governance concerns are explicit and testable.
