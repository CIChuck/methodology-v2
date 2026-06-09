# Sub-Agent Coordination Protocol

Status: Reusable Standard  
Authority: `docs/methodology/constitution/gendev.md`

## Purpose

This guide defines how a lead agent may coordinate sub-agents while keeping the human team member in
control and preventing authority drift.

Sub-agents increase review coverage and parallel analysis. They also introduce risk: conflicting
findings, scope expansion, shallow summaries, and false confidence. This protocol keeps sub-agent
work bounded and advisory.

## Coordination Model

```text
human team member
  -> lead agent
     -> bounded sub-agents
        -> advisory outputs
     -> synthesis and conflict report
  -> human approval
  -> accepted project documents
```

The human owns approval. The lead agent owns orchestration. Sub-agents provide bounded input.

## Lead Agent Responsibilities

The lead agent must:

- define sub-agent assignments;
- provide source authority;
- state output format;
- state non-goals;
- collect outputs;
- surface conflicts;
- synthesize recommendations;
- ask the human for approval when required;
- ensure accepted conclusions land in active project documents.

The lead agent must not hide significant disagreement.

## Sub-Agent Responsibilities

Sub-agents must:

- stay within assigned scope;
- cite source authority;
- identify assumptions;
- distinguish findings from suggestions;
- report uncertainty;
- avoid changing project authority unless explicitly delegated.

Sub-agents cannot:

- approve gates;
- approve risk;
- broaden phase scope;
- override architecture or governance;
- treat their own output as build authority;
- authorize production deployment.

## When To Use Sub-Agents

Use sub-agents when:

- an artifact is broad or high risk;
- architecture and security need independent review;
- implementation review benefits from parallel focus areas;
- production readiness needs operational, security, and rollback perspectives;
- the human requests deeper review.

Avoid sub-agents when:

- the task is small and low risk;
- source authority is missing;
- the lead agent cannot provide bounded instructions;
- outputs would overload the human without improving decisions.

## Standard Sub-Agent Assignment

Use this shape:

```text
Role:
Objective:
Source authority:
Scope:
Non-goals:
Questions to answer:
Output format:
Stop conditions:
```

## Common Sub-Agent Types

| Sub-Agent | Focus |
| --- | --- |
| Product reviewer | User goals, scope, non-goals, acceptance clarity. |
| Requirements reviewer | Testability, stable IDs, edge cases, deferrals. |
| Architecture reviewer | Boundaries, lifecycle, interfaces, stack fit. |
| Security reviewer | Identity, authorization, audit, data sensitivity, tool access. |
| Test reviewer | Coverage, negative tests, fixtures, UAT. |
| Code conformance reviewer | Drift from documented authority. |
| Deployment reviewer | Runbook, rollback, monitoring, production readiness. |

## Parallel Review

Parallel review is useful when independent perspectives matter.

Example:

```text
Run three bounded reviews:
1. Security/governance risk.
2. Test/UAT coverage.
3. Architecture and maintainability.
```

The lead agent then produces:

```text
Findings by severity:
Conflicts between reviewers:
Shared conclusions:
Recommendations:
Human decisions needed:
```

## Conflict Handling

When sub-agents disagree, the lead agent must surface:

- what conflicts;
- which authority each side cites;
- impact of each option;
- recommendation;
- required human decision.

The lead agent must not resolve material conflicts silently.

## Synthesis Format

Recommended synthesis:

```text
Sub-agents used:
Source authority reviewed:
High-confidence findings:
Conflicting findings:
Advisory improvements:
Required human decisions:
Recommended next step:
```

## Authority Rule

Sub-agent output is not authority. Authority changes only when accepted into:

- active project artifacts;
- approval records;
- decision records;
- traceability matrix;
- as-built close-out.

## Stop Conditions

The lead agent must stop if:

- sub-agent outputs conflict materially;
- sub-agent output implies broader scope;
- sub-agent requests missing authority;
- security risk is critical;
- human approval is needed.

## Completion Standard

This protocol is working when sub-agents improve coverage without fragmenting authority, hiding
conflicts, or overwhelming the human team member.
