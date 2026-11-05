---
description: Implement a reviewed /brainstorm plan task by task — builder writes tests and code, reviewer gates — and hand the uncommitted work to you for review; commits are split only after you accept.
argument-hint: [feature slug, optional if only one plan exists]
model: claude-sonnet-5-5
---

# implement

> 🎯 **Design for change.** Each task's diff should be small, local, and
> behind a stable seam, so each task reviews (and later commits) on its own.

Running this command is the user's sign-off on the **plan**, not on the code.
You are the orchestrator: you dispatch the builder and reviewer and hand the
work over **uncommitted**. You do **not** write or review code yourself, and
you never commit until the user accepts the solution (see *Accept*).

Repo facts (trunk, dev DB, tracker, API paths) are in `.claude/project.md`.
Pass it to every builder and reviewer.

## Preflight

1. **The plan.** `.claude/work/<slug>/` from `$ARGUMENTS`, else the only
   folder in `.claude/work/` with `Status: planned` in `plan.md`. Read
   `plan.md` and `stories.md`. If none, or several and none named, list them and stop.
2. **The branch.** The work lands on the current branch. If it is the trunk
   branch (or `main`), stop: `Create a feature branch from <trunk> first.`
   Never switch or create branches yourself.
3. **The tree.** Run `git status --short`. Unrelated changes are fine and are
   never committed, but if one touches a file a task owns, list it and ask
   whether to proceed. Note the starting state so the hand-over can tell the
   task's changes apart from what was already there.
4. Set `plan.md` to `Status: implementing`.

## The loop

For each task in `plan.md`, in order:

1. **Build.** Dispatch a `builder` subagent (`subagent_type: builder`) with
   the task text, its acceptance criteria from `stories.md`, the files it
   owns and its test files. The builder writes the task's tests first (via
   the `bdd-specs` skill, red), then the code, and returns the files it
   changed or created.
2. **Review.** Dispatch a `reviewer` subagent (`subagent_type: reviewer`)
   with the task text, its acceptance criteria and the builder's file list.
   It returns `PASS` or `FAIL` with findings.
3. **Recurse.** On `FAIL`, send the findings to a fresh `builder` for the
   same task, then review again, until `PASS`. If a task can't pass after
   repeated attempts, stop and report rather than handing over degraded code.
4. **Smoke the entry point** for wire tasks: a request through the router in
   the endpoint test case, or `Worker.perform/1`, asserting the criteria's
   response or side effect. Unit tests alone don't count.
5. **Record the task.** Note the files the builder changed or created (and,
   for a file several tasks touch, which hunks belong to this task), then tick
   the task in `plan.md`. Do **not** stage or commit. Next task.

## API doc

The last step of any work that changes the API (params, responses, routes,
access rules) is a Markdown document for API clients describing the change.
Use the API doc the plan names (drafted by `/brainstorm`); if it names none
but the API changed, write `docs/api/<slug>.md` in the style of the existing
API docs. That change doc is a hand-over for clients, **never committed**:
keep the committed `docs/api/` set small by updating the existing doc for each
endpoint touched instead, and don't link the change doc from them.

Check it against what was built: router, controllers, JSON views, and the API
spec schemas. Make the doc match the code. It must cover, per endpoint touched:
what changed (before → after), params, fields, a response example taken from a
real test response, access rules, errors, and ⚠️ on breaking changes with what
a client must change and when. Report any API spec gap as a finding for a
builder to fix. Leave it uncommitted.

## Finish

Run `mix compile --warnings-as-errors` and the full `mix test`. Set `plan.md`
to `Status: implemented` and append to `docs/MEMORY.md` any decision the
builders made that the plan didn't dictate.

Hand the user a **review guide**, one block per task:
- the task and its planned commit message: what it does, in one line;
- the files to look at, most important first, with `file:line` for the key change;
- decisions the builder made on its own, and review rounds that failed and why;
- how to try it: the test command, and an example request for endpoints.

Then the **proposed commit split**: the commits in order (ADR/terms first,
then one per task, the API doc last), each with its message and exact files
(hunks where a file is shared between tasks).

Then open the **Redline review** (needs the Redline VS Code extension and
its Claude Code plugin):

1. Run `/redline:redline-tour all`. It opens the uncommitted diff in VS Code
   as a PR-style round, with numbered notes in reading order. Make the notes
   follow the review guide: one per task (what it does, its planned commit
   message, decisions the builder made), on the task's key change.
2. If `redline_ping` reports `monitor: absent` (the VS Code chat panel), run
   `/redline:redline-connect listen` so submitted comments reach you.

End with anything still red and:
`Nothing is committed. Review in the Redline round in VS Code (hover a line, click +, then Submit review) or ask for fixes here, and say "accept" when it's right — then I'll commit it as split above.`

## Review comments

Submitted Redline threads arrive as one markdown document. Work through them
in file order:

1. A question gets an answer with `reply_comment`; the thread stays open.
2. A requested change goes through the same builder → reviewer loop as any
   other fix, scoped to that task. Then close the thread with
   `resolve_comment` and a one-line note naming what changed (`file:line`).
   A change you decline is resolved with the reason. A proposal that needs
   the user's decision is a `reply_comment`, left open.
3. Never edit or delete the user's comments.

When the batch is done, call `request_review` on the same source (`all`) so
the round refreshes with the fixes. Fixes stay uncommitted.

## Rules

- Sequential, in plan order. Use the Agent tool (subagents), not Agent Teams.
- Builder owns code, reviewer owns the gate, you own sequencing and, after
  acceptance only, the commits.
- Fixes asked for after hand-off go through the same builder → reviewer
  loop and stay uncommitted, folded into their task's planned commit.
- Never commit before the user accepts; "go" or running `/implement` is not acceptance.
- Never migrate or roll back the dev DB. Never push.
- Tests are never skipped. At Finish every test must be green; flaky tests
  listed in `.claude/project.md` may be rerun once.
