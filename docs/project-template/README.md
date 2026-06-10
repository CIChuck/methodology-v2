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

`project.yaml` is the active project's control-plane manifest. It records:

- project identity and current gate;
- human owner and approval fields;
- collaboration mode and lead-agent fields;
- authority document paths;
- current phase paths;
- current approval summary, including gate status, approver, evidence, risk acceptance, and next
  handoff;
- active amendment count and amendment protocol path;
- example/non-authority notes.

The manifest is a map and state summary, not a replacement for the documents it references.

## Approval Log

`approvals/gate-log.md` is the durable approval history for the active project. The manifest should
summarize the latest approval state; the log should preserve who approved what, what evidence was
reviewed, what risks were accepted, and what gate or role comes next.

## Orchestration

The active project uses the orchestration guides under `docs/methodology/guides/` to coordinate the
human team member, lead agent, and any sub-agents.

Key guides:

- `collaboration-modes.md`
- `human-agent-collaboration-loop.md`
- `start-and-next-step-protocol.md`
- `gate-transition-protocol.md`
- `amendment-and-regression-protocol.md`
- `human-approval-protocol.md`
- `subagent-coordination-protocol.md`
- `artifact-collaboration-protocol.md`
- `production-operations-protocol.md`
- `orchestration-validation.md`

## Validation

After initialization, run:

```bash
./scripts/check-methodology.sh
```

The checker validates the active project structure, manifest paths, approval-state invariants,
phase-plan sections, and basic traceability evidence signals.
