# 13. Codex-Specific Notes

## Purpose

This chapter contains Codex-specific operating notes for using GenDev. Codex is OpenAI's AI coding
agent environment. This chapter does not restate the full methodology. Use it only for behavior
that changes because the agent is Codex.

Reference used for this chapter: OpenAI Codex manual, fetched 2026-06-10 from
`https://developers.openai.com/codex/codex-manual.md`.

## Start From The Repository Root

Start Codex from the repository root (the top-level directory of the initialized project) unless
you intentionally want a narrower working directory. The repository root contains `AGENTS.md`,
which is the main durable instruction file (the persistent instruction file an agent reads from the
repository) for this baseline.

Typical interactive use:

```bash
codex
```

To start with an initial prompt:

```bash
codex "Let's begin."
```

To set the working directory explicitly:

```bash
codex --cd /path/to/project
```

## Use `AGENTS.md` As The Primary Codex Instruction Surface

Codex discovers project instructions from `AGENTS.md` files. This repository's root `AGENTS.md`
already tells Codex to follow the GenDev constitution (controlling methodology principles), guides,
templates, project manifest (the compact `project.yaml` tracking record), and approval log (the
durable approval history).

Practitioner rule:

```text
Do not duplicate the whole methodology in a Codex prompt. Keep the prompt short and point Codex back
to AGENTS.md and docs/project/project.yaml.
```

Good prompt:

```text
Let's begin. Follow AGENTS.md and docs/project/project.yaml. Use the GenDev start-and-next-step
protocol.
```

## Approval And Sandbox Posture

Codex supports approval and sandbox controls. Approval controls are tool-level prompts that ask
whether Codex may perform an action. Sandbox controls limit what files, commands, or network access
Codex can use. For GenDev work, prefer a posture that lets Codex edit the workspace while still
asking for approval when needed.

A practical local posture is:

```bash
codex --sandbox workspace-write --ask-for-approval on-request
```

The exact configuration may be managed by the user's Codex environment. GenDev's own approval gates
(methodology checkpoints requiring human approval) still apply even if Codex command approval
settings are permissive.

Important distinction:

- Codex tool approval controls whether Codex may run commands or access files.
- GenDev gate approval controls whether the project may advance lifecycle state.

Do not confuse one for the other.

## Useful Codex Commands For GenDev Work

Common Codex surfaces relevant to this methodology:

- `codex`: interactive terminal UI (a live command-line session with Codex);
- `codex exec`: non-interactive execution (run Codex for a bounded task without an ongoing chat);
- `codex resume`: continue a prior interactive session;
- `codex doctor`: diagnose local Codex setup;
- `codex mcp`: manage MCP servers (Model Context Protocol servers that expose tools or resources);
- `codex review`: review code, when available in the current installation;
- `codex app`: launch the desktop app on supported platforms.

Use interactive Codex for artifact collaboration (drafting and revising project documents with the
human) and gate movement. Use non-interactive execution only when the task is tightly bounded and
the required authority is already present.

## Fresh-Context Review With Codex

For GenDev code conformance review, prefer a fresh Codex context instead of asking the same
implementation conversation to self-review.

Practical pattern:

```bash
codex --cd /path/to/project
```

Then prompt:

```text
Use fresh-context review mode. Do not rely on the implementation session transcript. Read AGENTS.md,
docs/project/project.yaml, the accepted authority documents at their pinned revisions, the
construction directive, the implementation diff or commit, and the test/UAT evidence. Produce the
code review report with Context Provenance completed.
```

If using `codex exec`, keep the task bounded:

```bash
codex exec "Perform an independent GenDev code conformance review. Use only repository authority,
the implementation diff, and verification evidence. Do not use implementer chat history. Complete
the Context Provenance section."
```

Codex `resume` is useful for continuing the same collaboration, but it is usually the wrong tool
for independent conformance review because it intentionally restores prior conversation context.
Use a new session when review independence matters.

## Codex Subagents

Codex supports subagent workflows where specialized agents perform bounded work and return
summaries to the main agent. In GenDev, use Codex subagents (specialized AI workers assigned a
limited review or analysis task) for read-heavy analysis:

- review the PRD for testability;
- review architecture for boundary ambiguity;
- review governance for implicit authorization risk;
- review implementation for conformance;
- review deployment readiness.

Example prompt:

```text
Use bounded subagents for this review. Spawn one subagent for security/governance risk, one for
test/UAT coverage, and one for architecture boundaries. Give each subagent one concise pass and
stop if any reviewer finds C3-level risk or needs broader authority. Do not edit files. Wait for
all results, then reconcile findings and identify required human decisions.
```

Do not use subagents to approve gates or independently update authority (accepted project state).
Subagent output remains advisory (useful input, not controlling authority) until the lead agent
reconciles it and the human accepts any authority changes.

For review subagents, tell Codex to give each reviewer only the needed authority, diff, evidence,
and questions. Do not share the implementation session transcript unless the review report records
the exception.

## Methodology Guard With Codex

Codex may run local validation commands when the human permits tool execution. For GenDev, the most
useful guard commands are:

```bash
./scripts/check-methodology.sh
./scripts/methodology-guard.sh --staged
```

If the optional pre-commit hook is installed with `./scripts/install-hooks.sh`, Codex should treat a
hook failure as a methodology signal, not as an obstacle to work around. It should read the error,
re-orient from `docs/project/project.yaml`, and either fix the state or ask for the human decision
needed to proceed.

## Codex-Specific Failure Modes

Watch for:

- Codex treating command approval as methodology approval;
- Codex editing future-gate artifacts before the current gate is accepted;
- Codex using subagents for write-heavy work without reconciliation;
- Codex asking the implementation session to self-attest rather than using fresh-context review;
- Codex relying on chat memory instead of `project.yaml`;
- Codex bypassing hook or CI failures instead of reconciling the methodology state;
- Codex changing `AGENTS.md` when the project state belongs in `docs/project/`.

Correction prompt:

```text
Stop and re-orient. Codex tool approval is not GenDev gate approval. Read AGENTS.md,
docs/project/project.yaml, and docs/project/approvals/gate-log.md. Report the current gate and next
required human decision before making more changes. Include blast-radius class and enforcement
class in the report.
```

## What Belongs In Codex-Specific Docs

Codex-specific docs may describe:

- Codex instruction discovery;
- Codex command/sandbox/approval behavior;
- Codex subagent use;
- Codex review or non-interactive execution patterns;
- Codex MCP or plugin setup when needed.

They should not redefine:

- GenDev gates;
- artifact templates;
- human approval rules;
- production readiness rules;
- traceability requirements.
