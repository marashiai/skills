---
name: cerebro
description: Delegate or supervise a programming task with cerebro, an orchestrator meta-agent that plans, identifies prerequisites, implements, reviews, and verifies changes in isolated worktrees. Use when the user asks cerebro to implement work, hand off coding, observe paired child agents, sequence dependent issues and pull requests, or keep long-running implementation on track.
---

# Delegate or supervise with cerebro

Package the product contract and engineering guardrails for cerebro. Keep
the primary context at the orchestration level: plans, prerequisites,
scope, gates, review findings, verification evidence, and delivery state.
Do not follow or reproduce the implementation stream.

## What cerebro is

`cerebro` drops the user into an interactive agent chat configured as an
orchestrator. The user talks to it in plain English; it drafts a plan,
waits for the user's "go", then spawns short-lived sub-agents that branch,
implement, commit, push, open a PR, run a code review loop, and verify the
change in the running app — all in an isolated git worktree, never the
user's live checkout. The orchestrator itself never touches repos
directly.

When the user requests only a handoff, stop after setting it up. When the
user requests supervision, use a paired child plus an observer and manage
the big picture until the requested delivery is complete.

## Supervise by events, not implementation polling

Use `cerebro --observe` as the implementation-level control loop. Prompt
the observer to auto-steer or restart paired children on deviations and to
return only meaningful events: plan approval, a material product question,
a verified prerequisite, a blocker, review or verification results, pull
request readiness, CI completion, and merge completion. The primary agent
must not follow live coding, logs, incremental diffs, or review-fix minutiae.

Prefer a durable background task or wait mechanism that returns control on
those events. Confirm that completion automatically resumes or notifies the
controller before calling it event-driven. A background Cerebro terminal,
filesystem watcher, waiter, or other wrapper that must be checked with
timed `write_stdin`, `wait`, status, file, or process calls is still polling.
Never poll an event watcher or notification wrapper.

Never schedule a delayed `functions.exec` cell, `setTimeout`/`notify`
callback, yielded tool cell, or later `functions.wait` read as a wake-up
mechanism. That output may remain queued until the next user turn and does
not autonomously resume supervision. For delayed continuation, use a
previously verified background collaboration/controller task whose
completion creates a real agent/mailbox event, and keep the primary agent
waiting on that event instead of ending the turn.

If no true completion notification exists and polling is allowed, inspect
one high-level session-state surface directly with exponential backoff (for
example 30 seconds, then 1, 2, and 4 minutes, with a reasonable cap). Reset
the delay only after meaningful progress. Do not create a watcher merely to
poll the watcher, send heartbeat prompts, or repeatedly ask whether the
child is still coding. If the user requires event-only supervision and the
tool cannot deliver it, state that limitation instead of silently polling.

Let the observer and child resolve technical questions that are answerable
from the repository, tests, runtime, or established engineering practice.
Bring only material product ambiguity, contradictory requirements, new
authority, or a proposed scope change to the user. Keep the final control
check at the delivery level: approved scope, material review findings,
required evidence, pull-request shape, CI, merge, base refresh, and issue
closure.

## Default engineering contract

Include these requirements in every planned Cerebro handoff unless the
user explicitly overrides them:

- Proceed directly when the existing design supports a simple, proper
  implementation. Do not introduce a tidy-first phase, cleanup, or
  refactoring as routine ceremony.
- If planning or implementation reveals evidence that a missing shared
  API, mutation path, architectural capability, or real production test
  seam would force a workaround, duplication, path-specific patches, or
  an ownership violation, verify that impediment. Do not assume it.
- Extract only a genuine enabling change with its own contract or risk.
  Give it a separate issue, plan, branch, and pull request; merge it and
  refresh the base before resuming the dependent issue. Keep cohesive
  feature-local work in the feature issue.
- State the intended solution shape clearly enough to notice unexpected
  expansion. Prefer the simplest proper root fix, one source of truth,
  and thin callers.
- Stop and re-plan if the work materially exceeds the approved solution
  shape, crosses an unplanned boundary, copies production logic into a
  fixture, accumulates path-specific patches, discovers a likely shared
  prerequisite, or receives the same class of material review finding
  twice. Do not let the observer turn an invalid plan into a long sequence
  of local fixes.
- Use test-driven development where required, independent material review,
  and final visual verification in the real runtime. A substituted or
  hand-built test surface is not evidence of production behavior.

If Cerebro verifies a genuine prerequisite but lacks authority to create
or reorder issues, pause at that decision and ask the user. Do not
continue the dependent implementation by assumption.

## Critical constraint — allocate a real PTY

`cerebro` requires stdin and stdout to be real terminals. The parent
executable does not need to be a shell, so an agent controller such as
Codex may launch it when its terminal tool allocates a PTY.

- With the unified terminal tool, set `tty: true`, retain the returned
  session identifier, and interact through terminal stdin.
- Do not launch `cerebro` through pipes, redirected input/output, or a
  terminal tool without PTY allocation. It will correctly reject a
  genuinely non-interactive launch.
- If the available tool cannot allocate and maintain a PTY, use a real
  terminal pane instead.

## Handoff procedure

1. **Identify the target repo.** Default to the project root currently
   open in Zed; resolve it to an **absolute path** (cerebro addresses
   repos by absolute path). If the request names a different repo or is
   ambiguous, confirm the absolute path with the user first.

2. **Compose the handoff prompt.** Write a single plain-English message
   that names the repo by absolute path, states the product behavior and
   acceptance criteria, and includes the default engineering contract.
   Match cerebro's idiom:
   - Planned change (default): `In <abs-path>, <change>. Draft a plan first.`
   - Inline edit (skip ceremony): `Just <change> in <abs-path>, no plan needed.`
   Keep it tight — the orchestrator records it as the session spec.

3. **Open an interactive PTY in that repo.** Prefer the unified terminal
   tool with PTY allocation enabled and its working directory set to the
   repo. A normal terminal pane is also valid. If neither can maintain an
   interactive PTY, ask the user to open one at the repo root.

4. **Launch cerebro** in that terminal and retain the live terminal
   session so prompts and answers can be sent through stdin:
   - `cerebro` — mint a new session and drop into the chat.
   - `cerebro --resume [<id>]` — resume a session (omit id for the
     picker / most recent).
   - `cerebro list` — list sessions, newest first, if the user wants to
     resume a specific one.

5. **Paste the handoff prompt** from step 2 as the first message to the
   cerebro orchestrator. Show it to the user verbatim so they can paste
   it if you can't send it directly.

6. **Choose the requested control level.** For handoff-only work, stop and
   let the user drive. For supervised work, require implementation
   children to run in pair mode, start `cerebro --observe [<id>]` in a
   separate interactive terminal, and give the observer the tidy-first
   re-plan triggers above plus authority to auto-steer and auto-restart.
   Require event-level reports only. Do not implement the code yourself or
   follow its live implementation stream.

7. **Sequence delivery.** Run only one resource-heavy implementation or
   local Docker/test workload at a time. For dependent issues, finish the
   prerequisite review, verification, merge, issue closure, and base
   refresh before starting the next plan.

8. **Wait efficiently.** Use event-driven or durable background waiting
   only when completion automatically returns control. Never use timed
   reads to check that waiter. Otherwise, and only when polling is allowed,
   poll one session-state surface directly with exponential backoff and a
   reasonable cap; reset after meaningful progress. Ask the observer for a
   concise gate summary only when intervention is needed.

## Optional: backend / model selection

If the user wants a specific backend or model, set these in the terminal
**before** running `cerebro` (otherwise defaults apply):

- `CEREBRO_BACKEND` — `opencode` (default) or `claude`: the agent CLI for
  the orchestrator and editing children.
- `CEREBRO_MODEL` — model for the orchestrator + editing children.
- `CEREBRO_REVIEW_BACKEND` — backend for the read-only reviewer (default
  `opencode`); independent of the editing backend.
- `CEREBRO_REVIEW_MODEL` — model for the reviewer.

See `references/cerebro-commands.md` for the full sub-command and env
cheat sheet.
