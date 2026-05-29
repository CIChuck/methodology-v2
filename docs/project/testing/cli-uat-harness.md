# CLI UAT Harness

**Status:** Project testing authority  
**Date:** 2026-05-22  
**Scope:** BeneCard PA Document Intelligence project  
**Related authority:** `docs/project/prd/pa_document_intelligence_prd.md`, `docs/project/architecture/pa_document_intelligence_architecture.md`, `docs/project/security-governance/governance-security-spec.md`, `docs/project/build-plan/phase-roadmap.md`

## Purpose

This project uses the CLI as its primary phase-exit user acceptance testing and systems integration
harness. Each phase that produces user-observable behavior should expose or extend a bounded CLI
command that proves the phase acceptance signal end to end against approved non-PHI samples or
synthetic fixtures.

The CLI is an integration surface over application services. It must not become the home for
parsing, OCR, classification, analysis, persistence, lifecycle, or LLM business logic.

## Command Principles

- Commands must map to phase-approved workflows.
- Console output must be PHI-safe: approved source document name for non-PHI UAT inputs, status,
  counts, configured output directory, artifact paths, and error categories only.
- Commands must write reviewable artifacts to configured output paths when the phase produces
  artifacts.
- Commands that run workflow steps with LLM usage must print terminal diagnostics by key step:
  fixed phase, fixed step name, step type (`leaf` or `aggregate`), LLM call count, and elapsed
  seconds. Diagnostics must remain console-only unless a phase explicitly defines a diagnostic
  artifact.
- CLI UAT commands must also print `[uat_run] uat_run_total (aggregate)` as the final diagnostic
  row. This row measures complete command wall-clock time from workflow start to returned result.
- Exit code `0` means the phase workflow completed and required artifacts were written.
- Nonzero exit codes mean the requested workflow could not complete.
- Commands must fail closed when required configuration, source files, model capabilities, or
  environment prerequisites are unavailable.
- Commands must not call deferred modules or providers unless the current phase explicitly includes
  them.

## Phase Expectations

| Phase | CLI UAT Surface |
|---|---|
| 2.5 | `digest <source_path>` creates `packet_digest.json` and metadata-only `packet_digest.md`. |
| 3 | `digest <source_path>` extension inventories page types, components, unknown pages, and summaries through configured LiteLLM page analysis tasks. Optimized configs may use combined `page_analysis`; debug configs may use separate `page_classification` and `page_summary`. |
| 4 | `crosswalk <source_path>` produces PA form extraction and initial field-to-evidence crosswalk artifacts. |
| 5 | `analyze <source_path>` proves digest-driven retrieval, evidence workspace behavior, and configured context limits. |
| 6 | `evaluate <source_path>` proves `crosswalk_evaluation` routing, evaluated crosswalk JSON/Markdown/index output, evaluation trace output, capability gates, structured output validation, vision controls, and active-run tool boundaries. |
| 7 | Output command or completed workflow writes the durable review package, digest copy, trace, error artifacts, and optional SQLite index. |
| 8 | `process-once`, `reprocess`, and `status` prove lifecycle gates and idempotent operator workflow. |
| 9 | Watcher/reconciliation commands prove stable-file intake, duplicate prevention, and restart recovery. |

## Required Evidence

Every phase-exit CLI UAT should specify:

- command invocation;
- approved fixture or sample input;
- approved source document identity expectations;
- allowed model/provider behavior and task profiles for that phase;
- configured output directory;
- expected output artifacts;
- expected console output shape;
- expected exit code;
- required configuration;
- explicitly forbidden side effects;
- tests or scripts that exercise the command.

## Approved Test Inputs

The project reference sample folder `docs/project/reference/clinical-samples/` is an approved local
source for non-PHI PDFs and images used in CLI UAT, integration tests, and operator review. Synthetic
fixtures may also be used when deterministic edge cases are required.

For approved non-PHI UAT inputs, CLI output and human-readable review artifacts may identify the
source document name so reviewers can connect artifacts to the tested source. Artifact directory
prefixes must continue to use document/run identity rather than source filenames.

## Security Rules

- Treat CLI inputs, digest artifacts, OCR text, LLM requests/responses, logs, SQLite rows, and output
  artifacts as PHI unless explicitly approved as non-PHI fixtures.
- Do not print extracted document text, prompt content, LLM response content, patient identifiers, or
  source snippets to the console.
- Do not move, delete, archive, or upload source files unless the current phase explicitly owns
  lifecycle behavior.
- Do not use network, SFTP, LLM provider, local model endpoint, SQLite persistence, watcher, or
  lifecycle behavior unless the phase plan includes it.

## Phase 2.5, Phase 3, and Phase 3.5 Digest UAT

The first project-specific CLI UAT harness target is the digest review path. Phase 2.5 established
the JSON/Markdown artifact path; Phase 3 extends the same command with LiteLLM-backed page
classification, packet decomposition, and bounded digest summaries. Phase 3.5 adds Markdown summary
review sections and the derived packet analysis index artifact used by later crosswalk phases.

```bash
uv run benecard-pa --config config/app.example.yaml digest docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

This command should prove PDF/image input, parsing, Phase 2 image-to-text behavior, Phase 3 page
classification, component inventory, bounded summaries, artifact writing under the configured
`paths.output_dir`, Phase 3.5 analysis-index creation, and PHI-safe console output without
introducing Phase 4 or later behavior.

Expected Phase 3 console fields include:

```text
status: success
source: <source-document-name>
output_dir: <configured-output-dir>
digest_json: <digest_json_path>
digest_markdown: <digest_markdown_path>
analysis_index_json: <packet_analysis_index_path>
pages: <count>
components: <count>
missing_required_components: <component-list-or-none>
review_flags: <flag-list-or-none>
llm_tasks: page_analysis=<profile>, page_classification=<profile>, page_summary=<profile>, component_summary=<profile>
diagnostics:
  [phase_2_packet_preparation] parse_packet (leaf): llm_calls=0 elapsed_seconds=<seconds>
  [phase_2_packet_preparation] image_text_processing (leaf): llm_calls=0 elapsed_seconds=<seconds>
  [phase_3_digest] page_analysis (leaf): llm_calls=<count> elapsed_seconds=<seconds>
  [phase_3_digest] component_summary (leaf): llm_calls=<count> elapsed_seconds=<seconds>
  [phase_3_digest] digest_artifacts (leaf): llm_calls=0 elapsed_seconds=<seconds>
  [uat_run] uat_run_total (aggregate): llm_calls=<count> elapsed_seconds=<seconds>
```

When `packet_digest.page_analysis_mode: "separate"`, the diagnostics block replaces
`page_analysis` with separate `page_classification` and `page_summary` rows.

## Phase 4 PA Form Extraction and Crosswalk UAT

Phase 4 adds the bounded `crosswalk` command. The command may run the upstream digest workflow first,
then writes `pa_form_extraction.json`, the derived compact `form_extraction_index.json`,
`form_evidence_crosswalk.json`, and a bounded Markdown review under the same run directory. It must
use only classified PA form pages for form extraction and must not print extracted field values,
prompts, source snippets, or raw model responses to console.

```bash
uv run benecard-pa --config config/app.example.yaml crosswalk docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

Expected Phase 4 console fields include:

```text
status: success
source: <source-document-name>
output_dir: <configured-output-dir>
digest_json: <packet_digest_path>
analysis_index_json: <packet_analysis_index_path>
pa_form_extraction_json: <pa_form_extraction_path>
form_extraction_index_json: <form_extraction_index_path>
form_evidence_crosswalk_json: <crosswalk_path>
phase4_markdown: <markdown_path>
fields: <count>
crosswalk_items: <count>
conflicts: <count>
missing_or_unclear: <count>
review_flags: <flag-list-or-none>
llm_tasks: pa_form_extraction=<profile>
diagnostics:
  <upstream-digest-step>: llm_calls=<count> elapsed_seconds=<seconds>
  [phase_3_digest] phase_3_total (aggregate): llm_calls=<count> elapsed_seconds=<seconds>
  [phase_4_pa_form_crosswalk] pa_form_extraction_text (leaf): llm_calls=<0-or-1> elapsed_seconds=<seconds>
  [phase_4_pa_form_crosswalk] pa_form_extraction_vision (leaf): llm_calls=<0-or-1> elapsed_seconds=<seconds>
  [phase_4_pa_form_crosswalk] pa_form_extraction (aggregate): llm_calls=<count> elapsed_seconds=<seconds>
  [phase_4_pa_form_crosswalk] phase4_crosswalk_artifacts (leaf): llm_calls=0 elapsed_seconds=<seconds>
  [uat_run] uat_run_total (aggregate): llm_calls=<count> elapsed_seconds=<seconds>
```

Exit code `0` requires the Phase 4 artifacts to be written. The command must remain file-only and
must not invoke source lifecycle movement, watcher behavior, SFTP, SQLite-required persistence, final
review generation, or approval/denial language.

The Markdown artifact should include bounded form values in the extracted-field and crosswalk tables
so reviewers can quickly validate parsed field/value pairs against the evidence mapping.

## Phase 5 Digest-Driven Analysis Workspace UAT

Phase 5 adds the bounded `analyze` command. The command may run upstream digest and Phase 4
workflows first, then writes `evidence_workspace.json` and `analysis_trace.json` under the active
run directory. Phase 5 assembles candidate evidence context and trace metadata only; it must not
perform final clinical review, payer-policy interpretation, approval/denial language, source
lifecycle actions, Phase 6 crosswalk evaluation, or provider-native model tool-call loops.

```bash
uv run benecard-pa --config config/app.example.yaml analyze docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

Expected Phase 5 console fields include:

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
diagnostics:
  <upstream-phase-step>: llm_calls=<count> elapsed_seconds=<seconds>
  [phase_4_pa_form_crosswalk] phase_4_total (aggregate): llm_calls=<count> elapsed_seconds=<seconds>
  [phase_5_evidence_workspace] evidence_workspace (leaf): llm_calls=0 elapsed_seconds=<seconds>
  [uat_run] uat_run_total (aggregate): llm_calls=<count> elapsed_seconds=<seconds>
```

Exit code `0` requires both Phase 5 artifacts to be written. Console output must not print extracted
field values, page text, prompt content, source snippets, or raw model responses.
The JSON artifacts should record `execution_mode` and `fallback_reason` when configured
`tool_assisted` mode executes as deterministic staged workspace assembly. Candidate context pages
must not be interpreted as final evidence matches until Phase 6 evidence evaluation is implemented.

## Phase 6 LLM-Assisted Crosswalk Evaluation UAT

Phase 6 adds the bounded `evaluate` command. The command may run upstream digest, crosswalk, and
analysis workflows first, then writes the artifact set required by `analysis.output_mode`. The
default `uat_review` mode writes `evaluated_form_evidence_crosswalk.json`,
`evaluated_form_evidence_crosswalk.md`, `evaluated_form_evidence_crosswalk_index.json`, and a full
`crosswalk_evaluation_trace.json` under the active run directory. `production` writes only the two
primary review deliverables, `evaluated_form_evidence_crosswalk_index.json` and
`evaluated_form_evidence_crosswalk.md`. `audit_minimal` writes those same review deliverables plus
a minimal evaluation trace without full tool-use detail. In Phase 6.5 this mode applies to the
full active run directory: a successful `production` run must prune upstream digest, extraction,
crosswalk, workspace, page image, OCR, and text intermediates after the final review deliverables
are written. Phase 6 evaluates candidate evidence against extracted PA form fields only; it must not
perform final review packaging,
approval/denial language, source lifecycle actions, watcher behavior, SFTP intake, production
persistence, or provider-native model tool-call loops.

```bash
uv run benecard-pa --config config/app.example.yaml evaluate docs/project/reference/clinical-samples/doc08294920260513101420.pdf
```

Expected Phase 6 console fields include:

```text
status: success
source: <source-document-name>
output_dir: <configured-output-dir>
evaluated_form_evidence_crosswalk_json: <evaluated-crosswalk-path>
evaluated_form_evidence_crosswalk_markdown: <evaluated-crosswalk-markdown-path>
evaluated_form_evidence_crosswalk_index_json: <evaluated-crosswalk-index-path>
crosswalk_evaluation_trace_json: <evaluation-trace-path>
evaluated_items: <count>
supported: <count>
contradicted: <count>
missing: <count>
unclear: <count>
llm_task: crosswalk_evaluation=<profile-name>
execution_mode: <mode>
fallback_reason: <reason-or-none>
tool_use_count: <count>
llm_call_count: <count>
elapsed_seconds: <seconds>
skipped_blank_fields: <count>
skipped_administrative_fields: <count>
deterministic_matches: <count>
batched_evaluations: <count>
review_flags: <flag-list-or-none>
diagnostics:
  <upstream-phase-step>: llm_calls=<count> elapsed_seconds=<seconds>
  [phase_5_evidence_workspace] phase_5_total (aggregate): llm_calls=<count> elapsed_seconds=<seconds>
  [phase_6_evidence_evaluation] crosswalk_evaluation (leaf): llm_calls=<count> elapsed_seconds=<seconds>
  [uat_run] uat_run_total (aggregate): llm_calls=<count> elapsed_seconds=<seconds>
```

Exit code `0` requires the artifacts mandated by `analysis.output_mode` to be written. In
`production`, both full debug artifacts and the trace print as `not_written_by_output_mode`, and the
active run directory should contain only `evaluated_form_evidence_crosswalk_index.json` and
`evaluated_form_evidence_crosswalk.md`. In `audit_minimal`, omitted full debug artifacts print as
`not_written_by_output_mode`.
Console output must not print form values, evidence snippets, raw page text, prompt content, or raw
model responses. Evidence snippets, when produced, are artifact-only and must remain bounded to
cited source pages/spans.

Phase 6.5 keeps the same `evaluate <source_path>` command and artifact family while adding tuning
counters. UAT review should compare runtime, LLM calls, tool calls, blank-field skips,
administrative-field skips, deterministic matches, batch count, support-status distribution, and
limit-pressure flags against the Phase 6 baseline. The optimized run should exclude configured
administrative/contact/routing fields from the evaluated crosswalk and should avoid exhausting the
configured tool-call maximum under the default example config.

Reviewer-facing crosswalk artifacts should use generic review flags with plain-English definitions.
The compact `evaluated_form_evidence_crosswalk_index.json` and Markdown table should not expose
internal phase names such as `phase4_crosswalk_unclear`; those internal diagnostic flags remain in
the full evaluated crosswalk JSON and evaluation trace for developer audit.

Phase 6.5 also caches active-run page text during a single evaluation run. Reusing a page across
multiple form fields should not consume another configured tool call, while audit entries may still
record cache hits in `uat_review` and `debug_full`.

## UAT Findings Log

Use this section to preserve phase-exit observations that affect interpretation of CLI UAT output
but do not yet require immediate implementation changes.

### Phase 4: `doc08294920260513101420.pdf`

During Phase 4 CLI UAT, pages 2 and 7 were classified as `prior_authorization_form`, but reviewer
inspection confirmed they are physician notes. Page 2 is a physician addendum and page 7 is a
complete physician note.

Phase 4 behaved correctly by limiting PA form extraction to configured page/image request limits and
emitting `pa_form_text_pages_omitted_by_limit` and `pa_form_vision_pages_omitted_by_limit`. The
finding should be treated as an upstream page-classification quality issue, not a Phase 4 extraction
defect.

Disposition: defer prompt/model tuning and page-classification refinement until additional PA packet
samples are available.

### Phase 6.5: `doc08294920260513101420.pdf`

Phase 6.5 tuning UAT preserved the Phase 6 artifact family and improved the live local-model
baseline. Compared with the Phase 6 branch baseline of `1185.21s`, `tool_use_count: 200`, and
`tool_limit_or_scope_denial`, the tuned run completed in `584.10s` with `tool_use_count: 68`,
`llm_call_count: 28`, `skipped_blank_fields: 39`, and `deterministic_matches: 6`.

The optimized run produced the evaluated crosswalk artifacts and, after administrative-field
pruning, excludes configured administrative/contact/routing fields from the evaluated crosswalk.
Support-status distribution changed from the earlier LLM-driven baseline,
which is expected because deterministic matching, administrative pruning, and reduced candidate context alter which fields
receive LLM judgment. Additional prompt/model tuning should wait for more approved packet samples.
