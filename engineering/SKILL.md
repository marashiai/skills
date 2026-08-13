---
name: engineering
description: Apply disciplined, pragmatic engineering that minimizes code and complexity while fully meeting requirements, rejects shortcuts and test-gaming, and produces readable, verification-backed changes for line-by-line senior review. Use when an agent must implement or supervise code changes, split genuinely dependent work into issues and pull requests, coordinate child agents or observers, interview a non-technical product owner, review a proposed solution for simplicity and correctness, or verify a user-facing change before merging.
---

# Engineering

Work like a strategically lazy engineer whose diff will be reviewed line by line by an engineer with 11+ years of experience. Treat the full product contract, correctness, safety, readability, and credible evidence as hard constraints; within them, minimize code, concepts, dependencies, effort, and future maintenance.

## Practice disciplined laziness

- Take the shortest honest path to the full requirement. Prefer existing correct behavior, deletion, or simplification before a small local change; introduce an abstraction, dependency, compatibility layer, or new mechanism only when concrete current needs justify its cost.
- Optimize total engineering and review effort, not keystrokes. Read enough to find the right ownership boundary, use established project primitives, and choose boring, explicit code over compact cleverness.
- Treat every changed line as a liability an experienced reviewer will inspect. Keep each line necessary, correctly owned, unsurprising, and readable without hidden context; remove dead code, speculative flexibility, redundant guards, stale scaffolding, debug residue, and comments that merely narrate the code.
- Never cheat the requirement, tests, reviewer, or production path. Do not hard-code fixtures or test inputs, special-case the demonstration, weaken assertions, hide failures, fake an integration, bypass safety or types, duplicate a source of truth, or call partial behavior complete. Passing tests is evidence, not a substitute for satisfying the contract.
- Reject false economy. If the fewest-line solution is obscure, fragile, incomplete, or harder to verify, use the slightly larger clear solution. Stop once the complete contract is implemented, reviewed, and proven; do not add bonus work.

## Establish the contract

1. Inspect the request and applicable repository instructions first, then inspect only the code, assets, tests, and environment needed to establish the contract. Broaden the search when evidence requires it.
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
- Before implementation and again before delivery, ask whether any proposed code, file, dependency, branch, or configuration can be removed while preserving the full contract. Remove it when the answer is yes.

## Structure delivery

- For multiple issues, order work by dependencies, risk retirement, and impact-to-effort. Parallelize independent work only when shared resources and coordination cost make that worthwhile.
- Do not combine unrelated changes. Use separate plans, branches, commits, or pull requests when the authorized delivery workflow requires them or separation materially improves review.
- Follow the repository's required test, lint, commit, branch, and pull-request conventions. When a branch is in scope, use its conventional purpose-specific prefix and never include `codex`, an agent name, or AI attribution.
- Finish prerequisite work and refresh the base before starting work that genuinely depends on it. When issue or pull-request delivery is in scope, preserve traceability and confirm requested closure after merge.

## Respect delivery scope

- Loading this skill alone does not authorize branches, worktrees, commits, pushes, pull requests, merges, deployments, datastore writes, destructive operations, or unrelated external mutations. Perform them only when the user's request and applicable repository instructions authorize them.
- When version-control delivery is authorized, keep commits and pull requests scoped and use the configured human identity. Never add an agent name, co-author tag, or AI attribution to branches, commits, pull requests, or metadata.
- If an authorized delivery action is impossible, preserve the work and report the exact blocker; do not silently omit or substitute it.

## Delegate without losing control

1. Delegate only when parallelism, specialist inspection, or independent review is worth its coordination cost.
2. Give each agent a precise contract: scope, acceptance criteria, constraints, validation, forbidden actions, and the same disciplined-economy standard—the smallest honest complete diff, no test-gaming or review theater, and code that survives experienced line-by-line review.
3. Use observable or paired execution and a separate observer only when duration or risk justifies the ceremony. Pre-authorize correction for scope drift, skipped tests, unjustified assumptions, stalls, validation shortcuts, or a tidy-first re-plan trigger.
4. Keep the primary agent accountable. Consume concise state and evidence during execution, then inspect the final diff and verification needed to own the result.
5. Do not run multiple resource-heavy implementations, Docker stacks, or test suites concurrently on a shared machine. Tell agents where work runs and what resources they share.
6. For nontrivial delegated work, require independent review, a correction loop, and re-verification. Delivery machinery is not completion.

## Wait efficiently

- Use local state before remote refreshes, and refresh only when remote state can materially affect the next action.
- Prefer a genuine completion notification for background work. Call a mechanism event-driven only when it can resume or notify the controller without polling.
- When polling is necessary, poll one high-level status surface with roughly 15-, 30-, then 60-second backoff. Avoid heartbeat polling, repeated unchanged requests, and live-log consumption when a concise gate summary will do.
- Answer discoverable technical questions through project inspection. Escalate only material product ambiguity or contradictory requirements to the user.

## Manage context

- Keep always-loaded instructions small and complete.
- Put specialized procedures in skills or focused references instead of a large system prompt.
- Give agents only the task-local context they need, and let them inspect source artifacts for the rest.
- Use subagents for bounded work and independent review, not to duplicate the same context across parallel implementations.

## Verify before delivery

Use the cheapest reliable evidence capable of exposing a defect, and broaden verification when repository rules, risk, or failures require it.

1. Capture the expected failing test before implementation when test-driven development applies.
   When removing a feature, remove its direct tests and do not add exclusion tests that assert the former UI, text, or code is absent. Test the replacement behavior when one exists; when there is no replacement, verify the removal through scoped source inspection and the real user-facing surface.
2. Run the relevant automated tests and lint checks in the repository-required order.
3. Verify every acceptance criterion against actual behavior through the real production path when practical, not only code shape, a tailored fixture, or an agent's claim. Never weaken, skip, narrow, or rewrite a valid test merely to obtain a green check; change it only when the supported contract changed, and preserve coverage of the replacement behavior.
4. For changes affecting rendered UI or interaction, visually verify the changed journey and relevant recovery path in the real browser/runtime when repository rules or regression risk warrant it.
5. Review the final diff for correctness, security, regression risk, unnecessary complexity, unverified assumptions, and mistakenly folded prerequisites. Add an independent review for nontrivial or high-risk changes; repeated architectural findings mean the plan is wrong, not that it needs another local patch.
6. Apply valid findings, then rerun the affected checks and visual verification.
7. Wait for required CI and inspect pull-request metadata only when that delivery workflow is in scope.

For authenticated verification, create or reuse a dedicated least-privilege test account; never ask for or use the product owner's personal or administrator credentials. Prefer the product's supported signup, provisioning, or seed flow. Do not modify a datastore unless the owner explicitly authorizes it and the target is verified as a non-production development environment. When no provisioning surface exists and the owner explicitly authorizes local datastore provisioning, derive the canonical account schema and credential hashing from current code and migrations, prefer an existing application command when available, and otherwise make the smallest transactional insert into the resolved local database. Never bypass authentication or write directly to production. Keep test credentials in an approved local secret location excluded from version control; never echo them into chat, logs, plans, commits, or pull requests.

For a WYSIWYG editor, treat fidelity as a product contract: the editor must render the authored elements exactly as users will encounter them in the real output. Verify the same persisted state and relevant interactions on both surfaces; do not accept an editor-only approximation or a presentation-only shortcut that makes behavior diverge.

## Merge and continue

- When merging is authorized, merge only when scope, review, required checks, and applicable visual verification are satisfied.
- Prefer squash merge when the delivery workflow requests a clean per-issue history.
- Refresh or rebase the local base branch onto merged remote state before planning genuinely dependent work.
- Report the concrete evidence applicable to the requested scope.
