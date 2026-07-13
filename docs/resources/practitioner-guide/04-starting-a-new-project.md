# 04. Starting A New Project

## Purpose

This chapter explains the normal startup path for turning the baseline repository (the reusable
GenDev repository before product-specific initialization) into an active product project (the
initialized project under `docs/project/`).

## Starting Assumptions

This guide assumes:

- Git is installed on your platform
- you have cloned the baseline repository;
- you are on the branch you intend to use, and you know which branch is protected or treated as
  production authority;
- your working tree is in a state you understand;
- you can run shell commands from the repository root;
- you have an AI coding agent (an AI tool that can inspect files, draft artifacts, write code, and
run commands) available, such as Codex or Claude Code.

## Bringing The Methodology To An Existing Repository

The steps below assume you cloned the baseline repository and are starting a project inside it.
Two other starting points are common, and each has a script that handles it.

If you have a repository that already holds its own code and you want to bring GenDev to it rather
than start inside a fresh clone, run `scripts/install-methodology.sh` from inside the baseline
repository, passing the target repository path. It copies the methodology (the constitution,
guides, templates, agents, and the scripts) into the target so that repository can be run under
GenDev governance. It does not touch the target's own code, and it will not overwrite an existing
methodology install without `--force`. It preserves an existing root `AGENTS.md` by default; use
`--integrate-agents` only when the target owner approves adding the managed GenDev include block.
Use `--protected-branch BRANCH` when rendering the workflow for a branch other than the detected
current branch, and use `--with-resources` only when the target should receive reference material.
After it runs, initialize the project in the target the same way this chapter describes. The concise
1.0 adoption path is recorded in `docs/resources/releases/1.0.2-adoption.md`.

If you have a presales or discovery repository that already holds a vision, PRD, or architecture,
written for a customer rather than to a template, run `scripts/backfill-methodology.sh` against it
with at least one declared source such as `--vision path/to/vision.md`. It seeds the methodology,
creates missing control-plane files and directories without replacing imported authority, and writes
a per-document conformance report naming which required sections and front-matter each existing
document has and which it is missing. That report drives the mid-stream start: work each existing
document through its gate as a reformatting task rather than authoring it from a blank page. The
appendix, Starting Mid-Stream, covers that flow end to end, including the reformatting and
validation directives for each gate and the scripted gate close.

## Initialize The Project

From the repository root, run:

```bash
./scripts/init-project.sh "My Product Name"
```

Example:

```bash
./scripts/init-project.sh "Vendor Contract Tracker"
```

The script creates `docs/project/` and renders project-specific paths from the methodology
templates (starter documents that become project artifacts).

Expected output shape:

```text
Initialized docs/project for Vendor Contract Tracker
Project slug: vendor-contract-tracker
Next document: docs/project/vision/vision.md
```

Notice the generated filename: `vision.md`, not `vendor-contract-tracker-vision.md`.
Artifact names are canonical and fixed for every project (Chapter 03); the project
name appears in the slug recorded in `project.yaml`, not in the filenames. Each
generated authority artifact also carries a `project:` front-matter field set to
the slug, so an artifact declares which project it belongs to without that
identity being baked into its path. You do not name these files; the scaffold
does, identically for every project.


## Inspect The Manifest

After initialization, inspect:

```bash
sed -n '1,140p' docs/project/project.yaml
```

Confirm the manifest (the compact `project.yaml` tracking record for current project state):

- `project.name` is correct;
- `project.slug` is acceptable;
- `project.current_gate` is `G1` (the vision gate, where the team defines why the product exists);
- authority paths exist (paths to the documents and records that govern the project);
- `enforcement.class` is `attested` (human-confirmed methodology control) unless the project has
already installed active mechanical enforcement;
- `enforcement.protected_branch` names the branch the team treats as production project authority;
- `enforcement.attestation.cadence` records when humans must attest that required checks happened;
- `enforcement.binding_paths` points to the reference binding files, even if the project is still
operating in attested mode;
- `scaling.blast_radius_class` is `C1`, `C2`, or `C3`;
- `scaling.classification_reason` explains why that class is appropriate;
- `scaling.combined_gates` is empty unless the project intentionally combines gates;
- approval state is `pending`;
- the G1 evidence path points to the vision document.

The owner and approver fields may initially be `TBD`. The agent can draft early G1 material before
those fields are resolved, but it should not mark the gate `ready_for_approval` (ready for a human
approval decision) until required human authority is known.

Manifest defaults are intentionally conservative. Fields that identify the project, current gate,
approval record format, artifact paths, enforcement class, and blast-radius class must exist
immediately because tools and agents use them for orientation. Owner, approver, attester, protected
branch, and implementation paths may start as `TBD`, but they become blocking when the project asks
to mark a gate ready for approval, enters implementation planning, or relies on mechanical
enforcement. Do not delete deferred fields; replace `TBD` with named values at the gate where the
field becomes operational.


## Select Blast-Radius Class

Blast-radius class is the declared estimate of how much harm or cost a mistake could plausibly
cause. Choose it early and revise it when exposure changes.

Use:

- `C1` for contained work, such as a reversible internal utility with no sensitive data and no
external system effects;
- `C2` for ordinary product work, which is the default for most useful applications;
- `C3` for critical work, such as regulated data, irreversible actions, external integrations,
production-sensitive automation, agentic runtime behavior, or high operational impact.

Do not use `C1` simply because the team wants fewer documents. Use `C1` only when the project is
actually contained. If the work later touches sensitive data, production automation, external
systems, or irreversible outcomes, reclassify before continuing.

Example startup prompt:

```text
Before drafting the vision, classify the project as C1, C2, or C3. Explain the reason and identify
any reclassification triggers.
```

If the project is C1 and the human wants a GenDev Lite path, record the intended gate combination
under `scaling.combined_gates` with a justification. Do not combine gates silently.

## Run The Checker

Run:

```bash
./scripts/check-methodology.sh
```

For a clean initialized project, the checker should pass. If it warns about approval state (the
manifest's record of whether a gate is pending, drafting, ready, approved, blocked, or superseded),
resolve that state before treating a gate as ready or approved.

If it warns about enforcement state, inspect the `enforcement` block. A newly initialized project
should declare `class: attested`, an attestation cadence, an attester field, implementation paths,
excluded paths, binding paths, and an override record path. The attester and implementation paths
may initially be `TBD`, but the fields should exist so the team and agent know the project is
operating under an explicit enforcement contract.

## Optional Local Hook

The repository includes an optional local Git hook binding. Install it after initialization if the
team wants local staged-change checks before commits:

```bash
./scripts/install-hooks.sh
```

The hook runs:

```bash
./scripts/methodology-guard.sh --staged
```

This is a convenience guard. It does not replace human gate approval, and it does not replace CI or
repository branch protection.

## Start The Agent

Start the chosen AI coding agent from the repository root. The exact command depends on the tool.
For example, a Codex user starts a Codex session from the repository root. A Claude Code user starts
Claude Code from the repository root.

The important point is not the tool name. The important point is the working directory (the
directory where the agent starts and resolves repository-relative paths). The agent must be able to
read:

```text
AGENTS.md
docs/methodology/
docs/project/project.yaml
docs/project/
```

```text
refinement - Agents use AGENTS.md as their reference starting point. However, Claude Code uses clod.md. This is an agent-specific change. We need to rethink. For instance, does ClaudeMD get edited to refer to the methodologies in Agents.md? 
```

## First Prompt

Use a short prompt:

```text
Let's begin.
```

Expected agent behavior:

```text
Current gate: G1
Current mode: approval-gated, unless changed by the human
Active artifact: docs/project/vision/vision.md
Recommended next step: confirm owner, approver, collaboration mode, and draft the G1 vision
Human input needed: product objective, target users, constraints, and any known non-goals
```

The agent should not begin implementation. If it starts proposing code, stop it and re-orient:

```text
Stop. Re-read AGENTS.md and docs/project/project.yaml. We are at G1. Draft the vision artifact only.
Do not implement code.
```

## First-Run Preflight

GenDev declares four prerequisites: bash 4+, git, python3, and ripgrep (rg).
The doctor reports each one, and `./scripts/init-project.sh` refuses to run
until all are present. Install ripgrep with `apt install ripgrep`,
`brew install ripgrep`, `winget install BurntSushi.ripgrep.MSVC`, or
`cargo install ripgrep`.

Before drafting G1 content, run the 1.0 orientation commands from the repository root:

```bash
./scripts/gendev-doctor.sh
./scripts/project-state.sh
./scripts/check-methodology.sh
```

`gendev-doctor.sh` checks repository health and required tooling, `project-state.sh` summarizes the
active gate and approval posture, and `check-methodology.sh` verifies the initialized project paths
and records. The lead agent should summarize any failures or warnings before it drafts or edits
authority artifacts.

The lead agent should capture or confirm:

```text
Project owner:
Gate approver:
Deployment approver, if known:
Collaboration mode (how proactively the agent should act and when it must pause):
Sub-agents allowed (specialized AI workers for bounded review or analysis):
Blast-radius class:
Classification reason:
Initial product objective:
```

Example human response:

```text
Owner: Chuck
Gate approver: Chuck
Deployment approver: TBD until we define production
Mode: proactive, but keep gate approvals explicit
Sub-agents: allowed for reviews and risk analysis
Blast-radius class: C2
Classification reason: customer-facing business app with confidential contract metadata
Objective: build a lightweight system for tracking vendor contracts, owners, renewals, and status
```

The agent should record persistent state (state that must survive beyond the current chat or CLI
session) in `project.yaml` when the human intends it to survive the current session.

## Stop Point

The startup phase ends when:

- `docs/project/` exists;
- `project.yaml` is readable and coherent;
- the current gate is G1;
- enforcement class and attestation cadence are visible in `project.yaml`;
- blast-radius class and classification reason are visible in `project.yaml`;
- collaboration mode is known;
- the human has supplied enough context to draft the vision document;
- the agent knows not to proceed beyond G1 without approval.

## Provenance Pins

Every artifact's Derived from revision must be the hash of the last commit
that touched the source path. Do not compute it by hand: run
`./scripts/pin-provenance.sh <artifact>` after any source moves (every gate
closure moves one), and `--check` to preview. The full command sequence for
each gate lives in the runbook at `docs/resources/runbook/g0-to-g7-runbook.md`.
