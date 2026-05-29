# Phase 3.5 Build Plan: Digest Review and Analysis Index Hardening

**Status:** Implemented draft  
**Source authority:** `docs/project/prd/pa_document_intelligence_prd.md`, `docs/project/architecture/pa_document_intelligence_architecture.md`, `docs/project/security-governance/governance-security-spec.md`, `docs/project/testing/cli-uat-harness.md`, `docs/project/build-plan/phase-roadmap.md`

## Purpose

Phase 3.5 converts the Phase 3 digest from a technically correct artifact into a more useful review
and downstream-analysis package. The phase keeps `packet_digest.json` as the canonical packet
inventory, adds bounded summaries to the human-readable Markdown digest, and writes a derived
`packet_analysis_index.json` artifact that later crosswalk phases can use for efficient lookup.

## Scope

- Render a `Page Summaries` section in `packet_digest.md` when page summaries are present.
- Keep Markdown summaries bounded by each page's configured summary limit.
- Write `packet_analysis_index.json` next to `packet_digest.json` and `packet_digest.md`.
- Build the index only from `packet_digest.json` payload plus active `analysis.retrieval`
  configuration.
- Include lookup maps for pages by type, page type by page, summaries by page, text artifact paths,
  component IDs by type, component pages by ID, component summaries by ID, configured evidence
  component types, and candidate evidence pages.
- Report the analysis index path in CLI UAT output.

## Non-Goals

- Do not extract PA form fields.
- Do not create form-to-evidence crosswalk records.
- Do not introduce analysis tools, LLM tool calling, final review, watcher/lifecycle behavior, or
  production persistence.
- Do not treat `packet_analysis_index.json` as canonical truth.

## Rebuild Rule

`packet_analysis_index.json` is disposable and rebuildable. If the digest, prompt configuration,
retrieval configuration, or page/component classification changes, regenerate the digest run and
write a fresh index. Later code may rebuild the index from `packet_digest.json`; it must not require
manual edits or external state.

## Acceptance Criteria

- CLI digest UAT writes `packet_digest.json`, `packet_digest.md`, and `packet_analysis_index.json`
  under the same run artifact directory.
- Console output includes the analysis index artifact path.
- Markdown includes bounded page summaries but does not include full extracted page text.
- The index contains `pages_by_type`, `candidate_evidence_pages`, `page_summary_by_page`, and
  `text_artifact_by_page` lookups.
- Candidate evidence pages honor configured `analysis.retrieval.restrict_evidence_search_to_components`.
- Unit tests verify Markdown summary rendering, index creation, and CLI reporting.
