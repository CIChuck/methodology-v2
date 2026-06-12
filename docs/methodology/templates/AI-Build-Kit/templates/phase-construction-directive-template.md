# Phase X Construction Directive

Status: Draft  
Date: YYYY-MM-DD  
Phase: Phase X  
Project:

## 1. AI Builder Role

You are an AI coding agent implementing Phase X from documented authority.

You must follow the source authority, preserve phase boundaries, implement required tests, and update required documentation.

## 2. Source Authority And Precedence

List controlling documents:

```text
1. Phase X Tactical Implementation Plan:
2. Phase X Build Plan:
3. Architecture Specification:
4. Governance/Security Specification:
5. PRD / Requirements:
6. Project methodology:
```

## 3. Implementation Objective

State exactly what the AI builder must implement.

## 4. Allowed Scope

List implementation scope.

## 5. Explicit Non-Goals

List work the AI builder must not implement.

## 6. Required Coding Directives

Break work into concrete coding directives.

For each directive include:

```text
Directive ID:
Purpose:
Files/modules likely affected:
Required behavior:
Required tests:
Acceptance criteria:
Notes:
```

## 7. Migration / Removal Directives

Define replacement, deletion, rejection, compatibility, or migration behavior.

## 8. Security / Governance Directives

Define security-sensitive requirements:

```text
identity:
permissions:
policy:
approval:
audit:
data sensitivity:
secrets:
tool/external access:
```

## 9. Test Directives

Require:

```text
unit tests
integration tests
security/governance tests
negative tests
migration tests
CLI/API/UAT tests
```

Target:

```text
90% meaningful test coverage for new or materially changed code unless impractical and justified
```

## 10. Verification Directives

List commands to run and expected evidence.

If a command cannot be run, the AI builder must explain why.

## 11. Documentation Close-Out Directives

List required documentation updates.

## 12. Reporting Requirements

The AI builder must report:

```text
summary of changes
files changed
tests added or updated
commands run
skipped verification and reasons
documentation updated
risks
deviations from directive
```

## 13. Stop Conditions

The AI builder must stop and ask for clarification if:

```text
source authority conflicts
required files or systems are missing
security/governance requirements are unclear
implementation would require deferred scope
tests cannot be meaningfully added
architecture must be changed
```

## 14. Anti-Drift Rules

The AI builder must not:

```text
implement deferred features
broaden scope
silently change architecture
weaken security or governance behavior
remove unrelated code
rewrite unrelated modules
mark planned behavior as implemented unless implemented
hide skipped tests or failed verification
```

## 15. Accuracy Pass

Verify:

```text
each tactical workstream has coding directives
each directive has tests
security/governance requirements are represented
migration/removal requirements are represented
documentation close-out is represented
non-goals are explicit
stop conditions are explicit
```
