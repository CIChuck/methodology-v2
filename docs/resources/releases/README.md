# GenDev Releases

Latest published release: 0.5.0-operational-coherence
Active release candidate: 1.0.1

This index records methodology release identity, status, tag state, and adoption guidance. Tag
creation and pushing remain publication actions requiring separate human approval.

| Version | Status | Date | Tag | Ratification evidence | Supersedes | Superseded by | Adoption guide |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0.1.0-baseline | Released | 2026-06-10 | `v0.1.0-baseline` observed | `9e2749b` Prepare hardened baseline release | N/A | 0.2.0-phase-loop | Use later release guides as applicable. |
| 0.2.0-phase-loop | Accepted historical release; retrospective tag approved | 2026-06-12 | `v0.2.0-phase-loop` retrospective historical tag | Ratification commit verified: `85b9ec7` Ratify phase loop: stamp 0.2.0-phase-loop, records Accepted | 0.1.0-baseline | 0.3.0-documentation-structure | Use 1.0 adoption guide for current projects. |
| 0.3.0-documentation-structure | Accepted historical release; retrospective tag approved | 2026-06-17 | `v0.3.0-documentation-structure` retrospective historical tag | Ratification commit verified: `d11c49a` Ratify 0.3.0: release note and decision record | 0.2.0-phase-loop | 0.4.0-verification-first | Use 1.0 adoption guide for current projects. |
| 0.4.0-verification-first | Accepted historical release; retrospective tag approved | 2026-06-20 | `v0.4.0-verification-first` retrospective historical tag | Ratification commit verified: `23acdd2` Ratify 0.4.0-verification-first | 0.3.0-documentation-structure | 0.5.0-operational-coherence | Use 1.0 adoption guide for current projects. |
| 0.5.0-operational-coherence | Published | 2026-07-11 | `v0.5.0-operational-coherence` observed at `2841f02` | `docs/resources/evolution/0.5.0-operational-coherence-execution-log.md` | 0.4.0-verification-first | 1.0.1 | Use 1.0 adoption guide for current projects. |
| 1.0.0 | Superseded candidate; never published | 2026-07-11 | No tag; publication never occurred | `docs/resources/evolution/1.0.0-production-release-execution-log.md` | 0.5.0-operational-coherence | 1.0.1 | Use 1.0 adoption guide for current projects. |
| 1.0.1 | Production candidate; publication pending | 2026-07-11 | Planned `v1.0.1` | `docs/resources/evolution/1.0.1-production-release-execution-log.md` | 1.0.0 | N/A | `docs/resources/releases/1.0.1-adoption.md` |

## Historical tag policy

`v0.1.0-baseline` is the original observed published tag. The 0.2 through 0.4
tags are retrospective historical tags approved during 0.5 remediation closeout
for release-history consistency after exact ratification commits were verified.
The 0.5 release tag was approved separately and created after the 0.5 remediation
branch merged to `master`.
