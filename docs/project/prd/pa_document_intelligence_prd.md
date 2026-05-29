# Product Requirements Document: Prior Authorization Document Intelligence Pipeline

**Product name:** Prior Authorization Document Intelligence Pipeline  
**Version:** Draft v0.4  
**Date:** 2026-05-20  
**Primary users:** Pharmacy benefits manager operations staff, clinical reviewers, prior authorization analysts, and system administrators  
**Target runtime:** Python 3.13  
**Canonical governance/security authority:** `docs/project/security-governance/governance-security-spec.md`  
**Primary objective:** Convert incoming prior authorization PDFs, scanned PDFs, fax-generated PDFs, and standalone images into high-quality parsable text, create an auditable packet digest of every page and component, decompose prior authorization packets into their component documents, and use configurable LLM prompts to produce clinician-ready summaries, structured evidence outputs, and page-cited mappings from PA form fields to supporting evidence.

---

## 1. Executive Summary

The product will monitor a network storage intake directory, referred to as the **Dropbox**, for incoming prior authorization documents. When a PDF or image arrives, the system will trigger an ingestion pipeline that determines whether the document is text-based, scanned, fax-generated, image-only, or mixed. It will extract text directly when possible, apply configured image-to-text extraction when required, preserve page-level metadata, and produce a normalized document representation suitable for LLM review.

Before form extraction or summarization, the system will create a **packet digest**: an auditable page-by-page inventory that records each original page number, extraction method, OCR/text status, image-to-text strategy, selected text source, likely page type, classification confidence, page signals, compact page/component summaries, artifact paths, and grouped packet components. This digest becomes the stable map used by decomposition, evidence crosswalk, review output, troubleshooting, and audit workflows.

The LLM review will not autonomously approve or deny prior authorization requests. It will generate a structured summary, evidence checklist, and form-to-evidence crosswalk to support a clinician or authorized reviewer in making the final determination.

Many packets contain a physician-completed prior authorization form and accompanying physician notes. The system must not assume the PA form is always the first two pages. It should identify and separate packet components, treating the PA form and physician notes as mandatory components and treating fax cover sheets, labs, medication history, prescription records, and other documents as optional supporting components.

Because these documents will contain protected health information, the system must be designed with auditability, access control, encryption, PHI minimization, and HIPAA-aligned safeguards.

Once the document has been successfully parsed, text-extracted, digested, decomposed, analyzed, validated, written to configured artifacts, and persisted according to configuration, the original source file will be moved into a **processed** subfolder within the Dropbox. Failed documents will remain outside the processed folder or be moved into a configurable failed/error folder.

---

## 2. Problem Statement

Prior authorization requests for pharmaceuticals often arrive as PDFs, faxed forms, scanned clinical notes, prescription records, and supporting documentation. These documents may be poorly formatted, image-based, handwritten, partially completed, duplicated, out of order, or missing required evidence.

PBM staff and clinicians need a repeatable way to:

1. Detect new submissions as soon as they arrive.
2. Extract usable text from both native PDFs and fax/scanned PDFs.
3. Identify the document type and relevant drug/category.
4. Identify the PA form and physician notes within the packet.
5. Create a packet digest that inventories every page and maps likely page/component types.
6. Apply the correct prompt and evidence checklist.
7. Map PA form fields or questions to supporting, conflicting, missing, or unclear evidence in physician notes plus configured supporting documents.
8. Summarize clinically relevant facts.
9. Highlight missing, conflicting, or low-confidence evidence.
10. Store the pipeline output in file artifacts, and in SQLite when SQLite persistence is enabled.
11. Maintain an audit trail of source files, prompts, model version, output, confidence, errors, and processing history.
12. Move successfully processed source files into a processed subfolder so the Dropbox root remains operationally clean.

The product should also be designed as a bridge from fax/PDF workflows toward future structured prior authorization workflows.

---

## 3. Goals and Non-Goals

### 3.1 Goals

| Goal | Description |
|---|---|
| Automated intake | Monitor a configured Dropbox folder and trigger processing when supported files arrive. |
| Robust document parsing | Support native-text PDFs, scanned PDFs, faxed PDFs, mixed text/image PDFs, and standalone images. |
| Image-to-text extraction and normalization | Convert document contents into clean, page-aware, parsable text using native extraction, Tesseract, LLM vision extraction, or configured hybrid/compare mode. |
| Packet digest | Create an auditable page-by-page inventory with extraction strategy, selected text source, OCR/vision metadata, page-type, compact summaries, and artifact metadata. |
| Packet decomposition | Identify mandatory and optional packet components while preserving original page numbers. |
| Evidence crosswalk | Map PA form fields/questions to supporting evidence pages, contradictions, missing evidence, and confidence. |
| Configurable LLM review | Use externally maintained prompts, likely YAML, mapped to document/drug types. |
| Model flexibility | Use YAML-configured LiteLLM profiles so hosted frontier models, private-network endpoints, proxy-backed models, and local open-source models can be switched without rewriting the application. |
| Human-in-the-loop review | Generate summaries and evidence checklists for clinicians, not final autonomous clinical determinations. |
| Persistent artifacts | Write output summaries and structured JSON artifacts to an external target folder, with optional SQLite persistence. |
| Source lifecycle management | Move successfully processed files into a processed subfolder and optionally move failed files into a failed/error subfolder. |
| Traceability | Store source file hash, processing status, image-to-text path, prompt version, model version, timestamps, and outputs. |
| Retry and reprocessing | Allow failed or outdated documents to be reprocessed safely and idempotently. |

### 3.2 Non-Goals for MVP

| Non-Goal | Rationale |
|---|---|
| Fully automated approval or denial | Clinical and payer policy decisions require governed human review. |
| Full claims adjudication | The system summarizes and extracts evidence; it does not replace PBM adjudication systems. |
| Provider-facing portal | Intake is file-system based in MVP. |
| EHR integration | Future roadmap item. |
| Direct CMS prior authorization API integration | Future roadmap item; MVP handles fax/PDF workflows. |
| Model fine-tuning | Prompt iteration and model routing come first. |
| Handwriting guarantees | Handwriting recognition may be attempted but should not be guaranteed without validation. |

---

## 4. Users and Personas

| Persona | Needs |
|---|---|
| Clinical reviewer | Needs a concise summary of the request, supporting clinical evidence, missing documentation, contradictions, and whether the request appears ready for review. |
| PBM operations analyst | Needs automated processing status, error handling, searchable outputs, and a clear view of incomplete or failed submissions. |
| System administrator | Needs configurable paths, model settings, prompt files, database location, logs, lifecycle folders, and monitoring. |
| Prompt engineer / clinical policy analyst | Needs to edit prompt templates and document-type rules without changing Python code. |
| Compliance / audit reviewer | Needs evidence of who/what processed each document, when, with which model and prompt, and what output was produced. |

---

## 5. Core Workflow

### 5.1 Happy Path

1. Provider or upstream fax/PDF service deposits a file into the configured Dropbox folder.
2. Folder watcher detects a new file event.
3. System waits until the file is stable and fully written.
4. System validates file type, size, permissions, and duplicate hash.
5. System creates an ingestion record in the configured persistence layer, using file artifacts and SQLite when enabled.
6. PDF parser determines whether pages contain extractable text, images, or both.
7. Native text is extracted directly.
8. Image-only or low-text pages are rasterized for the configured image-to-text strategy.
9. Text is extracted through Tesseract, LLM vision, hybrid fallback, or compare mode according to configuration, then normalized into a canonical document representation.
10. Page classifier identifies likely packet components and page ranges.
11. Packet digest builder creates a page-level and component-level digest for the packet, including compact summaries when sufficient native or image-derived text is available.
12. Packet decomposer separates the physician-completed PA form, physician notes, and optional supporting documents.
13. Form field extractor identifies PA form fields, questions, answers, and required-evidence items.
14. Analysis orchestrator uses the packet digest to retrieve only the pages/components needed for each analysis step.
15. Evidence workspace accumulates extracted form fields, candidate evidence, page citations, confidence scores, unresolved items, and intermediate summaries.
16. Evidence crosswalk maps each PA form item to supporting, conflicting, missing, or unclear evidence with original source page references.
17. Final document classifier reconciles page-level, component-level, and form-field signals to identify the document type, drug category, and prompt profile.
18. LLM request is assembled with digest-derived context, evidence workspace contents, selected page/component text, component map, form fields, selected prompt, and structured output schema.
19. LiteLLM routes the call to the configured model endpoint, either directly or through a configured proxy.
20. LLM output is validated against the expected JSON schema.
21. System assembles the final review artifact from validated LLM output plus system-generated digest, trace, configuration, and lifecycle metadata.
22. System writes output artifacts to the configured output folder.
23. System saves structured output, metadata, and processing status to file artifacts and SQLite when enabled.
24. System moves the original source file to the configured `processed` subfolder inside the Dropbox.
25. System records the final processed file path in file metadata and SQLite when enabled.
26. Clinician reviews the summary and makes the final authorization decision outside or downstream of this pipeline.

### 5.2 Failure Path

If parsing, OCR, LLM vision extraction, image-to-text comparison, page classification, packet digest creation, packet decomposition, form field extraction, analysis orchestration, evidence workspace updates, evidence crosswalk generation, classification, LLM review, output writing, source movement, or configured persistence fails, the system must:

- Mark the document status as `failed`.
- Preserve the original file and intermediate artifacts where allowed.
- Write a machine-readable error record.
- Support retry by document ID or source file path.
- Avoid duplicate processing when a file event fires more than once.
- Move or copy failed outputs into a configured error/quarantine folder when enabled.
- Never move failed documents to the `processed` subfolder.

---

## 6. Functional Requirements

### 6.1 File Intake and Folder Monitoring

| ID | Requirement | Priority |
|---|---|---|
| FR-001 | The system shall monitor a configurable Dropbox directory for new files. | P0 |
| FR-002 | The system shall support PDF, JPEG, PNG, TIFF, and common fax-image formats when available through the imaging stack. | P0 |
| FR-003 | The system shall ignore unsupported file extensions unless configured to quarantine them. | P0 |
| FR-004 | The system shall wait for file stability before processing, using file size, modified timestamp, and lock/access checks. | P0 |
| FR-005 | The system shall compute a SHA-256 hash of each input file to support deduplication and auditability. | P0 |
| FR-006 | The system shall support manual reprocessing by file path or document ID. | P1 |
| FR-007 | The system shall support both event-based watching and periodic directory reconciliation to catch missed events. | P0 |
| FR-008 | The system shall explicitly ignore lifecycle subfolders such as `processed`, `failed`, `error`, `archive`, and `in_progress`. | P0 |

Folder monitoring implementation options include Python packages such as `watchfiles`, `watchdog`, or a polling fallback. The MVP should prefer event-based watching with periodic reconciliation because network shares can occasionally miss or delay events.

### 6.2 Document Parsing

| ID | Requirement | Priority |
|---|---|---|
| FR-009 | The system shall distinguish native-text PDFs from scanned/image-only PDFs. | P0 |
| FR-010 | The system shall extract text from native-text PDFs page by page. | P0 |
| FR-011 | The system shall detect pages with insufficient text and route them to configured image-to-text extraction. | P0 |
| FR-012 | The system shall render PDF pages to images for OCR or LLM vision extraction when needed. | P0 |
| FR-013 | The system shall extract embedded images from PDFs when useful for OCR or model input. | P1 |
| FR-014 | The system shall preserve page numbers, source file path, extraction method, and confidence metadata where available. | P0 |
| FR-015 | The system shall support standalone images as first-class inputs. | P0 |
| FR-016 | The system shall normalize extracted text by removing obvious OCR/extraction noise while preserving clinically meaningful content. | P0 |
| FR-017 | The system shall store raw extracted text and normalized text separately. | P1 |
| FR-131 | The system shall support a YAML-configured image-to-text extraction strategy for low-text PDF pages, scanned/faxed pages, and standalone images. | P0 |
| FR-132 | Supported image-to-text strategies shall include `tesseract`, `llm_vision`, `hybrid`, and `compare`. | P0 |
| FR-133 | Tesseract shall remain the default baseline image-to-text engine for MVP unless configuration explicitly selects another strategy. | P0 |
| FR-134 | The `llm_vision` strategy shall route through LiteLLM using a task-specific `image_text_extraction` model profile that supports vision. | P0 |
| FR-135 | The `hybrid` strategy shall run Tesseract first and invoke LLM vision only when configured thresholds or page-type rules indicate that additional extraction is needed. | P0 |
| FR-136 | The `compare` strategy shall run both Tesseract and LLM vision for evaluation and persist comparison metadata without silently choosing a winner unless a configured selection rule applies. | P0 |
| FR-137 | Each page shall record selected text source, alternate text source metadata when available, extraction confidence, comparison status, and reviewer flags for material disagreements. | P0 |
| FR-138 | LLM vision extraction shall not send full packets or full PDFs by default; it shall use selected page images or crops within configured image and token limits. | P0 |
| FR-139 | Image-to-text extraction artifacts shall preserve original page numbers and deterministic artifact paths for Tesseract output, LLM vision output, comparison results, and selected normalized text when those artifacts exist. | P0 |
| FR-140 | The fixture evaluation harness should support comparing Tesseract and LLM vision extraction quality for selected de-identified or synthetic samples. | P1 |
| FR-141 | Runtime configuration validation shall reject unsupported image-to-text strategies, image-to-text LLM tasks that are not mapped in `llm.task_profiles`, and vision strategies whose selected profile does not support vision. | P0 |
| FR-142 | Runtime configuration validation shall reject nonpositive parsing text thresholds so low-text and blank-page signaling remains deterministic. | P0 |
| FR-070 | The system shall create a packet digest after parsing/image-to-text extraction and before form extraction or LLM review. | P0 |
| FR-071 | The packet digest shall include one page inventory record for every original packet page. | P0 |
| FR-072 | Each page digest record shall preserve original page number, extraction method, image-to-text strategy, selected text source, OCR/text status, likely page type, page type confidence, page signals, artifact paths, OCR confidence when available, LLM vision confidence when available, and comparison status when available. | P0 |
| FR-073 | The packet digest shall include component records that group page ranges by component type, required/optional status, presence, confidence, and evidence role. | P0 |
| FR-074 | The system shall retain unknown page types in the packet digest rather than dropping or forcing them into known categories. | P0 |
| FR-075 | The packet digest shall be persisted as a machine-readable artifact and referenced from SQLite when SQLite is enabled. | P0 |
| FR-076 | The canonical full packet digest shall be written as a standalone JSON artifact. | P0 |
| FR-077 | When enabled, SQLite shall store the packet digest artifact path, digest version, page count, required component status, and any indexed page/component metadata needed for status or search. | P0 |
| FR-078 | The system shall not rely on SQLite as the only storage location for the full nested packet digest. | P0 |
| FR-079 | The digest shall use original packet page numbers as canonical page identifiers for all downstream references. | P0 |
| FR-080 | Decomposed packet components shall be represented logically by original page references and shall not require physical PDF splitting in MVP. | P0 |
| FR-081 | Each page digest record shall include deterministic artifact paths for generated page image, raw text, normalized text, OCR metadata, LLM vision text, and comparison metadata when those artifacts exist. | P0 |
| FR-082 | The system shall use deterministic output paths for packet digest JSON, review JSON, human summary, page artifacts, and component metadata. | P0 |
| FR-083 | The packet digest shall include a `digest_version` value so future schema changes can be handled safely. | P0 |
| FR-084 | The packet digest shall include digest-level review flags for missing required components, low-confidence pages, unknown pages, image-to-text failures, material extraction disagreements, and other conditions requiring reviewer attention. | P0 |
| FR-102 | The packet digest shall support configurable compact summaries for each page after native text extraction or image-to-text extraction is available. | P0 |
| FR-103 | Each page summary shall be bounded by a configurable maximum length and shall record the summary method used. | P0 |
| FR-104 | Packet component records shall support configurable component-level summaries derived from their member pages. | P0 |
| FR-105 | Page and component summaries shall be treated as retrieval/navigation aids, not authoritative evidence. | P0 |
| FR-106 | Final evidence matches shall still cite original page numbers and source page text or image context where available. | P0 |
| FR-144 | The human-readable packet digest shall include bounded page summaries when page summaries are enabled, while preserving the full machine-readable JSON digest as the authoritative record. | P0 |
| FR-145 | The system shall create a derived packet analysis index artifact from the packet digest to support efficient downstream lookup by page type, component type, candidate evidence page, summary, and text artifact path. | P0 |

Recommended implementation: use PyMuPDF as the primary PDF extraction/rendering library. Tesseract
should be treated as the baseline open-source image-to-text engine for MVP. LLM vision extraction
should be available through LiteLLM as a configurable strategy for selected pages, hybrid fallback,
or fixture comparison. OCRmyPDF remains optional for future preprocessing workflows.

Digest summaries should help the workflow identify candidate packet components and likely
supporting evidence pages. They must not replace source citations in the final form-to-evidence
crosswalk.

The packet analysis index is a derived artifact, not a second source of truth. It must be rebuildable
from `packet_digest.json` plus the active retrieval configuration and should be regenerated whenever
the digest is regenerated.

### 6.3 Packet Decomposition and Form Evidence Crosswalk

| ID | Requirement | Priority |
|---|---|---|
| FR-054 | The system shall identify packet components at the page or page-range level after native or image-derived text extraction. | P0 |
| FR-055 | The system shall treat the physician-completed PA form and physician notes as mandatory packet components. | P0 |
| FR-056 | The system shall not assume that the PA form is always the first page or first two pages of the packet. | P0 |
| FR-057 | The system shall support configurable hints for likely PA form length and placement, such as “usually 1-2 pages,” without making those hints hard requirements. | P1 |
| FR-058 | The system shall treat fax cover sheets, lab results, medication history, prescription records, insurance/member pages, and other supporting documents as optional components. | P0 |
| FR-059 | The system shall preserve original packet page numbers for all decomposed components. | P0 |
| FR-060 | The system shall flag packets missing a required PA form or required physician notes as incomplete and surface that status in the review output. | P0 |
| FR-061 | The system shall extract PA form fields, questions, answers, and required-evidence items where available. | P0 |
| FR-062 | The system shall map each non-administrative extracted PA form field/question to supporting evidence pages when evidence is found. | P0 |
| FR-063 | The system shall identify PA form fields/questions whose support is missing, unclear, contradicted, or low confidence. | P0 |
| FR-064 | The system shall include source page references and confidence values for each form-to-evidence mapping. | P0 |
| FR-065 | The system shall allow configured optional supporting components, such as lab results or medication history, to contribute supporting evidence when clinically relevant. | P0 |
| FR-066 | The system shall retain unknown or unclassified pages rather than forcing every page into a known component type. | P0 |
| FR-146 | The system shall write a standalone machine-readable PA form extraction JSON artifact containing each extracted form component, field/question label, normalized field ID, answer/value, source PA form page, confidence, extraction method, and review flags. | P0 |
| FR-107 | The system shall produce a crosswalk item for every non-administrative extracted PA form field/question, even when evidence is missing or unclear. Configured administrative/contact/routing fields may be excluded from evaluated evidence crosswalk artifacts while remaining present in form extraction artifacts. | P0 |
| FR-108 | Crosswalk support status shall use the controlled values `supported`, `contradicted`, `missing`, and `unclear`. | P0 |
| FR-109 | The crosswalk shall support many-to-many relationships between form fields and evidence pages. | P0 |
| FR-110 | Each supported or contradicted crosswalk item shall include evidence provenance: form field ID or label, form page, supporting page numbers, supporting component types, confidence, and evidence summary. | P0 |
| FR-111 | Each supported or contradicted crosswalk item should include a source text snippet, quote, or text span reference when available from native, OCR, or LLM vision text. | P1 |
| FR-112 | Crosswalk confidence shall account for extraction quality, page/component confidence, retrieval confidence, and evidence match confidence where available. | P0 |
| FR-113 | Contradictions shall be surfaced as first-class crosswalk outcomes and reviewer-facing risks. | P0 |
| FR-114 | The crosswalk shall preserve document evidence support separately from payer policy interpretation and shall not approve or deny a request. | P0 |
| FR-115 | The system shall validate crosswalk items against the structured output schema before including them in the final review artifact. | P0 |
| FR-116 | The LLM may propose evidence matches, but the system shall assemble and validate the final crosswalk artifact. | P0 |

Recommended component types:

- `prior_authorization_form`
- `physician_notes`
- `fax_cover_sheet`
- `lab_results`
- `medication_history`
- `prescription_record`
- `insurance_or_member_info`
- `other_supporting_document`
- `unknown`

Crosswalk construction rules:

- The PA form extraction artifact is the authoritative structured input for crosswalk construction.
  It should be rebuildable from the classified `prior_authorization_form` pages and the active
  `pa_form_extraction` prompt/schema configuration.
- Page and component summaries may be used to retrieve candidate evidence pages, but summaries are
  not final evidence.
- Final crosswalk entries must cite original packet page numbers.
- Supported and contradicted entries should include source text snippets or span references when
  available.
- Missing or unclear entries must still be represented so reviewers can see which PA form fields
  lack reliable support.
- Crosswalk output demonstrates document support only; payer policy criteria remain out of scope
  for MVP.

### 6.4 Document Classification

| ID | Requirement | Priority |
|---|---|---|
| FR-018 | The system shall classify documents into configured document types. | P0 |
| FR-019 | The system shall identify drug or drug class when possible, including GLP-1 requests. | P0 |
| FR-020 | The system shall support fallback classification as `unknown_prior_authorization` when confidence is low. | P0 |
| FR-021 | The system shall allow document-type rules to be maintained externally in YAML. | P0 |
| FR-022 | The system shall allow classifier output to select a prompt profile. | P0 |

Example document types:

- `glp1_prior_authorization`
- `general_medication_prior_authorization`
- `appeal_or_redetermination`
- `clinical_notes_only`
- `prior_authorization_form_only`
- `fax_cover_sheet`
- `lab_results`
- `unknown_prior_authorization`

### 6.5 Analysis Pipeline and Context Management

| ID | Requirement | Priority |
|---|---|---|
| FR-085 | The system shall use the packet digest as the authoritative retrieval index for LLM analysis. | P0 |
| FR-086 | The system shall not send the full packet text to the LLM by default. | P0 |
| FR-087 | The system shall support a bounded tool-assisted analysis mode for multi-page packets. | P0 |
| FR-088 | The system shall use a deterministic analysis orchestrator to control LLM calls, tool access, page retrieval, batching, retries, and stop conditions. | P0 |
| FR-089 | The system shall expose only constrained, read-only digest and page retrieval tools to the LLM, plus controlled evidence-recording operations. | P0 |
| FR-090 | The system shall analyze PA form pages and physician-note/supporting-evidence pages as separate components before final crosswalk synthesis. | P0 |
| FR-091 | The system shall maintain an evidence workspace across analysis steps containing extracted form fields, candidate evidence, page citations, confidence scores, unresolved items, and intermediate summaries. | P0 |
| FR-092 | The system shall reuse the evidence workspace between LLM calls instead of resending all prior page text. | P0 |
| FR-093 | The system shall support page/component batching with configurable page-count and token limits. | P0 |
| FR-094 | The system shall support configurable limits for maximum pages per LLM call, tokens per LLM call, candidate pages per field, tool calls per field, total tool calls, total analysis wall-clock seconds, analysis passes, and retries per step. | P0 |
| FR-095 | The system shall support configurable retrieval strategies, including digest keyword search, component scan, and hybrid retrieval. | P0 |
| FR-096 | The system shall support YAML-configured restrictions on which component types may be searched for supporting evidence. | P0 |
| FR-097 | The system shall require original page citations for every evidence match unless explicitly disabled for a non-production test configuration. | P0 |
| FR-098 | The system shall add reviewer-facing flags when configured context, tool-call, or confidence limits prevent reliable analysis. | P0 |
| FR-099 | The system shall record the effective analysis configuration, analyzed pages, skipped pages, summarized pages, deferred pages, tool-call counts, and context-exhaustion events for each processing run. | P0 |
| FR-100 | The system shall support YAML-configured analysis mode, context limits, loop limits, retrieval settings, and reviewer-flag thresholds. | P0 |
| FR-101 | The system shall support initial classification before decomposition and final classification after decomposition and evidence analysis. | P0 |
| FR-117 | The system shall support LLM tool calling only through the bounded analysis orchestrator. | P0 |
| FR-118 | Tool-callable operations shall be limited to configured document-analysis tools scoped to the active document/run. | P0 |
| FR-119 | The system shall prevent LLM tool calls from accessing arbitrary filesystem paths, shell commands, databases, networks, secrets, or runtime configuration. | P0 |
| FR-120 | The system shall support YAML-configured enablement of tool calling, allowed tool names, and tool-call limits. | P0 |
| FR-121 | The system shall audit tool-call metadata, including tool name, page/component references, run ID, result status, and model profile, without logging raw PHI by default. | P0 |
| FR-122 | Vision-capable LLM analysis shall use digest-selected page images or rendered page crops only when enabled by YAML and supported by the selected task-specific LiteLLM profile. | P0 |
| FR-123 | The system shall not send full packet images or full PDFs to vision models by default. | P0 |
| FR-124 | When the selected task-specific model profile does not support configured tool calling, vision input, or structured output, the system shall use configured fallback behavior or fail with a reviewer-facing error. | P0 |

Classification occurs twice in the pipeline. The initial classifier uses the page inventory and
early extraction signals to route decomposition and prompt selection. The final classifier reconciles
the digest, extracted PA form fields, component map, and evidence workspace before final output.

Recommended analysis modes:

- `single_pass`
- `staged`
- `tool_assisted`

Recommended constrained analysis tools:

- `get_packet_digest(document_id)`
- `list_component_pages(component_type)`
- `get_page_text(page_number)`
- `get_page_image(page_number)`
- `search_packet_text(query, component_type)`
- `get_component_text(component_type)`
- `record_evidence_match(form_field_id, page_number, evidence_summary, confidence)`

The tool-assisted mode must remain bounded and auditable. It is not an open-ended autonomous agent.
The orchestrator, not the LLM, owns iteration limits, allowed tools, component restrictions,
retry behavior, and stop conditions.

### 6.6 Prompt and LLM Review

| ID | Requirement | Priority |
|---|---|---|
| FR-023 | The system shall load prompts from an external YAML file. | P0 |
| FR-024 | The system shall map each document type to a prompt template and structured output schema. | P0 |
| FR-025 | The system shall support model configuration through application YAML and/or LiteLLM-compatible profile settings. | P0 |
| FR-026 | The system shall send selected normalized page/component context and digest-derived evidence workspace context to the selected LLM. | P0 |
| FR-027 | The system should support sending selected page images or rendered page crops to multimodal models when configured and supported. | P1 |
| FR-028 | The system shall request structured JSON output where supported. | P0 |
| FR-029 | The system shall validate LLM output against a schema before saving it as final output. | P0 |
| FR-030 | The system shall store LLM task name, prompt version, model profile, model name, model provider, and inference parameters with each LLM-derived result. | P0 |
| FR-031 | The system shall flag summaries as decision support only. | P0 |

The application should perform native parsing and configured image-to-text extraction before
downstream review. Direct PDF/image model input is optional, capability-gated, and limited to
selected pages or crops rather than full packets by default.

### 6.7 LiteLLM and Model Routing

| ID | Requirement | Priority |
|---|---|---|
| FR-032 | The system shall call LLMs through LiteLLM as the primary model-routing abstraction. | P0 |
| FR-033 | The system shall support direct LiteLLM provider calls and optionally support a LiteLLM proxy when configured. | P0 |
| FR-034 | The system shall support configurable `base_url`, API key, model name, timeout, retries, temperature, and max tokens. | P0 |
| FR-035 | The system shall support local/private-network model endpoints. | P0 |
| FR-036 | The system shall support switching models without code changes. | P0 |
| FR-037 | The system shall log LLM request metadata without logging PHI unless explicitly configured and approved. | P0 |
| FR-067 | The system shall support named LiteLLM model profiles in YAML, including at least one default fallback profile. | P0 |
| FR-068 | The system shall support configurable prompt files, schema files, default prompt keys, and document-type-to-prompt mappings in YAML. | P0 |
| FR-069 | The system shall support model profiles for remote frontier models, local OpenAI-compatible endpoints, and private-network models. | P0 |
| FR-125 | The system shall support YAML-configured LLM task profiles so workflow tasks can use different LiteLLM model profiles. | P0 |
| FR-126 | The system shall support at least the task roles `image_text_extraction`, `page_classification`, `page_summary`, `component_summary`, `pa_form_extraction`, `crosswalk_evaluation`, and `final_review`. | P0 |
| FR-127 | If a task-specific model profile is not configured, the system shall use `llm.default_profile` only when that profile satisfies the task capability requirements. | P0 |
| FR-128 | Each LLM task shall declare or enforce required capabilities such as structured output, tool calling, vision support, and image limits before the LLM call is made. | P0 |
| FR-129 | The system shall support task-scoped prompt mappings so page classification, summaries, form extraction, crosswalk evaluation, and final review can use different prompts when needed. | P0 |
| FR-130 | LLM audit metadata shall include task name, selected profile name, model name, prompt key/version, config hash, and capability flags for each LLM call. | P0 |
| FR-143 | Page classification prompts shall support configurable few-shot examples so packet page type behavior can be tuned without code changes. | P0 |

### 6.8 Output and Storage

| ID | Requirement | Priority |
|---|---|---|
| FR-038 | The system shall write a human-readable summary file to the configured output folder. | P0 |
| FR-039 | The system shall write a machine-readable JSON result file to the configured output folder. | P0 |
| FR-040 | The system shall optionally write raw and normalized extracted text files. | P1 |
| FR-041 | The system shall persist document metadata, processing status, and LLM output to durable file artifacts. | P0 |
| FR-042 | The system shall support SQLite persistence by configuration for queryable processing records, run status, artifact paths, and LLM output. | P0 |
| FR-043 | The system shall use atomic writes for output artifacts. | P0 |
| FR-044 | The system shall support output naming conventions based on timestamp, source filename, hash, and document ID. | P0 |

### 6.9 Source File Lifecycle Management

| ID | Requirement | Priority |
|---|---|---|
| FR-045 | After successful processing, the system shall move the original source file to a configurable `processed` subfolder within the Dropbox. | P0 |
| FR-046 | The system shall move files to the processed folder only after parsing/image-to-text extraction, digest creation, decomposition, analysis, LLM review, output writing, and configured persistence have completed successfully. | P0 |
| FR-047 | The system shall not monitor or reprocess files inside the `processed` subfolder. | P0 |
| FR-048 | The system shall retain the original filename within the configured processed naming convention, such as an optional date prefix plus original filename. | P0 |
| FR-049 | If a naming collision occurs in the processed folder, the system shall append a document ID, timestamp, or file hash to create a unique filename. | P0 |
| FR-050 | The system shall record both the original Dropbox path and the final processed path in file metadata and SQLite when enabled. | P0 |
| FR-051 | Files that fail processing shall not be moved to the processed folder. They shall remain in place or be moved to a configurable `failed` or `error` subfolder, depending on configuration. | P0 |
| FR-052 | The system shall support a configurable retention strategy for processed source files. | P1 |
| FR-053 | The system shall verify file hash after move or copy when operating on network shares or cross-volume paths. | P1 |

Recommended Dropbox folder structure:

```text
/dropbox
  /processed
  /failed
  /in_progress   optional
```

Recommended date-based folder structure for higher volume:

```text
/dropbox/processed/2026/05/13/request_001.pdf
/dropbox/failed/2026/05/13/request_002.pdf
```

Recommended successful lifecycle sequence:

1. Detect file in Dropbox.
2. Confirm file is stable.
3. Compute file hash.
4. Parse document and detect text extraction needs.
5. Extract native text and process low-text/image pages through the configured image-to-text strategy.
6. Build the packet digest and page/component inventory.
7. Decompose the packet into required and optional components.
8. Extract PA form fields and run initial/final classification as configured.
9. Run digest-driven analysis, evidence workspace updates, and form-to-evidence crosswalk.
10. Run LLM review with selected context.
11. Validate LLM output and assemble the final review artifact.
12. Write output artifacts.
13. Save successful processing state to file metadata and SQLite when enabled.
14. Move source file to `dropbox/processed`.
15. Record final processed file path in file metadata and SQLite when enabled.

For a network share, the safest behavior is:

```text
copy to processed temp path -> verify hash -> rename into final path -> delete original
```

If the source and destination are on the same filesystem, a filesystem rename/move is usually preferable. On network shares or cross-volume moves, verification should be enabled.

---

## 7. Proposed Architecture

### 7.1 Components

| Component | Responsibility |
|---|---|
| Folder watcher | Detect new files in Dropbox and enqueue processing jobs. |
| Stability checker | Ensure file copy/write is complete before ingestion. |
| Ingestion service | Validate file, compute hash, create processing record. |
| PDF/image parser | Extract text, page images, metadata, and page-level signals. |
| Image-to-text router | Route low-text/image pages through Tesseract, LLM vision, hybrid, or compare strategy. |
| OCR service | OCR scanned pages, faxed images, and standalone images through Tesseract. |
| LLM vision extractor | Extract text from selected page images/crops through LiteLLM vision-capable profiles. |
| Text normalizer | Clean OCR/extraction artifacts and produce canonical page-aware text. |
| Page classifier | Classify each page into likely packet component types while preserving original page numbers. |
| Packet digest builder | Produce the authoritative page and component inventory used by downstream analysis. |
| Digest summarizer | Produce bounded page and component summaries inside the packet digest after native or image-derived text is available. |
| Packet decomposer | Group pages into mandatory and optional packet components. |
| PA form field extractor | Extract PA form fields, questions, answers, and required-evidence items. |
| Analysis orchestrator | Control staged/tool-assisted analysis, context budgeting, retrieval, batching, retries, and stop conditions. |
| Digest retrieval tools | Provide constrained read-only access to packet digest, page text/images, and component text. |
| Evidence workspace | Persist intermediate form fields, candidate evidence, page citations, confidence, unresolved items, and summaries across LLM calls. |
| Evidence crosswalk generator | Link PA form items to supporting, missing, unclear, or contradictory evidence. |
| Document classifier | Determine document type, drug class, and prompt profile. |
| Prompt manager | Load prompt YAML, resolve templates, track prompt version. |
| LLM client | Call configured models through LiteLLM, with optional proxy or OpenAI-compatible endpoint settings. |
| Output validator | Validate structured response against schema. |
| Artifact writer | Write Markdown/text, JSON, raw text, and error artifacts. |
| SQLite repository | Store processing records, results, errors, and audit metadata when SQLite persistence is enabled. |
| File lifecycle manager | Move successful files to `processed`, failed files to `failed/error`, and record final paths. |
| CLI/admin utility | Reprocess, inspect status, list failures, validate config. |

### 7.2 Pipeline Stages

| Stage | Input | Output |
|---|---|---|
| Watch | Dropbox folder | File event |
| Stabilize | File path | Stable file path |
| Ingest | Stable file | Document record |
| Parse | PDF/image | Page objects, text, image references |
| Image-to-text extraction | Low-text pages/images | Selected text, alternate text metadata, confidence, OCR/LLM vision/comparison artifacts |
| Normalize | Raw extracted text | Canonical text |
| Page classify | Canonical pages | Page-level component labels |
| Build digest | Canonical pages + labels | Packet digest with page inventory and components |
| Decompose | Classified pages | Packet components and page ranges |
| Summarize digest | Packet digest + page/component text | Bounded page and component summaries for retrieval |
| Extract form fields | PA form component | Form fields, answers, required-evidence items |
| Retrieve candidates | Packet digest + form fields | Candidate evidence pages and component excerpts |
| Analyze batches | Candidate pages + context limits | Evidence observations and intermediate summaries |
| Update workspace | Analysis observations | Evidence workspace state |
| Crosswalk evidence | Form fields + evidence workspace | Page-cited support, contradictions, missing items, confidence |
| Final classify | Digest + form fields + evidence workspace | Document type, drug class, prompt key |
| Prompt | Prompt YAML + selected digest-derived context | LLM request |
| Review | LLM request | Validated structured sections |
| Validate | LLM response | Validated JSON |
| Persist | Result + metadata | Output folder artifacts + SQLite rows when enabled |
| Move source | Successfully processed source file | File in Dropbox `processed` subfolder |

---

## 8. Configuration Requirements

### 8.1 Application Config Example

```yaml
app:
  environment: "dev"
  log_level: "INFO"
  timezone: "America/New_York"

paths:
  dropbox_dir: "/mnt/prior_auth/dropbox"
  processed_dir: "/mnt/prior_auth/dropbox/processed"
  failed_dir: "/mnt/prior_auth/dropbox/failed"
  output_dir: "/mnt/prior_auth/output"
  archive_dir: "/mnt/prior_auth/archive"
  temp_dir: "/mnt/prior_auth/tmp"

watcher:
  provider: "watchfiles"       # watchfiles | watchdog | polling
  recursive: false
  ignored_subfolders:
    - "processed"
    - "failed"
    - "error"
    - "archive"
    - "in_progress"
  stability_wait_seconds: 10
  stability_checks: 3
  reconciliation_interval_seconds: 300

database:
  enabled: true
  sqlite_path: "/mnt/prior_auth/db/pa_pipeline.sqlite"

parsing:
  min_text_chars_per_page: 50
  render_dpi: 300
  ocr_engine: "tesseract"      # tesseract | ocrmypdf
  ocr_languages: ["eng"]
  low_ocr_confidence_threshold: 0.50
  save_page_images: false
  save_raw_text: true
  save_normalized_text: true

image_text_extraction:
  strategy: "tesseract"   # tesseract | llm_vision | hybrid | compare
  default_engine: "tesseract"
  llm_task: "image_text_extraction"
  selected_text_rule: "prefer_tesseract_unless_low_confidence"
  use_llm_when:
    min_tesseract_confidence_below: 0.70
    min_text_chars_below: 50
    page_types:
      - "prior_authorization_form"
      - "lab_results"
  compare_mode:
    enabled: true
    store_comparison_artifact: true
    flag_material_disagreement: true

packet_decomposition:
  required_components:
    - "prior_authorization_form"
    - "physician_notes"
  optional_components:
    - "fax_cover_sheet"
    - "lab_results"
    - "medication_history"
    - "prescription_record"
    - "insurance_or_member_info"
    - "other_supporting_document"
  pa_form_page_count_hint: [1, 2]
  require_form_to_evidence_crosswalk: true

packet_digest:
  enabled: true
  digest_version: "1.0"
  write_json_artifact: true
  include_page_signals: true
  include_page_summaries: true
  include_component_summaries: true
  include_artifact_paths: true
  include_unknown_pages: true
  store_full_digest_in_sqlite: false
  artifact_layout: "document_id"
  page_summary_max_chars: 500
  component_summary_max_chars: 1000
  summary_method: "llm"
  confidence_threshold_for_review_flag: 0.65

analysis:
  mode: "tool_assisted"        # single_pass | staged | tool_assisted
  use_packet_digest: true
  send_full_packet_by_default: false
  context:
    max_pages_per_llm_call: 4
    max_tokens_per_llm_call: 12000
    max_candidate_pages_per_field: 6
    max_page_images_per_llm_call: 2
    include_page_images: false
    include_page_text: true
    include_component_summaries: true
    summarize_intermediate_findings: true
  loop_limits:
    max_tool_calls_per_field: 8
    max_total_tool_calls: 200
    max_total_analysis_seconds: 600
    max_analysis_passes: 3
    max_retries_per_step: 2
  retrieval:
    strategy: "digest_keyword_search"  # digest_keyword_search | component_scan | hybrid
    restrict_evidence_search_to_components:
      - "physician_notes"
      - "lab_results"
      - "medication_history"
    allow_optional_components_as_support: true
  tool_calling:
    enabled: true
    allowed_tools:
      - "get_packet_digest"
      - "list_component_pages"
      - "get_page_text"
      - "get_page_image"
      - "search_packet_text"
      - "get_component_text"
      - "record_evidence_match"
    audit_tool_calls: true
    fail_when_unsupported: false
  review_flags:
    confidence_threshold: 0.70
    require_page_citations: true
    flag_context_exhaustion: true
    flag_missing_required_components: true

llm:
  provider: "litellm"
  default_profile: "clinical_reviewer_local"
  task_profiles:
    image_text_extraction: "clinical_reviewer_local"
    page_classification: "clinical_reviewer_local"
    page_summary: "clinical_reviewer_local"
    component_summary: "clinical_reviewer_local"
    pa_form_extraction: "clinical_reviewer_local"
    crosswalk_evaluation: "clinical_reviewer_local"
    final_review: "clinical_reviewer_local"
  profiles:
    fast_text_classifier:
      model: "openai/gpt-4.1-mini"
      base_url:
      api_key_env: "OPENAI_API_KEY"
      temperature: 0.0
      max_tokens: 1000
      timeout_seconds: 60
      retries: 2
      structured_outputs: true
      supports_vision: false
      supports_tool_calling: false
      max_images_per_request: 0
    clinical_reviewer_local:
      model: "clinical-reviewer-local"
      base_url:
      api_key_env: "LITELLM_API_KEY"
      temperature: 0.0
      max_tokens: 4000
      timeout_seconds: 120
      retries: 2
      structured_outputs: true
      supports_vision: false
      supports_tool_calling: true
      max_images_per_request: 0
    openai_frontier:
      model: "openai/gpt-4.1"
      base_url:
      api_key_env: "OPENAI_API_KEY"
      temperature: 0.0
      max_tokens: 4000
      timeout_seconds: 120
      retries: 2
      structured_outputs: true
      supports_vision: true
      supports_tool_calling: true
      max_images_per_request: 4
    anthropic_frontier:
      model: "anthropic/claude-sonnet-4"
      base_url:
      api_key_env: "ANTHROPIC_API_KEY"
      temperature: 0.0
      max_tokens: 4000
      timeout_seconds: 120
      retries: 2
      structured_outputs: true
      supports_vision: true
      supports_tool_calling: true
      max_images_per_request: 4
    local_openai_compatible:
      model: "openai/local-clinical-reviewer"
      base_url: "http://localhost:8000/v1"
      api_key_env: "LOCAL_LLM_API_KEY"
      temperature: 0.0
      max_tokens: 4000
      timeout_seconds: 120
      retries: 1
      structured_outputs: true
      supports_vision: false
      supports_tool_calling: false
      max_images_per_request: 0

prompts:
  file_path: "./config/prompts.yaml"
  schema_path: "./config/review_schema.json"
  default_prompt_key: "unknown_prior_authorization"
  reload_on_change: false
  prompt_profile_map:
    glp1_prior_authorization: "glp1_prior_authorization"
    unknown_prior_authorization: "unknown_prior_authorization"
  task_prompt_map:
    image_text_extraction: "image_text_extraction"
    page_classification: "page_classification"
    page_summary: "page_summary"
    component_summary: "component_summary"
    pa_form_extraction: "pa_form_extraction"
    crosswalk_evaluation: "crosswalk_evaluation"
    final_review: "glp1_prior_authorization"

file_lifecycle:
  move_successful_files: true
  move_failed_files: true
  processed_naming: "date_prefix"   # original | date_prefix | hash_prefix | document_id_prefix
  failed_naming: "date_prefix"
  create_date_subfolders: true
  verify_hash_after_move: true
  delete_original_after_verified_move: true
  collision_strategy: "append_document_id"  # append_document_id | append_hash | append_timestamp

security:
  redact_logs: true
  store_llm_raw_response: false
  store_llm_request_text: false
  require_output_encryption: false
  allow_public_llm_profiles: false
  allow_raw_llm_response_storage: false
```

Security-sensitive values in this section must conform to
`docs/project/security-governance/governance-security-spec.md`; raw LLM storage and encryption-disabled
output require explicit deployment approval before live PHI use. `config-check` must reject
unsupported `image_text_extraction.strategy` values, nonpositive
`parsing.min_text_chars_per_page` values, unknown image-to-text LLM task names, unapproved public
task-profile routing, raw LLM response storage without approval, and vision extraction strategies
whose selected profile does not declare `supports_vision: true`.

OCR confidence values exposed to page records, digest records, and downstream analysis are
normalized to `0.0`-`1.0`. When Tesseract returns raw confidence on a `0`-`100` scale, the raw value
may be retained separately as OCR raw-confidence metadata for audit and troubleshooting.

### 8.2 Prompt YAML Example

```yaml
version: "2026-05-13"

tasks:
  image_text_extraction:
    description: "Extract page text from a selected page image or crop."
    prompt: |
      Extract all readable text from the selected page image. Preserve line
      breaks where useful for forms or tables. Return structured output with
      extracted text, confidence, unreadable regions, and page-reference metadata.

  page_classification:
    description: "Classify a single packet page or small page batch."
    output_schema: "page_classification_v1"
    few_shots:
      - name: "prior_authorization_form"
        input_excerpt: "Prior Authorization Request Form. Patient information. Prescriber information. Drug requested."
        output:
          page_type: "prior_authorization_form"
          confidence: 0.92
          signals:
            - "contains prior authorization form title"
            - "contains patient and prescriber fields"
      - name: "physician_notes"
        input_excerpt: "Assessment and Plan. History of present illness. Current medications."
        output:
          page_type: "physician_notes"
          confidence: 0.88
          signals:
            - "contains clinical note sections"
            - "contains assessment and plan language"
    prompt: |
      Classify the selected packet page using the configured component labels.
      Return only structured output with page type, confidence, and brief signals.

  page_summary:
    description: "Produce a bounded page summary for digest navigation."
    prompt: |
      Summarize the selected page for packet navigation. Do not treat the summary
      as final evidence. Preserve clinically relevant facts and page references.

  component_summary:
    description: "Produce a bounded component summary from member pages."
    prompt: |
      Summarize the selected packet component from its member pages. Keep the
      output concise and cite original page numbers.

  pa_form_extraction:
    description: "Extract PA form fields, questions, answers, and evidence hints."
    prompt: |
      Extract fields, questions, answers, and evidence requirements from the
      selected prior authorization form pages. Return structured output only.

  crosswalk_evaluation:
    description: "Evaluate PA form fields against cited supporting evidence."
    prompt: |
      Compare each PA form field to candidate evidence pages. Assign support
      status, confidence, citations, and contradiction or missing-evidence flags.
      Do not approve or deny the request.

document_types:
  glp1_prior_authorization:
    description: "GLP-1 medication prior authorization request"
    classifier_keywords:
      - "GLP-1"
      - "semaglutide"
      - "tirzepatide"
      - "liraglutide"
      - "prior authorization"
      - "BMI"
    required_evidence:
      - "Prior authorization request form"
      - "Prescriber information"
      - "Patient identifiers"
      - "Requested medication and dose"
      - "Diagnosis or indication"
      - "Relevant clinical notes"
      - "Weight/BMI or other plan-required clinical criteria when present"
      - "Prior therapies or contraindications when present"
    prompt: |
      You are assisting a pharmacy benefits manager clinician.
      Review the provided packet digest, PA form fields, component map,
      evidence workspace, and selected page/component text for a GLP-1
      prior authorization request.
      Do not approve or deny the request.
      Produce a concise evidence crosswalk, identify missing documents,
      identify contradictions, and list facts that require clinician review.
      Cite original packet page numbers for every evidence match.

      Return only valid JSON matching the provided schema.

  unknown_prior_authorization:
    description: "Fallback prior authorization review"
    prompt: |
      Review the provided packet digest, component map, evidence workspace,
      and selected page/component text for a prior authorization packet.
      Identify the likely request type, medication, prescriber, patient,
      supporting evidence, missing information, and any low-confidence areas.
      Do not make a final approval or denial decision.
      Cite original packet page numbers for every evidence match.
      Return only valid JSON matching the provided schema.
```

---

## 9. Structured Output Schema

The final review JSON is assembled by the system. The LLM may contribute validated structured
sections such as clinical evidence, contradictions, and reviewer-facing summaries, but the packet
digest, analysis trace, configuration metadata, and lifecycle metadata are system-generated and
embedded into the final artifact for auditability.

The final review artifact should look similar to:

```json
{
  "document_classification": {
    "document_type": "glp1_prior_authorization",
    "drug_or_drug_class": "GLP-1",
    "confidence": 0.86,
    "classification_reason": "Text references GLP-1 medication and prior authorization form."
  },
  "request_summary": {
    "patient_name": null,
    "patient_dob": null,
    "prescriber_name": null,
    "requested_medication": null,
    "requested_dose": null,
    "request_type": "initial authorization | renewal | appeal | unknown"
  },
  "packet_digest": {
    "digest_version": "1.0",
    "page_count": 24,
    "pages": [
      {
        "page_number": 1,
        "extraction_method": "ocr",
        "image_text_strategy": "hybrid",
        "selected_text_source": "tesseract",
        "text_status": "ok",
        "page_type": "prior_authorization_form",
        "page_type_confidence": 0.91,
        "page_signals": ["clinical review form", "medication requested", "diagnosis"],
        "page_summary": "PA form page lists requested medication, diagnosis, and prescriber-submitted clinical criteria.",
        "summary_method": "llm",
        "summary_confidence": 0.78,
        "ocr_confidence": 0.84,
        "llm_vision_confidence": null,
        "text_comparison_status": "not_run",
        "page_image_path": "artifacts/doc_123/pages/page_001.png",
        "raw_text_path": "artifacts/doc_123/pages/page_001.raw.txt",
        "normalized_text_path": "artifacts/doc_123/pages/page_001.normalized.txt",
        "ocr_metadata_path": "artifacts/doc_123/pages/page_001.ocr.json",
        "llm_vision_text_path": null,
        "text_comparison_path": null
      }
    ],
    "components": [
      {
        "component_type": "prior_authorization_form",
        "required": true,
        "present": true,
        "pages": [1, 2],
        "confidence": 0.9,
        "evidence_role": "form_source",
        "component_summary": "PA form contains patient identifiers, requested medication, diagnosis, and plan criteria responses.",
        "component_artifact_path": "artifacts/doc_123/components/prior_authorization_form.json"
      },
      {
        "component_type": "physician_notes",
        "required": true,
        "present": true,
        "pages": [3, 4, 5],
        "confidence": 0.88,
        "evidence_role": "supporting_evidence",
        "component_summary": "Physician notes contain diagnosis, medication history, and clinical support for the request.",
        "component_artifact_path": "artifacts/doc_123/components/physician_notes.json"
      }
    ],
    "required_component_status": {
      "prior_authorization_form": "present",
      "physician_notes": "present"
    },
    "review_flags": [
      "low_ocr_confidence_page_008",
      "unknown_pages_present"
    ]
  },
  "packet_components": [
    {
      "component_type": "prior_authorization_form",
      "required": true,
      "pages": [1, 2],
      "confidence": 0.91
    },
    {
      "component_type": "physician_notes",
      "required": true,
      "pages": [3, 4, 5],
      "confidence": 0.88
    }
  ],
  "analysis_trace": {
    "mode": "tool_assisted",
    "effective_config_hash": "sha256-of-analysis-config",
    "analyzed_pages": [1, 2, 4, 5],
    "skipped_pages": [],
    "summarized_pages": [6, 7],
    "deferred_pages": [12],
    "tool_call_count": 14,
    "analysis_pass_count": 2,
    "context_exhausted": false,
    "analysis_timed_out": false
  },
  "form_evidence_crosswalk": [
    {
      "form_field": "Prior therapies tried",
      "form_field_id": "prior_therapies_tried",
      "form_question": "Has the patient tried and failed preferred therapy?",
      "form_page": 1,
      "form_value": "Yes",
      "support_status": "supported",
      "supporting_pages": [4, 5],
      "supporting_component_types": ["physician_notes"],
      "evidence_summary": "Physician notes describe prior therapy history.",
      "source_text_snippets": [
        "Relevant source excerpt or OCR text span from the cited page."
      ],
      "source_span_refs": [
        {
          "page_number": 4,
          "text_artifact_path": "artifacts/doc_123/pages/page_004.normalized.txt",
          "start_char": 120,
          "end_char": 210
        }
      ],
      "ocr_confidence": 0.81,
      "evidence_provenance": {
        "retrieval_method": "digest_keyword_search",
        "validated_against_source": true,
        "used_summary_only": false
      },
      "confidence": 0.82
    }
  ],
  "clinical_evidence": [
    {
      "evidence_type": "doctor_notes",
      "present": true,
      "summary": "Clinical notes appear to be included.",
      "source_pages": [2, 3],
      "confidence": 0.74
    }
  ],
  "missing_or_unclear_items": [
    {
      "item": "Prior authorization form signature",
      "reason": "No clear signature detected in extracted text.",
      "source_pages_checked": [1],
      "confidence": 0.65
    }
  ],
  "contradictions_or_risks": [
    {
      "issue": "Medication name differs between form and notes.",
      "details": "Form references one drug while notes reference another.",
      "source_pages": [1, 4],
      "confidence": 0.72
    }
  ],
  "clinician_review_notes": [
    "Verify plan-specific GLP-1 criteria against the PBM policy.",
    "Confirm whether notes are recent enough for policy requirements."
  ],
  "recommended_next_step": "ready_for_clinician_review | request_missing_info | needs_reviewer_attention",
  "summary_for_reviewer": "Concise natural-language summary here."
}
```

---

## 10. SQLite Data Model

When SQLite persistence is enabled, minimum tables are:

| Table | Purpose |
|---|---|
| `documents` | One row per ingested source file. |
| `document_pages` | Page-level extraction metadata, selected text source, and OCR/vision status. |
| `packet_digests` | One row per generated packet digest artifact and high-level digest status. |
| `packet_components` | Indexed component page ranges and confidence metadata from the digest. |
| `analysis_runs` | Effective analysis configuration, context limits, tool-call counts, and analyzed page metadata. |
| `processing_runs` | One row per processing attempt. |
| `llm_reviews` | Structured output, model metadata, prompt version. |
| `artifacts` | Paths to generated output files. |
| `errors` | Parse/image-to-text/digest/decomposition/classification/analysis/LLM/output/lifecycle failures. |

Recommended `documents` fields:

- `id`
- `source_path`
- `source_filename`
- `sha256_hash`
- `file_size_bytes`
- `mime_type`
- `created_at`
- `detected_at`
- `status`
- `processed_path`
- `failed_path`
- `archive_path`
- `current_run_id`

Recommended `processing_runs` fields:

- `id`
- `document_id`
- `started_at`
- `completed_at`
- `status`
- `parse_status`
- `image_text_status`
- `ocr_status`
- `llm_vision_status`
- `classification_status`
- `llm_status`
- `output_status`
- `file_lifecycle_status`
- `error_id`

Recommended `packet_digests` fields:

- `id`
- `document_id`
- `processing_run_id`
- `digest_version`
- `artifact_path`
- `page_count`
- `required_component_status_json`
- `review_flags_json`
- `created_at`

Recommended `packet_components` fields:

- `id`
- `packet_digest_id`
- `component_type`
- `required`
- `present`
- `pages_json`
- `confidence`
- `evidence_role`
- `component_artifact_path`

Recommended `analysis_runs` fields:

- `id`
- `document_id`
- `processing_run_id`
- `mode`
- `effective_config_hash`
- `analyzed_pages_json`
- `skipped_pages_json`
- `summarized_pages_json`
- `deferred_pages_json`
- `tool_call_count`
- `analysis_pass_count`
- `context_exhausted`
- `analysis_timed_out`
- `created_at`

Recommended `llm_reviews` fields:

- `id`
- `document_id`
- `processing_run_id`
- `document_type`
- `prompt_key`
- `prompt_version`
- `model_provider`
- `model_name`
- `model_config_hash`
- `temperature`
- `structured_output_json`
- `human_summary`
- `created_at`

---

## 11. Non-Functional Requirements

### 11.1 Reliability

| ID | Requirement | Priority |
|---|---|---|
| NFR-001 | The system shall be idempotent by file hash and processing run ID. | P0 |
| NFR-002 | The system shall recover from process restarts without losing unprocessed files. | P0 |
| NFR-003 | The system shall reconcile the Dropbox folder periodically to catch missed file events. | P0 |
| NFR-004 | The system shall not delete source files unless archiving, processed movement, failed movement, or deletion is explicitly configured. | P0 |
| NFR-005 | The system shall support retry of failed LLM calls with bounded retries. | P0 |
| NFR-006 | The system shall avoid reprocessing files in lifecycle subfolders. | P0 |
| NFR-007 | The system shall not mark a document complete until the final source file movement has succeeded or been explicitly skipped by configuration. | P0 |

### 11.2 Performance

| ID | Requirement | Target |
|---|---|---|
| NFR-008 | Native-text PDF extraction | Complete within seconds for typical PA packets under 25 pages. |
| NFR-009 | Image-to-text processing | Tesseract should target under 10 seconds per page at 300 DPI for typical fax pages, hardware dependent; LLM vision extraction uses configured LLM timeouts. |
| NFR-010 | LLM review | Configurable per-call timeout; default 120 seconds. |
| NFR-011 | Analysis orchestration | Configurable total wall-clock timeout; default 600 seconds. |
| NFR-012 | Throughput | MVP should process at least 100 documents/day on a single worker, assuming modest page counts. |

### 11.3 Security and Compliance

Detailed security and governance behavior is canonical in
`docs/project/security-governance/governance-security-spec.md`. The requirements below define product-level
security expectations; implementation plans must use the governance/security spec for enforceable
controls, denial behavior, audit requirements, and security tests.

| ID | Requirement | Priority |
|---|---|---|
| NFR-013 | The system shall treat all source documents and outputs as PHI unless explicitly marked otherwise. | P0 |
| NFR-014 | Logs shall not include full patient text, raw LLM prompts, or raw extracted document content by default. | P0 |
| NFR-015 | Access to config, output, database, archive, processed, failed, and temp folders shall be restricted. | P0 |
| NFR-016 | The system shall support PHI-safe error messages. | P0 |
| NFR-017 | The system shall maintain an audit trail of processing runs. | P0 |
| NFR-018 | Secrets shall be loaded from environment variables or secret stores, not hardcoded YAML. | P0 |
| NFR-019 | Temporary files shall be removed or retained according to a configurable retention policy. | P0 |
| NFR-025 | The system shall conform to the canonical governance/security specification for identity, permission boundaries, tool access, LLM provider governance, audit records, retention, encryption, and negative security tests. | P0 |

### 11.4 Observability

| ID | Requirement | Priority |
|---|---|---|
| NFR-020 | The system shall produce structured logs. | P0 |
| NFR-021 | The system shall expose processing counts by status. | P1 |
| NFR-022 | The system shall record timing for parsing, image-to-text extraction, digest creation, decomposition, analysis, LLM review, output writing, and source movement. | P0 |
| NFR-023 | The system shall record OCR fallback rate, LLM vision extraction rate, compare-mode disagreement rate, and low-confidence extraction rate. | P1 |
| NFR-024 | The system shall record counts of files pending, processed, failed, and retried. | P1 |

---

## 12. MVP Scope

### Included in MVP

- Python 3.13 application.
- Configurable Dropbox folder monitoring.
- PDF and image ingestion.
- Native PDF text extraction.
- Configurable image-to-text extraction for scanned/faxed PDFs and standalone images, with
  Tesseract baseline, optional LLM vision extraction, hybrid fallback, and compare mode.
- Packet digest creation with page-level inventory, page-type mapping, compact summaries, selected
  text source, OCR/vision text status, artifact paths, and component grouping.
- Packet decomposition into mandatory PA form and physician notes components, plus optional supporting components.
- PA form field extraction and page-cited form-to-evidence crosswalk.
- YAML-configured, digest-driven analysis pipeline with bounded context and tool-call limits.
- Prompt YAML loading.
- Document-type prompt selection.
- Task-specific LiteLLM model profile selection for page classification, page/component summaries,
  image text extraction, PA form extraction, crosswalk evaluation, and final review.
- LiteLLM-based LLM calls, with optional proxy or OpenAI-compatible endpoint support.
- Structured JSON output.
- Human-readable summary output.
- Optional SQLite persistence.
- Error handling and retry.
- Successful source file movement to Dropbox `processed` subfolder.
- Optional failed source file movement to Dropbox `failed` or `error` subfolder.
- CLI commands for reprocess/status/config validation.
- Lightweight fixture-based evaluation harness for approved non-PHI clinical reference PDFs/images,
  generated synthetic files, and expected digest/crosswalk outputs.
- Basic audit trail.

### Deferred

- UI dashboard.
- Full EHR integration.
- Full PBM adjudication integration.
- Multi-tenant access control.
- Advanced analytics.
- Human feedback loop for model/prompt evaluation.
- Automated policy rule engine.
- Manual triage workflow and operational work queue.
- CMS prior authorization API support.
- Fine-tuned OCR or LLM models.

---

## 13. Acceptance Criteria

| Area | Acceptance Criteria |
|---|---|
| File detection | When a PDF is copied into Dropbox, the application detects it and creates a processing record. |
| Stability | The application does not process a file until it is fully copied. |
| Native PDF | A text-based PDF is parsed without OCR, and extracted text is saved. |
| Scanned PDF | An image-only PDF is processed through the configured image-to-text strategy and normalized text is saved. |
| Standalone image | A JPEG/PNG/TIFF input is processed through the configured image-to-text strategy and reviewed. |
| Image-to-text compare mode | In compare mode, Tesseract and LLM vision outputs are preserved as separate artifacts, comparison status is recorded, and material disagreements create reviewer-facing flags. |
| Configuration validation | Invalid parsing thresholds, unsupported image-to-text strategies, unknown image-to-text LLM task mappings, unapproved public task-profile routing, unapproved raw LLM response storage, and vision strategies without vision-capable profiles fail during configuration validation. |
| Packet digest | Each packet produces a machine-readable digest that inventories every original page, page type, confidence, extraction method, image-to-text strategy, selected text source, OCR/vision text status, and grouped components. |
| Digest summaries | The packet digest includes bounded page and component summaries when native or image-derived text is available, and those summaries are used only as retrieval aids rather than final evidence. |
| Packet decomposition | A faxed packet is decomposed into required PA form and physician notes components when both are present. |
| Required components | Packets missing the PA form or physician notes are marked incomplete and surfaced in the review output. |
| Context management | LLM analysis uses digest-driven page retrieval and does not send full packet text by default. |
| Tool-assisted analysis | Multi-page analysis respects configured limits for pages, tokens, tool calls, wall-clock runtime, retries, analysis passes, candidate pages, and reviewer-flag thresholds. |
| Form evidence crosswalk | Each extracted PA form field/question that is not excluded by configured administrative/contact/routing pruning is mapped to supporting, contradicted, missing, or unclear evidence with original supporting-evidence page references. |
| Crosswalk provenance | Supported and contradicted crosswalk items include form page, supporting pages, component types, confidence, and source snippet or span reference when available. |
| Crosswalk completeness | Every non-administrative extracted PA form field/question has a crosswalk item, including missing or unclear evidence outcomes. Configured administrative/contact/routing fields remain in form extraction artifacts but are excluded from evaluated evidence crosswalk artifacts to reduce reviewer noise. |
| Crosswalk validation | Crosswalk items validate against the structured output schema before final review artifacts are written. |
| Policy separation | Crosswalk output demonstrates document evidence support only and does not approve or deny the prior authorization. |
| Prompt routing | A GLP-1 prior authorization packet selects the GLP-1 prompt profile. |
| LLM review | Each LLM task uses its configured task-specific model profile or a capability-compatible fallback profile and returns validated structured sections for the final review artifact. |
| Output folder | JSON and human-readable summaries are written to the configured output folder. |
| Persistence | Document metadata, run status, artifacts, lifecycle paths, and LLM output are persisted to file artifacts and SQLite when enabled. |
| Retry | A failed document can be reprocessed without duplicating source records. |
| Audit | Output includes source hash, LLM task name, prompt version, model profile/name, original source path, final processed path, and processing timestamps. |
| PHI-safe logging | Logs do not contain raw patient document text by default. |
| Processed file movement | After a document is successfully parsed, text-extracted, digested, decomposed, analyzed, reviewed, written to output, and saved through configured persistence, the original source file is moved to the configured `processed` subfolder. |
| No reprocessing | Files moved to `processed/` are not picked up again by the Dropbox watcher. |
| Failed files | Files that fail parsing, image-to-text extraction, digest creation, decomposition, classification, analysis, LLM review, validation, output writing, persistence, or source movement are not moved to `processed/`. |
| Collision handling | If a file with the same name already exists in `processed/`, the system writes a uniquely named processed file without overwriting the prior file. |

---

## 14. Key Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Poor fax quality | Tesseract or LLM vision extraction may miss critical evidence. | Track extraction confidence, support hybrid/compare mode, flag low-confidence pages or material extraction disagreements, preserve page images for manual review when configured. |
| Mixed document packets | Wrong prompt or component labels may be selected. | Use page-level classification, packet decomposition, confidence scoring, and reviewer-facing flags. |
| Incomplete page inventory | Downstream review could lose track of source pages or omit unknown pages. | Build a packet digest that includes every original page, including blank, separator, and unknown pages. |
| PA form placement varies | The system may miss the PA form if it assumes fixed pages. | Detect PA form pages by content/layout signals and use page-count hints only as configurable heuristics. |
| Missing mandatory components | A packet without a PA form or physician notes cannot produce a reliable form-to-evidence crosswalk. | Mark the packet incomplete and surface that status rather than producing unsupported conclusions. |
| Context overflow | Sending too much packet content to an LLM can exceed context limits or increase cost. | Use digest-driven retrieval, component batching, evidence workspaces, and YAML-configured page/token limits. |
| Runaway tool loop | Tool-assisted analysis could make excessive calls or repeat unproductive searches. | Enforce YAML-configured tool-call, pass, retry, and candidate-page limits through the deterministic orchestrator. |
| Missed evidence from narrow retrieval | Retrieval may skip relevant physician-note or supporting-document pages. | Use hybrid retrieval options, confidence thresholds, analyzed/skipped page tracking, and reviewer-facing flags on unresolved evidence. |
| Local model lacks vision/PDF support | Direct PDF/image model input may fail. | Keep Tesseract as the default image-to-text baseline; treat multimodal model input as optional and capability-gated. |
| LLM hallucination | Reviewer could be misled. | Require citations to page numbers, structured schema, missing-evidence flags, and “decision support only” labeling. |
| Duplicate file events | Same file processed multiple times. | Hash-based idempotency and processing locks. |
| Network share event misses | Files may not trigger processing. | Periodic reconciliation scan. |
| PHI leakage in logs | Compliance exposure. | Redaction by default; no raw prompt logging unless explicitly enabled. |
| Prompt drift | Outputs change unexpectedly. | Version prompts and store prompt version with each run. |
| Model drift | Results change after model swaps. | Store model name/config hash; maintain evaluation set. |
| SQLite concurrency | Multiple workers could contend. | MVP single worker; future queue/database upgrade for scale. |
| Processed-folder reprocessing loop | Moving a file into `processed/` could trigger another watcher event. | Explicitly ignore lifecycle subfolders. |
| Failed post-processing move | LLM/output may succeed but file move may fail. | Treat source movement as a lifecycle stage, record failure, retry movement separately, and do not mark final status complete until resolved or explicitly skipped. |
| Cross-volume or network-share move behavior | File move may be non-atomic. | Use copy-verify-rename-delete strategy when configured or required. |

---

## 15. Recommended Technical Stack

| Layer | Recommendation |
|---|---|
| Runtime | Python 3.13 |
| Packaging | `uv` |
| PDF parsing | PyMuPDF |
| Image-to-text extraction | Tesseract baseline through Python `pytesseract`; optional LiteLLM vision extraction by configuration; OCRmyPDF optional for future preprocessing workflows |
| Image handling | Pillow/OpenCV optional for preprocessing |
| Folder watching | `watchfiles` primary, `watchdog` or polling fallback |
| LLM gateway | LiteLLM direct provider calls, with LiteLLM proxy optional by configuration |
| LLM client | LiteLLM Python package |
| Config | YAML + environment variables |
| Output | JSON + Markdown/text |
| Persistence | File artifacts with optional SQLite |
| Logging | Structured JSON logs |
| Validation | Pydantic models / JSON Schema |
| Testing | pytest with approved non-PHI clinical reference PDFs/images and generated synthetic fixtures |

---

## 16. References

- Python 3.13 documentation: https://docs.python.org/3/whatsnew/3.13.html
- HHS HIPAA Privacy Rule overview: https://www.hhs.gov/hipaa/for-professionals/privacy/laws-regulations/index.html
- CMS electronic prior authorization overview: https://www.cms.gov/priorities/electronic-prior-authorization/overview
- watchfiles documentation: https://watchfiles.helpmanual.io/
- watchdog package: https://pypi.org/project/watchdog/
- PyMuPDF documentation: https://pymupdf.readthedocs.io/
- Tesseract OCR documentation: https://tesseract-ocr.github.io/tessdoc/
- OCRmyPDF documentation: https://ocrmypdf.readthedocs.io/
- OpenAI PDF file inputs guide: https://platform.openai.com/docs/guides/pdf-files
- OpenAI vision guide: https://platform.openai.com/docs/guides/vision
- OpenAI structured outputs guide: https://platform.openai.com/docs/guides/structured-outputs
- liteLLM documentation: https://docs.litellm.ai/
- liteLLM proxy documentation: https://docs.litellm.ai/docs/simple_proxy

---

## 17. Resolved Decisions and Deferred Questions

| Topic | MVP Decision | Later Phase / Open Item |
|---|---|---|
| Intake location | MVP monitors a configurable filesystem Dropbox directory. SFTP delivery may land files into that directory outside the application. | Native SFTP polling/download adapter can be added later if needed. |
| Accepted file formats | MVP accepts PDF, JPEG, PNG, TIFF, and common fax-image formats supported by the imaging stack. | Additional formats are deferred until encountered in client data. |
| Image-to-text strategy | MVP supports configurable `tesseract`, `llm_vision`, `hybrid`, and `compare` strategies. Tesseract is the default baseline; `compare` mode is primarily for fixture evaluation. | Production defaults should be tuned after comparing extraction quality, cost, latency, and governance constraints. |
| Packet size limits | Use configurable limits. Initial defaults should support at least 100 MB files and 100 pages, while optimizing for typical packets under 25 pages. | Tune limits after reviewing the client test corpus. |
| Source lifecycle | Successful files move to `processed`; failed files remain outside `processed` and may move to `failed` or `error` by configuration. | Separate long-term archive workflows are deferred. |
| Successful file movement | Movement to `processed` is configurable by environment and defaults to enabled. | None. |
| Failed file movement | Failed-file movement is configurable and defaults to enabled for operational cleanliness. | Alerting/work queues are deferred. |
| Folder layout | Date-based `processed` and `failed` subfolders are the recommended default for volume and auditability. | Flat layout remains configurable for small deployments. |
| Processed naming | Default naming should retain the original filename with a date prefix and append document ID/hash/timestamp only for collisions. | Exact naming policy can be tuned per deployment. |
| Processed/failed retention | Retention period is not known for MVP. Preserve files by default unless deletion is explicitly configured. | Formal retention policy should be defined with compliance/operations. |
| Handwriting | MVP does not guarantee handwriting recognition. Suspected handwriting or poor OCR should be flagged for reviewer attention. | Specialized handwriting OCR is deferred. |
| Drug class scope | GLP-1 is the first known class. Unknown/other classes use generic prior authorization handling. | Additional drug classes are deferred until identified by the client. |
| PBM policy criteria | MVP summarizes and crosswalks evidence; it does not apply policy rules or approve/deny requests. | Plan-specific policy rule engine is deferred. |
| Output type | MVP produces both machine-readable JSON and human-readable Markdown/text summaries. | Downstream adjudication payloads are deferred. |
| Patient identifiers | Patient identifiers should be included in reviewer outputs. Logs should still avoid raw patient text by default. | Redaction profiles can be added later if required. |
| Local model vision support | MVP assumes local models may be text-only. Tesseract remains the default local image-to-text baseline. | Multimodal image/PDF input remains optional by model profile. |
| Task-specific model routing | MVP supports task-specific LiteLLM profile mappings for image text extraction, page classification, summaries, PA form extraction, crosswalk evaluation, and final review, with `default_profile` as a capability-gated fallback. | Task profiles should be tuned against evaluation results and cost/latency targets. |
| Public API use | LiteLLM configuration determines whether remote APIs, private endpoints, or local models are used. No public API dependency is hardcoded. | Environment-specific approval for public APIs remains a deployment decision. |
| Artifact/log retention | Retention period for source files, extracted text, LLM outputs, logs, and SQLite records is not yet known. Preserve by default. | Formal retention schedules and cleanup jobs are deferred. |
| Review flags | No manual triage workflow in MVP. Low-confidence, incomplete, context-limited, or unresolved items are surfaced as reviewer-facing flags in JSON/Markdown output and status metadata. | Manual triage workflow and operational queue are deferred. |
| Evaluation harness | MVP should include a lightweight fixture-based evaluation harness using approved non-PHI clinical reference PDFs/images, generated synthetic files, and expected digest/crosswalk outputs. | Larger regression suite and human feedback analytics are later-phase work. |
| Approval criteria | Approval/denial criteria are plan-specific. MVP does not make final determinations. | Automated policy application is deferred. |
| Case IDs | MVP generates its own document/run IDs and should capture external case IDs when detectable. | Formal PBM case-system integration is deferred. |
| Audit requirements | MVP stores LLM task name, prompt version, model profile, config hash, source hash, processing timestamps, and reprocessing history. | Advanced audit reporting is deferred. |
| UI scope | MVP is CLI-first. | Web dashboard is deferred. |
| PA form templates | Required templates are unknown. MVP should support configurable/generic form extraction. | Template-specific extraction profiles are deferred until templates are known. |
| Optional supporting evidence | Default supporting evidence components are physician notes, lab results, and medication history. Other optional components remain classified and available by configuration. | Drug/form-specific evidence component policies can be added later. |
| Confidence thresholds | No manual triage threshold in MVP. Recommended review-flag defaults are `0.65` for packet/page review flags and `0.70` for analysis/evidence confidence flags. | Thresholds should be tuned against the evaluation corpus. |
