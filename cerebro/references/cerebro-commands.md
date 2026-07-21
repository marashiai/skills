# cerebro command & env cheat sheet

Reference for the handoff skill. The user drives these from the cerebro
chat in plain English; you normally never type sub-commands yourself.
Included only so you can answer follow-up questions the user has while
delegating.

## Top-level (typed in a terminal)

```
cerebro                       # start a new session (interactive chat)
cerebro --resume [<id>]       # resume a session (id, or most recent)
cerebro --observe [<id>]      # watch-and-steer another session's live children
cerebro list                  # list sessions, newest first
cerebro --help                # help
```

## How to talk to the orchestrator

- Name the repo by **absolute path** and describe the change.
- Planned change (default): "In `<abs-path>`, `<change>`. Draft a plan first."
- Skip ceremony: "Just `<change>` in `<abs-path>`, no plan needed."
- Wait for the plan, then say "go".
- Resume a paused child: the orchestrator handles `cerebro answer …` —
  just answer its question in the chat.
- Pair / watch / steer: ask the orchestrator to "pair" a child, then from
  another session "observe <id>" and `cerebro steer "<msg>"`.

## Environment variables

| Var | Default | Purpose |
|---|---|---|
| `CEREBRO_HOME` | `$HOME/.cerebro` | Base dir (sessions, plans, worktrees). |
| `CEREBRO_BACKEND` | `opencode` | Agent CLI for orchestrator + editing children (`opencode` / `claude`). |
| `CEREBRO_MODEL` | `github-copilot/gemini-3.1-pro-preview` | Model for orchestrator + editing children. |
| `CEREBRO_REVIEW_BACKEND` | `opencode` | Backend for the read-only reviewer (independent of editing backend). |
| `CEREBRO_REVIEW_MODEL` | `github-copilot/gpt-5.5` | Model for the reviewer. |
| `CEREBRO_TIMEOUT` | — | Seconds for child agent calls; `0`/`none` = no timeout. |
| `CEREBRO_CLAUDE_BASE_URL` | empty | Point spawned `claude` at a custom Anthropic-compatible endpoint. |

## Requirements

`jq`, `python3` on PATH, plus `opencode` and/or `claude` depending on the
configured backends. Child runs additionally need `git` and `gh` for
execute / apply-review / doc-write. `rg` recommended.

## Key facts

- **Interactive-only.** `cerebro` requires real TTY input and output; it
  rejects pipes, redirected streams, scripts without a PTY, and cron.
  The name of its parent process is not an interactivity requirement.
  Sub-agents it spawns are exempt via `CEREBRO_SESSION_ID`.
- **No concurrency control.** Don't run two mutating ops against the same
  repo at once — sequence them.
- **Isolated worktrees.** Edits happen in `$CEREBRO_HOME/worktrees/`, not
  the user's live checkout.
- **Sessions are durable** and resume where they stopped.
