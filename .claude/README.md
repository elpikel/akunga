# 🧰 Claude workflow kit (Elixir/Phoenix)

How to take an issue or an idea to reviewed, accepted, committed code with the slash commands, agents and skills in this folder. Built for Elixir/Phoenix, Ecto/PostgreSQL, Oban and ExUnit.

The kit is generic. Everything specific to a repo (trunk branch, issue tracker, databases, test layout, router pipelines, access rules) lives in **`.claude/project.md`**, which the commands and agents read.

---

## 🚀 Using the kit in another repo

1. Copy these from this repo into the other repo's `.claude/`:
   - `commands/`
   - `agents/`
   - `skills/`
   - `README.md`

   Don't copy `project.md` or `work/`.
2. Run `/init`. It reads the repo (`mix.exs`, config, router, `test/support`, migrations) and asks only what it can't detect: the issue tracker, the trunk if unclear, the access rules and any flaky tests. It then writes:
   - `.claude/project.md`;
   - a "Work tracking" section in `CLAUDE.md`;
   - any missing `CONTEXT.md`, `docs/adr/`, the API docs folder and `docs/MEMORY.md`;
   - `.claude/work/` added to `.gitignore`.
3. Review `.claude/project.md`, commit the kit, and start with `/brainstorm`.

Teammates on a repo that already has the kit committed need no setup.

---

## 🗺️ The flow

```
💡 issue (pasted) or an idea
  │
/brainstorm <paste>     talk it through, then write the plan and its docs:
  │                     plan, acceptance criteria (+ stories), ADR and API doc if needed
  ✋ you review the docs, ask for changes
/implement              builder writes tests + code, reviewer gates,
  │                     nothing committed
  ✋ you review in Redline (or the working tree), comments go back to the agent
"accept"                commits split as planned: one per task
```

| Size of the change | What to run |
|---|---|
| 🐜 Typo, wrong condition, stale doc line | Just ask in the chat |
| 🧩 A feature or behaviour change | `/brainstorm` → review → `/implement` → review → accept |
| 📝 Docs drifted from the code | `/document` |

**Before `/implement`, create your feature branch from the trunk.** Claude never switches branches, and `/implement` refuses to run on the trunk.

---

## 1. `/brainstorm <pasted issue or idea>`

Paste the issue description, or describe the idea. Claude reads the code it touches, the related ADRs and API docs, and talks it through with you:
- restates the task with what the code does today;
- points out conflicts with existing behaviour, ADRs or the access rules, and anything ambiguous in the task;
- asks what the code can't answer and recommends options;
- keeps a list of what's agreed and what's still open.

Nothing is written until you say yes to "Write the plan?". Then:

| Doc | Where | When |
|---|---|---|
| `plan.md` | `.claude/work/<slug>/` | Always: the approach, then tasks in order, each with its files, criteria and commit message. |
| `stories.md` | `.claude/work/<slug>/` | Always: acceptance criteria as Given/When/Then; a user story on top when it helps. |
| ADR | `docs/adr/NNNN-<slug>.md` | Only for a hard-to-reverse or surprising decision. |
| API doc | the API docs folder, `<slug>.md` | Only if params or responses change: the contract for API clients, drafted up front. |
| Terms | `CONTEXT.md` | Only new domain terms. |

`.claude/work/` is gitignored: the plan and stories are working docs for you and `/implement`. With an issue tracker, the tracker stays the record and the slug starts with the issue id, e.g. `abc-630-role-positions`. With local tasks (as in this repo, see `.claude/project.md`), `.claude/work/<slug>/` is the record and the slug is a short name, e.g. `user-signup`.

Review the docs and ask for changes in the same chat. Rerunning `/brainstorm` on the same slug refines them.

## 2. `/implement [slug]`

Running it is your sign-off. For each task in `plan.md`:
1. The **builder** (Opus) writes the task's tests from its acceptance criteria (red), then the code, and runs format, compile, credo and tests.
2. The **reviewer** (Opus) checks the diff against the task, its criteria, the project rules, the access rules and security: PASS or FAIL.
3. On FAIL, a fresh builder fixes the findings and the reviewer checks again, until it passes.
4. Wire tasks are smoke-tested through the router or `Worker.perform/1`.
5. **Nothing is committed.** The task's files are recorded and the task is ticked; the API doc is checked against the built code and API spec.

## 3. Review

`/implement` ends with a **review guide**, one block per task: what it does, the files to look at (`file:line`), decisions the builder made on its own, failed review rounds, and how to try it. Then a **proposed commit split**:
1. `docs:` the ADR, if any;
2. one commit per task (shared files split by hunk);
3. `docs(api):` the API doc.

It then opens a **Redline review** in VS Code: the uncommitted diff as a PR-style round, with one note per task. Hover a line, click **+** to comment, then **Submit review**. Claude fixes each thread through the same builder → reviewer loop, then resolves it or replies, and refreshes the round. You need the [Redline](https://nikiforovall.blog/redline/guide) VS Code extension and its plugin (`/plugin marketplace add nikiforovall/redline`, then `/plugin install redline@redline`). If you run Claude in the VS Code panel rather than a terminal, run `/redline:redline-connect listen` so comments reach the session.

You can also review the working tree (`git diff`) and ask for fixes in the chat. Either way, fixes stay uncommitted.

## 4. Accept

Say **"accept"** when the solution is right. Only then are the commits made, as split above, with the plan's Conventional Commit messages and the issue reference. No co-author line. Nothing is pushed, amended or rebased; unrelated uncommitted changes in your tree are left alone. Then push and open the PR yourself.

---

## 🧪 Test rules (enforced by the agents)

- **Never skipped.** No `@tag :skip` and no exclusion tags. Every commit leaves the suite green.
- **Where tests live:** endpoint tests in one file per controller action (`<controller>/<action>_test.exs`), module tests mirroring `lib/`. The exact paths and test cases are in `.claude/project.md`. Files are never named after stories or issues.
- **Shape:** flat top-level `test` blocks named by behaviour. No `describe`, no `setup`. Each test arranges its own data with `insert(:factory)`. Mock external APIs with Mox.

---

## 🤖 Agents

| Agent | Model | Role |
|---|---|---|
| `builder` | Opus | Implements one task, tests first. Follows the Elixir conventions in `agents/builder.md`. Never commits, never switches branches, never migrates the dev DB. |
| `reviewer` | Opus | Read-only gate. Runs the checks itself, traces the entry point, and fails on rule violations, access-rule breaches, security issues or dead code. |

`/implement` coordinates them (Sonnet) and, after you accept, makes the commits. It never writes or reviews code itself.

## 🧭 Commands

| Command | Model | Use it to |
|---|---|---|
| `/init` | Sonnet | Set the kit up in a new repo (once). |
| `/brainstorm <paste>` | Opus | Talk a task through; write the plan, criteria, and ADR/API doc if needed. |
| `/implement [slug]` | Sonnet | Build the plan with builder + reviewer, uncommitted; commit the planned split once you accept. |
| `/document [area]` | Sonnet | Bring README, architecture prose and `MEMORY.md` back in line with the code. |

## 📚 Skills

| Skill | Used for |
|---|---|
| `bdd-specs` | The builder writing a task's tests from its acceptance criteria. |
| `domain-modeling` | ADRs and `CONTEXT.md` terms (`/brainstorm`). |
| `design-principles` | Module and context design in Elixir: coupling, cohesion, seams. |
| `postgres-dba` | Ecto migrations, schemas, indexes, views. |
| `github` | Commit and PR message conventions. |
| `agent-teams` | Running parallel agent teams (rarely needed). |

---

## ⚠️ Things to know

- **Nothing is committed until you accept.** `/implement` commits its planned split only after your "accept"; everywhere else, Claude commits only when you ask. No co-author lines, ever. Nothing is pushed.
- **Claude never writes to the issue tracker.**
- **The dev DB is never migrated or rolled back.** Migrations are verified on the test DB (`mix test` migrates it).
- **Known flaky tests** are listed in `.claude/project.md`. Rerun before investigating.
