# Phase 5 Build Plan: Digest-Driven Analysis Orchestration

**Status:** Approved

**Date:** 2026-05-23

**Phase:** 5

**Source authority:** `docs/project/prd/pa_document_intelligence_prd.md`, `docs/project/architecture/pa_document_intelligence_architecture.md`, `docs/project/security-governance/governance-security-spec.md`, `docs/project/configuration/config_yaml_reference.md`, `docs/project/testing/cli-uat-harness.md`, `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`, `docs/project/build-plan/phase-roadmap.md`, `docs/project/build-plan/phases/phase-4-pa-form-extraction-crosswalk.md`

**Methodology:** `docs/methodology/constitution/gendev.md` and `docs/methodology/dev-skills/phase-build-planner.md`

## Executive Summary

Phase 5 turns the packet digest, analysis index, PA form extraction artifact, and initial crosswalk
into a bounded analysis workspace. The phase introduces the orchestration layer that selects
candidate evidence context from existing artifacts, batches pages/components under YAML limits,
tracks analyzed, skipped, omitted, and deferred context, and writes an auditable intermediate
analysis artifact.

This phase is not final clinical review. It does not approve, deny, apply payer policy, or produce a
final reviewer package. The main outcome is a reusable evidence workspace and analysis trace that
later phases can use for crosswalk evaluation and final review.

## Phase Objective

- Use `packet_digest.json` and `packet_analysis_index.json` as the retrieval authority.
- Use `pa_form_extraction.json` and `form_evidence_crosswalk.json` as current form/crosswalk input.
- Build an evidence workspace with one workspace entry per extracted PA form item.
- Select candidate evidence pages from configured supporting components, not from the full packet by
  default.
- Enforce YAML-configured page, token, image, pass, retry, tool-call, and wall-clock limits.
- Record analysis trace metadata that explains what was analyzed, skipped, omitted, or deferred.
- Preserve file-only operation and PHI-safe CLI output.

## In Scope

- Add an analysis workspace model for form field IDs, candidate evidence pages, evidence
  observations, source page refs, confidence, and review flags.
- Add an analysis trace model for mode, effective configuration summary/hash, page batches, pass
  counts, tool-call counts, timeout/context flags, analyzed pages, skipped pages, and deferred
  pages.
- Read existing Phase 3.5 and Phase 4 artifacts from a single run directory.
- Implement digest-driven candidate selection using `analysis.retrieval` settings.
- Implement deterministic batching under `analysis.context.max_pages_per_llm_call` and
  `analysis.context.max_candidate_pages_per_field`.
- Implement text-context assembly from normalized text artifacts through safe artifact path
  resolution.
- Support `analysis.mode` values as bounded orchestration modes:
  - `single_pass`: one deterministic pass over candidate pages.
  - `staged`: deterministic staged batching without LLM tool calls.
  - `tool_assisted`: only if configured and supported, with bounded tool-call accounting.
- Add a Phase 5 CLI UAT surface, tentatively `analyze <source_path>`, that can run upstream digest
  and Phase 4 workflows before writing Phase 5 artifacts.
- Write `evidence_workspace.json` and `analysis_trace.json` under the active run directory.
- Keep console output to status, source name, artifact paths, counts, and review flags.
- Add tests for config enforcement, retrieval scope, batching, safe path resolution, trace
  completeness, and no deferred side effects.

## Out of Scope

- Final review narrative or reviewer-ready decision summary.
- Approval, denial, payer policy interpretation, medical necessity determination, or triage.
- Broad autonomous agent loops.
- Arbitrary LLM access to filesystem, shell, database, network, secrets, or configuration.
- Full Phase 6 LiteLLM tool-calling expansion and final review routing.
- Rewriting Phase 3 page classification or prompt tuning based on the current UAT finding.
- Source lifecycle movement, watcher behavior, SFTP intake, queueing, or reprocess/status commands.
- SQLite as required persistence.
- Sending full packet text, full packet PDFs, or all page images to an LLM by default.

## Required Artifacts

| Artifact | Purpose | Authority |
|---|---|---|
| `packet_digest.json` | Canonical page/component inventory | Existing source of packet truth |
| `packet_analysis_index.json` | Derived retrieval helper | Existing Phase 3.5 artifact |
| `pa_form_extraction.json` | Extracted PA form field set | Existing Phase 4 artifact |
| `form_evidence_crosswalk.json` | Initial field-to-evidence status | Existing Phase 4 artifact |
| `evidence_workspace.json` | Phase 5 candidate evidence observations and field workspace | New Phase 5 artifact |
| `analysis_trace.json` | Phase 5 orchestration trace, limits, and review flags | New Phase 5 artifact |

## Workstreams

### 1. Artifact Path and Run Resolution

- Add deterministic Phase 5 artifact paths for `evidence_workspace.json` and `analysis_trace.json`.
- Resolve all input artifacts through the active run directory and configured output directory.
- Reject absolute or escaping artifact paths.

### 2. Workspace and Trace Models

- Define typed models for evidence workspace entries, evidence observations, context batches, and
  analysis trace metadata.
- Preserve original packet page numbers as canonical citations.
- Include review flags for missing input artifacts, missing candidate pages, context exhaustion,
  timeout, unsupported mode, unsupported tool calling, and missing required components.

### 3. Retrieval and Batching

- Use `analysis.retrieval.restrict_evidence_search_to_components` to select eligible evidence
  pages.
- Allow optional components only when `allow_optional_components_as_support` is true.
- Batch candidate pages by field and component under configured limits.
- Track omitted pages and deferred pages rather than silently dropping them.

### 4. Analysis Execution Boundary

- Implement deterministic `single_pass` and `staged` modes first.
- In `tool_assisted` mode, enforce configuration and model capability gates before exposing tools.
- If tool calling is unsupported and `fail_when_unsupported` is false, fall back to deterministic
  staged analysis and record a review flag.
- Do not expose arbitrary tools; Phase 5 may define the tool interface but should keep execution
  constrained to current-run digest/page/component reads and workspace observation recording.

### 5. CLI UAT

- Add `analyze <source_path>` or an equivalent clearly named Phase 5 command.
- The command may run upstream digest and crosswalk workflows first, then write Phase 5 artifacts.
- Console output must include artifact paths, counts, mode, review flags, and LLM/task capability
  summary when applicable.
- Console output must not include raw document text, prompts, source snippets, or raw LLM
  responses.

## Sequencing

1. Add artifact paths and models.
2. Add input artifact loader and validator.
3. Add retrieval selection and batching.
4. Add workspace and trace builders for deterministic modes.
5. Add bounded tool-assist capability gates without broad LLM tool execution.
6. Add CLI UAT command and PHI-safe output.
7. Add tests and update project documentation/traceability.
8. Run CLI UAT against approved non-PHI sample packets and log findings.

## Security and Governance Implications

- All Phase 5 artifacts are PHI-bearing unless the input fixture is explicitly approved non-PHI.
- Logs and console output must remain PHI-safe.
- Retrieval tools, if exposed, must be scoped to the active document/run only.
- Tool calling must be denied unless both YAML and the selected LiteLLM profile allow it.
- Page images may be included only when YAML enables them and the selected profile supports vision.
- Phase 5 must not store raw LLM requests/responses unless governance settings explicitly allow it.

## Test Strategy

- Unit tests for workspace and trace model serialization.
- Unit tests for retrieval scope, optional component inclusion, and missing candidate pages.
- Unit tests for page batching and omitted/deferred page review flags.
- Negative tests for absolute/traversal artifact paths.
- Config validation tests for analysis modes, tool-calling gates, and context limits.
- CLI tests proving `analyze` writes Phase 5 artifacts and avoids deferred modules.
- Scope tests proving no lifecycle, watcher, SFTP, SQLite-required persistence, approval/denial, or
  final review behavior.
- CLI UAT using `docs/project/reference/clinical-samples/doc08294920260513101420.pdf`.

## Acceptance Criteria

- `evidence_workspace.json` is written for packets with required upstream artifacts.
- `analysis_trace.json` is written and records mode, configured limits, batches, analyzed/skipped
  pages, context exhaustion, timeout status, and review flags.
- Evidence workspace entries preserve one-to-one linkage to extracted PA form field IDs.
- Candidate evidence pages come from digest/index component restrictions, not full-packet text by
  default.
- The orchestrator respects configured page, image, pass, retry, tool-call, and wall-clock limits.
- Omitted or deferred evidence context is surfaced as reviewer-facing flags.
- Unsupported tool calling fails closed or falls back according to YAML.
- All cited evidence uses original packet page numbers and source artifact refs.
- CLI UAT reports Phase 5 artifact paths and counts without printing PHI-bearing text.
- File-only mode remains valid.

## Deferred Items

- Final review artifact and reviewer-ready narrative move to Phase 6/7.
- Broad LiteLLM tool-calling execution and final-review task routing remain Phase 6.
- SQLite indexing of analysis runs remains Phase 7.
- Lifecycle, watcher, SFTP, reprocess, and status operations remain Phase 8/9.
- Prompt/model tuning for current page-classification UAT findings is deferred until more sample
  packets are available.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Phase 5 becomes an open-ended agent loop | Keep deterministic orchestrator ownership and hard YAML limits. |
| Full packet content leaks into model context | Use digest/index retrieval and keep `send_full_packet_by_default: false`. |
| Candidate evidence misses relevant pages | Track omitted/deferred pages and log UAT findings for later prompt/retrieval tuning. |
| Tool calling overreaches | Gate by YAML and model profile; restrict tools to current-run document reads only. |
| Analysis artifacts become final evidence prematurely | Label observations as intermediate and preserve source citations for later validation. |

## Open Decisions

- Final command name: `analyze <source_path>` is recommended unless another operator-facing name is
  preferred.
- Whether Phase 5 should call the LLM at all in `staged` mode, or only assemble deterministic
  workspace context for Phase 6.
- Whether `evidence_workspace.json` should include bounded text snippets in Phase 5 or defer
  snippet extraction to Phase 6 crosswalk evaluation.

## Accuracy Pass

- Scope ambiguity: tool-assisted mode is included only as a gated boundary, not broad tool
  execution.
- Deferred items: final review, broad tool calling, SQLite indexing, lifecycle, and watcher behavior
  are explicitly deferred.
- Acceptance coverage: every in-scope artifact and CLI behavior has an acceptance criterion.
- Security coverage: tool boundaries, PHI-safe output, image gates, and safe artifact paths are
  required.
- Tactical readiness: this plan is ready to convert into a Phase 5 tactical implementation plan
  after review and approval.
