Here is a first ARD draft you can refine.

# Architecture Directive Record: Agent-Buildable Modern UI Stack

## 1. Purpose

This Architecture Directive Record defines the approved UI development stack, project structure, coding conventions, and enforcement rules for applications built primarily or partially by AI coding agents.

The goal is to maximize agent reliability, reduce architectural drift, improve maintainability, and ensure that generated code follows a consistent, testable, production-ready methodology.

## 2. Approved Stack

The approved default UI stack is:

* **Language:** TypeScript
* **Application Framework:** Next.js using the App Router
* **UI Library:** React
* **Styling:** Tailwind CSS
* **Component System:** shadcn/ui
* **Primitive Components:** Radix UI
* **Forms:** React Hook Form
* **Validation:** Zod
* **Client/Server State:** TanStack Query where needed
* **Database Access:** Prisma or Drizzle
* **Database:** PostgreSQL
* **Authentication:** Auth.js, Clerk, or Supabase Auth
* **AI Integration:** Vercel AI SDK
* **Testing:** Vitest, Testing Library, and Playwright
* **Package Manager:** pnpm
* **Deployment Target:** Vercel or containerized Node.js runtime

No substitutions are permitted without an approved architecture exception.

## 3. Architectural Principle

The system must be designed for predictable agent execution.

Therefore:

* Prefer explicit conventions over implicit judgment.
* Prefer boring, well-documented patterns over clever abstractions.
* Prefer typed boundaries over informal contracts.
* Prefer small feature slices over broad multi-file rewrites.
* Prefer reusable components over duplicated UI logic.
* Prefer server-side logic unless client-side interactivity is required.

## 4. Project Structure

The agent must follow this folder structure:

```text
/src
  /app
    /(routes)
    /api
  /components
    /ui
    /layout
    /feature
  /lib
    /auth
    /db
    /ai
    /utils
  /features
    /<feature-name>
      components
      actions
      schemas
      queries
      tests
  /hooks
  /types
  /styles
/tests
  /unit
  /integration
  /e2e
```

Rules:

1. `components/ui` contains shadcn/ui components only.
2. Feature-specific components must live under `/features/<feature-name>/components`.
3. Shared layout components must live under `/components/layout`.
4. Server actions must live under the relevant feature’s `actions` folder.
5. Zod schemas must live under the relevant feature’s `schemas` folder.
6. No business logic may be placed directly inside React components unless trivial.
7. No API boundary may exist without a corresponding TypeScript type and Zod schema.

## 5. TypeScript Rules

The project must use strict TypeScript.

Required rules:

* `strict: true`
* No `any` unless explicitly justified in a comment.
* No untyped API responses.
* No untyped form payloads.
* No untyped environment variables.
* All external input must be validated with Zod.
* All shared interfaces must live in `/types` or the relevant feature folder.

The agent must not bypass type errors by weakening types.

## 6. UI Component Rules

All UI must be built from:

1. shadcn/ui components
2. Tailwind utility classes
3. feature-specific composed components

The agent must not introduce a new component library unless explicitly approved.

Rules:

* Use shadcn/ui for buttons, dialogs, cards, inputs, tables, dropdowns, tabs, forms, alerts, and navigation primitives.
* Use Radix primitives only when shadcn/ui does not already provide the required component.
* Do not create custom base components when a shadcn/ui component exists.
* Do not use inline styles except for dynamic values that cannot be represented cleanly with Tailwind.
* Do not hardcode repeated design values.

## 7. Styling Rules

Tailwind CSS is the only approved styling system.

Rules:

* No CSS Modules unless approved.
* No styled-components.
* No Emotion.
* No Bootstrap.
* No Material UI.
* No arbitrary design systems introduced by the agent.
* Use semantic layout patterns.
* Preserve responsive behavior.
* Prefer accessibility-safe defaults.

## 8. Forms and Validation

All forms must use:

* React Hook Form
* Zod
* `zodResolver`

Rules:

* Every form must have a schema.
* The schema is the source of truth for validation.
* Server-side validation is mandatory.
* Client-side validation is helpful but insufficient by itself.
* Error messages must be visible to the user.
* Submit states must show pending, success, and failure behavior.

## 9. Data Access Rules

Database access must occur through the approved database layer.

Rules:

* No raw SQL unless approved.
* Use Prisma or Drizzle consistently.
* Do not mix Prisma and Drizzle in the same application.
* Data access logic must not be placed in UI components.
* Mutations must validate input before execution.
* Queries must return typed results.
* Sensitive fields must never be sent to the client.

## 10. AI Integration Rules

AI features must use the approved AI integration layer.

Rules:

* Use Vercel AI SDK unless otherwise approved.
* Place AI logic under `/lib/ai` or the relevant feature folder.
* Prompts must be versioned or named.
* Tool calls must have typed inputs and outputs.
* Streaming responses must handle loading, cancellation, and error states.
* AI-generated content must be clearly distinguishable where required.
* Never expose model secrets, API keys, or provider credentials to the client.

## 11. Environment and Configuration

Environment variables must be explicitly typed and validated.

Rules:

* Use a central environment validation file.
* Do not access `process.env` throughout the codebase.
* Do not hardcode secrets.
* Do not commit `.env` files.
* Provide `.env.example`.
* Fail fast when required configuration is missing.

## 12. Agent Coding Rules

The AI agent must follow these directives:

1. Implement one feature slice at a time.
2. Do not rewrite unrelated files.
3. Do not introduce new dependencies without justification.
4. Do not change architecture without an explicit instruction.
5. Do not silence lint, type, or test failures.
6. Do not remove tests to make the build pass.
7. Do not weaken validation to satisfy TypeScript.
8. Do not duplicate existing components or utilities.
9. Check existing project conventions before generating new code.
10. After every change, run the required quality gates.

## 13. Required Quality Gates

Before work is considered complete, the agent must run:

```bash
pnpm lint
pnpm typecheck
pnpm test
pnpm build
```

For user-facing flows, the agent must also run:

```bash
pnpm test:e2e
```

The agent must report:

* Files changed
* Dependencies added
* Tests added or modified
* Commands run
* Remaining risks
* Known limitations

## 14. Testing Rules

Testing is mandatory for meaningful behavior.

Rules:

* Utility functions require unit tests.
* Server actions require validation and failure-path tests.
* Forms require interaction tests.
* Critical user journeys require Playwright tests.
* Regression tests must be added for bug fixes.
* Snapshot tests are discouraged unless justified.

## 15. Accessibility Rules

All UI must meet basic accessibility expectations.

Rules:

* Use semantic HTML.
* Labels are required for form fields.
* Buttons must have accessible names.
* Dialogs must be keyboard accessible.
* Color alone must not communicate state.
* Loading and error states must be announced where appropriate.
* Do not remove accessibility attributes from shadcn/ui or Radix components.

## 16. Security Rules

Security-sensitive behavior must be explicit.

Rules:

* Validate all inputs.
* Sanitize rendered user content.
* Do not expose secrets to the browser.
* Use server-side authorization checks.
* Never trust client-side role checks.
* Log security-relevant failures.
* Avoid storing sensitive data unless required.
* Use least-privilege access patterns.

## 17. Dependency Rules

The agent may use approved dependencies only.

Approved by default:

* Next.js
* React
* TypeScript
* Tailwind CSS
* shadcn/ui
* Radix UI
* React Hook Form
* Zod
* TanStack Query
* Prisma or Drizzle
* Vercel AI SDK
* Vitest
* Testing Library
* Playwright

Any additional dependency requires:

* Purpose
* Alternative considered
* Bundle impact
* Maintenance risk
* Security risk

## 18. Definition of Done

A feature is done only when:

* It follows the approved folder structure.
* It uses approved stack components.
* It has typed inputs and outputs.
* It validates all external input.
* It handles loading, success, empty, and error states.
* It includes appropriate tests.
* It passes linting, type checking, tests, and build.
* It does not introduce architectural drift.
* It includes a concise implementation note.

## 19. Prohibited Patterns

The agent must not:

* Use JavaScript when TypeScript is expected.
* Use `any` to escape type safety.
* Add a second styling system.
* Add a second component library.
* Put database queries inside React components.
* Put business logic inside route files when it belongs in features.
* Skip validation.
* Skip tests.
* Modify unrelated architecture.
* Introduce global state without justification.
* Store secrets in client-side code.
* Generate large, unreviewable code changes.

## 20. Architecture Exception Process

An exception is required when deviating from this directive.

An exception must include:

* Requested deviation
* Reason
* Scope
* Expected benefit
* Risk
* Mitigation
* Expiration or review date

No exception is valid unless explicitly approved by the project owner or architecture authority.

## 21. Agent Prompt Contract

Every AI coding agent working on this project must be given the following instruction:

> You are working inside a governed Next.js, TypeScript, Tailwind, shadcn/ui application. Follow the Architecture Directive Record exactly. Do not introduce new architecture, dependencies, folder structures, styling systems, or validation patterns unless explicitly instructed. Implement only the requested feature slice. Preserve existing conventions. Validate inputs with Zod. Use strict TypeScript. Run lint, typecheck, tests, and build before completion. Report all changes clearly.

## 22. Status

Status: Proposed
Owner: Architecture Team
Applies To: Agent-built UI applications
Review Cadence: Every 90 days or after major framework upgrades

This is a strong v1. Next, I’d probably add a **“Feature Slice Template”** section so every agent task has the same required implementation shape.
