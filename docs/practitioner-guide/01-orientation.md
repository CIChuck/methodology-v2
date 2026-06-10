# 01. Orientation

## What GenDev Is

GenDev is a documentation-first methodology (a repeatable way of working where durable documents
guide and constrain implementation) for building software products with AI-assisted coding agents
(AI tools that can inspect files, draft documents, write code, run commands, and report results).
The repository is meant to be cloned, initialized for a specific product, and then evolved through a
controlled sequence of gates (explicit lifecycle checkpoints where the team decides whether the
project is ready to move forward).

The methodology exists because AI coding agents are most effective when they are given durable
project authority (the accepted files and records that govern the product) instead of a loose
stream of chat instructions. GenDev makes that authority explicit. The human team member and the
agent collaboratively create the vision (the problem, users, outcomes, and success definition), PRD
(product requirements document), architecture (the system structure and technical boundaries),
governance (the security, policy, approval, and operational rules), phase plans (bounded plans for
increments of work), construction directives (specific build instructions for implementation
agents), tests, reviews, deployment plans, and as-built records (documents that record what was
actually built and operated) that define the product.

The central rule is simple:

```text
Chat can start work, but durable project documents govern work.
```

## Who This Is For

The primary readers are diverse technical practitioners:

- product owners who must define goals, scope (what is included and excluded), and acceptance
  (the decision that work is good enough to move forward);
- developers who will collaborate with coding agents during implementation;
- system architects who must keep structure, boundaries, and technology decisions coherent;
- engineering leads who must sequence phases and manage risk;
- AI-agent operators who need predictable instructions for Codex, Claude Code, or similar tools.

The guide assumes readers know Git, the shell, and CLI-based development workflows (command-line
development workflows). It does not explain how to clone a repository, create a branch, or run a
command unless the command is specific to this methodology.

## What Problem This Methodology Solves

AI coding agents can move quickly. That speed is useful only when the agent is moving through a
known process. Without a process, the agent may:

- jump to code before the product is understood;
- invent requirements that the human never approved;
- make architecture choices without recording tradeoffs;
- skip security and governance decisions;
- write tests that do not trace to requirements;
- mark work done without review or as-built documentation;
- create production risk without deployment (release), rollback (return to a previous known-good
  state), or monitoring (observing health, errors, and important signals) plans.

GenDev reduces those risks by putting a documented gate between each major lifecycle state
(a major stage such as vision, requirements, architecture, implementation, review, deployment, or
close-out).

GenDev also makes the project measurable. The methodology records gate movement, approval timing,
traceability samples, enforcement overrides, and post-deployment value review (a later comparison of
declared success criteria against actual evidence) so the team can learn whether the process is
reducing drift and rework.

## What GenDev Does Not Do

GenDev does not replace human judgment. The human still owns intent (what the product is meant to
achieve), product fit, business risk, organizational constraints, approval, and production
decisions.

GenDev does not require every project to become heavyweight. Small projects may combine artifacts
(durable project documents such as the vision, PRD, architecture, plans, reviews, and close-out)
when the required content still exists and approvals are preserved. The goal is not bureaucracy.
The goal is enough durable context (repository state that survives beyond the chat session) that an
agent can do useful work without making hidden product, architecture, or risk decisions.

GenDev also does not prescribe a single AI tool. The methodology is tool-agnostic. Codex-specific
and Claude Code-specific chapters exist only to explain how those tools should be pointed at the
same methodology.

## The Practitioner's First Move

For a new project, the practitioner does three things:

1. Clone the baseline repository.
2. Initialize `docs/project/` with `scripts/init-project.sh`.
3. Start the selected AI coding agent from the repository root (the top-level project directory) and
   prompt it to begin.

The first prompt can be short:

```text
Let's begin.
```

A well-oriented agent should not start writing product code. It should read the repository
instructions, inspect `docs/project/project.yaml` (the project manifest, or compact tracking record
for current project state), identify the current gate, confirm ownership and collaboration mode
(how proactively the agent should act and when it must pause), and begin the G1 vision loop
(the first gate cycle where the vision artifact is drafted, reviewed, and approved).

## Success Standard

The orientation phase is successful when the human and agent both know:

- what project is being initialized;
- who owns product and approval decisions;
- which collaboration mode is active;
- which gate is current;
- which artifact is active;
- how success will eventually be measured;
- what the next human decision will be.
