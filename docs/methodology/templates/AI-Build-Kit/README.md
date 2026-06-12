# AI Build Kit

Status: Initial Draft  
Purpose: A focused, reusable process for creating phase build artifacts for AI-assisted software implementation.

## Purpose

This kit defines a repeatable process for constructing the four core phase artifacts used to drive AI-assisted code generation:

```text
1. Phase X Build Plan
2. Phase X Tactical Implementation Plan
3. Phase X Construction Directive
4. Phase X Build Prompt
```

The kit is intentionally narrow. It is not a full software-delivery constitution. It is the practical phase-generation workflow used to turn a roadmap and project methodology into implementation-ready AI build instructions.

## Folder Structure

```text
docs/AI-Build-Kit/
  README.md
  phase-build-artifact-process.md
  templates/
    phase-build-plan-template.md
    phase-tactical-implementation-plan-template.md
    phase-construction-directive-template.md
    phase-build-prompt-template.md
  directives/
    phase-build-plan-authoring-directive.md
    phase-tactical-plan-authoring-directive.md
    phase-construction-directive-authoring-directive.md
    phase-build-prompt-authoring-directive.md
    full-phase-artifact-sequence-directive.md
```

## Source Authority Model

Every phase artifact should be generated from explicit authority:

```text
Phase Roadmap
Project methodology documents
PRD or product requirements, when available
Architecture specifications
Governance/security specifications, when applicable
Prior phase build plans
Prior tactical plans and construction directives
Prior code review and remediation reports, when applicable
Deferred feature backlog, when applicable
```

If source authority is missing, the AI should state the gap and either ask for clarification or proceed with explicitly labeled assumptions.

## Artifact Chain

```text
Phase Roadmap
  -> Phase X Build Plan
     -> Phase X Tactical Implementation Plan
        -> Phase X Construction Directive
           -> Phase X Build Prompt
              -> AI coding agent implementation
```

## Quality Standard

Each artifact must:

```text
preserve phase scope
prevent feature drift
identify non-goals
identify deferred work
define test expectations
include security/governance requirements when applicable
include documentation close-out requirements
identify unresolved questions
perform an accuracy pass
```

## Test Coverage Standard

Phase artifacts should instruct builders to target at least:

```text
90% meaningful test coverage for new or materially changed code
```

If 90% is not practical, the implementation agent must explain why and identify compensating verification.

## Recommended Use

Use the directives in order:

```text
1. directives/phase-build-plan-authoring-directive.md
2. directives/phase-tactical-plan-authoring-directive.md
3. directives/phase-construction-directive-authoring-directive.md
4. directives/phase-build-prompt-authoring-directive.md
```

Use `directives/full-phase-artifact-sequence-directive.md` when asking an AI to guide the full phase-document sequence.

## Note On Earlier Template Reference

The phase build plan should use:

```text
templates/phase-build-plan-template.md
```

The code review report template is not appropriate for authoring a build plan. It should only be used after code has been generated and needs review.
