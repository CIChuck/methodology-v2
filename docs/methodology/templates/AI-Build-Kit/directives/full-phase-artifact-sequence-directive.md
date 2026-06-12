# Full Phase Artifact Sequence Directive

Use this directive when asking an AI to guide the complete document sequence for a phase.

## Directive

```text
Guide the creation of Phase X implementation artifacts using the AI Build Kit.

The required artifact sequence is:

1. Phase X Build Plan
2. Phase X Tactical Implementation Plan
3. Phase X Construction Directive
4. Phase X Build Prompt

Use these templates:

- docs/AI-Build-Kit/templates/phase-build-plan-template.md
- docs/AI-Build-Kit/templates/phase-tactical-implementation-plan-template.md
- docs/AI-Build-Kit/templates/phase-construction-directive-template.md
- docs/AI-Build-Kit/templates/phase-build-prompt-template.md

Do not skip steps.

Before creating each artifact:

- confirm required source authority exists;
- identify missing or contradictory authority;
- ask blocking clarifying questions if needed.

After creating each artifact:

- perform an accuracy pass;
- identify unresolved blockers;
- do not proceed to the next artifact unless the current artifact is accepted.

Do not implement code.

Preserve phase boundaries, non-goals, deferred items, testability, security/governance requirements, and documentation close-out throughout the sequence.
```
