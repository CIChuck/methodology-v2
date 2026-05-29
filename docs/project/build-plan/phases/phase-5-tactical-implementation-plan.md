# Phase 5 Tactical Implementation Plan: Digest-Driven Analysis Orchestration

**Status:** Approved

**Date:** 2026-05-23

**Phase:** 5

**Source authority:** `docs/project/build-plan/phases/phase-5-digest-driven-analysis-orchestration.md`, `docs/project/prd/pa_document_intelligence_prd.md`, `docs/project/architecture/pa_document_intelligence_architecture.md`, `docs/project/security-governance/governance-security-spec.md`, `docs/project/configuration/config_yaml_reference.md`, `docs/project/testing/cli-uat-harness.md`, `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`, `docs/project/build-plan/phase-roadmap.md`

**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/tactical-implementation-planner.md`

## Implementation Objective

Implement Phase 5 as a bounded analysis orchestration layer that turns existing run artifacts into
a durable evidence workspace and analysis trace. The workflow must use `packet_digest.json`,
`packet_analysis_index.json`, `pa_form_extraction.json`, and `form_evidence_crosswalk.json` as
inputs, select candidate evidence from configured supporting components, batch context under YAML
limits, and write `evidence_workspace.json` plus `analysis_trace.json`.

For the MVP, the analysis workspace is strictly file-artifact based. `evidence_workspace.json` is
the Phase 5 workspace source of truth. SQLite indexing is deferred and, when later added, must be
non-authoritative.

Phase 5 must not produce final clinical review, payer-policy interpretation, approval/denial
language, lifecycle movement, watcher behavior, SFTP behavior, or broad autonomous tool loops.

## Source Authority Precedence

1. Governance/security specification for PHI handling, tool boundaries, LLM capability gates, raw
   request/response storage, and provider routing.
2. Phase 5 build plan for included/deferred scope.
3. Architecture for artifact ownership, digest-driven retrieval, orchestrator responsibility, and
   evidence workspace boundaries.
4. PRD for functional requirements and acceptance criteria.
5. Configuration reference for YAML behavior.
6. CLI UAT harness for phase-exit operator evidence.
7. Traceability matrix and phase roadmap for phase placement.

If implementation pressure conflicts with this plan, defer the feature rather than expanding Phase
5 scope.

## Assumptions

- Phase 3.5 and Phase 4 artifacts exist or can be created by the Phase 5 CLI command.
- `packet_analysis_index.json` is the primary retrieval helper for page/component lookup.
- `pa_form_extraction.json` is the authoritative form-field input.
- `form_evidence_crosswalk.json` is the current initial crosswalk input, not a final evidence
  determination.
- `analysis.mode` defaults may be `tool_assisted`, but Phase 5 implementation may fall back to
  deterministic staged analysis when tool calling is unsupported and YAML allows fallback.
- Approved non-PHI clinical samples may be used for CLI UAT and integration tests.
- Tests must mock LLM behavior and should not require LM Studio, remote APIs, network access, or
  secrets.

## Non-Goals

- Do not generate final review artifacts or reviewer-ready clinical narratives.
- Do not approve, deny, triage, or apply payer policy.
- Do not tune Phase 3 page classification prompts based on current sample limitations.
- Do not implement broad Phase 6 LiteLLM tool-calling execution or final review routing.
- Do not require SQLite persistence.
- Do not move, delete, archive, or otherwise mutate source documents.
- Do not implement watcher, SFTP, queueing, lifecycle, reprocess, or status workflows.
- Do not send full packet text, full PDFs, or all page images to an LLM by default.

## File and Module Ownership

| Area | Ownership expectation |
|---|---|
| `src/benecard_pa/analysis/` | New Phase 5 package for workspace models, artifact loading, retrieval, batching, trace building, and workflow orchestration. |
| `src/benecard_pa/document/artifact_paths.py` | Add deterministic run-relative paths for `evidence_workspace.json` and `analysis_trace.json`. |
| `src/benecard_pa/settings.py` | Validate Phase 5 analysis mode, context limits, retrieval options, and tool-calling fallback rules if not already enforced. |
| `src/benecard_pa/cli.py` | Add bounded `analyze <source_path>` CLI UAT command that delegates to service code. |
| `config/app.example.yaml` | Ensure Phase 5 analysis defaults are explicit and match config reference. |
| `docs/project/testing/cli-uat-harness.md` | Add Phase 5 command shape and expected output fields. |
| `docs/project/traceability/pa_document_intelligence_traceability_matrix.md` | Add Phase 5 implementation evidence after completion. |
| `tests/` | Add analysis, CLI, config, path-safety, and negative scope tests. |

## Workstream 1: Artifact Paths and Run Resolution

**Purpose:** Add deterministic Phase 5 outputs and safely locate required upstream artifacts.

**Implementation tasks:**

- Add `phase5_artifact_paths()` to `src/benecard_pa/document/artifact_paths.py`.
- Return run-relative paths for `evidence_workspace.json` and `analysis_trace.json`.
- Reuse existing safe artifact path resolution for all reads and writes.
- Create an artifact loader that accepts paths to digest, analysis index, PA form extraction, and
  initial crosswalk artifacts.
- Fail closed when an input artifact is missing, malformed, absolute, or path-traversing.

**Affected areas:** `src/benecard_pa/document/artifact_paths.py`,
`src/benecard_pa/analysis/artifacts.py`, `tests/test_artifacts.py`,
`tests/test_analysis_phase5.py`.

**Required tests:** Phase 5 paths are deterministic and run-relative; escaping input artifact paths
fail; malformed JSON fails; missing upstream artifacts produce PHI-safe failure.

**Acceptance criteria:** Phase 5 can resolve all inputs and outputs inside one active run directory
without absolute local path leakage.

**Dependencies:** Existing digest and Phase 4 artifact layout.

**Non-goals:** Do not add new source filename-based artifact layouts.

## Workstream 2: Workspace and Trace Models

**Purpose:** Define the durable file-artifact shape for Phase 5 workspace state and orchestration
trace.

**Implementation tasks:**

- Create `src/benecard_pa/analysis/models.py`.
- Define `EvidenceWorkspaceArtifact`, `EvidenceWorkspaceEntry`, `EvidenceObservation`,
  `AnalysisTraceArtifact`, `AnalysisBatch`, and related provenance/review-flag structures.
- Require one workspace entry per extracted PA form field.
- Preserve form field ID, label/question, value, form page, candidate evidence pages, selected
  context pages, observations, confidence, source refs, and review flags.
- Record trace fields for mode, effective limits, batch counts, analyzed pages, skipped pages,
  omitted pages, deferred pages, context-exhaustion flag, timeout flag, tool-call counts, pass
  counts, and fallback mode.
- Include source document name only under the existing approved non-PHI/UAT source identity policy.

**Affected areas:** `src/benecard_pa/analysis/models.py`, `tests/test_analysis_phase5.py`.

**Required tests:** Workspace and trace serialize with stable keys; one workspace entry is created
per form field; missing or empty fields are represented with explicit review flags; trace records
limits and page sets.

**Acceptance criteria:** `evidence_workspace.json` and `analysis_trace.json` have stable, typed,
file-reviewable schemas.

**Dependencies:** Workstream 1 artifact loader.

**Non-goals:** Do not store hidden agent memory or database-only workspace state.

## Workstream 3: Retrieval Selection and Candidate Page Batching

**Purpose:** Build deterministic candidate evidence context from the digest/index instead of full
packet text.

**Implementation tasks:**

- Create `src/benecard_pa/analysis/retrieval.py`.
- Read eligible pages from `packet_analysis_index.json` using
  `analysis.retrieval.restrict_evidence_search_to_components`.
- Respect `analysis.retrieval.allow_optional_components_as_support`.
- Limit candidate pages per field using `analysis.context.max_candidate_pages_per_field`.
- Build page batches using `analysis.context.max_pages_per_llm_call`.
- Track omitted and deferred candidate pages in workspace entries and trace metadata.
- Reuse Phase 4 crosswalk hints when available, but do not treat Phase 4 `unclear` items as final
  evidence.

**Affected areas:** `src/benecard_pa/analysis/retrieval.py`,
`src/benecard_pa/settings.py`, `tests/test_analysis_phase5.py`.

**Required tests:** Component restrictions are honored; optional components are included/excluded
according to config; candidate page limits create review flags; batches do not exceed configured
page limits; full-packet fallback is disabled by default.

**Acceptance criteria:** Candidate evidence context is reproducible from upstream artifacts and
YAML settings.

**Dependencies:** Workstream 2 models and existing `AnalysisSettings`.

**Non-goals:** Do not perform semantic retrieval, embedding search, or broad LLM evaluation in this
phase.

## Workstream 4: Context Assembly and Safe Source References

**Purpose:** Assemble bounded text context for analysis while preserving source provenance and PHI
rules.

**Implementation tasks:**

- Create `src/benecard_pa/analysis/context.py`.
- Resolve normalized text artifact paths through safe artifact resolution only.
- For each batch, collect page numbers, component types, text artifact refs, available summaries,
  and bounded text lengths.
- Do not include page images unless `analysis.context.include_page_images` is true and model
  capability gates pass.
- Record missing text artifacts and skipped image refs as review flags.
- Do not print assembled text context to console.

**Affected areas:** `src/benecard_pa/analysis/context.py`,
`tests/test_analysis_phase5.py`.

**Required tests:** Text context comes from normalized text artifacts; absolute/traversal paths
fail; missing text is flagged; image refs are excluded by default; bounded context does not exceed
configured page counts.

**Acceptance criteria:** Context assembly is safe, bounded, and auditable without leaking content to
console output.

**Dependencies:** Workstreams 1 and 3.

**Non-goals:** Do not send all page text or images to a model.

## Workstream 5: Analysis Orchestrator

**Purpose:** Own Phase 5 execution, limits, workspace creation, and trace creation.

**Implementation tasks:**

- Create `src/benecard_pa/analysis/workflow.py`.
- Implement deterministic `single_pass` and `staged` modes.
- For `tool_assisted`, check YAML and selected model profile capability before enabling tool
  behavior.
- If tool calling is unsupported and `analysis.tool_calling.fail_when_unsupported` is false, fall
  back to deterministic staged mode and record `tool_calling_unsupported_staged_fallback`.
- Enforce configured analysis pass, retry, tool-call, page, and wall-clock limits at the
  orchestrator boundary.
- Build workspace entries and trace artifacts even when analysis is incomplete, with explicit
  review flags.
- Return a PHI-safe result object for CLI printing.

**Affected areas:** `src/benecard_pa/analysis/workflow.py`,
`src/benecard_pa/analysis/models.py`, `src/benecard_pa/settings.py`,
`tests/test_analysis_phase5.py`.

**Required tests:** Single-pass and staged modes write artifacts; unsupported tool-assisted mode
falls back or fails according to config; context exhaustion is flagged; timeout handling is
represented in trace; missing required upstream artifacts fail safely.

**Acceptance criteria:** The orchestrator writes workspace and trace artifacts without final review
or broad tool execution.

**Dependencies:** Workstreams 1-4.

**Non-goals:** Do not implement Phase 6 LLM tool execution beyond capability gates and trace
accounting.

## Workstream 6: CLI UAT Command

**Purpose:** Add a Phase 5 CLI integration surface for operator review and phase-exit testing.

**Implementation tasks:**

- Add `analyze <source_path>` to `src/benecard_pa/cli.py`.
- Delegate work to `Phase5Workflow`; keep business logic out of CLI.
- Run upstream digest and Phase 4 crosswalk workflow as needed to produce required inputs.
- Print PHI-safe fields:
  - `status`
  - `source`
  - `output_dir`
  - upstream artifact paths
  - `evidence_workspace_json`
  - `analysis_trace_json`
  - workspace entry count
  - analyzed/deferred/omitted page counts
  - mode and fallback mode
  - review flags
- Return exit code `0` only when Phase 5 artifacts are written.

**Affected areas:** `src/benecard_pa/cli.py`, `tests/test_cli.py`,
`docs/project/testing/cli-uat-harness.md`.

**Required tests:** CLI success output includes Phase 5 artifact paths; CLI failure output is
PHI-safe; CLI does not print raw document text; CLI does not import deferred watcher/lifecycle/SFTP
modules.

**Acceptance criteria:** `uv run benecard-pa --config config/app.example.yaml analyze <source>`
provides a reviewable Phase 5 UAT path.

**Dependencies:** Workstream 5.

**Non-goals:** Do not add long-running service mode.

## Workstream 7: Configuration and Governance Validation

**Purpose:** Ensure analysis settings are enforceable and safe before Phase 5 execution.

**Implementation tasks:**

- Validate `analysis.mode` values: `single_pass`, `staged`, `tool_assisted`.
- Validate positive context, loop, retry, page, and image limits.
- Validate allowed tool names are from the approved Phase 5 set.
- Validate tool calling requires both YAML enablement and selected profile capability when tool
  execution is attempted.
- Keep `send_full_packet_by_default: false` as the expected MVP default and flag any full-packet
  mode as explicitly configured.

**Affected areas:** `src/benecard_pa/settings.py`, `config/app.example.yaml`,
`docs/project/configuration/config_yaml_reference.md`, `tests/test_settings.py`.

**Required tests:** Invalid modes fail; nonpositive limits fail; unknown allowed tools fail; tool
calling falls back or fails according to config; config-check validates Phase 5 settings.

**Acceptance criteria:** Misconfigured Phase 5 analysis cannot silently proceed with unsafe or
unbounded behavior.

**Dependencies:** Existing settings model.

**Non-goals:** Do not add provider approval workflows beyond existing governance settings.

## Workstream 8: Documentation and Traceability Close-Out

**Purpose:** Keep the documentation trail synchronized with implementation.

**Implementation tasks:**

- Update `docs/project/testing/cli-uat-harness.md` with Phase 5 command output and UAT criteria.
- Update `docs/project/configuration/config_yaml_reference.md` only if settings semantics change.
- Update `docs/project/traceability/pa_document_intelligence_traceability_matrix.md` with Phase 5
  implementation evidence after verification.
- Add UAT findings to the running UAT findings log.
- Mark Phase 5 plan/directive statuses only after implementation and verification are complete.

**Affected areas:** project documentation under `docs/project/`.

**Required tests:** Documentation references match actual command names and artifact names.

**Acceptance criteria:** A reviewer can trace Phase 5 requirements to code, tests, CLI UAT, and
artifacts.

**Dependencies:** All implementation workstreams.

**Non-goals:** Do not rewrite PRD or architecture unless implementation reveals a real requirement
or architecture correction.

## Data and Schema Changes

- Add `evidence_workspace.json`.
- Add `analysis_trace.json`.
- Add deterministic Phase 5 artifact paths under the existing document/run directory.
- No SQLite schema changes in Phase 5.
- No changes to `packet_digest.json`, `packet_analysis_index.json`, `pa_form_extraction.json`, or
  `form_evidence_crosswalk.json` unless a bug fix is required and separately reviewed.

## API, CLI, and Config Changes

- CLI: add `analyze <source_path>`.
- Config: validate existing `analysis` section more rigorously if needed.
- API/internal services: add `Phase5Workflow` result object and service modules under
  `src/benecard_pa/analysis/`.
- LLM: no new required live LLM call is expected for deterministic `single_pass` and `staged`
  modes. Tool-assisted capability gates may inspect LLM profile metadata.

## Migration Order

1. Add artifact paths and models.
2. Add retrieval and context assembly.
3. Add deterministic workspace and trace builder.
4. Add orchestration workflow and result object.
5. Add CLI command.
6. Add config validation hardening.
7. Add docs and traceability updates.
8. Run unit, integration, and CLI UAT verification.

## Negative Tests

- Escaping artifact paths are rejected.
- Missing upstream artifacts fail safely.
- Unknown analysis mode fails config validation.
- Unknown tool name fails validation.
- Nonpositive page/tool/time limits fail validation.
- Tool-assisted mode with unsupported profile fails or falls back according to YAML.
- CLI does not print raw text, prompts, snippets, or raw LLM responses.
- CLI does not invoke lifecycle, watcher, SFTP, SQLite-required persistence, final review, or
  approval/denial behavior.

## CLI UAT Check

Recommended command:

```bash
uv run benecard-pa --config config/app.example.yaml analyze docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

Expected console shape:

```text
status: success
source: <source-document-name>
output_dir: <configured-output-dir>
digest_json: <packet_digest_path>
analysis_index_json: <packet_analysis_index_path>
pa_form_extraction_json: <pa_form_extraction_path>
form_evidence_crosswalk_json: <crosswalk_path>
evidence_workspace_json: <workspace_path>
analysis_trace_json: <trace_path>
workspace_entries: <count>
analyzed_pages: <count>
deferred_pages: <count>
omitted_pages: <count>
mode: <single_pass|staged|tool_assisted>
fallback_mode: <mode-or-none>
review_flags: <flag-list-or-none>
```

## Verification Commands

```bash
uv run benecard-pa --config config/app.example.yaml config-check
ruff check .
uv run pytest
git diff --check
uv run benecard-pa --config config/app.example.yaml analyze docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

## Acceptance Criteria

- Phase 5 writes `evidence_workspace.json`.
- Phase 5 writes `analysis_trace.json`.
- Workspace contains one entry per extracted PA form field.
- Workspace entries include candidate evidence pages and review flags.
- Trace records effective limits, mode, fallback mode, batches, analyzed pages, deferred pages,
  omitted pages, context exhaustion, timeout status, pass counts, and tool-call counts.
- Retrieval uses digest/index component restrictions and does not send full packet text by default.
- Safe artifact path resolution is enforced for all source text reads.
- CLI UAT reports Phase 5 artifact paths and counts without raw PHI-bearing content.
- File-only mode remains valid.
- Deferred systems remain untouched.

## Documentation Close-Out

- Update CLI UAT harness with Phase 5 command evidence.
- Update traceability matrix after implementation verification.
- Log UAT findings discovered during Phase 5 testing.
- Mark this tactical plan implemented only after verification and review pass.

## Risks

| Risk | Mitigation |
|---|---|
| Workspace grows into hidden agent memory | Keep it as explicit JSON under the run directory. |
| Analysis becomes final review prematurely | Label observations as intermediate and defer final review. |
| Tool-assisted mode expands too far | Implement capability gates and deterministic fallback first. |
| Retrieval misses relevant evidence | Track deferred/omitted pages and preserve UAT findings. |
| PHI leaks through CLI output | Keep console output to paths, counts, flags, and status. |

## Accuracy Pass

- Implementation steps are mapped to concrete files/modules.
- Ownership is explicit for new `analysis` package, CLI, settings, artifacts, tests, and docs.
- Tests include positive, negative, security, CLI, and no-scope-leakage checks.
- Migration order starts with artifacts/models before CLI exposure.
- Security/governance checks cover PHI-safe output, safe paths, tool gates, and raw LLM storage.
- CLI UAT evidence is defined.
- No contradiction found with the approved Phase 5 build plan.
