# Phase 1 Test And UAT Plan

Status: Accepted
project: csv-cleanup-helper

Automated checks:

- positive fixture cleanup equals `fixtures/expected.csv`;
- missing input returns nonzero and reports `input file not found`;
- same input/output path returns nonzero.

Manual UAT is N/A because the operator-visible workflow is the CLI command itself and the fixture
script exercises it end to end.
