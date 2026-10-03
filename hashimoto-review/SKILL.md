---
name: hashimoto-review
description: Review customer-facing code changes for regressions, security, and operational risk, then annotate the diff in Hunk or revdiff with numbered, categorized notes that let an engineer explain and defend the shipped system. Use for PRs, commit ranges, release candidates, or recent merged work; do not use for quick prototypes where the user explicitly prioritizes speed over production understanding.
---

# Hashimoto Review

## Origin and standard

This workflow is inspired by Mitchell Hashimoto's ["whiteboard defense" post on X](https://x.com/mitchellh/status/2100249348345057389). It operationalizes his benchmark for responsible AI-assisted, customer-facing work: the engineer should be able to explain how a shipped system works, defend important choices and alternatives, reason about malicious actors, describe its data structures, and identify where it fails. This is an independently authored review workflow, not an official skill from or endorsement by Hashimoto.

Produce two outcomes together:

1. an evidence-backed engineering review; and
2. a coherent set of review notes that lets the responsible engineer pass a whiteboard defense after reading them carefully.

Do not edit implementation code during a review unless the user separately asks for fixes. Hunk and revdiff notes are sidecar review annotations, not source-code comments.

## Establish the review boundary

Resolve the exact base and head before judging the change. For stacked or recently merged work, review the final integrated diff once, then inspect individual PR or commit boundaries only where ownership, intent, or conflict resolution matters. Include shared code and deployment changes that can affect existing products, not only the new app's directory.

Read applicable repository instructions and the change's issue or PR descriptions. Treat stated intent and prior test claims as hypotheses to verify, not proof.

Classify the work as customer-facing, internal production, or experimental. Apply the full workflow to the first two. If the user explicitly labels it a disposable proof of concept or experiment, scale the depth to that request.

## Open the review in Hunk or revdiff

Use the viewer the user requests; default to Hunk. For revdiff, read its installed skill and follow its documented annotation-preloading workflow. Keep the required file/line record headers intact and put the numbered, categorized prose in each annotation body. Preserve the distinction between agent-authored explanations and human requests when processing returned annotations. Continue with the audit and note-writing rules below; the live-session commands in this section apply only to Hunk.

When Hunk is installed, locate and read its bundled review skill before using the live-session API:

```sh
hunk skill path hunk-review
```

Load or install that skill through the agent's supported skill mechanism when needed. Treat it as the authoritative source for current Hunk commands; this section adds the Hashimoto-review policy on top of it.

Determine the exact command for the resolved range, such as:

```sh
hunk diff <base>...<head>
```

Use `hunk show <commit>` for one commit. Tell the user to run the exact command in another terminal from the repository root and leave the Hunk window open. Do this early so the user can read notes as they arrive. The Hunk TUI belongs to the user: never launch `hunk diff`, `hunk show`, or another interactive Hunk command yourself.

Check `command -v hunk`. If Hunk is unavailable, do not install it without authorization. Continue the code audit and show every prepared note directly to the user with the relevant code excerpt plus its exact file and line anchor. Clearly state that applying the notes to the live diff is waiting on Hunk, point the user to the official Hunk installation documentation, and repeat the exact command they should run. Never reduce or omit the teaching notes merely because Hunk is unavailable.

Once a live window exists, use Hunk's live-session interface rather than scraping its terminal UI. Inspect the session list first. If multiple sessions share a repository, select the user's window by exact session ID instead of using `--repo`:

```sh
hunk session list --json
hunk session get --repo . --json
hunk session review --repo . --json
```

Start with the structure-only review. Request `--include-patch` only for raw diff text the audit actually needs, and use `hunk session context` when current focus matters. Use the live review model as the source of file paths, 1-based hunk numbers, and old/new line anchors.

Inspect existing notes before writing. Navigate or focus the window so the user sees the relevant code. Prefer one validated `hunk session comment apply ... --stdin` batch when several prepared notes are ready; use `comment add` for a one-off note or reply. A batch item must contain `summary` plus either `replyTo`, or `filePath` and exactly one of `hunk`, `hunkNumber`, `oldLine`, or `newLine`. Use `--focus` sparingly to start the guided tour at its first note.

Put the numbered, categorized prose in Hunk's required `summary` field, without a separate title. Use the optional `rationale` only for additional explanation, never to repeat the summary.

Afterward, verify every applied note's number, category, prose, and code anchor with:

```sh
hunk session comment list --repo . --type all --json
```

Never clear, remove, or overwrite the user's Hunk notes. Avoid duplicating an existing note; reply when the new information belongs to an existing thread. Highlights are optional and visual-only; pair any important explanation with a persistent comment.

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

Choose the code locations that best explain the change, and arrange the notes in reading order. Prefer ownership boundaries, state transitions, policy enforcement, and failure handling over mechanically changed lines. Let the explanations determine how many notes are needed; do not squeeze unrelated points into one note to keep the count small.

Start every agent-authored note, including defect comments and replies, with `N. [category] ` followed immediately by explanatory prose. Do not add a title, headline, or separate summary sentence that merely names the topic. Apply the same format in Hunk, revdiff, and any notes shown directly to the user when the viewer is unavailable.

Use one sequence starting at 1 across the entire review, spanning files, categories, and batches. Assign numbers in the intended reading order before publishing; they are not severity ranks or file/hunk numbers. Keep published numbers stable, continue after the highest existing agent-note number when adding notes or resuming the same review, and refer to earlier explanations by note number. Never renumber or rewrite the user's notes.

Choose one primary category from this vocabulary. Use `bug` for a confirmed defect, including security or performance defects, and state its severity in the prose. Use `note` when no more specific category fits. Categories help navigation; they are not a checklist or a reason to add more notes.

| Category | Use for |
| --- | --- |
| `bug` | An evidence-backed defect requiring correction. |
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

For example, three notes at their respective code anchors could read:

```text
1. [architecture] The handler passes accepted jobs to the queue. The worker owns execution, so the request can finish before the job does.

2. [hot path] Every job-status request reads this cache before querying storage. A cache hit avoids a database read, but the returned status can lag behind the worker.

3. [bug] High severity: include the tenant ID in this cache key. Two tenants can use the same job ID, so the current key can return another tenant's status.
```

The notes must form a standalone guided tour of the changed system. Across the complete set, teach:

- what the system does for the customer and the end-to-end request or event flow;
- which component owns each decision and piece of data;
- why this design was chosen over the most plausible alternative;
- the invariants and data structures that make it work;
- what a malicious or buggy actor can attempt and where it is stopped;
- where it fails, how failure is surfaced, and whether retry or rollback is safe;
- how an operator can detect, diagnose, recover, and verify it;
- what remains intentionally unresolved or risky.

Write connected sentences that explain the code. The topics above guide the audit; they are not fields to fill in for every note. Assume the reader is an experienced engineer, but make the grammatical relationships explicit. Say which component does what, under which conditions, and why the result matters. Keep technical terms precise without joining them into shorthand that the reader must decode.

For example, "Expired-cache refresh failure preserves stale reads" names concepts without clearly connecting them. "If refreshing an expired cache entry fails, the reader receives the old value. Reads remain available, but callers can receive stale data" explains the behavior and its cost. This is an example of sentence construction, not a template for every note.

When discussing tests, describe the scenario and the result they assert. Distinguish the scenarios a test sets up from the properties its assertions actually check. A list of technologies or topics that tests "cover" does not explain what they establish. Mention test setup when it affects the strength or limits of the evidence; do not imply that a simulated dependency proves the real service works.

Before publishing, read each note as prose. Remove repeated details instead of the verbs, conditions, or connecting phrases that make it understandable. A note should explain an important point accurately on its first reading, without requiring the reader to reconstruct the sentence or guess how its terms relate.

Keep claims within the component and conditions the code supports. Follow a value back to its source when its meaning depends on another layer; do not attribute a guarantee to the whole system just because one function implements part of it. State uncertainty honestly. Never invent a rationale; label an inferred rationale and identify what would confirm it. Keep defect comments distinct from explanatory notes. A severe finding may also teach the violated invariant, but its opening sentence must make the severity and required action unmistakable.

## Test the engineer's understanding

After the review notes are applied, provide a compact defense brief keyed to their note numbers:

- a 60-second system explanation;
- the three most consequential design decisions and alternatives;
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

Lead with whether the change is safe to ship, conditionally safe, or not ready. List findings in severity order while retaining their note numbers, then regression evidence, security evidence, verification gaps, and the whiteboard-defense map in numbered reading order. Link to exact local files and lines when available.

Do not say there are no breaking changes or vulnerabilities merely because tests pass. Use narrower language: what was tested, what was inspected, what actors and boundaries were considered, and what remains unknown.
