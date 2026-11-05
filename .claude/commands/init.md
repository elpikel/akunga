---
description: Set up the Claude kit in an Elixir/Phoenix repo — detect the repo's facts into .claude/project.md and create the docs the flow needs. Run once after copying the kit.
model: claude-sonnet-5-5
---

# init

Make a freshly copied kit (`.claude/commands`, `.claude/agents`,
`.claude/skills`, `.claude/README.md`) work in this repo. The kit is generic
Elixir/Phoenix; everything repo-specific goes in `.claude/project.md`.

Re-entrant: never overwrite a file that exists. Fill in missing values only,
and report what was already there.

## 1. Detect

Read the repo, don't guess. Use `.claude/project.md`'s headings (below) as
the checklist:

| Setting | Where to look |
|---|---|
| App name, OTP app, context and web roots, Repo | `mix.exs`, `lib/`, `config/config.exs` |
| Trunk branch | `git symbolic-ref refs/remotes/origin/HEAD`, else ask |
| Dev and test DB | `config/dev.exs`, `config/test.exs` (`database:`) |
| Table prefixes | `priv/repo/migrations/` table names; group by shared prefix |
| Endpoint and data test cases, factory | `test/support/` (`*ConnCase`, `*DataCase`, ExMachina factory) |
| Endpoint test file layout | existing files under `test/<app>_web/controllers/`; if both flat and per-action folders exist, use per-action folders (`<controller>/<action>_test.exs`) |
| Mox mocks | `Mox.defmock` in `test/test_helper.exs` |
| Known flaky tests | ask; default none |
| Router, path prefixes, pipelines | `lib/<app>_web/router.ex` (`pipeline :name`, `scope "..."`), with a few words on what each pipeline guards |
| API spec | `OpenApiSpex` in `mix.exs` deps and the specs directory; else "none" |
| API docs directory | an existing `docs/api/`, else `docs/api/` |
| Access rules | paywall, roles or tenancy checks (plugs, `paid?`, `authorize`, scoping by user); ADRs that describe them |
| Docs | `CONTEXT.md`, `docs/adr/`, `docs/architecture.md`, `docs/MEMORY.md` |

## 2. Ask

Ask only what the repo can't answer, in one batch (AskUserQuestion):
- the issue tracker and its id format (e.g. Linear `ABC-123`) and the commit
  reference format (e.g. `Refs ABC-123`);
- the trunk branch, if not detected;
- access rules the reviewer must enforce, confirming what you found;
- known flaky tests, if any.

## 3. Write

| File | Content |
|---|---|
| `.claude/project.md` | The detected and answered facts, in the same sections as the Ether example: App, Git and tracking, Databases, Tests, API, Access rules, Docs. Tables, not prose. |
| `CLAUDE.md` | If missing: a one-line description of the app, the test command, and a "Work tracking" section. If present: add the "Work tracking" section only. The section reads: stories and tasks live in the issue tracker; flow `/brainstorm` → review → `/implement` → review; see `.claude/README.md` and `.claude/project.md`. |
| `CONTEXT.md` | If missing: a stub with a heading and a short "Terms" table to fill. |
| `docs/adr/` | If missing: create it with a `.gitkeep`. |
| API docs directory | If missing and the repo has an API: create it with a `.gitkeep`. |
| `docs/MEMORY.md` | If missing: a header ("Dated decision log: what, why, what was rejected") and a first entry: `<date>: Claude kit set up.` |
| `docs/architecture.md` | Leave alone if present. If missing, don't create it; suggest `/document` later. |
| `.gitignore` | Add `.claude/work/` if it isn't there. |

Never commit.

## Hand off

The values detected, the ones you asked about, and the files created vs.
already present. Then:
`Kit ready. Review .claude/project.md, then start a feature with /brainstorm <issue or idea>.`
