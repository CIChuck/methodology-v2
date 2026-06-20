
# Formal Verification in Spec-Driven Development — Enterprise Level

## In regulated enterprise, a specification becomes an executable contract. Why AI-generated code must be proven with formal methods, not just tested.


Your AI-generated code passed every test. In a regulated bank, that doesn’t mean it’s correct — it means you haven’t checked it where it will break. **Green CI lights give comfort that a financial auditor won’t buy.**

==At enterprise scale, a specification stops being a descriptive document. It becomes an== ==**executable contract**== ==— a versioned artifact with conditions the code must satisfy.== An AI agent must fulfill that contract, because no auditor will accept “tests passed” as proof of compliance.

There’s been a lot of discussion lately about a **gap in spec-driven development** — most teams write a spec but don’t code it into enforceable tests. That’s a fair diagnosis and a good starting point. But at the level of a regulated enterprise, that gap goes much deeper.

Over the next 10 minutes, you’ll see **what separates a proof from a test**, which tools from the rigor ladder apply to which problem, and how to build a roadmap you can defend before a regulator — without a PhD in proof theory.

## The One Thing That Matters: Proof and Test Are Two Different Classes of Guarantee

Let me start with the single thought you must take away from this article: **a test and a proof are two different classes of guarantee, not two levels of the same thing.** A test executes a program for a finite sample of inputs — even a million runs is still a sample. Formal verification exhaustively searches the entire modeled state space and proves that a given property always holds, or produces a concrete counterexample.

This isn’t “better testing.” It’s a different operation: **empirical sampling versus mathematical proof.** For code written by hand, that difference was often academic. For AI-generated code, it isn’t — because language models are masters at **passing tests.** They were trained on millions of test files, so they perfectly mimic the patterns of correct code, while simultaneously hiding an architectural flaw somewhere no test will ever look.

In a regulated enterprise, where a single bug means a financial penalty or a threat to human life, “tests passed” is no longer sufficient proof of compliance. This is the thesis of the whole article: **SDD closes the loop only with formal methods** — contracts, property-based testing, and model checking. One condition keeps everything in check: a proof is valid only within the boundaries of what you modeled. Beyond the model, there’s no guarantee, and that’s the entire craft.

Let’s start with why a descriptive document at the enterprise level simply stops being enough.

## Why Enterprise Needs More Than a “Markdown Spec”

Not long ago, **“vibe coding”** was the default — coding by feel, where an engineer hands the wheel to the model and stops reading code line by line. In a simple web project, that works surprisingly well. In a regulated system — financial, medical, or aviation — it ends in rapid architectural degradation and **intent drift:** the divergence between what you wanted and what the agent took as its default assumption.

Spec-Driven Development is the answer to that chaos. It inverts the workflow: the spec document stops being a description created after the fact and becomes the primary, versioned artifact from which code is merely a derived output. Early deployments in non-trivial agentic tasks report several-fold increases in first-pass success rate — the share of tasks completed correctly on the first attempt.

But SDD’s maturation exposed its weak point. Julias Shaw described a widespread gap, and Martin Fowler popularized it in March 2026: people write specs before prompting en masse, but **almost nobody takes the next step** — nobody codes those specifications into executable tests that actually enforce the contract. A spec is a plan — the safety net is the test suite that catches the moment code deviates from it.

That’s an accurate observation, but it addresses the **spec → executable tests** gap, not the tests → formal verification gap. This is where my own thesis comes in — an extension of that one. For an ordinary web application, automated tests are a sufficient safety net. At the level of a regulated enterprise, with AI-generated code, **tests aren’t enough** — and the gap reaches all the way to formal verification.

The limit of a “Markdown spec” isn’t a matter of team discipline. It’s structural: a descriptive document doesn’t enforce its own execution, and AI-generated code drifts from intent faster than a human can catch it in review. In banking, a contract with a vendor can’t say “do it nicely” — it needs clauses that can’t be broken, and proof that they weren’t. The spec must therefore evolve from a Markdown format into an **executable contract.** And since a document isn’t enough, one question worth the entire article remains: what exactly separates a proof from a test?

Press enter or click to view image in full size

![](https://miro.medium.com/v2/resize:fit:2000/1*82EGDohaf43ov7P14cfJEA.png)

_From vibe coding to executable contract: why enterprise needs more than a document._

## Formal Verification vs. Classical Tests — Proof vs. Sampling

### The intuition: state space and its scale

Start with the intuition, because without it the rest makes no sense. A system with 10 bits of state has 1,024 possible states. A system with 100 bits of state has 2 to the power of one hundred — **a number on the order of 10³⁰, astronomically large**, which no real test suite will ever finish sampling.

**A test samples that space**, hitting a handful of points. A model checker searches it exhaustively, within the bounds of the model, and either confirms a property or returns a concrete trace leading to its violation.

> _“No amount of experimentation can ever prove me right; a single experiment can prove me wrong.” — Albert Einstein, Physicist_

Einstein described the scientific method here, but the sentence perfectly captures the limits of software testing. Testing is empirical — it falsifies the hypothesis “the program works” by looking for a counterexample. The absence of a bug in tests doesn’t prove correctness. It only proves that the selected sample of paths didn’t hit a defect. Dijkstra put it more bluntly: **tests show the presence of bugs, never their absence.** Formal verification works differently — like mathematics, deductively ruling out the existence of a bug across the entire modeled scope.

### AWS: a bug at step 35 that nobody saw

The best illustration of this difference comes from a major cloud provider. Engineers described a distributed replication system in TLA+ and ran the model checker on it. The machine found a bug that could lead to data loss — **it only appeared in a trace spanning 35 steps** of a specific failure-and-recovery sequence. This bug survived numerous design reviews, code reviews, and tests undetected. None of those techniques had any chance of reproducing it. The checker found it quickly.

This is precisely where the proof/test distinction becomes critical for AI-generated code. Modern coding assistants were trained on vast corpora of test files, so they generate code that **flawlessly passes unit and integration tests**, mimicking all the right patterns — and yet hides structural flaws deep in business logic. Formal verification eliminates that vector, because a proof of bug absence doesn’t depend on whether anyone thought of the edge case. The key insight: a model checker asks about all states, not just the ones you thought of.

### The boundary of a proof: model scope is everything

There’s a boundary that can’t be glossed over. **A proof is valid only within the modeled state space and the chosen abstraction.** A mismatch between the model and the actual implementation produces false confidence.

Ariane 5 exploded despite code that was correct relative to its specification — because the spec, copied from an earlier rocket, was wrong for the new flight trajectory. Parts of the WPA2 protocol were formally analyzed, and the KRACK attack still exposed a weakness in the 4-way handshake mechanism of the 802.11i standard — because the vulnerability lived in the specification layer, not in a single implementation. Proof of compliance isn’t proof of model correctness.

In practice, this means one question every architect must keep asking themselves: what exactly did I model, and does my model match production? That question beats blind faith in green tests. Since a proof beats a test but only within model scope — which tools should you use and at what level of rigor?

Press enter or click to view image in full size

![](https://miro.medium.com/v2/resize:fit:2000/1*jV3SUi0oKSCcsRBMl-v6MQ.png)

_Sampling vs. proof: a test checks a few paths, model checking checks all of them — within the model’s bounds._

## Tools and Frameworks in 2026 — A Rigor Ladder, Not a Leap

The biggest mistake in adopting formal methods is treating them as binary: either you prove everything or you prove nothing. **The right model is a rigor ladder** — a continuum of cost and strength, which you climb only as far as the blast radius demands. You don’t put every screw through aviation certification, but the one holding the engine, you absolutely do.

### Light rigor: contracts and property-based testing

The lowest, cheapest rung is assertions and types. Just above them sits **Design by Contract (DbC)** — a way of writing code where every function declares entry conditions (preconditions), output guarantees (postconditions), and invariants. It’s the executable part of the specification, embedded directly at the module boundary (a concept formalized by Bertrand Meyer in the Eiffel language). Modern runtime implementations are everywhere: the icontract library in Python, and SPARK in Ada. (A naming note: “Kotlin contracts” are compiler hints, not classical runtime DbC in Meyer’s sense.) For AI-generated code, a contract is a natural guardrail — **any implementation satisfying the same contract is interchangeable and verifiable against a fixed specification.**

One rung higher sits **property-based testing (PBT).** Instead of individual examples, you define a rule the code must always satisfy, and the framework generates thousands of random, mutated inputs trying to break it (a technique from the late 1990s). PBT is an interesting middle rung by nature: highest **fidelity** (it runs real code), but still sampling — it doesn’t prove the absence of bugs, it checks the rule against a massive random sample. ==That’s an honest trade-off between a test and a proof.==

### Heavy rigor: model checking and proofs

At the top of the ladder for distributed systems sits **TLA+** (by Leslie Lamport) — a language for describing how a system should behave, not for writing code. You describe states and transitions in simple discrete mathematics, and the TLC model checker explores the entire reachable space, looking for violations. It proves two kinds of properties: **safety** (“nothing bad will happen”, e.g., two clients won’t get the same record) and **liveness** (“something good will eventually happen”, e.g., the system won’t deadlock).

Alongside TLA+ stands **Alloy** (designed by Daniel Jackson at MIT) — and here’s a naming warning, because the name misleads. This is the formal methods language for relational logic, not the fintech company of the same name. Alloy examines structures and relationships — data schemas, access control models — using bounded model checking over a small scope. Where TLA+ handles temporal sequences brilliantly, **Alloy proves the absence of gaps in permission models.** The bridge from prose to these tools is the **EARS** notation — five patterns (Ubiquitous, Event, State, Unwanted, Optional) that convert soft “should” into unambiguous, formalizable “must.”

From this ladder, a simple decision framework emerges: contracts at the boundaries of AI-generated modules, TLA+ for consensus and distributed state, and Alloy for permissions. The ladder makes sense in theory — but does anyone in a regulated industry actually use it?

Press enter or click to view image in full size

![Pyramid of verification rigor levels from contracts to proof assistants, with descriptions of what each proves and at what cost.](https://miro.medium.com/v2/resize:fit:2000/1*SCd2hR1xYkd0dyEAKfkr7A.png)

_The rigor ladder: from cheap contracts to expensive proofs — you choose a rung, not a leap._

## Examples from Regulated Companies — Proof in Production

The strongest ROI evidence doesn’t come from vendor marketing but from infrastructure where a single bug is irreversible. That’s where formal methods are the norm, not a curiosity. I’ll say this honestly, though: **there are surprisingly few public case studies from named large banks.** The best available proxy for “regulated infrastructure” remains a major cloud provider.

That provider has used TLA+ since 2011 across 10 large production systems, in seven teams. What’s most interesting about that story isn’t the scale, but the learning curve: engineers from junior to principal learned TLA+ **from scratch in two to three weeks**, sometimes on their own time, and caught bugs unreachable by any other technique. This dismantles the myth that formal methods require a PhD in mathematics.

In the transactional world, there are more precedents, though rarely with a banking nameplate. Financial ledger databases are sometimes validated with **deterministic simulation** — running the system thousands of times in a repeatable failure world, with thousands of assertions in production code. Smart contract verification protects billions in value locked in DeFi protocols. In one financial deployment, business logic was described in the Lean 4 proof assistant, which **proved the existence of flaws invisible to tests** — that wasn’t a coverage gap, it was a mathematical proof.

The most mature precedents come from outside fintech. A metro line built with the B-Method hasn’t had a functional failure in over 25 years of operation. Avionics has the DO-333 supplement as a formal complement to the DO-178C standard. Automotive combines Simulink modeling with certified code generation under ISO 26262. The CompCert verified compiler let Airbus improve its guaranteed worst-case execution time (WCET) by 12%. The common denominator is simple: **the cost of a bug exceeds the cost of the verification team.**

Regulations add pressure, though none mandate formal methods by name. The EU DORA regulation on digital operational resilience in financial services has been in effect since January 17, 2025. The EU AI Act classifies credit scoring as a high-risk system. ISO/IEC 42001 and the NIST AI RMF enforce traceability and verification rigor.

All these regimes demand one thing: **bidirectional traceability** — regulation → requirement → implementation → proof. That’s the role of a Compliance Traceability Matrix, which ties the spec to the audit and gives the regulator a hard trail.

Since this works but costs money — what does AI change, supposedly lowering the entry barrier?

Press enter or click to view image in full size

![](https://miro.medium.com/v2/resize:fit:2000/1*xY8ohMA9TPNrIw9Pk11Q7w.png)

_Proof in production: where and how regulated industries apply formal verification._

## How AI Helps with Formal Verification — and Where It Goes Wrong

Here’s an elegant paradox. The probabilistic nature of a language model, normally a liability, becomes harmless in formal methods. AI plays three real roles: it translates specifications from natural language to a formal model (**autoformalization**), generates properties to check, and converts raw counterexamples into human language. Each role lowers the entry barrier that kept formal methods in a niche for decades.

### Why AI hallucinations don’t hurt — this time

**A proof checker rejects every invalid proof** and forces a retry — so it doesn’t matter that the model sometimes fabricates, because the checker catches that deterministically. It’s like a chatty intern writing drafts: the checking machine throws every wrong draft in the trash, and only what passes gets to production. With one condition — the machine has the final word, not the model. A researcher in distributed systems summed up this intuition well in late 2025, predicting that AI would make formal verification mainstream.

But the boundary needs to be set firmly, because the hype blurs it. Today’s benchmarks are unforgiving: in TLA+ spec generation, the best models achieve around **8.6% semantic correctness** and 26.6% syntactic. In the broader task of generating code together with a proof of correctness (vericoding), results range from 27% to 82% depending on the language. The conclusion is clear and uncomfortable: **an AI-spec is a draft to be verified by machine, not a source of truth.** Whoever treats a generated specification as a finished artifact transfers the risk from the model to production.

### The feedback loop: synthesis → compilation → repair

The mechanism that actually lowers costs is exactly this loop. The AI generates an initial formal model, the parser and checker reject erroneous clauses, the model corrects — and round it goes, until something syntactically and semantically correct emerges. It’s this feedback cycle, not the model’s raw talent, that cuts formalization hours.

One thing remains unsolved: **the ambiguity of natural language.** Spec ambiguity propagates into formal model errors, and LLM non-determinism amplifies it. AI doesn’t eliminate this. That’s why the practical pattern is: let the model write a draft contract or model, but never trust it without running it through the checker. Since AI lowers costs but doesn’t eliminate them — when does this investment pay off, and when is it overkill?

Press enter or click to view image in full size

![Diagram of the generation-verification loop: a language model creates a draft, the checker rejects bad versions, a correct proof passes through.](https://miro.medium.com/v2/resize:fit:2000/1*OmHjAMAtguQv55ZuModr3g.png)

_AI writes the draft, the checker has the final word: the synthesis-verification-repair loop._

## Costs and Benefits — When It Pays Off, and When It’s Overkill

The question isn’t “whether formal methods” but “for which component.” The answer comes from the **blast radius** — how far the effects of a single bug reach — not from trends or fear of audit. You don’t buy a safe for every pen, but for a notarized deed, you do.

### Triage: when heavy rigor makes sense

Triage is straightforward. Reserve heavy rigor for distributed data consistency, payments and settlements, access control, smart contracts, and safety-critical control systems. **There, a single bug is catastrophic and irreversible.** For most features, the expected cost of bugs is simply lower than the cost of the proof — and then formal methods are overkill.

The numbers on the benefits side are real, but I’ll report them honestly, as stated. The two to three weeks of TLA+ learning and bugs unreachable by other techniques. Reported savings on the order of **hundreds of thousands of dollars per year** from just two days of modeling a critical migration. A double-digit improvement in guaranteed worst-case execution time (WCET) through a verified compiler. What’s missing is a reliable statistic on “the percentage of bugs caught” — only absolute numbers and cost data exist.

### The other side: cost and the Waterfall objection

Heavy rigor can be extremely expensive: the formal verification of an operating system kernel took approximately **20 person-years for 8,700 lines of code** — a proof-to-code ratio of roughly 23 to 1. That’s the upper bound, not the norm. A methodological objection also surfaces: heavy specification before code is sometimes criticized as a regression to Waterfall — an attempt to flatten a multi-dimensional graph into a document before you’ve even traversed that graph.

That objection deserves to be taken seriously, not dismissed. The answer isn’t to “formalize everything,” but to use **thin, local models** only at interfaces that manipulate regulated state. The rigor ladder plus blast-radius triage is the defense before a committee, without analysis paralysis. One question remains: where do you start on Monday?

## Summary — A Roadmap You Can Defend Before an Auditor

SDD at the enterprise level closes the loop only with formal verification. A descriptive document is a suggestion to an AI agent and evidence of negligence to a regulator. Here’s what you should take away for your next architecture review:

- **A proof and a test are different classes of guarantee**, not levels of the same thing — and that distinction becomes critical precisely when the author of the code is an AI optimized to “pass tests.”
- **Match the rigor ladder rung to the component’s blast radius**, not “all or nothing”: contracts at module boundaries, model checking for distributed state and consensus.
- **Treat an AI-spec as a draft to be machine-verified** — the proof checker is the guardrail, not the language model.
- **Remember the proof boundary**: it’s valid only within the modeled space — a model↔code mismatch is false confidence.

The implementation roadmap is gradual, not a leap. Start with lightweight contracts and the EARS notation at the boundaries of regulated state — that’s a cheap, fast win. Introduce property-based testing where rules are clear and inputs are rich. Reach for model checking only in components whose blast radius demands it.

At the end, tie everything together with a Compliance Traceability Matrix that maps regulations to proofs and gives an auditor a bidirectional trail. The specification stops being a document at that point — it becomes a contract you can prove.

Press enter or click to view image in full size

![](https://miro.medium.com/v2/resize:fit:2000/1*CK7O3-oGUjF5f_vUaXXB9w.png)

_The entire article in one image: from document to provable contract, and the implementation roadmap._