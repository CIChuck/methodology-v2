# Project Template

This directory defines the canonical `docs/project/` structure for an initialized product.

Run:

```bash
./scripts/init-project.sh "Project Name"
```

The script creates `docs/project/`, copies starter documents from `docs/methodology/templates/`,
and writes a project manifest.

The template is intentionally documentation-first. Product source code, package configuration,
tests, CI, deployment files, and runtime commands should be added only after the active project
authority documents define the stack and implementation plan.

## Manifest

`project.yaml` is the active project's tracking manifest. It records:

- project identity and current gate;
- human owner and approval fields;
- collaboration mode and lead-agent fields;
- authority document paths;
- current phase paths;
- current approval summary;
- example/non-authority notes.

The manifest is a map, not a replacement for the documents it references.

## Orchestration

The active project uses the orchestration guides under `docs/methodology/guides/` to coordinate the
human team member, lead agent, and any sub-agents.

Key guides:

- `collaboration-modes.md`
- `human-agent-collaboration-loop.md`
- `start-and-next-step-protocol.md`
- `gate-transition-protocol.md`
- `human-approval-protocol.md`
- `subagent-coordination-protocol.md`
- `artifact-collaboration-protocol.md`
- `production-operations-protocol.md`

## Validation

After initialization, run:

```bash
./scripts/check-methodology.sh
```

The checker validates the active project structure, manifest paths, phase-plan sections, and basic
traceability evidence signals.
