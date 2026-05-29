# Phase 5 AI Construction Directive: Digest-Driven Analysis Orchestration

**Status:** Implemented and verified

**Date:** 2026-05-23

**Phase:** 5

**Directive type:** AI construction directive

**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/ai-construction-directive-builder.md`

## AI Builder Role

You are the implementation agent for Phase 5 of the BeneCard PA Document Intelligence project. Your
job is to implement a bounded digest-driven analysis orchestration layer that writes a file-based
evidence workspace and analysis trace. Implement only the Phase 5 scope authorized here.

## Source Authority and Precedence

Use these documents in this order:

1. `docs/project/build-plan/phases/phase-5-tactical-implementation-plan.md`
2. `docs/project/build-plan/phases/phase-5-digest-driven-analysis-orchestration.md`
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

Add a bounded Phase 5 CLI UAT workflow that can process an approved packet and produce:

- existing upstream digest and Phase 4 artifacts as needed;
- `evidence_workspace.json` containing one workspace entry per extracted PA form field;
- `analysis_trace.json` containing orchestration mode, limits, batches, analyzed pages, deferred
  pages, omitted pages, context exhaustion, timeout status, pass counts, tool-call counts, fallback
  mode, and review flags;
- PHI-safe console output with artifact paths, counts, mode, fallback mode, and review flags.

For MVP, the analysis workspace is strictly a file artifact. `evidence_workspace.json` is the Phase
5 workspace source of truth. SQLite indexing is deferred and must remain non-authoritative when
added later.

## Allowed Scope

You may edit or create:

- `src/benecard_pa/analysis/__init__.py`
- `src/benecard_pa/analysis/artifacts.py`
- `src/benecard_pa/analysis/models.py`
- `src/benecard_pa/analysis/retrieval.py`
- `src/benecard_pa/analysis/context.py`
- `src/benecard_pa/analysis/workflow.py`
- `src/benecard_pa/document/artifact_paths.py`
- `src/benecard_pa/settings.py`
- `src/benecard_pa/cli.py`
- `config/app.example.yaml`
- tests for Phase 5 analysis, artifact paths, settings, and CLI
- project docs required for Phase 5 close-out after implementation

Use cautiously:

- `src/benecard_pa/pa_form/` only as an upstream dependency; do not move Phase 5 logic there.
- `src/benecard_pa/digest_review.py` only for upstream workflow reuse.
- `src/benecard_pa/llm/` only for capability metadata checks; do not add broad Phase 6 LLM tool
  execution.

## Explicit Non-Goals

Do not implement or invoke:

- final clinical review narratives;
- approval, denial, medical necessity outcome, payer policy interpretation, or triage;
- broad autonomous agent loops;
- broad Phase 6 LiteLLM tool-calling execution;
- final-review LLM task routing;
- prompt/model tuning for current page-classification UAT findings;
- full packet text, full PDFs, all page images, or all source text sent to an LLM by default;
- arbitrary filesystem, shell, database, network, secret, or configuration access by an LLM;
- SQLite-required persistence or SQLite schema changes;
- source lifecycle movement, copy, delete, archive, quarantine, processed/failed transitions, or
  retention behavior;
- Dropbox watcher, SFTP intake, process queues, reprocess/status commands, or daemon behavior.

## Required Workstreams

### 1. Artifact Paths and Run Resolution

Implement deterministic Phase 5 artifact paths and safe artifact loading.

Requirements:

- add `phase5_artifact_paths()` to `src/benecard_pa/document/artifact_paths.py`;
- write `evidence_workspace.json` and `analysis_trace.json` under the active document/run
  directory;
- return run-relative artifact paths only;
- reuse existing safe artifact path resolution for reads and writes;
- reject missing, malformed, absolute, or path-traversing input artifacts;
- keep source filename-based artifact layouts disabled.

### 2. Workspace and Trace Models

Create stable models for Phase 5 artifacts.

Requirements:

- define `EvidenceWorkspaceArtifact`, `EvidenceWorkspaceEntry`, `EvidenceObservation`,
  `AnalysisTraceArtifact`, `AnalysisBatch`, and related provenance/review flag structures;
- create one workspace entry per extracted PA form field;
- preserve form field ID, label/question, value, form page, candidate evidence pages, selected
  context pages, source refs, and review flags;
- keep evidence observations empty or explicitly provisional until Phase 6 performs evidence
  evaluation; Phase 5 candidate context is not a final evidence judgment;
- record requested mode, execution mode, fallback reason, effective limits, batch counts,
  analyzed/skipped/omitted/deferred pages,
  context-exhaustion flag, timeout flag, tool-call counts, pass counts, and fallback mode;
- keep workspace state explicit in JSON and do not create hidden agent memory.

### 3. Retrieval Selection and Candidate Page Batching

Implement digest/index-driven candidate evidence selection.

Requirements:

- use `packet_analysis_index.json` and `analysis.retrieval.restrict_evidence_search_to_components`;
- respect `analysis.retrieval.allow_optional_components_as_support`;
- limit candidates using `analysis.context.max_candidate_pages_per_field`;
- batch pages using `analysis.context.max_pages_per_llm_call`;
- track omitted and deferred pages rather than silently dropping them;
- reuse Phase 4 crosswalk hints when helpful, but do not treat `unclear` items as final evidence;
- do not use full-packet retrieval by default.

### 4. Context Assembly and Safe Source References

Assemble bounded source context for workspace entries.

Requirements:

- resolve normalized text artifacts through safe artifact resolution only;
- collect page numbers, component types, text artifact refs, summaries, and bounded text lengths for
  each batch;
- exclude page images by default;
- include page image refs only when YAML enables them and model capability gates pass;
- flag missing text artifacts and skipped image refs;
- never print assembled source text, prompts, snippets, or raw LLM responses to console.

### 5. Analysis Orchestrator

Implement Phase 5 workflow orchestration.

Requirements:

- create `Phase5Workflow` and a PHI-safe result object;
- implement deterministic `single_pass` and `staged` modes;
- for `tool_assisted`, check YAML and selected model profile capability before enabling any
  tool-like behavior;
- if tool calling is unsupported and `analysis.tool_calling.fail_when_unsupported` is false, fall
  back to deterministic staged mode and record `tool_calling_unsupported_staged_fallback`;
- enforce configured pass, retry, tool-call, page, image, and wall-clock limits at the orchestrator
  boundary;
- write workspace and trace artifacts even when analysis is incomplete, using explicit review flags;
- do not perform final review or broad tool execution.

### 6. CLI UAT Command

Add the Phase 5 CLI surface.

Requirements:

- add `analyze <source_path>` to `src/benecard_pa/cli.py`;
- delegate to `Phase5Workflow`; keep business logic out of CLI;
- run upstream digest and Phase 4 crosswalk workflow as needed to produce required inputs;
- print only PHI-safe fields:
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
- return exit code `0` only when Phase 5 artifacts are written.

### 7. Configuration and Governance Validation

Harden existing analysis configuration.

Requirements:

- validate `analysis.mode` is `single_pass`, `staged`, or `tool_assisted`;
- validate positive context, loop, retry, page, image, and time limits;
- validate allowed tool names against the approved Phase 5 set;
- validate tool calling requires YAML enablement and selected profile capability when tool-like
  behavior is attempted;
- keep `send_full_packet_by_default: false` as the MVP default;
- flag any full-packet mode as explicitly configured;
- preserve public-provider governance and raw LLM storage controls.

### 8. Documentation and Traceability Close-Out

Update documentation only after implementation behavior is real.

Requirements:

- update `docs/project/testing/cli-uat-harness.md` with the final Phase 5 command shape;
- update `docs/project/configuration/config_yaml_reference.md` only for actual settings semantics;
- update `docs/project/traceability/pa_document_intelligence_traceability_matrix.md` with
  implementation evidence after verification;
- log Phase 5 UAT findings in the running UAT findings log;
- do not mark planned behavior implemented until implemented and verified.

## Data and Schema Requirements

- Add `evidence_workspace.json`.
- Add `analysis_trace.json`.
- Add deterministic Phase 5 paths under the existing document/run artifact layout.
- Do not change SQLite schema in Phase 5.
- Do not change existing digest, analysis index, PA form extraction, or crosswalk schemas unless a
  bug fix is required and explicitly reported.

## Security and Governance Requirements

- Treat all Phase 5 inputs and artifacts as PHI-bearing unless the input is explicitly approved
  non-PHI.
- Keep console output PHI-safe.
- Do not log raw document text, selected context, prompts, snippets, page images, or raw LLM
  responses.
- Restrict any retrieval/tool-like behavior to the active document/run scope.
- Deny tool calling unless YAML and model profile capability both allow it.
- Include page images only when YAML and profile capability allow it.
- Do not weaken governance/security settings.
- Do not add arbitrary filesystem, shell, network, database, secret, or configuration access.

## Testing Requirements

Add or update tests for:

- Phase 5 artifact path generation;
- safe artifact loading and path traversal rejection;
- workspace model serialization;
- trace model serialization;
- one workspace entry per PA form field;
- component-restricted retrieval;
- optional component inclusion/exclusion;
- candidate page limits and omitted/deferred page flags;
- page batch size limits;
- missing text artifacts;
- default exclusion of page images;
- invalid `analysis.mode`;
- nonpositive context/tool/time limits;
- unknown allowed tool names;
- unsupported tool-assisted mode fallback/failure behavior;
- CLI success output with Phase 5 artifact paths and counts;
- CLI PHI-safe failure output;
- no raw text, prompts, snippets, or raw LLM responses in console output;
- no lifecycle, watcher, SFTP, SQLite-required persistence, final review, or approval/denial
  behavior.

Tests must not require live LM Studio, remote providers, network access, or secrets.

## Verification Commands

Run:

```bash
uv run benecard-pa --config config/app.example.yaml config-check
ruff check .
uv run pytest
git diff --check
uv run benecard-pa --config config/app.example.yaml analyze docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

If any command cannot be run, report it explicitly with the reason.

## CLI UAT Requirements

Recommended command:

```bash
uv run benecard-pa --config config/app.example.yaml analyze docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

Expected console fields:

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

The CLI must remain file-only and must not require SQLite.

## Documentation Close-Out

After implementation and verification:

- update Phase 5 build plan status only when verified;
- update Phase 5 tactical plan status only when verified;
- update CLI UAT harness;
- update configuration reference if settings behavior changed;
- update traceability matrix;
- log UAT findings;
- report verification commands and results.

## Reporting Requirements

When finished, report:

- files changed;
- artifacts added;
- tests added;
- verification commands run and results;
- CLI UAT command and artifact paths;
- any skipped verification;
- any remaining known limitations or deferred items.

## Stop Conditions

Stop and report before proceeding if:

- implementation requires changing PRD, architecture, or governance authority;
- Phase 5 cannot be implemented without final review, broad tool calling, SQLite-required
  persistence, lifecycle movement, watcher behavior, SFTP, or source mutation;
- required config would expose full packet text/images by default;
- safe artifact path rules cannot be maintained;
- tests would require real PHI, network access, remote providers, or secrets;
- source authority conflicts cannot be resolved from the precedence order.

## Anti-Drift Instructions

- Do not implement deferred features.
- Do not broaden scope.
- Do not silently change architecture.
- Do not weaken security or governance behavior.
- Do not remove unrelated code or user-created files.
- Do not mark planned behavior as implemented unless it is implemented and verified.
- Report skipped verification honestly.

## Accuracy Pass

- Every tactical workstream is represented.
- Required positive, negative, security, CLI, and UAT tests are included.
- Non-goals are explicit.
- Migration/removal behavior is explicit: no SQLite schema, lifecycle, watcher, SFTP, final review,
  or broad tool execution in Phase 5.
- Documentation close-out is included.
- Reporting requirements and stop conditions are explicit.
