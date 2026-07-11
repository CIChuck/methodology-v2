# Combined G1-G4 Framing: CSV Cleanup Helper

Status: Accepted
project: csv-cleanup-helper

## Non-Authoritative Example Boundary

This file is example evidence only. It is not active authority for a cloned project.

## Preserved G1 Vision Content

A local operator needs a tiny CLI that normalizes common CSV header variants, removes fully blank
rows, and writes a separate cleaned file so the original input stays intact.

Success is observable when the fixture input produces the expected cleaned output and invalid input
fails with a clear nonzero error.

## Preserved G2 Requirements And Criteria

REQ-C1-001: Normalize supported header variants.

Observable criterion: Given a CSV with `Item Name`, `Qty`, and `Location`, the tool writes
`item_name,quantity,location` in the output header.

REQ-C1-002: Remove fully blank rows.

Observable criterion: Given a CSV containing a row where every cell is blank after trimming, the
output omits that row.

REQ-C1-003: Missing input fails clearly.

Unwanted behavior: If the input path does not exist, the command must not create the output file and
must return a nonzero status with `input file not found` on stderr.

REQ-C1-004: Input is never overwritten.

Unwanted behavior: If input and output paths are the same, the command must fail with nonzero status.

## Preserved G3 Architecture Assumptions

The implementation is a single Python standard-library CLI. It performs local file IO only. It has
no service boundary, network client, credential use, persistence layer, or background process.

Verification specification:

| Criterion ID | Source requirement | Required proof |
| --- | --- | --- |
| VER-C1-001 | REQ-C1-001, REQ-C1-002 | Fixture comparison succeeds. |
| VER-C1-002 | REQ-C1-003 | Missing input returns nonzero and expected stderr. |
| VER-C1-003 | REQ-C1-004 | Same input/output path returns nonzero. |

## Preserved G4 Governance And Security Assumptions

Only non-sensitive operator-supplied CSV fixtures are in scope. Sensitive data, production use,
external integrations, persistent storage, or destructive writes require reclassification before
continuing.
