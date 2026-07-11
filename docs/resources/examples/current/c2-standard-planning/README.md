# Current C2 Example: Standard Planning Stop

Status: Non-Authoritative Current Example
methodology_version: 0.5.0-operational-coherence
blast_radius_class: C2
declared_gate: G5.3
real_code: false

This example demonstrates the honest stopping point for a C2 product that has separate vision, PRD,
architecture, governance/security, phase plan, tactical task IDs, construction directive, and test
plan, but no implemented product code. It must not claim `verified` traceability rows, phase exit,
implementation acceptance, deployment readiness, or G9 closeout.

C2 acceptance criteria use EARS-style statements where useful, including unwanted behavior for error
and abuse paths. G3 includes a verification specification with stable criterion IDs before
implementation planning relies on it.

Because no real implementation ships in this example, `real_code: false` and there are no runtime
validation commands. The correct next action is implementation under an accepted construction
directive, not retrospective evidence fabrication.
