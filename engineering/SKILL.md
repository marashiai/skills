---
name: engineering
description: Apply pragmatic, verification-first engineering practices to software planning, implementation, conditional prerequisite discovery, delegation, review, and delivery. Use when an agent must implement or supervise code changes, split genuinely dependent work into issues and pull requests, coordinate child agents or observers, interview a non-technical product owner, review a proposed solution for simplicity and correctness, or verify a user-facing change before merging.
---

# Engineering

Engineer for the intended product behavior, with the smallest complete solution and evidence that it works.

## Establish the contract

1. Inspect the issue, code, assets, tests, environment, and repository instructions before asking questions.
2. Ask only a few material product questions whose answers would change the result. Do not ask a layperson to decide technical details, prompt-engineering choices, or facts discoverable from the project.
3. State important assumptions and verify them. Treat an unverified assumption as an open item, not a fact.
4. Prefer established product and industry conventions when the choice is technical and low-risk.
5. Treat material ambiguity or contradictory requirements as a hard gate. Stop the active implementation before it makes a product-level assumption, explain the decision that needs resolution, and ask the product owner to clarify. Resume only after the contract is clear.

## Tidy first when needed

Do not add cleanup, refactoring, or a prerequisite phase by default. Proceed directly when the existing design supports a simple, proper implementation.

While planning, notice evidence that the requested behavior cannot be implemented cleanly through the existing ownership boundaries, public APIs, mutation paths, persisted state, real runtime surfaces, or test seams. Investigate only the suspected impediment far enough to verify it.

Treat a missing shared capability as separate enabling work when implementing the feature without it would require a workaround, duplicated source of truth, path-specific patches, a fake production surface, or an inappropriate ownership violation. A normal feature-local helper or cohesive internal change is not a separate prerequisite merely because it is new.

When a genuine prerequisite has its own contract or risk, stop the dependent plan. Create or request a separate issue when authorized, then use a separate plan, branch, and pull request. Merge it and refresh the base before planning the dependent feature. Otherwise keep the cohesive change in the feature issue.

Stop and re-plan when implementation materially exceeds the approved solution shape, crosses an unplanned ownership boundary, reveals a missing shared capability, duplicates production behavior in a fixture, accumulates case-by-case patches, or receives the same class of material review finding twice. Decide whether a verified prerequisite must be extracted instead of continuing a piecemeal review-fix loop.

## Choose the solution

- Prefer a simple, proper fix over a workaround, compatibility layer, speculative abstraction, or broad rewrite.
- Fix the root cause within scope. Do not preserve obsolete behavior merely for backward compatibility unless a real supported contract requires it.
- Fail fast with a useful, correctly presented error when continuing would require an arbitrary or unsafe default.
- Keep the change cohesive and as small as possible without leaving the user journey incomplete.
- Challenge defaults, fallbacks, and extra complexity: require a verified need for each one.

## Structure delivery

- For multiple issues, start with low-hanging fruit and sequence work when tasks share a resource-constrained machine.
- Keep one issue, one approved plan, one branch, and one pull request. Do not combine unrelated issues.
- Finish, review, merge, and update the base branch before beginning the next issue.
- Use the repository's required test, lint, commit, branch, and pull-request conventions.
- Ensure the pull request closes its issue; after merge, confirm the issue actually closed.

## Delegate without losing control

1. Give each agent a precise contract: scope, acceptance criteria, constraints, validation, and forbidden actions.
2. Run child agents in pair/observable mode whenever supported.
3. Assign an observer to watch paired children and pre-authorize it to steer or restart immediately on scope drift, skipped tests, unjustified assumptions, stalls, validation shortcuts, or a tidy-first re-plan trigger. Let the observer own implementation-level monitoring and correction.
4. Keep the primary agent at the orchestration level. Do not inspect, copy, summarize, or repeatedly poll the child's implementation stream; consume only plans, state transitions, gates, material findings, questions, and final evidence.
5. Do not run multiple resource-heavy implementations, Docker stacks, or test suites concurrently on a shared laptop. Tell agents where work runs and what resources they share.
6. Hold the implementer accountable for an independent review, a correction loop, and re-verification. Pull-request creation is not completion.

## Wait efficiently

- Prefer durable background work and event-driven notifications that return control when a meaningful state changes: plan ready, product question, verified prerequisite, blocked run, review result, verification result, pull request ready, CI completion, or merge completion.
- Never use a delayed `functions.exec` cell, `setTimeout`/`notify` callback, yielded tool cell, or later `functions.wait` read as a wake mechanism. Its completion can remain queued until another user turn and therefore does not autonomously resume work.
- For a delayed resume, use a previously verified background controller or collaboration task whose completion produces a real agent/mailbox event, and remain on that event wait. Do not end the turn while assuming pending tool output will wake the primary agent.
- Call a mechanism event-driven only when its completion automatically resumes or notifies the controller. A background process, terminal session, filesystem watcher, or waiter that must be checked with timed `write_stdin`, `wait`, status, file, or process calls is not event-driven.
- Once an event-driven wait is armed, never poll the work, watcher, waiter, terminal, or notification wrapper. Let the event return control.
- Before choosing an event wait, verify its delivery semantics. If it cannot notify the controller, do not wrap it in another polling loop or describe it as event-driven. Use a genuine callback/completion notification, or—only when polling is allowed—poll one high-level status surface directly with exponential backoff, reset after real progress, and a reasonable cap.
- Do not spend primary-agent context or tool calls on heartbeat polling.
- Never use polling as a reason to read live implementation logs or absorb code-level details. Ask the observer for a concise gate summary when intervention is required.
- Answer discoverable technical questions through the observer's project inspection. Escalate only material product ambiguity or contradictory requirements to the user.

## Manage context

- Keep always-loaded instructions small and complete.
- Put specialized procedures in skills or focused references instead of a large system prompt.
- Give agents only the task-local context they need, and let them inspect source artifacts for the rest.
- Use subagents for bounded work and independent review, not to duplicate the same context across parallel implementations.

## Verify before delivery

Require evidence proportional to risk:

1. Capture the expected failing test before implementation when test-driven development applies.
2. Run the relevant automated tests and lint checks in the repository-required order.
3. Verify every acceptance criterion against actual behavior, not only code shape or an agent's claim.
4. For user-facing work, perform final visual verification in the real browser/runtime environment. Inspect the resulting state and the full recovery or interaction path; a unit test alone is insufficient.
5. Run an independent code review focused on correctness, security, regression risk, unnecessary complexity, unverified assumptions, and prerequisites that were mistakenly folded into the feature. Classify repeated architectural findings as evidence that the plan is wrong, not as an invitation for another local patch.
6. Apply valid findings, then rerun the affected checks and visual verification.
7. Wait for required CI checks. Review the final pull-request diff and metadata before merging.

For authenticated verification, create or reuse a dedicated least-privilege test account; never ask for or use the product owner's personal or administrator credentials. Prefer the product's supported signup, provisioning, or seed flow. Do not modify a datastore unless the owner explicitly authorizes it and the target is verified as a non-production development environment. When no provisioning surface exists and the owner explicitly authorizes local datastore provisioning, derive the canonical account schema and credential hashing from current code and migrations, prefer an existing application command when available, and otherwise make the smallest transactional insert into the resolved local database. Never bypass authentication or write directly to production. Keep test credentials in an approved local secret location excluded from version control; never echo them into chat, logs, plans, commits, or pull requests.

For a WYSIWYG editor, treat fidelity as a product contract: the editor must render the authored elements exactly as users will encounter them in the real output. Verify the same persisted state and relevant interactions on both surfaces; do not accept an editor-only approximation or a presentation-only shortcut that makes behavior diverge.

## Merge and continue

- Merge only when scope, review, automated checks, and visual verification are all satisfied.
- Prefer squash merge when the delivery workflow requests a clean per-issue history.
- Refresh or rebase the local base branch onto the merged remote state before planning the next issue.
- Report concrete evidence: pull request, checks, visual verification, merge result, base-branch update, and issue closure.
