---
name: hashimoto-review
description: Review customer-facing code changes for regressions, security, and operational risk, then open the diff in Hunk with numbered, categorized notes on the non-trivial code paths the engineer must review, including every shortcut and everything that needs their attention, so they can explain and defend the shipped system. Use for PRs, commit ranges, release candidates, or recent merged work; do not use for quick prototypes where the user explicitly prioritizes speed over production understanding.
---

# Hashimoto Review

## Origin and standard

This workflow is inspired by Mitchell Hashimoto's ["whiteboard defense" post on X](https://x.com/mitchellh/status/2100249348345057389). It operationalizes his benchmark for responsible AI-assisted, customer-facing work: the engineer should be able to explain how a shipped system works, defend important choices and alternatives, reason about malicious actors, describe its data structures, and identify where it fails. This is an independently authored review workflow, not an official skill from or endorsement by Hashimoto.

Produce two outcomes together:

1. an evidence-backed engineering review; and
2. a coherent set of review notes that lets the responsible engineer pass a whiteboard defense after reading them carefully.

Do not edit implementation code during a review unless the user separately asks for fixes. Hunk notes are sidecar review annotations, not source-code comments.

## Establish the review boundary

Resolve the exact base and head before judging the change. For stacked or recently merged work, review the final integrated diff once, then inspect individual PR or commit boundaries only where ownership, intent, or conflict resolution matters. Include shared code and deployment changes that can affect existing products, not only the new app's directory.

Read applicable repository instructions and the change's issue or PR descriptions. Treat stated intent and prior test claims as hypotheses to verify, not proof.

Classify the work as customer-facing, internal production, or experimental. Apply the full workflow to the first two. If the user explicitly labels it a disposable proof of concept or experiment, scale the depth to that request.

## Open the review in Hunk

Present the review in [Hunk](https://hunk.dev). Its `}` and `{` keys move to the
next or previous annotated hunk in the order Hunk shows the diff, so the notes
are numbered in that order (see below). Hunk's `review-note-navigator` example
extension lists every note on `F8`. The setup is in `marashiai/rcs` (`hunk/`).

Read Hunk's bundled review skill before using its live-session API, and treat it
as the authoritative source for current Hunk commands:

```sh
hunk skill path hunk-review
```

Check `command -v hunk`. If Hunk is missing, do not install it without
authorization. Continue the audit and show every prepared note directly to the
user with the relevant code excerpt plus its exact file and line anchor, and
point to the setup in `marashiai/rcs`. Never reduce or omit the teaching notes
because the viewer is unavailable.

Resolve the exact Hunk arguments for the range, such as `diff <base> <head>`,
`diff <base>...<head>`, or `show <commit>`. Limit the diff with a pathspec to
the files that carry notes, so trivial changes do not sit between them, and list
the files left out in the written review.

### Write the notes

Finish the audit and write the notes before opening Hunk, so the user opens a
complete review. Anchor every note on a line inside a changed hunk.

Keep review artifacts outside the reviewed repository, for example under
`${TMPDIR:-/tmp}/hunk-review/<repo>-<range>/`. Write the notes to `notes.json` as
one `hunk session comment apply` batch. A batch item contains `summary` plus
either `replyTo`, or `filePath` and exactly one of `hunk`, `hunkNumber`,
`oldLine`, or `newLine`. Put the numbered, categorized prose in `summary`,
without a separate title. Leave `rationale` out: notes are read aloud (see
"Write notes for listening"), and detail that does not fit a short spoken note
belongs in the written review.

### Open Hunk with the notes

When the user asks for review notes in Hunk, open the review for them in a new
terminal window with the bundled script. It prints the new live session's id:

```sh
id=$(scripts/open-hunk.sh <repo> <hunk args...>)
hunk session comment apply "$id" --stdin < notes.json
```

Run the script from this skill's directory. It needs Ghostty on macOS. Elsewhere
it exits with the exact command for the user to run; once their window is open,
select its session with `hunk session list --json` and apply the notes to it.
Never run Hunk inside the agent's own terminal.

Before applying notes to an existing window, inspect its notes. Never clear,
remove, or overwrite the user's notes. Avoid duplicating an existing note; reply
when the new information belongs to an existing thread.

Afterward, verify every applied note's number, category, prose, and code anchor:

```sh
hunk session comment list "$id" --type all --json
```

Tell the user that `}` and `{` step through the notes in number order and `F8`
lists them. Live notes disappear when the Hunk window closes; reopen the review
by repeating the two commands above with the saved notes.

## Audit the change

Trace behavior across the real boundaries the diff touches:

- entry points, callers, services, queues, jobs, and external dependencies;
- authentication, authorization, trust boundaries, secrets, and tenant isolation;
- persistent records, ownership keys, indexes, caches, files, and lifecycle transitions;
- deployment configuration, migrations, rollout ordering, backward compatibility, and rollback;
- timeouts, retries, concurrency, quotas, resource bounds, partial failure, cleanup, and observability;
- user journeys in every existing product that consumes changed shared code.

For malicious-actor analysis, ask what an unauthenticated outsider, ordinary customer, compromised customer artifact, authenticated owner, malicious tenant, compromised internal service, and network-position attacker can do. Do not treat signed provenance as proof that content is safe, or a UI restriction as authorization.

Run the repository-required checks when permitted. Add focused tests or scanners only as evidence, and distinguish:

- verified behavior;
- reasoned inference;
- an untested assumption;
- an environmental blocker.

Check locked dependencies against a current authoritative advisory source. Separate vulnerabilities introduced by the reviewed range from pre-existing vulnerable dependencies that are nevertheless reachable from the new code. Absence of a scanner finding is not a source-level security review.

Report review findings by severity before the teaching narrative. A finding must include impact, a concrete trigger or actor, the affected location, and the evidence. Do not inflate theoretical concerns whose preconditions are excluded by the deployed architecture; do record those deployment assumptions explicitly.

## Write the whiteboard-defense notes

### Choose what to annotate

Annotate the code paths the engineer must review personally: the non-trivial ones, where a bug can hide or where the behavior would surprise them later. Typical examples are state that several sources update, ordering and races, retries and timeouts, caches, lifecycle transitions, authorization checks, data written to storage, changed defaults, behavior that moves between components, and shared code that other callers depend on.

Leave trivial changes out, even when they are part of the diff: styling such as a button color matched to the others, copy edits, renames, formatting, code moved without a behavior change, and boilerplate in tests or fixtures. A trivial-looking change gets a note only when it changes behavior someone relies on.

Every shortcut gets a note. When the change patches a symptom instead of fixing its cause, for example with a counter, flag, retry, timeout, special case, or guard where a redesign would remove the problem, say so plainly. Name the proper fix, why it was not taken, and what it would cost. This applies most of all to changes the agent wrote itself: never present a workaround as the design.

Every surprise gets a note: behavior a reasonable reader would not expect from the diff or the pull request description. Label it `bug` when the behavior is wrong and `attention` otherwise. Examples are a side effect on another screen or product, a user moved somewhere they did not ask to go, a changed default, data kept longer than it looks, and a rule that is guidance rather than an enforced check.

Within these paths, prefer ownership boundaries, state transitions, policy enforcement, and failure handling over mechanically changed lines. The notes must still give a full understanding of the non-trivial system; let that, not the size of the diff, determine how many notes are needed, and do not squeeze unrelated points into one note to keep the count small.

Start every agent-authored note, including defect comments and replies, with `N. Category: ` followed immediately by explanatory prose, for example `3. Bug, high severity: ` or `5. Hot path: `. The colon gives a spoken pause. Do not add a title, headline, or separate summary sentence that merely names the topic. Apply the same format in Hunk and in any notes shown directly to the user when the viewer is unavailable.

### Write notes for listening

The user listens to notes through text-to-speech, so every note must be short and sound natural when read aloud:

- Keep a note to two to four plain sentences, at most about 60 words. Make one point per note; split a second point into its own note rather than lengthening this one.
- Use no Markdown, backticks, bullet lists, code, file paths, line numbers, URLs, SQL, or symbols such as slashes, arrows, brackets, parentheses, underscores, percent signs, or comparison signs. The anchor already shows the code; the note explains it.
- Name things the way an engineer would say them, such as "the answer handler" or "the per-player view", not `chats_answer_question` or `state_for_viewer`. Spell out versions and units that speech engines misread: "version three point two", "300 megabytes".
- Give the behavior, its condition, and why it matters. Leave out evidence trails, test names, query text, and exact counts unless the number itself is the point.
- Put the detail a note cannot carry, such as queries, rollback SQL, file and line references, test names, and evidence, in the written review that accompanies the verdict, and refer to it from the note as "the review file".

Use one sequence starting at 1 across the entire review, spanning files, categories, and batches. Assign numbers in the order Hunk shows the notes, by file path and then line, so `}` reads them in sequence; write each note to make sense at that position and refer back to earlier notes by number. Numbers are not severity ranks. Keep published numbers stable, continue after the highest existing agent-note number when adding notes or resuming the same review, and refer to earlier explanations by note number. Never renumber or rewrite the user's notes.

Choose one primary category from this vocabulary and write it capitalized in the prefix. Use `bug` for a confirmed defect, including security or performance defects, and put its severity in the prefix, as in `Bug, medium severity:`. Use `shortcut` and `attention` whenever they apply, even when another category also fits, because those are the notes the engineer must not miss. Use `note` when no more specific category fits. Categories help navigation; they are not a checklist or a reason to add more notes.

| Category | Use for |
| --- | --- |
| `bug` | An evidence-backed defect requiring correction. |
| `shortcut` | A workaround or narrower fix chosen over a proper design fix, with the proper fix and its cost. |
| `attention` | Behavior a reader would not expect from the diff or description that is not a defect, such as a side effect elsewhere or an unenforced rule. |
| `note` | Useful context that does not fit another category. |
| `architecture` | Component boundaries, ownership, design choices, and alternatives. |
| `hot path` | Frequent or latency-critical execution paths. |
| `data model` | Records, identifiers, relationships, and data lifecycle. |
| `invariant` | Rules the system must preserve and where they are enforced. |
| `security` | Trust boundaries, authorization, actor capabilities, and defenses. |
| `failure handling` | Errors, retries, partial failure, fallbacks, and recovery. |
| `performance` | Computational cost, resource bounds, and bottlenecks. |
| `compatibility` | Existing callers, API or schema changes, migrations, and rollout or rollback. |
| `operations` | Configuration, monitoring, diagnosis, and operator actions. |
| `testing` | Scenarios and assertions, verified behavior, and verification gaps. |
| `question` | An unresolved assumption or decision that needs confirmation. |

For example, five notes at their respective code anchors could read:

```text
1. Architecture: The handler passes accepted jobs to the queue. The worker owns execution, so the request can finish before the job does.

2. Hot path: Every job status request reads this cache before querying storage. A cache hit avoids a database read, but the returned status can lag behind the worker.

3. Bug, high severity: Include the tenant in this cache key. Two tenants can use the same job number, so the current key can return another tenant's status.

4. Shortcut: Two counters stop an older snapshot from erasing a newer question. The proper fix is a server sequence number on snapshots and events, which needs a server change. Until then the client still merges three sources that arrive in no fixed order.

5. Attention: After a change finishes, the maker lands on the play step, not on the feedback step where they started it.
```

The notes must form a standalone guided tour of the changed system. Across the complete set, teach:

- what the system does for the customer and the end-to-end request or event flow;
- which component owns each decision and piece of data;
- why this design was chosen over the most plausible alternative;
- the invariants and data structures that make it work;
- what a malicious or buggy actor can attempt and where it is stopped;
- every shortcut taken instead of a proper fix, and what the proper fix is;
- where the change will surprise a maintainer or user later;
- where it fails, how failure is surfaced, and whether retry or rollback is safe;
- how an operator can detect, diagnose, recover, and verify it;
- what remains intentionally unresolved or risky.

Write connected sentences that explain the code. The topics above guide the audit; they are not fields to fill in for every note. Assume the reader is an experienced engineer, but make the grammatical relationships explicit. Say which component does what, under which conditions, and why the result matters. Keep technical terms precise without joining them into shorthand that the reader must decode.

For example, "Expired-cache refresh failure preserves stale reads" names concepts without clearly connecting them. "If refreshing an expired cache entry fails, the reader receives the old value. Reads remain available, but callers can receive stale data" explains the behavior and its cost. This is an example of sentence construction, not a template for every note.

When discussing tests, describe the scenario and the result they assert. Distinguish the scenarios a test sets up from the properties its assertions actually check. A list of technologies or topics that tests "cover" does not explain what they establish. Mention test setup when it affects the strength or limits of the evidence; do not imply that a simulated dependency proves the real service works.

Before publishing, read each note aloud, or as if it were read aloud. Remove repeated details instead of the verbs, conditions, or connecting phrases that make it understandable. A note should explain an important point accurately on its first reading, without requiring the reader to reconstruct the sentence or guess how its terms relate.

Keep claims within the component and conditions the code supports. Follow a value back to its source when its meaning depends on another layer; do not attribute a guarantee to the whole system just because one function implements part of it. State uncertainty honestly. Never invent a rationale; label an inferred rationale and identify what would confirm it. Keep defect comments distinct from explanatory notes. A severe finding may also teach the violated invariant, but its opening sentence must make the severity and required action unmistakable.

## Test the engineer's understanding

After the review notes are applied, provide a compact defense brief keyed to their note numbers:

- a 60-second system explanation;
- the three most consequential design decisions and alternatives;
- the shortcuts taken and the proper fixes they defer;
- the main data model and ownership rules;
- the top malicious-actor scenario;
- the most likely failure and recovery path;
- the evidence supporting the release verdict;
- unresolved risks or checks still needed.

End with realistic questions the engineer should be able to answer, including:

- Why did we choose this boundary instead of the nearest alternative?
- What happens when a normal customer behaves maliciously?
- Which identifier or record is authoritative, and why?
- Where can this fail partially, and is retry safe?
- What breaks during rollout or rollback?
- Which claim rests on a deployment assumption rather than an enforced invariant?

The goal is not memorizing functions. It is being able to reconstruct the system, defend its choices, and name its limits without hand-waving.

## Deliver the verdict

Lead with whether the change is safe to ship, conditionally safe, or not ready. List findings in severity order while retaining their note numbers, then the shortcuts and attention notes by note number, then regression evidence, security evidence, verification gaps, and the whiteboard-defense map in numbered reading order. Link to exact local files and lines when available.

Do not say there are no breaking changes or vulnerabilities merely because tests pass. Use narrower language: what was tested, what was inspected, what actors and boundaries were considered, and what remains unknown.
