# Current C1 Example: CSV Cleanup Helper

Status: Non-Authoritative Current Example
methodology_version: 0.5.0-operational-coherence
blast_radius_class: C1
declared_gate: G9
real_code: true

This example is a contained, reversible local CLI. It processes only operator-supplied
non-sensitive CSV files, writes a separate output file, performs no network calls, uses no
credentials, and has no production side effect.

Reclassification triggers: sensitive data, production automation, external integrations,
persistent storage, destructive writes, or irreversible workflow effects move this out of C1.

The example includes a compact current lifecycle trail:

- combined G1-G4 framing with C1 observable criteria and unwanted behavior;
- strict example manifest and combined-gate decision;
- G5.0 phase plan and one complete G5.1.1 through G5.1.3 phase ladder;
- stable tactical task IDs;
- construction directive and issued build prompt;
- test/UAT plan and implementation evidence;
- independent review and `not_required` remediation disposition;
- traceability, as-built closeout, and non-deployment G8-to-G9 terminal record.

Acceptance criteria are observable:

- inconsistent supported headers are normalized;
- fully blank rows are removed;
- missing input fails with nonzero status and a clear message;
- the command never overwrites the input path.

Validation:

```bash
./docs/resources/examples/current/c1-csv-cleanup/tests/run.sh
```

Expected result: exit status `0`. The test includes missing-file and same-input-output negative
cases that expect nonzero command status.

This example is not active authority for a new clone. Its command output is evidence only for this
example directory.
