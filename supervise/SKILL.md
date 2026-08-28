---
name: supervise
description: Supervise repository discovery, QA, GitHub issue triage, implementation, independent review, and landing as a meta-harness using either a dependency DAG or an explicit PR stack. Use when the user asks Codex to supervise, orchestrate, or take an unattended handoff with delegated workers, parallel low-conflict delivery lanes, human or merge-queue landing, merge-aware rebasing, node-local bounded retries, and strict scope and verification gates.
---

# Supervise

Act as the control plane, like a tech lead directing senior engineers. Keep task execution and artifact inspection in subagents. Retain only authorization, approved scope, acceptance criteria, attempt counters, terminal evidence, the issue and PR ledger, and the next orchestration action in the parent context.

## Non-negotiable invariants

- Obey the user's instructions and every applicable repository instruction file.
- Apply skill requirements only within the workflow phase the user authorized. Infer normal steps needed to complete that phase, but do not add earlier or later phases. Treat the user's execution contract as authoritative: skill defaults cannot silently expand a landing-only request into implementation, review, or testing. Normal engineering checks remain implied for authorized implementation unless the user explicitly defers or excludes them.
- Reuse one role agent for a homogeneous serial queue. Spawn another only for concurrent ownership, genuinely independent or clean-context review when that gate is authorized and not already satisfied by an authorized human, remediation or retry after a quality failure or deviation, suspected context contamination, or an explicit user request. Isolation comes from pinned refs, dedicated worktrees, leases, per-node packets, and ledger entries, not agent identity.
- Clarify the execution contract immediately. Before dispatching discovery, ask one concise batch of every material question already apparent from the user's request. Do not defer an obvious authorization, scope, risk, environment, or stopping-condition question until after hours of delegated work.
- Accept either a staged handoff or an unattended handoff. In a staged handoff, do not implement before the user confirms the discovered worklist. In an unattended handoff, the user may explicitly pre-authorize implementation of all later confirmed, in-scope findings; record that authorization and do not pause solely to obtain a second worklist confirmation.
- Treat an unattended handoff with an explicit outcome and scope as authorization for routine, reasonable, reversible actions needed within the authorized workflow phase; do not repeatedly ask for routine confirmations. This includes using repository-designated least-privilege local/test credentials only on their designated local/test domains, performing supported-UI representational actions needed to verify local/test behavior (for example, submitting a generated local authoring request), and posting requested proof comments or attachments to the scoped GitHub issues. It does not authorize production or deployment changes, personal credentials or accounts, direct database writes, destructive or irreversible cleanup, security-sensitive disclosure, unrelated external communication, or merge, push, PR, or publication actions not otherwise authorized. Higher-priority safety and tool policies still apply; after an express confirmation in the current continuous workflow, do not ask again for an equivalent routine action unless policy requires a new confirmation.
- Execute every authorized task step in a subagent. This includes repository and GitHub reconnaissance, backups and other safeguards, fetches and worktree setup, builds and runtime setup, QA and browser testing, issue drafting or creation, implementation, test execution, review, CI inspection, remediation, landing audits, restacking, and graph verification. Do not perform this legwork in the supervising context.
- Use tools in the supervising context only for control-plane work: plans, subagent dispatch and waiting, terminal-report classification, authorization and retry tracking, and concise user updates. A command is not control-plane work merely because it is short or precedes delegation. The agent responsible for a mutation must perform and report its prerequisites, including required backups.
- Run a direct recovery check only when an interrupted orchestration action leaves external state genuinely unknown and delegating the check cannot safely resolve it. Delegate any resulting task work.
- Require implementation and review subagents to use the `engineering` skill when it is available. Let it govern implementation quality and verification, while this skill governs authorization, isolation, graph and landing state, retries, and merge authority. Its merge guidance does not authorize a merge here.
- Map every node to one PR-sized unit, normally one issue. Record explicit dependencies instead of making unrelated work depend on delivery order.
- Use DAG mode by default when the user wants implementation, review, or merging to overlap. Independent nodes branch from freshly fetched `main` and target `main`; stack a node only on a genuine prerequisite. Use a single sequential stack only when the user requests it or the work is actually linear.
- Schedule independent nodes across only the authorized number of lanes. Never run conflicting work, shared-state browser journeys, Docker rebuilds, or resource-heavy test suites concurrently unless the readiness gate proves those resources are isolated.
- Track accepted PRs whether they remain open or are merged by an authorized human or merge queue. A merge is a normal DAG state transition, not automatically a blocker.
- Keep unrelated user work untouched. Require a dedicated isolated worktree for every implementation and remediation attempt; never let a worker change the supervisor's or user's active checkout. Have the responsible worker or a dedicated setup/cleanup subagent create, verify, and retire worktrees.
- When independent review is part of the authorized contract and is not already satisfied by an authorized human, require a separate reviewer subagent with no inherited implementation conversation. The implementer or remediator cannot perform that independent review.
- Supervise terminal reports, not implementation artifacts. After dispatching a complete packet, wait for the subagent's terminal handoff without inspecting its worktree, code, diff, logs, tests, processes, PR contents, or CI; requesting checkpoints; suggesting implementation details; or steering its method.
- Do not inspect or execute agent-created code even after the subagent finishes. The supervisor performs orchestration only: maintain authorization and the ledger, allocate/retire isolated worktrees, dispatch subagents, and classify terminal reports. Delegate code, diff, scope, test, PR metadata, CI, landing, and graph verification to independent subagents, then make judgments only from their final messages.
- Do not accept a PR with unresolved major review findings or failing required checks.
- Treat retry exhaustion as node-local by default. Mark the exhausted node skipped, block only descendants whose prerequisite can no longer be satisfied, and continue every unaffected ready node. End the overall run only when no actionable node remains or a graph-wide safety, authorization, or integrity condition requires it.
- Never merge a PR unless the user explicitly authorizes the agent to merge. The user may authorize themselves, another developer, or a merge queue to review and merge while the run continues; record that landing contract and adapt only affected DAG nodes.
- Do not push, open PRs, modify production, or perform destructive operations unless the user's handoff and repository rules authorize them.

## 1. Delegate discovery and build the worklist

Before delegation, establish the execution contract:

- Summarize the requested outcome, mutations, external actions, landing authority, and likely stop conditions.
- Ask all material questions that can already be identified from the request in one batch.
- Ask whether the user wants a staged confirmation after triage or an unattended run that pre-authorizes the dynamically discovered worklist. Treat an explicit request to keep working unsupervised through QA, issue creation, fixes, and open PRs as unattended pre-authorization when the scope and permissions are otherwise clear.
- Establish the delivery topology: dependency DAG or explicit sequential stack; the maximum implementation lanes; whether review may overlap implementation; who may merge; and whether a protected merge queue is available. Default to a DAG with main-targeting independent PRs when the user wants two developers or agents to avoid blocking each other.
- Establish shared-resource policy. Ask whether each lane has isolated Docker project names, ports, data roots, credentials, and browser sessions. If not, allow parallel code work and review but serialize rebuilds, browser QA, and resource-heavy tests through an explicit lease.
- If the user chooses unattended execution, record the routine-action authorization above, state the safe assumptions you will use and the exceptional conditions that can still force a stop, and do not ask routine follow-up questions later.

Dispatch discovery subagents to inspect repository instructions, GitHub issues, dependencies, current branches, existing PRs, and relevant code without making implementation changes. Build the dependency graph only from their terminal reports. If evidence is incomplete, dispatch a focused audit instead of inspecting artifacts in the supervising context.

For QA-led work, delegate the complete discovery path: map the requested change window, identify affected journeys and both shared and product-specific surfaces, satisfy repository safeguards, rebuild and start the authorized local runtime, perform targeted real-browser QA, reproduce findings, and create authorized GitHub issues with evidence. Keep resource-heavy builds and test suites sequential on a shared machine. The supervisor coordinates these agents and classifies their terminal findings; it does not rebuild, browse, test, or file issues itself.

For every proposed node, record:

- issue number and title;
- intended outcome and explicit non-goals;
- acceptance criteria and required verification;
- dependency or ordering constraints;
- conflict domains and proposed delivery lane;
- target application or subsystem when the repository has parallel products;
- expected PR boundary and target base branch;
- whether it can land independently or must wait for a prerequisite.

Split an issue before approval only when it cannot reasonably fit one reviewable PR. Do not invent extra work. Produce an acyclic dependency graph, not an arbitrary total order. Present the graph, lanes, and genuine short stacks for confirmation in staged mode. In unattended mode, record them, publish a concise progress update, and dispatch ready non-conflicting nodes without pausing when they fit the pre-authorized scope.

## 2. Complete the pre-handoff readiness gate

Before accepting an unattended handoff, have readiness subagents resolve everything reasonably discoverable from the repository and GitHub. Require terminal evidence for at least:

- applicable repository and directory instructions;
- issue descriptions, comments, linked PRs, and acceptance criteria;
- the exact target product, component, environment, and compatibility expectations;
- freshly fetched `main`, its exact commit, open conflicting work, working-tree safety, branch protection, merge-queue availability, and PR base behavior;
- available credentials and authorization for branches, isolated worktrees, PRs, reviews, and checks;
- required tests, formatting, CI, backups, and visual or runtime verification;
- per-lane Docker, port, data-root, test-account, and browser isolation; when unavailable, the single-owner lease for shared runtime and test resources;
- the human-review and landing protocol, including how review comments, branch pushes, merges, and merge-queue events will be detected and incorporated;
- database, deployment, security, or other operations that require separate approval;
- ambiguous product decisions or missing artifacts that would change the solution materially.

Resolve all material questions now. Prefer evidence from the readiness subagents and the safe assumptions recorded in the initial execution contract. In staged mode, summarize the final approved scope, assumptions, stopping conditions, dependency graph, lanes, shared-resource leases, and landing protocol, then wait for an explicit handoff. In unattended mode, treat the recorded pre-authorization as that handoff and proceed without a second confirmation. After either handoff, do not ask routine implementation questions; make only small, safe, in-scope assumptions. If a newly discovered decision would materially change scope or risk and cannot be resolved from the execution contract, stop execution and report it. Never satisfy a readiness item personally to advance the gate; re-dispatch the responsible subagent with the missing requirement.

## 3. Dispatch ready DAG nodes through worker subagents

Maintain the dependency graph and lane ledger. A node is ready only when its prerequisites have the state required by its base strategy, no active node owns an overlapping conflict domain, and any required shared-resource lease is available. Permit at most one implementation attempt per lane and no more lanes than authorized. A clean-context reviewer may run while another independent node is implemented. Assign every worker or remediator a monotonically increasing attempt number for its node.

For a two-developer pipeline, keep one lane producing ready PRs while the other independently reviews, remediates review findings, or audits human landing events. Add a second implementation lane only when conflict domains and runtime resources are isolated and independent review capacity remains available.

Choose a unique dedicated worktree path without changing the active checkout, then give the assigned implementation-lane agent a self-contained packet requiring it to create and verify that worktree and containing:

- repository and issue identifiers;
- DAG node, lane, dependencies, conflict domains, and current landing state;
- approved scope, non-goals, and acceptance criteria;
- relevant repository instructions;
- the required base branch, pinned base commit, PR target, dedicated worktree path, and branch naming rules;
- required tests and evidence;
- authorization to create the branch, commit, push, and open the PR;
- an instruction to use the `engineering` skill when available;
- a warning not to leave the dedicated worktree, merge, or broaden scope.

Choose the base from actual dependencies, never from scheduling order:

- For an independent node, fetch the remote immediately before dispatch, pin current `origin/main`, branch from it, and target `main`.
- For a node with one open prerequisite PR, verify that PR is accepted, open, and at its recorded exact head; branch from that head and target the prerequisite branch.
- When all prerequisites are already merged, branch from freshly fetched `origin/main` after a landing audit and target `main`.
- Do not start a node that depends on multiple open PRs. Wait until all but at most one prerequisite have landed, or obtain explicit authorization for a temporary integration branch.
- In explicit stack mode, treat each preceding node as the one prerequisite and retain the original sequential behavior.

Verify that every PR shows only its node's intended delta relative to its actual base. Keep stacks short; do not stack unrelated nodes merely to keep a worker busy.

Require the worker to inspect before editing, follow test-first development when required, preserve unrelated changes, commit cohesive work, acquire and release any shared-resource lease, run required checks sequentially, push, open a non-draft PR unless repository policy says otherwise, and return a concise handoff containing the node/lane, attempt number, worktree path, branch, base branch, pinned base commit, head commit, PR URL/number, changed-file summary, test results, and risks.

After dispatch, enter a hands-off wait:

- Do not inspect the live worktree, diff, logs, tests, processes, PR, or CI to infer progress.
- Do not ask for routine status updates or tell the worker how to solve discoveries made during its attempt.
- Treat quiet execution and long-running checks as normal. Let the worker investigate, revise, and verify its own approach.
- Intervene only when the subagent explicitly requests help or approval, the user changes the request, or independently observed external state creates a concrete safety or stack-integrity risk.
- If a tool requires bounded waits, repeat the wait without contacting or probing the subagent. User-facing updates may say only that the supervisor is still waiting; do not speculate about the worker's stage.
- After the terminal handoff, evaluate only the worker's final message and reported approach. Do not open or run the committed implementation. Delegate all artifact-level validation to the independent reviewer or a separate clean-context audit subagent.

An implementation-lane agent may process multiple independent nodes serially when the work is homogeneous and each node receives a new pinned base, dedicated worktree, packet, attempt record, and lease state. Do not replace it merely because the node changed. Replace it only under the agent-separation rule in the invariants.

Give each worktree to exactly one live attempt. After an attempt returns, dispatch a cleanup subagent to retire and safely remove only that run-owned worktree before another attempt checks out the same branch; preserve its committed branch and open PR unless the deviation procedure requires abandoning them.

Treat local-only work, a branch without a PR, a PR with the wrong dependency base or base commit, work performed in the active checkout, an unverified PR, or a worker that used another lane's leased runtime as an incomplete node.

## 4. Audit scope through terminal subagent evidence

Compare the worker's terminal changed-file and approach summary with the approved packet. When review is authorized, have that reviewer inspect the actual PR, code, diff, and graph metadata. Otherwise use the worker's terminal evidence, and dispatch a clean-context scope auditor only when the report is incomplete or context contamination is suspected. A scope audit validates boundaries without silently adding a code-review gate. The supervisor must not inspect those artifacts itself. A deviation includes unrelated changes, implementation in the wrong product, unapproved feature expansion, bypassed repository safeguards, use of the wrong dependency base, or a solution that changes the agreed behavior.

Treat the worker's final report as provisional only while an authorized review or necessary scope audit remains outstanding. If the report is complete and neither condition applies, classify it directly without adding another workflow phase.

When a worker deviates:

1. Classify the attempt as `deviation`, record the evidence, and increment the node's deviation count exactly once. Do not also increment its quality-failure count.
2. Preserve unrelated user work, then delegate any code-aware restoration or abandonment to a fresh remediation subagent. The supervisor may retire only a run-owned worktree through orchestration commands and may close an invalid unmerged PR only from the terminal audit evidence.
3. Start a fresh worker subagent from the correct clean dependency base with a corrected packet. Leave unrelated DAG lanes running.

Allow at most two re-dispatches caused by deviation. On the third attempt classified as `deviation`, mark the node `skipped (deviation limit)`, record all attempts and evidence, preserve its current safe branch and PR state, and do not dispatch it again. Mark only descendants that require it `blocked by skipped prerequisite`, then continue unrelated ready nodes. Never accept deviating work or present its PR as merge-ready.

## 5. Obtain an authorized independent PR review

Run this section only when independent review is part of the authorized execution contract and has not already been satisfied by an authorized human. Do not add review to an implementation-only or landing-only request. When required, start a reviewer subagent without inherited conversation history; in Codex, use `fork_turns: "none"` or the closest available clean-context equivalent. Give it only the repository identifier or path, raw issue, approved acceptance criteria, repository instructions, exact base and head commits, parent PR or base branch, and PR reference. Do not provide the worker's conclusions or review summary as ground truth. Confirm that this reviewer did not implement or remediate the step, and instruct it to use the `engineering` skill when available without making changes or merging.

Require the reviewer to inspect the PR's own delta and relevant surrounding code, verify behavior and tests, check CI and repository rules, confirm the PR's current expected open or authorized-merged state, and classify findings as major or minor. Major findings include requirement gaps, regressions, unsafe data or security behavior, wrong-product changes, material scope creep, invalid architecture, dependency contamination, missing production-equivalent verification, or failing required checks.

Apply the same hands-off wait to reviewers. Do not ask for checkpoints, inspect their temporary worktree, or influence an unfinished review. Assess only the terminal verdict and evidence unless the reviewer explicitly requests help or reports a decision that requires supervisor action.

The reviewer must return:

- verdict: `accept` or `major issues`;
- findings with concrete file or PR references;
- acceptance-criteria coverage;
- checks and test evidence inspected;
- residual risks or minor follow-ups.

Consider the review gate satisfied when the authorized independent reviewer's terminal message reports no major issues and confirms the PR has the expected base, exact head, and passing required checks, or when the execution contract recognizes an authorized human's completed review. Record the accepted head commit. If the PR was merged by the authorized landing path during review, delegate a landing audit before accepting it; never infer the merge result from the reviewer alone. Before dispatching a dependent worker, require its preflight to confirm the prerequisite's recorded open head or audited merged state. If a branch was unexpectedly pushed, retargeted, closed, or deleted, delegate a state audit and reopen only the affected node's authorized gates. Do not stop unrelated lanes unless graph integrity is at risk.

## 6. Retry failed quality gates

Give each completed attempt exactly one terminal classification, in this order:

1. `deviation` when the scope audit finds any deviation; increment only the deviation count.
2. `quality failure` when there is no deviation but implementation, tests, acceptance criteria, or independent review has a major failure; increment the quality-failure count exactly once regardless of the number of findings.
3. `accepted` when scope and every quality gate pass.

Do not finish or count an attempt for a transient infrastructure failure; retry the blocked check or confirm a persistent external blocker. For a `quality failure`, assign a fresh remediation subagent a new attempt number, isolated worktree, and tightly scoped packet containing the branch and PR when they exist plus the concrete findings. Re-run the authorized scope audit and required checks after remediation, and repeat clean-context independent review only when it is part of the execution contract.

If an amended prerequisite already has descendants, restack only the affected descendant subgraph. Verify every affected PR still contains only its own delta, rerun invalidated authorized checks, and obtain a fresh independent review only where the effective diff or required approval changed and review is part of the execution contract. Continue unaffected lanes.

Allow at most two re-dispatches caused by quality failure. On the third attempt classified as `quality failure`, mark the node `skipped (quality limit)`, record the PR, failures, attempts, and current safe state, and do not dispatch it again. Mark only descendants that require it `blocked by skipped prerequisite`, then continue unrelated ready nodes. Treat a persistent external blocker as node-local in the same way when unaffected ready nodes remain; end the overall run only when the blocker is graph-wide or no actionable node remains. Leave any unaccepted PR clearly recorded as unaccepted and preserve it unless closing it is authorized.

## 7. Coordinate reviews and landing without blocking lanes

Treat human review and landing as first-class pipeline stages:

- A human may review any accepted or under-review PR while independent workers continue. Convert actionable comments into node-local remediation packets; comments on one node do not pause unrelated lanes.
- Without explicit agent merge authorization, never click merge or call a merge API. The user or merge queue may merge an accepted PR while the supervisor continues.
- Prefer protected `main`, required checks, and a merge queue. Do not enable repository settings without authorization. Without a merge queue, require the human landing protocol to merge one accepted main-targeting PR at a time and let a delegated landing audit refresh the graph before the next dependent merge.
- Never ask a human to merge an open prerequisite while its dependent PR still targets the prerequisite branch unless the landing protocol includes automatic retarget/rebase handling.
- Reuse one landing agent for an entire authorized homogeneous ordered merge sequence. Give it the exact order and require a landing-state refresh between merges; do not create one landing agent per PR unless an agent-separation condition from the invariants applies.

After any authorized merge, branch push, retarget, closure, or review-request change, dispatch a state/landing auditor. Require terminal evidence of the new `origin/main`, the merged PR and commit relationship, comments or changed heads, and the exact affected descendant subgraph. Classify the event:

- An accepted independent PR merged into `main`: mark that node landed; leave unrelated open PRs alone unless their merge-queue or CI state changed.
- An open prerequisite merged: rebase or cherry-pick each direct dependent's own delta onto freshly fetched `main` or its remaining unmet prerequisite, retarget appropriately, use force-with-lease only when authorized, and cascade through only that descendant subgraph.
- A human pushed commits to an agent branch: treat the new head as unverified; rerun the node's authorized scope and check gates, repeat independent review only when it is part of the contract, and restack affected descendants.
- A conflicting or failed merge-queue update: assign a fresh remediation attempt to the affected node; do not resolve conflicts in the supervising context.

When a rebase, retarget, or merge changes a PR's effective delta, invalidate its old acceptance and rerun the affected gates that are part of the execution contract. Preserve an accepted human or agent review across a conflict-free mechanical rebase when a delegated auditor proves patch identity or an equivalent range-diff and therefore an unchanged effective delta. Require fresh review only when the effective delta changed or equivalence cannot be proved and review is part of the authorized contract.

## 8. Finish and verify the delivery graph

Finish the orchestration run when every approved node is either:

- merged through the authorized landing path and verified present in the intended base; or
- open, in-scope, accepted under every gate in the authorized contract, and green where checks are required, when the contract ends at handoff rather than merge; or
- terminally `skipped` after exhausting its retry limit, with its unaccepted artifact and final findings recorded; or
- `blocked by skipped prerequisite` or by a persistent external blocker, with no safe ready path remaining for that node.

Call the result fully delivered only when every approved node satisfies one of the first two states. Otherwise call it a partial delivery and continue all unaffected ready work before finishing.

Have the landing role agent verify the final graph, or dispatch a fresh clean-context graph verifier only when an agent-separation condition in the invariants applies. Give it the approved DAG, dependency edges, lane ledger, recorded branch/base/head/PR/merge mapping, and repository rules. Require its terminal message to confirm:

1. Every issue maps to exactly one accepted open PR, audited merged PR, or explicit terminal skipped/blocked record; no unaccepted PR is represented as accepted.
2. Every merged prerequisite is present in the intended `main` ancestry or documented merge result.
3. Every open accepted independent PR targets current `main`; every open accepted dependent PR targets its one unmet prerequisite branch, or current `main` after all prerequisites landed.
4. Every open accepted PR shows only its node's intended delta against its effective base, retains the recorded exact head, and satisfies the checks and review gates in the authorized contract; every skipped PR remains explicitly unaccepted.
5. No accepted node was invalidated by a later human push, rebase, retarget, merge, or prerequisite amendment.
6. The complete issue, dependencies, lane, branch, base, pinned commit, accepted head when any, PR, landing or terminal state, skip reason, blocked descendants, and residual-follow-up mapping.

Judge only that verifier's terminal report. Remediate mismatches through the affected subgraph; do not inspect artifacts in the supervising context. Hand back the verified graph and exact safe merge order for any remaining open dependent PRs.

## 9. Handle newly discovered work

Add a newly discovered node without user input only when it is small, clearly necessary to unblock an approved node, preserves the approved outcome, carries no meaningful new risk, and can follow the same one-node/one-PR workflow. Record its dependency edges and why it was added.

If the new work is substantial, independently valuable, changes product behavior, expands risk, or would alter the approved ordering, stop execution and report it instead of expanding scope.

## Reporting and stop conditions

Provide concise progress updates at dispatch, terminal handoff, classification, review, and landing boundaries. During hands-off waits, report only that the supervisor is waiting when an update is necessary; do not turn wait timeouts into worker probes. Build the ledger exclusively from terminal subagent messages: node, dependencies, lane, conflict domains, state, current attempt, terminal classification, deviation count, quality-failure count, worktree, branch, effective base, pinned base commit, accepted head, PR, checks, reviewer verdict, landing state, skip reason, and blocked descendants.

For unattended runs, progress updates are informational rather than approval gates. Continue automatically after discovery, triage, accepted nodes, review comments, audited landing transitions, and node-local retry exhaustion unless an explicit overall-run stop condition applies.

Stop in a safe state and report instead of improvising when:

- a retry-exhausted or persistently blocked node leaves no other ready independent work and every remaining node depends on it;
- a persistent external blocker affects the whole graph rather than one node;
- a material decision was missed before handoff;
- authorization, credentials, required artifacts, or external services are unavailable;
- repository rules conflict with the approved workflow;
- unrelated user work cannot be preserved safely;
- an external merge or branch mutation cannot be reconciled without overwriting unverified human work;
- required parallel runtime isolation is unavailable and the agreed shared-resource lease cannot be enforced;
- a newly required node is too large or risky to add pragmatically.

On completion, report the issue-to-PR mapping, dependency graph, lanes, accepted heads, open or merged state, skipped and blocked nodes, verification, applicable reviewer verdicts, exact remaining landing order, and minor residual follow-ups. Claim full delivery only when every approved node has an accepted or audited-merged PR on the correct effective base with every authorized gate satisfied. Otherwise report partial delivery explicitly, without treating skipped, blocked, unresolved-major, or failing-check PRs as accepted.
