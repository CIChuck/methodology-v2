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

The human owns approval. The lead agent owns orchestration and reconciliation. Sub-agents provide
bounded input.

## Lead Agent Responsibilities

The lead agent must:

- define sub-agent assignments;
- provide source authority;
- state the expected effort budget;
- state output format;
- state non-goals;
- collect outputs;
- surface conflicts;
- synthesize recommendations;
- ask the human for approval when required;
- ensure accepted conclusions land in active project documents, approval records, or decision
  records.

The lead agent must not hide significant disagreement.

## Sub-Agent Responsibilities

Sub-agents must:

- stay within assigned scope;
- cite source authority;
- use fresh context for review, evaluation, or governance tasks;
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

## Fresh-Context Review Rule

Review, evaluation, and governance sub-agents should start from a fresh context. Fresh context means
the sub-agent receives the documents and evidence needed for review, but does not inherit the
implementation agent's session transcript, private reasoning, or broad conversational history.

Allowed reviewer inputs:

- authority documents at pinned revisions;
- implementation diff, commit, pull request, or artifact under review;
- applicable test, UAT, verification, and traceability evidence;
- explicit review scope and questions;
- known constraints from accepted project authority.

Disallowed reviewer inputs unless explicitly justified:

- implementation agent session transcript;
- implementation agent reasoning trace;
- broad chat history unrelated to accepted authority;
- informal claims that are not present in project artifacts or evidence.

If an exception is necessary, record it in the review output under context provenance.

Review sub-agents are automated governance agents in the lightweight GenDev sense: they help enforce
documented authority, identify drift, and surface risk. They remain advisory. They do not approve
gates, accept risk, or change authority.

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

## Budget And Cost Control

Sub-agent work must have an explicit budget expectation. Budget may be stated as time, tokens,
dollars, rough effort, number of passes, or another practical limit supported by the tool and team.

Budget fields are not a substitute for judgment. They exist to prevent automated runaway
delegation, hidden review cost, and broad sub-agent prompts that produce more material than the
human can use.

When a sub-agent assignment is likely to exceed budget, the lead agent should stop and surface:

```text
assignment
budget expectation
work completed
remaining work
risk of stopping
recommendation
human decision needed
```

C1 projects should normally use few or no sub-agents unless independent review would materially
improve safety or clarity. C2 projects use sub-agents when scope or risk justifies them. C3
projects should use stronger independent review and may assign multiple bounded reviewers, but each
assignment still needs a budget.

## Standard Sub-Agent Assignment

Use this shape:

```text
Role:
Objective:
Source authority:
Scope:
Non-goals:
Questions to answer:
Budget:
Budget escalation:
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
| Code conformance reviewer | Drift from documented authority against the six constitutional principles. See Six-Principle Checklist below. |
| Deployment reviewer | Runbook, rollback, monitoring, production readiness. |

### Six-Principle Checklist (Code Conformance Reviewer)

This reviewer operates under the Fresh-Context Review Rule: no shared context with the
implementing agent, fed only the construction directive, the Accepted architecture's Domain
Model, the surrounding codebase modules relevant to DRY checking, and the artifact under
review.

**What to check, and what each question requires as input:**

| Principle | Question | Required input |
| --- | --- | --- |
| YAGNI (narrow) | Does the code do anything the directive's stated scope and non-goals did not ask for? | The directive's Allowed Scope and Explicit Non-Goals sections |
| KISS | Is there a simpler structure that satisfies the same requirement? | The directive's implementation objective and the code |
| DRY | Does this logic already exist elsewhere in the codebase? | The relevant surrounding modules, not just the new file |
| SRP | Does any single unit (function, class, module) do more than one coherent job? | The code |
| NAA | Does every entity, field, relationship, class, and interface in this code already appear in the Accepted architecture's Domain Model? | The Accepted architecture document's Domain Model section |
| LA | Would the obvious reading of the requirement lead a reader to expect this behavior? | The requirement and the code |

**Honest scope of this checklist.** Four of the six questions are cleanly checkable given
the right inputs: KISS, DRY, NAA (its entity-lookup half), and narrow YAGNI. Two are
judgment-dependent and the reviewer's finding should be treated as advisory rather than
deterministic: broad YAGNI (was this genuinely unneeded by the project, requiring roadmap
knowledge the reviewer does not have) and LA (what would a reader expect, which is closer
to a human judgment call than a comparison against a document). Do not imply this checklist
covers everything; state the limits when reporting findings.

**Finding format.** Use the same finding format as all other sub-agent reviewers: principle
violated (use the key: YAGNI, KISS, DRY, SRP, NAA, LA), specific evidence (the function,
class, or logic at issue), severity (blocking or advisory), and recommended action.

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

Only the lead agent should update authoritative project documents or approval records unless the
human explicitly delegates a bounded write task to a sub-agent.

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
