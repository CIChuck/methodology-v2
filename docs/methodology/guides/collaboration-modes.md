# Collaboration Modes

Status: Reusable Standard  
Authority: `docs/methodology/constitution/gendev.md`  
Applies to: Human-agent collaboration in initialized projects

## Purpose

This guide defines how a human team member can control the operating style of the lead AI agent.

The methodology supports multiple collaboration modes because different moments need different
levels of autonomy. Early discovery may benefit from a proactive agent. Security review, gate
approval, deployment, and destructive migration require explicit human control.

The mode controls process behavior. It does not override the constitution, active project authority,
gate requirements, security/governance rules, or human approval requirements.

## Mode Summary

| Mode | Use When | Agent Behavior |
| --- | --- | --- |
| `proactive` | Human wants the agent to lead the process. | Agent recommends next steps, drafts artifacts, and asks for approval at control points. |
| `approval-gated` | Human wants explicit approval before gate movement or major artifact finalization. | Agent pauses at each approval point and waits. |
| `advisory` | Human wants analysis and recommendations only. | Agent does not edit active artifacts unless instructed. |
| `execution-focused` | A plan is already approved and the agent should carry it out. | Agent follows the directive and avoids reopening scope unless blocked. |

## Default Mode

The default mode for a new initialized project is:

```text
approval-gated
```

This default keeps early projects conservative until the human sets a different mode.

## Proactive Mode

Use proactive mode when the human wants the lead agent to drive progress.

Example human instruction:

```text
Lead proactively through the methodology. Ask only when a decision affects scope, security,
architecture, acceptance, or production.
```

The agent may:

- inspect `AGENTS.md`, `docs/project/project.yaml`, and current gate docs;
- recommend the next gate-aware action;
- draft artifacts from available authority and clearly labeled assumptions;
- identify missing information;
- propose approval language;
- update non-final draft documents when instructed or when the current mode permits;
- coordinate sub-agents for bounded advisory work.

The agent must stop for:

- gate approvals;
- technology stack acceptance;
- architecture acceptance;
- governance/security acceptance;
- phase scope acceptance;
- construction directive acceptance;
- critical or major finding acceptance;
- destructive migrations;
- external integrations;
- production release or rollback decisions.

## Approval-Gated Mode

Use approval-gated mode when the human wants tight control.

Example human instruction:

```text
Use approval-gated mode. Draft the next artifact, then wait for my approval before moving on.
```

The agent may:

- inspect state and recommend next steps;
- ask clarifying questions;
- draft an artifact;
- propose edits;
- identify readiness gaps.

The agent must wait before:

- marking an artifact accepted;
- changing `current_gate`;
- updating approval records;
- generating a construction directive from a tactical plan;
- treating a review finding as accepted;
- proceeding from planning to implementation.

## Advisory Mode

Use advisory mode when the human wants analysis without artifact changes.

Example human instruction:

```text
Stay advisory. Evaluate the PRD and tell me what is missing, but do not edit files.
```

The agent may:

- analyze documents;
- compare artifacts to the methodology;
- propose questions, edits, and risks;
- produce a review memo in conversation.

The agent must not:

- edit active project documents;
- update manifest fields;
- advance gates;
- create implementation directives;
- run project-changing commands.

## Execution-Focused Mode

Use execution-focused mode after planning is accepted.

Example human instruction:

```text
Use execution-focused mode for Phase 1. Follow the construction directive and do not reopen
product scope unless blocked.
```

The agent may:

- implement or document only the approved scope;
- run approved verification;
- update required close-out docs;
- report skipped verification and risks.

The agent must stop if:

- implementation needs new scope;
- architecture must change;
- security/governance behavior would change;
- the approved plan is contradictory;
- verification cannot be run and the risk is material.

## Changing Modes

The human may change modes at any time with plain language:

```text
Switch to proactive mode.
Use approval-gated mode from here.
Stay advisory for this review.
Proceed execution-focused against the construction directive.
```

The lead agent should confirm:

```text
Mode set to: [mode]
Scope of mode: [session | current artifact | current phase]
Required approvals remain in force.
```

## Manifest Tracking

Initialized projects should track the current collaboration mode in `docs/project/project.yaml`.

Recommended manifest fields:

```yaml
collaboration:
  mode: approval-gated
  lead_agent: TBD
  active_role: product-vision-agent
  subagents_enabled: true
  mode_set_by: TBD
  mode_set_on: TBD
```

The manifest records state. It does not grant authority by itself. Authority remains in the active
project documents and recorded approvals.

## Mode Conflict Rule

If a mode conflicts with a gate, security rule, approval requirement, or active construction
directive, the stricter rule wins.

Examples:

- Proactive mode cannot skip human deployment approval.
- Execution-focused mode cannot implement deferred features.
- Advisory mode cannot update docs unless the human changes mode or explicitly authorizes the edit.

## Completion Standard

This guide is working when a human can set an operating mode in plain language and the lead agent can
adjust its behavior without losing gate discipline, approval discipline, or project authority.
