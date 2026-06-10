# 08. Subagents And Delegation

## Purpose

This chapter explains how to use sub-agents (specialized AI agents or agent roles assigned bounded
review or analysis tasks) safely. Sub-agents can improve coverage and speed, but they also increase
coordination risk (the risk that parallel work becomes inconsistent, conflicting, or hard to
reconcile).

## What Sub-Agents Are For

Sub-agents are bounded workers (contributors with limited scope, source material, and output
expectations). They are useful when independent analysis improves decision quality.

Good uses:

- product clarity review (checking whether the product intent is understandable);
- requirements testability review (checking whether requirements can be proven with tests or UAT);
- architecture risk review (checking structural or technical risks);
- security/governance review (checking policy, identity, authorization, data, audit, and tool
  rules);
- test and UAT coverage review (checking automated and user acceptance testing coverage);
- code conformance review (checking implementation against accepted authority);
- deployment readiness review (checking whether release, rollback, and operations are ready).

Poor uses:

- asking multiple agents to edit the same artifact without coordination;
- letting sub-agents approve gates;
- using sub-agent output as authority without reconciliation;
- asking broad, vague questions that produce overlapping opinions.

## Authority Rule

Sub-agent output is advisory (useful input that is not project authority by itself). Authority
changes only when accepted into:

- active project artifacts;
- approval records;
- decision records;
- traceability matrix;
- as-built close-out.

The lead agent owns reconciliation (turning multiple inputs into one coherent recommendation). The
human owns approval.

## Fresh-Context Review

For review, evaluation, and governance tasks, use fresh context. Fresh context means the sub-agent
receives the authority documents, implementation diff, test evidence, and review questions, but not
the implementation agent's full session transcript or private reasoning.

Fresh context matters because a reviewer who inherits the implementer's conversation may also
inherit the implementer's assumptions. Independent review is strongest when the reviewer compares
the artifact or diff directly against accepted authority.

Allowed reviewer inputs:

- authority documents at pinned revisions;
- implementation diff, commit, pull request, or artifact under review;
- test/UAT evidence and verification output;
- traceability evidence;
- explicit review scope and questions.

Avoid reviewer inputs unless justified:

- implementation session transcript;
- implementation reasoning trace;
- broad chat history;
- informal claims that were never recorded in project authority.

Review sub-agents are automated governance agents in a bounded sense. They can enforce the
methodology by identifying drift and missing evidence, but their output remains advisory until the
lead agent reconciles it and the human accepts any authority change.

## When To Use Sub-Agents

Use sub-agents when:

- the artifact (durable project document or record) is broad or high risk;
- the topic crosses product, architecture, security, and test concerns;
- review quality benefits from independent perspectives;
- implementation has enough surface area to justify parallel review;
- production readiness needs specialized operational scrutiny.

Avoid sub-agents when:

- the work is small;
- the source authority is missing;
- the lead agent cannot give bounded assignments;
- the outputs would overwhelm the human without improving decisions.

## Assignment Format

A good sub-agent assignment includes:

```text
Role:
Objective:
Source authority:
Context boundary:
Scope:
Non-goals:
Questions to answer:
Output format:
Stop conditions:
```

Example:

```text
Use three bounded sub-agents.

Security reviewer:
Source: PRD, architecture, governance/security draft.
Question: Identify implicit authorization, data sensitivity, audit, and tool-access risks.

Test reviewer:
Source: PRD, phase plan, test/UAT plan.
Question: Identify missing positive, negative, security, and UAT coverage.

Architecture reviewer:
Source: PRD, architecture draft, stack ADR.
Question: Identify boundary, lifecycle, data-model, and deferred-architecture gaps.
Context boundary: Use only the listed documents and explicit questions. Do not use implementer
session history.

Wait for all outputs, then reconcile conflicts and return findings by severity.
```

## Lead-Agent Synthesis

The lead agent should return:

```text
Sub-agents used:
Source authority reviewed:
Context boundaries:
High-confidence findings:
Conflicting findings:
Advisory improvements:
Required human decisions:
Recommended next step:
```

The lead agent should not hide disagreement. If one sub-agent says a feature is in scope (inside
the approved work) and another says it violates the non-goals (things the team explicitly chose not
to build now), the conflict must be surfaced.

## Write Discipline

Parallel write-heavy workflows are risky. If multiple agents edit the same files, they can create
conflicts or inconsistent authority (documents that contradict each other or no longer match the
accepted record). Prefer sub-agents for read-heavy review and analysis.

When sub-agents produce proposed text, the lead agent should:

1. compare it against source authority;
2. reconcile conflicts;
3. propose a single coherent edit;
4. ask for human review or approval when required;
5. update project documents only after acceptance.

## Human Prompt Example

```text
Before we approve the architecture, run a bounded sub-agent review. Use one reviewer for security
and governance, one for testability, and one for architecture boundaries. Do not edit files yet.
Return a reconciled findings list with required human decisions.
```

Expected lead-agent behavior:

- define bounded reviewer assignments;
- run or simulate the sub-agent workflow depending on tool support;
- summarize findings;
- identify conflicts;
- recommend artifact revisions;
- avoid gate approval until the human decides.
