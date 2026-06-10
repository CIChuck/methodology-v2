# 03. Repository Map

## Purpose

This chapter explains where practitioners should look for methodology authority (the reusable rules
that govern how GenDev work is performed), initialized project state (the product-specific files
created from the baseline), and agent-facing instructions (repository instructions intended to be
read by an AI coding agent).

## Baseline Repository Areas

The baseline repository (the clean reusable repo before it has been initialized for a specific
product) has three major areas:

```text
AGENTS.md
docs/methodology/
docs/project-template/
```

After initialization, the project also has:

```text
docs/project/
```

Each area has a different purpose.

## `AGENTS.md`

`AGENTS.md` is the root entry point for AI coding agents (AI tools that can inspect files, draft
documents, write code, and run commands). It tells agents:

- what this repository is;
- where methodology authority lives;
- which guides to follow;
- how to treat active project documents;
- how to preserve approval discipline;
- where initialized project paths live.

Practitioners should keep `AGENTS.md` concise and durable (stable enough to guide many sessions).
It should not become a dumping ground for every decision. Project-specific authority belongs in
`docs/project/`.

## `docs/methodology/`

`docs/methodology/` contains reusable methodology authority (the general GenDev rules, templates,
and procedures). It is not the active project (the initialized product-specific project).

Important subdirectories:

```text
docs/methodology/constitution/
docs/methodology/guides/
docs/methodology/templates/
docs/methodology/dev-skills/
docs/methodology/agents/
docs/methodology/design/
docs/methodology/architecture/
```

The constitution (the highest-level GenDev principles) defines the controlling principles. The
guides define operating procedures. The templates provide artifact starting points (starter
documents for project artifacts). The role playbooks help the lead agent take the right stance for
each lifecycle stage.

## `docs/project-template/`

`docs/project-template/` is the skeleton copied by `scripts/init-project.sh`. Practitioners
normally do not work in this directory during a product project. They update it only when evolving
the baseline methodology.

The most important file is:

```text
docs/project-template/project.yaml
```

This becomes the active project manifest (the compact `project.yaml` tracking record) after
initialization.

## `docs/project/`

`docs/project/` is created for the active product. This is where project authority (accepted
product-specific artifacts and records) lives.

Typical initialized structure:

```text
docs/project/
  README.md
  project.yaml
  approvals/
    gate-log.md
  vision/
  prd/
  architecture/
  security-governance/
  decisions/
  build-plan/
  testing/
  traceability/
  as-built/
```

The agent should treat these files as active authority after initialization.

## `project.yaml`

`docs/project/project.yaml` is the control-plane summary (a small manifest that points to the
current gate, approval state, active role, and evidence). It does not replace the artifacts. It
tells future humans and agents where the project currently stands.

It records:

- project name and slug;
- current gate;
- human owner and approvers;
- methodology authority paths;
- collaboration mode;
- active role;
- enforcement class (whether methodology controls are mechanically enforced or human-attested);
- current approval status;
- evidence paths;
- risk disposition;
- next gate, role, and artifact;
- current phase paths.

When a future agent starts a session, it should inspect `project.yaml` before recommending work.

## `approvals/gate-log.md`

`docs/project/approvals/gate-log.md` is the durable approval history (the persistent record of who
approved what, when, based on what evidence, and with what risks accepted). The manifest summarizes
the current approval state; the gate log preserves the decision record.

Use it for:

- gate approvals;
- material risk acceptance;
- permission to carry open questions forward;
- production deployment approval;
- rollback decisions;
- phase close-out approval.

## Artifact Directories

Each artifact directory supports a lifecycle stage (one major movement through the methodology):

- `vision/`: why the product exists and what success means;
- `prd/`: testable product requirements;
- `architecture/`: system structure, boundaries, lifecycle, and technology decisions;
- `security-governance/`: identity, authorization, data, audit, tool, and approval rules;
- `decisions/`: ADRs (architecture decision records) and durable technical decisions;
- `build-plan/`: phase roadmap, build plans, tactical plans, construction directives, review docs;
- `testing/`: test and UAT plans;
- `traceability/`: requirement-to-test-to-implementation evidence;
- `as-built/`: final record of what was actually built.

## Common Navigation Commands

Useful inspection commands:

```bash
rg --files docs/project
sed -n '1,160p' docs/project/project.yaml
sed -n '1,120p' docs/project/approvals/gate-log.md
./scripts/check-methodology.sh
```

The practitioner should not need to inspect every file manually on every turn. The lead agent should
do that orientation work and report the current state.
