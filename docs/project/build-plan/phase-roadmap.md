# PA Document Intelligence Phase Roadmap

**Status:** Draft roadmap  
**Date:** 2026-05-20  
**Source authority:** `docs/project/prd/pa_document_intelligence_prd.md`, `docs/project/architecture/pa_document_intelligence_architecture.md`, `docs/project/security-governance/governance-security-spec.md`, `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`  
**Methodology:** `docs/methodology/constitution/gendev.md`

## Purpose

This roadmap describes the full intended build arc for the PA Document Intelligence Pipeline. It is
not a tactical implementation plan. Each phase should receive its own bounded build plan and tactical
implementation plan before code generation begins for that phase.

## CLI UAT Harness

For this project, phase exits should be proven through the CLI wherever the phase produces
user-observable behavior. The canonical project-specific reference is
`docs/project/testing/cli-uat-harness.md`. Phase build plans and tactical implementation plans
should identify the command, expected artifacts, PHI-safe console output, exit-code behavior, and
explicitly forbidden side effects for that phase.

## Phase 1: Fixture Manifest, Parser Foundation, and Provisional Packet Digest

Phase 1 establishes the first testable vertical slice. It creates the fixture manifest structure,
loads generated synthetic fixtures and approved non-PHI clinical reference sample metadata,
recognizes supported file types, extracts native PDF text through PyMuPDF, preserves page numbers,
identifies low-text/image-text-needed pages, and creates a provisional packet digest with one
inventory record per original page.

This phase does not run image-to-text extraction, classify packet components, call LLMs, use tool
calling, process images with vision models, or create evidence crosswalks. The primary acceptance
signal is that native PDFs and standalone images produce stable page-aware records and a provisional
digest that never drops a page.

## Phase 2: Image-to-Text Execution and Page Artifact Generation

Phase 2 adds actual image-to-text execution for scanned PDFs, fax-generated image pages, low-text
pages, and standalone images. Tesseract remains the baseline default. The phase should also define
the configurable strategy boundary for `tesseract`, `llm_vision`, `hybrid`, and `compare` modes so
fixture evaluation can compare Tesseract output with selected LiteLLM vision extraction where
governance and model capabilities allow it.

This phase still avoids LLM analysis and final clinical interpretation. Its goal is reliable
page-level text availability and artifact production. The primary acceptance signal is that scanned
or image-only fixtures produce configured image-to-text output, selected text-source metadata,
confidence metadata, page artifacts, comparison artifacts when enabled, and updated digest records
without losing original page identity.

## Phase 3: Page Classification, Packet Decomposition, and Digest Summaries

Phase 3 identifies what each page likely contains and groups pages into logical packet components.
It introduces the first narrow LiteLLM-backed task path for page classification, page summaries, and
component summaries. Configured prompts, including few-shot examples, classify likely PA form pages,
physician notes, fax covers, labs, medication history, prescription records, insurance/member pages,
unknown pages, and other supporting documents while preserving original page numbers. It also adds
bounded page and component summaries to the packet digest once native or image-derived text is
available.

This phase does not extract PA form fields or decide whether evidence supports specific PA form
questions. The primary acceptance signal is that packets can be inventoried into required and
optional components, missing required components create reviewer-facing flags, summaries remain
bounded, unknown pages are retained, and the three Phase 3 LLM tasks resolve through LiteLLM
profiles and prompt configuration without hard-coded model or prompt behavior.

## Phase 3.5: Digest Review and Analysis Index Hardening

Phase 3.5 hardens the digest output without starting PA form field extraction or evidence
crosswalk generation. It improves reviewer usability by rendering bounded page summaries in the
human-readable digest and creates a derived `packet_analysis_index.json` artifact for downstream
lookup by page type, component type, candidate evidence page, summary, and text artifact path.

This phase preserves `packet_digest.json` as the canonical packet inventory. The analysis index is
rebuildable from the packet digest plus active analysis retrieval configuration and must not become
a second source of truth. The primary acceptance signal is that a Phase 3 digest run writes
`packet_digest.json`, `packet_digest.md`, and `packet_analysis_index.json`, with the CLI reporting
all three artifacts and no Phase 4 form extraction or crosswalk behavior introduced.

## Phase 4: PA Form Field Extraction and Evidence Crosswalk

Phase 4 extracts fields, questions, answers, and required-evidence hints from the
physician-completed PA form and writes a standalone `pa_form_extraction.json` artifact. That
artifact should preserve each extracted form component, normalized field ID, label/question,
answer/value, source PA form page, confidence, extraction method, and review flags. Phase 4 then
creates the first system-owned form-to-evidence crosswalk, mapping each extracted PA form item to
supporting, contradicted, missing, or unclear evidence in physician notes and configured supporting
documents.

The LLM may later help propose evidence, but this phase should establish the deterministic crosswalk
contract, output schema validation, provenance requirements, confidence fields, contradiction
handling, and missing/unclear outcomes. PA form extraction and crosswalk evaluation are distinct LLM
tasks and may use different model profiles. The primary acceptance signal is that every extracted PA
form field is present in the PA form extraction artifact and receives a crosswalk item with original
page references or an explicit missing/unclear status.

## Phase 5: Digest-Driven Analysis Orchestration

Phase 5 builds the bounded analysis orchestrator and evidence workspace. It uses the packet digest
as the retrieval index, batches pages/components under YAML limits, tracks analyzed/skipped/deferred
pages, stores candidate evidence observations, records context-exhaustion events, and avoids sending
the full packet text to the LLM by default.

This phase is about orchestration and context management, not broad autonomous agency. The primary
acceptance signal is that analysis can select relevant page/component context from the digest,
maintain an evidence workspace across steps, enforce configured limits, and emit reviewer-facing
flags when analysis is incomplete or constrained.

## Phase 6: LiteLLM Crosswalk Evaluation and Vision-Gated Analysis

Phase 6 expands the LiteLLM foundation introduced in Phase 3 into crosswalk evaluation and
vision-gated analysis. It adds `crosswalk_evaluation` execution, validates structured LLM responses,
and writes evaluated crosswalk artifacts. It uses orchestrator-owned active-run tool operations to
assemble bounded context before LLM calls. Provider-native model tool-call loops and `final_review`
execution remain deferred.

This phase must preserve the architecture boundary that LLM outputs are advisory intermediate
signals. The system owns final crosswalk assembly, schema validation, provenance enforcement, and
artifact writing. The primary acceptance signal is that crosswalk evaluation resolves the correct
task profile, is capability-gated, active-run tool use cannot access arbitrary resources, selected
context is auditable, and unsupported capabilities fail or fall back predictably.

If LLM vision image-to-text extraction is deferred from Phase 2, Phase 6 must complete the LiteLLM
vision boundary for the `image_text_extraction` task before any `llm_vision`, `hybrid`, or `compare`
strategy is enabled outside fixture evaluation.

## Phase 6.5: Tuning and Optimization

Phase 6.5 tunes the Phase 6 crosswalk evaluation path before final review packaging begins. It
reduces avoidable LLM/tool work through blank-field gates, candidate evidence ranking, structured
value prechecks, priority-based budgets, batched evaluation, early-exit rules, and performance
metadata.

This phase does not change the evaluated crosswalk artifact family or introduce final approval,
denial, adjudication, lifecycle, watcher, or persistence behavior. The primary acceptance signal is
that the CLI `evaluate` UAT still writes the Phase 6 artifacts while reducing tool-limit pressure and
runtime against the approved reference packet.

## Phase 7: Output Artifacts, Persistence, and Audit Trail

Phase 7 completes the durable output layer. It writes machine-readable review JSON,
human-readable Markdown/text summaries, packet digest JSON, error artifacts, analysis traces, and
optional raw/normalized text artifacts with atomic writes. It also indexes run status, artifact
paths, digest metadata, and review metadata in SQLite when enabled while keeping file artifacts as
the durable source of truth.

This phase should make file-only mode fully valid. The primary acceptance signal is that a completed
run can be understood from its artifact folder even when SQLite is disabled, and when SQLite is
enabled it serves as a query index rather than the only store for nested review content.

## Phase 8: Source Lifecycle, CLI Operations, and Reprocessing

Phase 8 wires successful and failed processing outcomes into source-file lifecycle behavior and
operator commands. It moves or copies successful source files to configured `processed` locations
only after outputs and configured persistence succeed, handles failed files according to
configuration, verifies hashes when configured, avoids lifecycle-folder reprocessing, and supports
CLI commands for status, reprocess, config validation, and targeted processing.

This phase turns the pipeline into an operator-usable CLI workflow, but it still does not require a
long-running watcher. The primary acceptance signal is that source files move only after successful
completion gates, failed files never enter `processed`, and reprocessing is idempotent by document
ID or source path.

## Phase 9: Dropbox Watcher and Reconciliation Loop

Phase 9 adds the continuous intake loop. It monitors the configured Dropbox directory, ignores
lifecycle folders, waits for file stability, enqueues supported files, reconciles periodically to
catch missed events, and prevents duplicate processing caused by repeated file events or restart
conditions.

This phase should use the already-stable parser, digest, artifact, and lifecycle services rather
than redefining pipeline behavior. The primary acceptance signal is that copied files are processed
once after they become stable, missed files are caught by reconciliation, lifecycle folders are
ignored, and process restarts do not lose pending work.

## Phase 10: Evaluation Harness, Hardening, and Pilot Readiness

Phase 10 prepares the system for a controlled pilot. It expands the fixture corpus, adds golden
expected digest/crosswalk outputs, measures parser/image-to-text/analysis behavior, verifies PHI-safe logging,
documents operational configuration, captures known limitations, and produces pilot-readiness
evidence for the client.

This phase should not introduce major new product scope. It is for hardening, evaluation, and
documentation close-out. The primary acceptance signal is that the project can run against the
approved test corpus with repeatable results, clear failure reporting, documented residual risks,
and traceability from requirements to tests and artifacts.

## Cross-Cutting Governance and Security Work

Governance and security requirements span all phases and should not wait until the end. The
canonical governance/security specification is
`docs/project/security-governance/governance-security-spec.md`. It must be cited by phase plans before
implementing LLM tool calling, vision analysis, production persistence, pilot workflows, or any
other security-sensitive behavior. That specification defines PHI handling, secret management,
audit records, allowed model routes, retention expectations, tool access boundaries, logging
policy, denial behavior, and negative security tests.

## Roadmap Accuracy Pass

- **Phase boundary clarity:** Early phases stabilize documents and page identity before clinical
  evidence analysis.
- **Deferred-feature control:** image-to-text extraction, decomposition, page classification,
  crosswalk, LLM review, tool calling, lifecycle, and watcher behavior are separated into distinct
  phases, with Phase 3 owning only the narrow LiteLLM classification/summary slice.
- **Acceptance visibility:** Each phase includes a primary acceptance signal.
- **CLI UAT visibility:** Phase exits should include a CLI-based UAT/system-integration surface
  where practical for this project.
- **Security visibility:** Governance/security work is called out as cross-cutting and required
  before LLM/tool/vision-heavy phases.
- **Implementation readiness:** Each phase still requires a detailed build plan and tactical
  implementation plan before code generation.
