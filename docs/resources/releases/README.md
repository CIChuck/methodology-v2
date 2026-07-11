# GenDev Releases

Latest release: 0.5.0-operational-coherence

This index records methodology release identity, status, tag state, and migration guidance. Tag
creation and pushing remain publication actions requiring separate human approval.

| Version | Status | Date | Tag | Ratification evidence | Supersedes | Superseded by | Migration guide |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0.1.0-baseline | Released | 2026-06-10 | `v0.1.0-baseline` observed | `9e2749b` Prepare hardened baseline release | N/A | 0.2.0-phase-loop | Use later release guides as applicable. |
| 0.2.0-phase-loop | Accepted historical release; tag not observed | 2026-06-12 | Unknown, do not create without approval | Candidate ratification commit observed by search: `85b9ec7` Ratify phase loop: stamp 0.2.0-phase-loop, records Accepted | 0.1.0-baseline | 0.3.0-documentation-structure | Use 0.5 migration guide if adopting current strict mode. |
| 0.3.0-documentation-structure | Accepted historical release; tag not observed | 2026-06-15 | Unknown, do not create without approval | Candidate ratification commit observed by search: `b7bf61d` Stamp methodology version 0.3.0-documentation-structure | 0.2.0-phase-loop | 0.4.0-verification-first | Use 0.5 migration guide if adopting current strict mode. |
| 0.4.0-verification-first | Accepted historical release; tag not observed | 2026-06-20 | Unknown, do not create without approval | Candidate ratification commit observed by search: `23acdd2` Ratify 0.4.0-verification-first | 0.3.0-documentation-structure | 0.5.0-operational-coherence | Use 0.5 migration guide if adopting current strict mode. |
| 0.5.0-operational-coherence | Released | 2026-07-11 | Proposed `v0.5.0-operational-coherence`; not created pending tag approval | `docs/resources/evolution/0.5.0-operational-coherence-execution-log.md` | 0.4.0-verification-first | N/A | `docs/resources/releases/0.5.0-operational-coherence-migration.md` |

## Historical tag policy

Only `v0.1.0-baseline` was observed locally. Historical tag mappings for 0.2 through 0.4 are
candidate mappings from commit-message and file-history search, not permission to create tags.
If historical tags are desired, present each proposed tag and evidence to the human separately.
