# GenDev Practitioner Guide

Status: Draft
Audience: Product owners, developers, system architects, technical leads, and AI-agent operators.

## Purpose

The GenDev Practitioner Guide is the field manual for using this repository as a baseline for
AI-assisted product development. It explains how a human team member and one or more AI coding
agents move from a short starting prompt, such as `Let's begin`, through product definition,
architecture, build planning, implementation, review, deployment readiness, production operation,
and as-built close-out.

This guide assumes the reader is comfortable with Git, a terminal, the operating-system shell, and
the basic idea of an AI coding agent. It does not assume the reader already knows the GenDev
methodology.

## Reading Path

Read chapters 1 through 7 before using the methodology on a real project. Chapters 8 through 11 are
used as the project moves into implementation and production. Chapters 12 through 18 provide a
worked example, tool-specific notes, prompts, checklists, failure-mode diagnostics, and terminology
reference.

The chapters define GenDev-specific terms inline at first use where a new practitioner may need
immediate context. Chapter 18 provides the deeper glossary for review and reference.

The appendix, Starting Mid-Stream, is reference material for one specific case: bringing GenDev to a
repository that already holds a vision, PRD, or architecture written before the methodology was in
place, as often happens when a project grows out of presales work. Read it when that is your
starting point rather than a blank slate.

The guide now assumes the hardened GenDev baseline: explicit approvals, structured gate records,
artifact provenance, amendment/regression discipline, independent review context provenance,
enforcement class, blast-radius scaling, process metrics, value review, and production operations.
It also assumes the documentation-structure baseline: the principle of technique neutrality
(Chapter 02), canonical artifact naming and the architecture-independent documentation scaffold
(Chapter 03), and the supporting-artifact mechanism by which a technique's design artifacts attach
to canonical artifacts as typed references (Chapter 06).

1. [Orientation](01-orientation.md)
2. [Core Mental Model](02-core-mental-model.md)
3. [Repository Map](03-repository-map.md)
4. [Starting A New Project](04-starting-a-new-project.md)
5. [Working With The Agent](05-working-with-the-agent.md)
6. [Gates And Artifacts](06-gates-and-artifacts.md)
7. [Approvals And Risk](07-approvals-and-risk.md)
8. [Subagents And Delegation](08-subagents-and-delegation.md)
9. [Build Planning And Implementation](09-build-planning-and-implementation.md)
10. [Review, Remediation, And Close-Out](10-review-remediation-and-closeout.md)
11. [Production Operations](11-production-operations.md)
12. [Vendor Contract Tracker Walkthrough](12-vendor-contract-tracker-walkthrough.md)
13. [Codex-Specific Notes](13-codex-specific-notes.md)
14. [Claude Code-Specific Notes](14-claude-code-specific-notes.md)
15. [Prompt Library](15-prompt-library.md)
16. [Checklists](16-checklists.md)
17. [Common Failure Modes](17-common-failure-modes.md)
18. [Glossary](18-glossary.md)

Appendix: [Starting Mid-Stream](19-starting-mid-stream.md)

## How To Use This Guide

This guide is written as a field manual with examples that resemble a tutorial. Each chapter
explains:

- what the practitioner is trying to accomplish;
- what the human team member owns;
- what the lead agent should do;
- what files normally change;
- what approvals or stop points apply;
- example prompts and expected agent behavior.

The methodology reference docs remain authoritative. If this guide and a methodology protocol
conflict, use the protocol and update this guide.

Primary authority references:

- `AGENTS.md`
- `docs/methodology/constitution/gendev.md`
- `docs/methodology/guides/`
- `docs/project/project.yaml`, after initialization
- `docs/project/approvals/gate-log.md`, after initialization

## Version Status

This guide is aligned with the hardened pre-1.0 GenDev baseline. It is intentionally complete
across the lifecycle while keeping the walkthrough thin enough to read end to end. As the
methodology matures, the walkthrough should be embellished with richer artifact excerpts, stronger
production evidence, and more tool-specific addenda.
