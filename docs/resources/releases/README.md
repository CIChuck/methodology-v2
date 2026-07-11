# GenDev Releases

Latest release: 0.5.0-operational-coherence

This index records methodology release identity, status, tag state, and migration guidance. Tag
creation and pushing remain publication actions requiring separate human approval.

| Version | Status | Date | Tag | Ratification evidence | Supersedes | Superseded by | Migration guide |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0.1.0-baseline | Released | 2026-06-10 | `v0.1.0-baseline` observed | `9e2749b` Prepare hardened baseline release | N/A | 0.2.0-phase-loop | Use later release guides as applicable. |
| 0.2.0-phase-loop | Accepted historical release; retrospective tag approved | 2026-06-12 | `v0.2.0-phase-loop` retrospective historical tag | Ratification commit verified: `85b9ec7` Ratify phase loop: stamp 0.2.0-phase-loop, records Accepted | 0.1.0-baseline | 0.3.0-documentation-structure | Use 0.5 migration guide if adopting current strict mode. |
| 0.3.0-documentation-structure | Accepted historical release; retrospective tag approved | 2026-06-17 | `v0.3.0-documentation-structure` retrospective historical tag | Ratification commit verified: `d11c49a` Ratify 0.3.0: release note and decision record | 0.2.0-phase-loop | 0.4.0-verification-first | Use 0.5 migration guide if adopting current strict mode. |
| 0.4.0-verification-first | Accepted historical release; retrospective tag approved | 2026-06-20 | `v0.4.0-verification-first` retrospective historical tag | Ratification commit verified: `23acdd2` Ratify 0.4.0-verification-first | 0.3.0-documentation-structure | 0.5.0-operational-coherence | Use 0.5 migration guide if adopting current strict mode. |
| 0.5.0-operational-coherence | Released | 2026-07-11 | Proposed `v0.5.0-operational-coherence`; not created pending tag approval | `docs/resources/evolution/0.5.0-operational-coherence-execution-log.md` | 0.4.0-verification-first | N/A | `docs/resources/releases/0.5.0-operational-coherence-migration.md` |

## Historical tag policy

`v0.1.0-baseline` is the original observed published tag. The 0.2 through 0.4
tags are retrospective historical tags approved during 0.5 remediation closeout
for release-history consistency after exact ratification commits were verified.
Do not infer permission to create the 0.5 release tag from these retrospective
historical tags.
