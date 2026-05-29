# Prior Authorization Document Intelligence Pipeline Vision

**Status:** Aligned to approved PRD  
**Date:** 2026-05-20  
**Project:** Prior Authorization Document Intelligence Pipeline  
**Related authority:** `docs/project/prd/pa_document_intelligence_prd.md`

## Purpose

This document frames the product vision and problem space for a prior authorization document
intelligence pipeline. It exists so requirements, architecture, build plans, tests, and AI-assisted
implementation work can trace back to a stable explanation of why the project exists and what
success means.

## Problem Statement

Prior authorization requests arrive as PDFs, fax-generated packets, scanned pages, clinical notes,
forms, prescription records, and standalone images. These files are often inconsistent, incomplete,
duplicated, poorly scanned, mixed in page order, or difficult to search. Reviewers need usable,
page-aware text and clinician-ready summaries, but current document intake workflows require too
much manual inspection before a reviewer can understand what evidence is present, missing, or
unclear.

The project aims to reduce that manual burden without replacing clinical judgment or payer policy
decision-making.

## Target Users and Operators

- Clinical reviewers who need concise summaries, missing-evidence flags, contradictions, and page
  references.
- PBM operations analysts who need processing status, failure handling, and searchable outputs.
- System administrators who need configurable paths, model settings, logs, database location, and
  lifecycle folders.
- Prompt engineers and clinical policy analysts who need editable prompt profiles without Python
  code changes.
- Compliance and audit reviewers who need traceable processing history.

## User Pain and Opportunity

The current opportunity is to turn unstructured PA document packets into normalized, auditable,
review-ready evidence packages. Success should make the intake folder operationally cleaner,
make extracted evidence easier to inspect, and make failed, incomplete, or low-confidence documents
visible through reviewer-facing flags.

## Desired Outcomes

- Incoming PDFs and images are detected, parsed, normalized, and reviewed consistently.
- Native-text PDFs avoid unnecessary OCR; scanned or low-text pages are routed to OCR.
- Review output identifies likely request type, relevant drug or class, evidence present, evidence
  missing, contradictions, low-confidence areas, and reviewer-facing follow-up considerations.
- Each packet has an auditable digest that inventories every page, packet component, compact
  page/component summaries, artifact paths, and review flags.
- PA form fields are crosswalked to supporting, contradicted, missing, or unclear evidence in
  physician notes and configured supporting documents.
- Outputs are available as human-readable artifacts, machine-readable JSON, and audit records.
- Successfully completed source files move to `processed/`; failed files never do.
- The system remains configurable enough to support local/private models through LiteLLM.

## Success Criteria

- A synthetic native PDF fixture produces page-aware extracted text without OCR.
- A synthetic scanned PDF or image fixture produces OCR-derived text with extraction metadata.
- A GLP-1 prior authorization fixture routes to the GLP-1 prompt profile.
- Structured LLM output validates before being saved as final output.
- File artifacts include source hash, status, prompt version, model name, output paths, lifecycle
  paths, packet digest, and review output; SQLite may index these values when enabled.
- Logs do not include raw patient document text by default.
- Failed documents are marked failed and are not moved to `processed/`.
- `uv run pytest` and `uv run ruff check .` pass for each implementation phase.

## Non-Goals

- Fully automated approval or denial.
- Replacement of PBM adjudication systems.
- Provider-facing portal.
- Direct EHR or CMS prior authorization API integration in the MVP.
- Model fine-tuning.
- Guaranteed handwriting recognition.
- Use of real PHI in test fixtures or examples.

Approved non-PHI clinical reference samples under `docs/project/reference/clinical-samples/` are
valid for unit tests, integration tests, and user acceptance testing.

## Facts

- The target runtime is Python 3.13.
- Dependency management uses `uv`.
- The project has selected PyMuPDF for PDF parsing and rendering.
- OCR uses a system Tesseract install with Python `pytesseract`.
- LLM calls should use LiteLLM as the primary path; a LiteLLM proxy may be configured but is not
  required.
- The current repository contains a scaffold, example config, prompt YAML, SQLite schema,
  traceability matrix, phase roadmap, and phase-specific build plan.

## Assumptions

- MVP intake is file-system based.
- The intake location may be a network share or similar shared folder.
- Initial model review can operate on normalized text before multimodal document review is added.
- File artifacts are authoritative for MVP persistence. SQLite may be enabled as an optional
  single-worker query index.
- Initial fixture data will be synthetic or fully de-identified.

## Constraints

- All source documents and generated outputs must be treated as PHI unless explicitly marked
  otherwise.
- Secrets must come from environment variables or a secret store, not committed YAML.
- File lifecycle behavior must be idempotent and audit-friendly.
- Implementation work should preserve traceability from vision to PRD, build plan, tests, and
  eventual as-built documentation.

## Security and Governance Considerations

The system handles protected health information. Raw document text, OCR output, normalized text,
LLM prompts containing document content, LLM responses, SQLite rows, and output artifacts are
sensitive. Logs must avoid raw patient text by default. Audit records should capture what was
processed, when, with which prompt and model, and what outputs were produced, without exposing
unnecessary PHI.

## Testability Implications

Test data is a first-class dependency. The fixture set should include native PDFs, scanned PDFs,
mixed PDFs, standalone images, unsupported files, duplicate files, and intentionally low-confidence
documents. Tests should verify parsing behavior, OCR routing, packet digest completeness,
page/component summary bounds, evidence crosswalk provenance, classifier routing, schema validation,
artifact writing, persistence, lifecycle moves, failure handling, and PHI-safe logging.

## Risks

- Poor scan or fax quality may produce incomplete OCR text.
- Mixed packets may select the wrong prompt profile.
- LLM output may be incomplete, malformed, or unsupported by a selected model.
- Network folder events may be missed or duplicated.
- Lifecycle moves may fail on cross-volume or network-share paths.
- Prompt or model changes may alter output behavior without obvious operational visibility.
- Real clinical examples may accidentally introduce PHI into fixtures or logs.

## Resolved Decisions and Open Questions

Resolved MVP decisions:

1. File-only mode is valid; SQLite is optional.
2. The PA form and physician notes are mandatory packet components.
3. Fax cover sheets and other supporting documents are optional packet components.
4. Evidence crosswalks map PA form fields to physician notes plus configured supporting documents.
5. Manual triage workflow is deferred; MVP emits reviewer-facing flags.
6. Reviewer outputs may include patient identifiers; logs should avoid raw patient text by default.
7. GLP-1 is the first known drug class; unknown classes use generic PA handling.
8. MVP should include a lightweight fixture-based evaluation harness.

Open deployment and operations questions:

1. Is production LLM use restricted to private/local endpoints, or are public APIs permitted in any
   environment?
2. What retention periods apply to source files, extracted text, outputs, logs, and SQLite records?
3. What exact PA form templates and additional drug classes will appear in the client corpus?
4. What final file size, page count, encryption-at-rest, and fixture corpus limits should production
   enforce?

## Documentation Chain

The architecture specification defines component ownership, data lifecycle, error behavior, trust
boundaries, persistence boundaries, and extension points. The traceability matrix and canonical
governance/security specification now extend that authority so PHI handling, auditability,
retention, model routing, and requirement-to-test coverage are explicit before implementation.
