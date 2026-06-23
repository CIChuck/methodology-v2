# Vision / Problem Framing: Documentation Coherence Linter

Status: Draft
Date: 2026-06-15
Owner: Chuck Russell
Authority: `docs/methodology/constitution/gendev.md` — Vision / Problem Framing
Produced by: human-agent collaboration
Produced on: 2026-06-15
Produced with: human-agent collaboration
Agent identity: assisting model, human-directed
Derived from:
  - path: initial human prompt or project brief
    revision: N/A

---

## Completion Standard

This document is complete when:

```text
the team can explain why the work matters and what success looks like
with measurable success criteria that can be read after deployment
```

---

## Problem Statement

Structured documentation sets accumulate coherence defects that are mechanically
detectable but are, in current practice, caught only by human or LLM review:
late, inconsistently, and at high cost. A reference points at a file that has
moved. A document's status header disagrees with its body. A downstream document
restates a rule that its governing source has since changed, and now teaches the
old rule. These are not prose-quality problems and not matters of taste; they are
factual incoherences between documents, or within one document, that have a
determinate right answer.

The people who experience this are the maintainers of any documentation set whose
documents derive authority from one another — where some documents are canonical
and others must conform to them. It matters now because review of such defects is
done by reading, and reading does not scale and does not tile the space. A human
or an LLM reviewing for coherence is exhaustible, varies between passes, and
misses on a later pass what it would have caught fresh. Defects survive review not
because they are subtle but because the reviewer ran out of attention before
reaching them.

---

## Target Users

Primary: a maintainer of a structured documentation set who needs coherence
feedback about that set. This single archetype is used at two cadences — tightly,
while authoring a document (frequent, informal, fast feedback), and deliberately,
at a review point before a document or document set is accepted (infrequent,
evidentiary). The two cadences want the same checks and the same findings; they
differ only in how often and how formally the tool is invoked.

Secondary: an automated reviewer (a CI job or an AI judge) that consumes the
tool's findings as machine-readable input to a larger decision, rather than
reading them as a human.

Explicitly not target users: authors seeking prose, grammar, or style feedback;
readers seeking rendered or formatted output; users of unstructured document sets
with no authority relationships among documents.

---

## User Pain or Opportunity

The pain is the cost and unreliability of coherence review done by reading. A
recent in-house case is illustrative: a methodology amendment was reviewed across
six rounds by a human directing an AI judge, and each round surfaced coherence
defects the prior rounds had missed — stale cross-references, a precedence
ordering that contradicted the canonical source, claims in records that other
records falsified. None of these were difficult to detect once named; they
survived multiple review passes because reading-based review does not
systematically enumerate references and claims. The reviewers exhausted their
attention before the document set was exhausted.

The opportunity is that the systematic portion of this work is automatable with
certainty. A mechanical check enumerates every reference and every checkable claim,
every run, without fatigue or variance. Automating that portion both removes a
recurring manual cost and — the larger opportunity below — supplies a
deterministic foundation that an automated review process can trust.

---

## Desired Outcomes

When this project succeeds:

- A maintainer can determine, mechanically and repeatably, whether a documentation
  set is coherent with itself and with its declared canonical sources, without
  reading the whole set.
- The systematic classes of coherence defect are caught with certainty rather than
  with the variable reliability of human or LLM reading.
- The tool's findings are actionable: each names where the defect is, what is
  wrong, and — where authority is involved — which canonical source the defect
  contradicts.
- The tool's output is consumable by both a human and an automated process,
  establishing the foundation for the longer-term goal below.

## Strategic Context: The Long-Term Goal

This tool is the short-term deliverable of a longer trajectory, and that
trajectory is its deepest justification. The longer goal is to reduce human
involvement in the review of structured work to the points where human judgment is
irreplaceable, and to allow automated judgment (AI, and in principle robotic)
elsewhere.

Review gates fall into three kinds:

- Intent gates — deciding what to build and how to shape it. Human judgment is
  irreplaceable here; intent cannot be delegated.
- Conformance gates — deciding whether work matches its ratified authority. This is
  the largest, most repetitive review burden, and it is the target for automation.
- Governance and acceptance gates — accepting risk, authorizing consequence,
  confirming the result is what was wanted. Human judgment stays here because these
  gates absorb accountability, which a machine cannot hold.

Automating the conformance tier safely requires two complementary reviewers: a
probabilistic one (an AI judge that reads for meaning, powerful but fallible and
non-exhaustive) and a deterministic one (a mechanical checker that enumerates the
systematic cases with certainty). The judge alone is insufficient — the six-round
case above is evidence of what reading-based review misses. This linter is the
deterministic reviewer: the floor beneath the judge. With it, mechanical defects
are caught with certainty and the judge's fallible reasoning is reserved for what
only judgment can assess. That division of labor is what makes withdrawing the
human from conformance review responsible rather than reckless.

This vision builds the deterministic reviewer. It does not build the judge, the
gate enforcement, or the orchestration that together complete the automated
conformance system; those are named as trajectory, not as scope (see Non-Goals).

---

## Success Criteria

| Criterion | Measure | Target | Read Timing | Owner | Evidence Source |
| --- | --- | --- | --- | --- | --- |
| Detects the four coherence check-classes | check-classes implemented and demonstrated (referential integrity, internal contradiction, structural conformance, cross-document coherence) | all four | at v1 acceptance | Chuck Russell | test corpus results |
| Findings are actionable | each finding carries location, severity, description, and (for authority defects) the conflicting canonical source | 100% of findings | at v1 acceptance | Chuck Russell | finding output inspection |
| Output is dual-consumable | human-readable rendering and machine-readable rendering with a meaningful exit code | both present | at v1 acceptance | Chuck Russell | output inspection / CI trial |
| Beats fatigued manual review on systematic defects | run against the GenDev methodology repository, detects at least one genuine coherence defect that the six manual review rounds did not catch | >= 1 such defect, OR a documented finding that none remain | at v1 acceptance | Chuck Russell | linter run on methodology repo vs. review history |
| Performance supports tight-loop cadence | wall-clock to lint a representative project doc set | fast enough for on-save use (target order: a few seconds) | at v1 acceptance | Chuck Russell | timed runs |

Note on the fourth criterion (the honest gradient): the claim "beats fatigued
manual review" is strong and provable for referential integrity, where mechanical
enumeration is strictly more reliable than reading. It is weaker and
authority-dependent for cross-document coherence, where the tool needs a correct
canonical-source declaration and lacks the judgment a human brings. The success bar
is therefore scoped to systematic defects; the tool is not claimed to be smarter
than a reviewer everywhere, only more exhaustive where exhaustiveness is what was
missing.

---

## Non-Goals

- Not a prose, grammar, spelling, or style checker. Coherence, not quality.
- Not a renderer, formatter, or previewer.
- No semantic or LLM-backed analysis in v1. Internal-contradiction detection in v1
  is bounded to mechanical and pattern-based checks; open-ended semantic
  contradiction detection is the ceiling and is out of scope for v1.
- Report-only in v1. The tool does not modify, rewrite, or "fix" documents. A fix
  mode is deferred future scope, not v1.
- Not a gate-enforcement layer in v1. The tool is invoked on demand and reports; it
  does not block gate transitions or fail builds as a binding control. Enforcement
  is named trajectory, not v1 scope.
- Not the AI judge, the judge-linter orchestration, or the loop harness. This
  vision builds only the deterministic reviewer. The probabilistic reviewer and the
  system that combines them are the larger trajectory, explicitly out of scope here.
- Not tied to one document format ecosystem beyond what v1 needs (v1 targets
  markdown); broader format support is future scope.
- Framing note: this is a general documentation-coherence linter with an
  authority-agnostic core, demonstrated first on a GenDev ruleset. GenDev is its
  first customer, not its definition. Methodology-specific needs are expected to be
  expressed as rules and authority declarations supplied to the tool, not baked
  into its core.

---

## Strategic Constraints

- Must run locally on a developer laptop with no external services, no network
  dependency, no secrets, and no database. Inputs are local files.
- Python, command-line. Chosen for low environment friction and because the tool's
  first proving ground is methodology testing.
- Must produce machine-readable output and a meaningful exit code from v1, because
  the long-term trajectory (automated conformance review) depends on those even
  though v1 itself is a human-invoked utility.
- The core must remain authority-agnostic; methodology-specific knowledge enters as
  configuration (rules and canonical-source declarations), not as hardcoded core
  logic.

---

## Major Assumptions

- Coherence defects in a real documentation set are substantially mechanical and
  therefore detectable without semantic understanding. (Risk: some real defects may
  require comprehension the v1 tool will not have.)
- A document set's authority relationships can be declared or derived (for example
  from existing provenance headers) cheaply enough to be practical. (Risk: the
  authority model may prove more complex than provenance headers support.)
- The four check-classes are the right decomposition of "coherence" for v1. (Risk:
  use may reveal a fifth class, or that one of the four splits.)
- A useful portion of internal-contradiction detection is reachable with bounded,
  pattern-based checks rather than semantic analysis. (Risk: the pattern floor may
  be too low to be useful, forcing a mid-build reconsideration.)

---

## Major Risks

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| Internal-contradiction detection requires semantic understanding the v1 tool lacks, making that check-class weak | Medium | Medium | Scope v1 internal-contradiction to a bounded pattern set; name the semantic ceiling as out of scope; let the architecture decide where under the ceiling it lands |
| The authority/canonical-source model balloons in complexity | Medium | High | Start from existing provenance headers; treat richer central declaration as a later phase; keep the core authority-agnostic so the model can grow without core rewrites |
| The tool only matches, rather than exceeds, manual review, undercutting the automation rationale | Low | High | Prove against the real GenDev repo specifically to find what manual review missed; if it only matches, that is itself a recorded finding |
| Cross-document coherence produces false "disagreements" without an authority to adjudicate | Medium | Medium | Make authority declaration the input that activates adjudication; without it, report detected disagreements as lower-severity, not as definitive errors |
| Scope creep toward the full automated-review system | Medium | Medium | Non-Goals fence the judge, enforcement, fix mode, and orchestration as trajectory; v1 is the deterministic reviewer only |

---

## Initial Security, Governance, and Compliance Concerns

v1 is report-only and reads local files, so the data-sensitivity surface is small.
The one governance concern that matters even in v1's framing is the deferred fix
mode: a tool that could rewrite a user's authoritative documents is a real safety
surface, and the decision to keep v1 report-only is partly a governance decision,
not only a scope decision. When fix mode is eventually considered, modifying
canonical documents must be treated as a governed action (explicit, reversible,
never silent). No identity, access, audit, or regulatory concerns arise from the
v1 read-only utility.

---

## Testability Implications

The systematic check-classes are highly testable: defects can be seeded into a
fixture document set and the tool's detection verified deterministically. The hard-
to-test areas are the boundaries of internal-contradiction detection (what counts
as a contradiction the bounded checker should catch versus one only semantic
analysis could) and cross-document coherence (which depends on a correct authority
declaration, so test results are conditional on test authority being declared
correctly). The clearest observable confirmation that the problem is solved is the
fourth success criterion: the tool, run on the GenDev repository, surfaces a real
coherence defect that exhaustive manual review missed.

---

## Open Questions

| Question | Owner | Due |
| --- | --- | --- |
| How is a document's authority declared — embedded in provenance headers, centrally in config, or both? | Chuck Russell | by G3 (architecture) |
| Where under the semantic ceiling does v1 internal-contradiction detection land? | Chuck Russell | by G3 (architecture) |
| Does this tool subsume, complement, or share a schema source with check-methodology.sh for structural conformance? | Chuck Russell | by G3 (architecture) |
| Are there a fifth check-class or non-functional requirements (performance, output contract) that belong in the PRD spine? | Chuck Russell | by G2 (PRD) |

---

## Accuracy Pass

```text
errors: none identified
omissions: none identified at vision scope
contradictions: none identified
scope drift: guarded by Non-Goals; the long-term goal is framed as trajectory, not v1 scope
unstated assumptions: surfaced in Major Assumptions
risks without mitigation: none; all risks carry mitigations
open questions without owners: none; all owned and dated to a gate
```

---

## G1 Exit Checklist (Vision Ready)

```text
[ ] problem is clear
[ ] target users are clear
[ ] success criteria are measurable and have read timing
[ ] non-goals are documented
[ ] open questions have owners
```
