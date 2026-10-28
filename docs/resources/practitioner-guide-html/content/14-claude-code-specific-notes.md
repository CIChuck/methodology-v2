# 14. Claude Code-Specific Notes

## Purpose

This chapter contains Claude Code-specific operating notes for using GenDev. Claude Code is
Anthropic's AI coding agent environment. This chapter does not restate the full methodology. Use it
only for behavior that changes because the agent is Claude Code.

References used for this chapter:

- `https://code.claude.com/docs/en/overview`
- `https://code.claude.com/docs/en/memory`
- `https://code.claude.com/docs/en/settings`
- `https://code.claude.com/docs/en/sub-agents`

1.0 review stamp:

- Last reviewed: 2026-07-11
- Review scope: Claude Code-specific GenDev operation, including surfaces, CLAUDE.md and AGENTS.md
  relationship, settings scopes, project rules, subagents, memory, hooks, and guard behavior.
- Source status: official Claude Code documentation pages above were reachable during 1.0 release
  work.

## Start From The Repository Root

Start Claude Code from the initialized repository root (the top-level directory of the active
project):

```bash
cd /path/to/project
claude
```

Then prompt:

```text
Let's begin. Follow the GenDev methodology. Start by reading the project instructions and
docs/project/project.yaml.
```

## Claude Code Reads `CLAUDE.md`, Not `AGENTS.md`

This repository uses `AGENTS.md` as the tool-agnostic and Codex-friendly root instruction file
(persistent instructions stored in the repository). Claude Code's persistent project instruction
file is `CLAUDE.md`.

For a Claude Code project, create a root `CLAUDE.md` that imports `AGENTS.md`:

```markdown
@AGENTS.md

## Claude Code

Follow the GenDev methodology. Treat docs/project/project.yaml as the active project control-plane
summary and docs/project/approvals/gate-log.md as the durable approval history.
```

This avoids duplicating methodology instructions. If the two files diverge (say different or
conflicting things), future agents may behave inconsistently.

A symlink may also work on systems that support it, but an import is more portable across platforms.

## Use Claude Rules For Claude-Specific Project Behavior

For larger projects, Claude Code supports project rules under `.claude/rules/`. Rules are scoped
instruction files that guide Claude Code behavior for a project or path. Use rules for
Claude-specific behavior that should not live in the methodology itself.

Examples:

```text
.claude/rules/testing.md
.claude/rules/security.md
.claude/rules/frontend.md
```

Do not move GenDev gate rules into Claude rules. Keep GenDev methodology in `AGENTS.md` and
`docs/methodology/`. Use Claude rules only for Claude-specific or path-specific behavior.

## Settings Scope

Claude Code supports managed, user, project, and local settings scopes. Settings are configuration
layers that affect Claude Code behavior. For GenDev:

- use project scope for team-shared Claude Code settings that belong in the repository;
- use local scope for personal machine-specific settings;
- use managed scope for organization-enforced security policies;
- avoid putting product authority (accepted product-specific artifacts and records) in settings
  files.

Product authority still belongs in `docs/project/`.

## Fresh-Context Review With Claude Code

For GenDev code conformance review, prefer a fresh Claude Code session or a dedicated review
subagent that receives only the review inputs. Do not ask the implementation conversation to
self-attest to conformance.

Practical pattern:

```bash
cd /path/to/project
claude
```

Then prompt:

```text
Perform an independent GenDev code conformance review. Use CLAUDE.md, AGENTS.md,
docs/project/project.yaml, accepted authority documents at their pinned revisions, the construction
directive, the implementation diff or commit, and test/UAT evidence. Do not use the implementation
session transcript or reasoning trace. Complete the Context Provenance section in the review
report.
```

If Claude Code memory contains implementation-session details, treat that memory as context, not
authority. The review report should still state whether implementer session context was shared with
the reviewer and record any exception.

## Claude Code Subagents

Claude Code supports custom subagents and parallel agent work. In GenDev, use them the same way the
methodology describes sub-agents (specialized AI workers assigned bounded review or analysis):

- keep assignments bounded;
- provide source authority (the governing documents the sub-agent must use);
- ask for summarized findings;
- keep sub-agent output advisory (useful input, not controlling authority);
- let the lead agent reconcile (turn multiple inputs into one coherent recommendation);
- require human approval before authority changes.

Example prompt:

```text
Use Claude Code subagents for bounded review. Create one security/governance reviewer, one
testability reviewer, and one architecture-boundary reviewer. Give each reviewer one concise pass
and stop if any reviewer finds C3-level risk or needs broader authority. Do not edit files. Return
a reconciled findings list with conflicts and required human decisions.
```

For conformance review, configure or prompt review subagents to start from fresh context: authority
documents, implementation diff, verification evidence, and explicit questions only. Avoid sharing
the implementer transcript unless the review report records the exception.

Project-specific Claude Code subagents belong under `.claude/agents/` when they should be checked
into the repository for the team. Personal subagents belong under `~/.claude/agents/`. Keep GenDev
approval and authority rules in the methodology; use Claude subagent files only to package bounded
review roles.

## Claude Memory And GenDev Authority

Claude Code supports persistent instruction and memory mechanisms. Memory means tool-stored context
that may help future sessions. Treat memory as helpful context, not project authority.

If Claude learns a durable fact (a fact that should survive sessions and guide future work) that
affects the product, architecture, tests, or production, record that fact in the appropriate GenDev
artifact. Do not rely on auto memory as the only record.

Examples:

- build command discovered by Claude: update the phase plan or project instructions;
- recurring test issue: update the test/UAT plan or close-out notes;
- architecture constraint: update architecture or ADR (architecture decision record);
- security rule: update governance/security spec.

## Methodology Guard With Claude Code

Claude Code may run local validation commands when the human permits tool execution. For GenDev,
the most useful guard commands are:

```bash
./scripts/check-methodology.sh
./scripts/methodology-guard.sh --staged
```

If the optional pre-commit hook is installed with `./scripts/install-hooks.sh`, Claude should treat
a hook failure as a methodology signal. It should not bypass the hook or silently force a commit.
It should explain the failed control, re-orient from `docs/project/project.yaml`, and ask for the
human decision needed to fix or override the condition.

## Claude-Specific Failure Modes

Watch for:

- Claude not reading `AGENTS.md` because no `CLAUDE.md` imports it;
- Claude treating memory as authority instead of updating project docs;
- Claude rules duplicating or contradicting GenDev methodology;
- Claude subagents producing unreviewed authority changes;
- Claude continuing the implementation conversation for conformance review instead of using fresh
  context;
- Claude advancing gates from chat approval without updating `gate-log.md` and `project.yaml`.
- Claude bypassing hook or CI failures instead of reconciling the methodology state.

Correction prompt:

```text
Stop and re-orient. Read CLAUDE.md, AGENTS.md, docs/project/project.yaml, and
docs/project/approvals/gate-log.md. Report the current GenDev gate, active artifact, approval state,
blast-radius class, enforcement class, and next human decision before making changes.
```

## What Belongs In Claude-Specific Docs

Claude-specific docs may describe:

- `CLAUDE.md` imports;
- `.claude/rules/`;
- Claude settings scopes;
- Claude subagents;
- Claude memory behavior;
- Claude hooks (configured actions that run around Claude Code events) or permissions when needed.

They should not redefine the GenDev lifecycle.
