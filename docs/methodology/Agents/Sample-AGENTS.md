# Repository Guidelines

## Methodology Authority

Follow `docs/methodology/constitution/gendev.md` for
documentation-first development, traceability, phase boundaries, test planning, and as-built
close-out. 

When creating or revising project documents, use the relevant local skill in
`docs/methodology/dev-skills/`, for example `vision-framing.md`, `prd-author.md`,
`architecture-spec-author.md`, `phase-build-planner.md`, `tactical-implementation-planner.md`,
`ai-construction-directive-builder.md`, `governance-security-spec.md`, or
`traceability-matrix.md`. 

The canonical project security and governance authority is
`docs/project/security-governance/governance-security-spec.md`. Do not treat chat history as build
authority when a methodology or skill document applies.

# Security & Configuration Tips

secrets, retention, audit, or lifecycle movement must conform to
`docs/project/security-governance/governance-security-spec.md`.

#  Commit & Pull Request Guidelines

This repository has little commit history, so use concise imperative commit messages such as
`Add OCR client scaffold`. Pull requests should describe the changed pipeline stage, list tests
run, call out PHI/security implications, and mention any config or dependency changes.

# For Python   
Build, Test, and Development Commands

Use `uv` for dependency and environment management.

```bash
uv sync --all-extras
uv run benecard-pa --config config/app.example.yaml config-check
uv run benecard-pa --config config/app.example.yaml init-db
uv run pytest
uv run ruff check .
```

Use `uv add <package>` for new Python dependencies. Do not use `pip install` to mutate this
project environment. PDF parsing is based on PyMuPDF. OCR uses the macOS/system `tesseract`
binary plus the Python `pytesseract` wrapper.

## Coding Style & Naming Conventions

Target Python `3.13`. Use 4-space indentation, type annotations for public boundaries, and
small modules with clear responsibility. Prefer dataclasses or typed models for structured data.
Keep PHI-sensitive paths explicit in names, for example `source_path`, `processed_path`, and
`failed_path`. Ruff is the linting tool; keep code passing `uv run ruff check .`.

## Testing Guidelines

Tests use `pytest` and should be named `tests/test_*.py`. Add focused tests for config parsing,
file lifecycle behavior, idempotency, SQLite persistence, schema validation, OCR routing, and LLM
client boundaries. Files in `docs/project/reference/clinical-samples/` are approved non-PHI
clinical reference samples and may be used for unit, integration, and UAT fixtures. New fixtures
must be generated synthetic files, formally de-identified files, or explicitly approved non-PHI
reference samples; never commit patient identifiers, extracted PHI, or LLM responses containing PHI.
This project uses the CLI as the primary phase-exit UAT and systems-integration harness; follow
`docs/project/testing/cli-uat-harness.md` when adding user-observable phase behavior.

