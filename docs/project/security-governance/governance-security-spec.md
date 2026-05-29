# Governance and Security Specification

**Status:** Draft canonical authority  
**Date:** 2026-05-21  
**Project:** Benecard PA Document Intelligence  

## Source Authority

This specification is governed by:

- `docs/project/vision/pa_document_intelligence_vision.md`
- `docs/project/prd/pa_document_intelligence_prd.md`
- `docs/project/architecture/pa_document_intelligence_architecture.md`
- `docs/project/traceability/pa_document_intelligence_traceability_matrix.md`
- `docs/methodology/constitution/gendev.md`

This is the canonical security and governance document for the project. The PRD and architecture
define product and system behavior; this document defines required security-sensitive behavior,
governance boundaries, denial behavior, audit expectations, and verification requirements.

## Governance Principles

1. Treat all source documents, derived text, page images, packet digests, summaries, LLM context,
   LLM responses, output artifacts, SQLite rows, and logs containing document metadata as PHI unless
   explicitly proven otherwise.
2. Use least privilege for filesystem, model, tool, and persistence access.
3. Preserve page provenance and auditability for every processing run.
4. Do not allow the system or an LLM to approve, deny, or adjudicate a prior authorization request.
5. Keep LLM behavior bounded by configured task profiles, prompts, schemas, context limits, and
   tool access rules.
6. Prefer metadata-only logs by default. PHI-bearing logs, prompts, requests, and raw responses
   require explicit configuration and deployment approval.
7. Any security-sensitive behavior must have a test, inspection command, or operational checklist.

Files under `docs/project/reference/clinical-samples/` are explicitly approved non-PHI clinical
reference samples. They may be used for unit tests, integration tests, and user acceptance testing.
New documents must not be added to that folder unless they are confirmed non-PHI.

## Identity and Actor Model

| Actor | Identity | Allowed Role |
|---|---|---|
| Operator | OS user or service account running the CLI/process | Configure and run local processing. |
| Clinician or authorized reviewer | External business identity, outside MVP UI scope | Review outputs and make final decisions outside the app. |
| Application process | Local process identity | Execute configured pipeline steps for the active run only. |
| LLM task | Task name plus prompt version and selected model profile | Produce advisory structured outputs or bounded image-to-text extraction within configured boundaries. |
| LiteLLM provider/proxy/local endpoint | Configured model profile | Return model output; never receives arbitrary tool or filesystem access. |
| Tesseract subprocess | Local OCR binary | OCR configured page images only. |

MVP identity is process-level, not multi-user. Multi-tenant identity, role-based UI access, and
reviewer work queues are deferred features.

## Permission and Authorization Boundaries

- The application may read only configured intake/source files and generated per-run artifacts.
- The application may write only configured output, temp, archive, processed, failed, and optional
  SQLite paths.
- The LLM must never receive filesystem paths as authority to read files. It may receive selected
  text/images assembled by the orchestrator.
- Tool calls are authorized only for the active document/run and configured allowed tool names.
- Cross-document retrieval is denied unless a future PRD/architecture update explicitly authorizes
  it.
- Direct shell, network, arbitrary database, secret, config, and unrestricted filesystem access from
  LLM tool calls is prohibited.
- Public LLM API use is deployment-approved behavior. If not approved, configuration must use a
  private proxy or local/private-network model profile.

Missing authorization must fail closed with a PHI-safe error, audit event, and reviewer-facing flag
when the run can continue safely.

## Policy and Approval Model

- The application produces document intelligence and evidence support only.
- The system must not recommend approval, denial, step therapy outcome, medical necessity outcome,
  or payer policy determination.
- A human clinician or authorized business reviewer makes final PA decisions outside the MVP.
- Configuration changes that enable public model endpoints, raw prompt/request storage, raw response
  storage, PHI-bearing logs, or disabled encryption controls require deployment approval.
- Runtime config validation must reject public LLM task-profile routing and raw LLM response storage
  unless explicit approval flags are enabled for the deployment.
- Runtime config validation must reject unsupported image-to-text strategies, unknown image-to-text
  LLM task mappings, nonpositive parser text thresholds, and vision image-to-text strategies whose
  selected model profile does not support vision.
- Policy-engine behavior, adjudication, and automated triage are deferred.

## Data Sensitivity Model

| Data Class | Examples | Required Handling |
|---|---|---|
| Source PHI | Incoming PDFs/images, fax packets | Access-controlled paths; no logs; hash for audit. |
| Derived PHI | OCR text, LLM vision text, normalized text, rendered page images, page crops, extraction comparisons | Store only when configured; treat as sensitive artifacts. |
| Digest PHI | Page signals, page summaries, component summaries, artifact paths | Durable artifact; cite source pages; do not publish broadly. |
| LLM PHI | Request context, selected page text/images, raw responses | Metadata-only logging by default; storage controlled by config. |
| Audit metadata | Run IDs, hashes, model/profile/prompt names, timestamps, durations | Loggable when it excludes patient text and direct identifiers. |
| Secrets | API keys, proxy credentials, local model credentials | Environment variables or secret store only; never YAML or logs. |
| Approved non-PHI reference samples | Files under `docs/project/reference/clinical-samples/` | Valid for unit, integration, and UAT fixtures; new additions require non-PHI confirmation before commit. |

Patient identifiers are PHI and must not appear in logs unless explicitly approved for a controlled
environment.

## Secrets Handling

- YAML may contain only environment variable names such as `OPENAI_API_KEY`.
- The settings loader must not print secret values.
- Secret resolution failures must name the missing variable, not its value.
- Secrets must not be included in packet digests, review artifacts, SQLite records, error artifacts,
  or audit logs.

## LLM, Tool, and External-System Rules

- All normal LLM calls must route through the LiteLLM client boundary.
- Every LLM call must resolve a task name to a configured task profile or capability-compatible
  default profile.
- The first model-backed digest phase may allow only `page_classification`, `page_summary`, and
  `component_summary` calls; that narrow allowance must not imply approval for tool calling,
  crosswalk evaluation, final review generation, or vision inputs.
- Tool calling, structured output, and vision/image inputs must be capability-gated before the call.
- Page images or crops may be sent only when YAML enables image context or LLM vision
  image-to-text extraction, and the selected task profile supports vision with sufficient image
  capacity.
- LLM vision image-to-text extraction must use the `image_text_extraction` task or an explicitly
  configured equivalent task and must preserve selected page scope, original page number, prompt
  version, model profile, output artifact path, and confidence metadata.
- Parser and image recognizer failures must emit PHI-safe errors and must not chain or log
  source-path-bearing library exceptions in user-facing paths.
- Full packet text, full PDFs, and full packet image sets must not be sent to an LLM by default.
- Allowed tools are document-analysis tools only, including digest reads, component page listing,
  selected page text/image retrieval, packet text search, component text retrieval, and controlled
  evidence observation recording.
- Tool results must preserve original page numbers and active run scope.
- Unsupported tools, cross-run access, unsupported profile capabilities, or excessive tool counts
  must be denied or stopped according to configured failure behavior.

## Audit Record Model

Each processing run should record:

- document ID, run ID, source hash, source path metadata, and lifecycle paths;
- config hash and relevant security configuration values;
- parser/image-to-text methods, page counts, OCR fallback, LLM vision extraction, compare-mode
  disagreements, selected text sources, and low-confidence flags;
- packet digest version and artifact path;
- LLM task name, selected profile, model name, provider, prompt key/version, capability flags, and
  inference parameters;
- tool-call metadata: tool name, active run, page/component references, status, count, and duration;
- analyzed, skipped, deferred, and summarized pages;
- crosswalk item counts and support statuses;
- error/failure status using PHI-safe messages;
- final artifact paths and timestamps.

Audit records must not include raw page text, full prompts, full request context, raw model output,
or patient identifiers by default.

## Failure, Retry, Recovery, and Deactivation

- Failed or incomplete runs must remain auditable and must not be silently discarded.
- Source files must not move to `processed` until required output, persistence, and lifecycle steps
  have succeeded.
- Failed files may move only to configured failed/quarantine folders.
- Retry/reprocess operations must create traceable run history and must not overwrite prior audit
  records.
- If model capability checks fail, the run must use configured fallback behavior or fail with a
  reviewer-facing flag.
- If a model profile, prompt, tool, provider, or endpoint is revoked, configuration must disable or
  remove it; subsequent runs must fail closed if no authorized fallback exists.

## Retention, Encryption, and Storage

- Production retention periods for source files, page artifacts, output artifacts, logs, temp files,
  and SQLite records are an open compliance/operations decision.
- MVP config may expose retention and encryption flags, but production deployment must define exact
  retention and encryption-at-rest requirements before live PHI use.
- Temp files must be deleted or retained according to explicit configuration.
- File-only mode remains valid; SQLite is optional and must not become required for secure operation.

## Threat Scenarios and Required Controls

| Threat Scenario | Required Control |
|---|---|
| PHI appears in logs | PHI-safe logger tests; metadata-only defaults; redaction review. |
| LLM tool attempts arbitrary file access | Tool registry denylist/allowlist tests; active-run scoping. |
| Public model is used without approval | Deployment config review; allowed-provider checks. |
| Full packet sent to model by drift | Context and image-to-text assembly tests proving selected digest-derived context/page images only. |
| Cross-document evidence leakage | Active document/run scoping tests. |
| Secret value written to logs/artifacts | Secret redaction tests and config lint. |
| Model without vision receives images | Capability-gating negative tests. |
| LLM vision extraction used without approval | Config/governance check for provider approval and selected task profile capability. |
| Extraction methods materially disagree | Compare-mode artifact and reviewer-flag tests. |
| Summary used as final evidence | Crosswalk provenance tests requiring original page citations. |
| System implies approval/denial | Policy-separation tests on output wording/schema. |
| Failed run appears successful | Completion-gate and lifecycle tests. |

## Security Test Requirements

Phase plans must include applicable tests for:

- PHI-safe logging and error handling;
- missing or unresolved secrets;
- denied LLM tool names and denied cross-run access;
- unsupported tool-calling, vision, structured-output, and image-capacity capabilities;
- no full-packet-by-default LLM context;
- LLM vision image-to-text extraction using selected pages only;
- compare-mode disagreement flags and selected text source metadata;
- source lifecycle completion gates;
- prompt/request/raw response storage flags;
- output schema policy separation;
- audit metadata completeness without PHI leakage;
- optional SQLite disabled mode.

## CLI and Inspection Requirements

The CLI should support or preserve a path for:

- `config-check` validation of profile references, security flags, lifecycle paths, and required
  packet components;
- process/reprocess/status inspection without printing PHI;
- run artifact discovery by document ID or run ID;
- verification that configured model routes and task profiles are allowed for the deployment.

## Documentation Close-Out Requirements

Any implementation phase that touches intake, parsing/image-to-text artifacts, digest storage,
analysis, LLM routing, tool calling, output artifacts, persistence, lifecycle movement, logging,
secrets, or retention must reconcile:

- this governance/security spec;
- PRD requirements and acceptance criteria;
- architecture security boundaries;
- traceability rows and test evidence;
- phase and tactical build plans;
- AGENTS.md if contributor instructions change.

## Open Governance Decisions

| Decision | Current Status |
|---|---|
| Exact production retention periods | Open compliance/operations decision. |
| Whether public LLM APIs are allowed for live PHI | Open deployment decision. |
| Encryption-at-rest requirements by environment | Open compliance/operations decision. |
| Final reviewer identity and approval workflow | Deferred outside MVP UI/work queue. |
| Role-based access model | Deferred until multi-user UI or service deployment exists. |

## Accuracy Pass

- **Identity model:** MVP is process-level; multi-user identity is intentionally deferred.
- **Permission boundaries:** Filesystem and tool boundaries are explicit and fail closed.
- **Denial behavior:** Missing authorization, unsupported capabilities, and revoked profiles deny or
  fail with auditable PHI-safe errors.
- **Auditability:** Required metadata is defined without requiring PHI-bearing logs.
- **Implementation risk:** Retention, public LLM approval, and encryption-at-rest remain open
  deployment decisions and must be resolved before live PHI production use.
