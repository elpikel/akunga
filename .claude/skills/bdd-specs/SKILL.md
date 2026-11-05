---
name: bdd-specs
description: >-
  Behavior-driven design for Elixir/Phoenix: write executable ExUnit specs
  BEFORE implementation code, from the agreed acceptance criteria (a tracker
  issue or a /brainstorm conversation). Tests go in the endpoint's file (controllers/<controller>/<action>_test.exs) or the module's file, never a story-named file; flat
  top-level tests (no describe, no setup), each test arranging its own data
  with ExMachina and asserting one behaviour; happy paths first, sad paths
  after. New specs are never skipped: they run red until built. At least one test per Feature
  goes through the router (ConnCase) or Oban worker perform/1. Use when asked
  to "spec out", "write the tests first", do BDD/TDD, or turn stories into a
  test suite.
---

# Behavior-Driven Design: Specifications First (ExUnit)

Specs are written **before** implementation. They encode the intended
behaviour from the agreed acceptance criteria, start red, and become the
definition of done. Don't write implementation code under this skill.

## 🎯 Why: Design for Change

Specs are the safety net that makes change possible. One behaviour per test
means a failing test names exactly what broke; happy/sad ordering means you
can change one behaviour without re-reading the whole file.

## The workflow (in order)

### 1. Require agreed acceptance criteria
They come from the issue (tracker in `.claude/project.md`) or from the
`/brainstorm` conversation, plus
the feature's rules in `docs/SPEC.md`. If there are none, or they're too vague
to assert on, stop and ask. Never invent criteria. Each story is one Feature;
each acceptance criterion is a group of tests.

### 2. Read what exists
Read the endpoint's and module's existing test files. Append to them; never
change or remove existing tests.

### 3. Pick the case template and location
- HTTP behaviour → `use` the endpoint test case with `async: true`, in the
  endpoint's file. The case module, the endpoint test file path and its
  module naming are in `.claude/project.md` (shape:
  `controllers/<controller>/<action>_test.exs`, e.g.
  `rankings_controller/list_v3_test.exs`). If the file
  exists, append the story's tests to it; otherwise create it. A story that
  spans several endpoints puts each endpoint's tests in that endpoint's file.
- Context, query or worker behaviour → the data test case from
  `.claude/project.md` with `async: true` (or `ExUnit.Case` with no DB), in
  the module test file layout from `.claude/project.md` (mirroring the
  `lib/` path of the module under test).
- Never name a file after a story or an issue id. The
  `.claude/work/<slug>/plan.md` lists which test files prove which task.

### 4. Generate, then stop
Write the files from `templates/feature_test.exs` (swap `MyAppWeb` for the
web module in `.claude/project.md`), then present them for
review. No implementation until the user approves.

## The spec shape (mandatory)

Example from the Ether codebase; adapt module names to your repo.

```elixir
defmodule EtherWeb.Controllers.SkillsLeaderboardController.ListV3Test do
  use EtherWeb.ConnCase, async: true

  test "an unpaid viewer sees the team filter locked with no options", %{conn: conn} do
    team = insert(:team)
    insert(:squad, team: team)

    response =
      conn
      |> get("/api/v3/rankings/skill_leaderboards")
      |> json_response(200)

    assert %{"locked" => true, "list" => [], "selected" => []} = response["filters"]["team"]
  end
end
```

Hard rules for every generated file:

1. **Files belong to endpoints (or modules), not stories.** A story's tests
   go into the file of the endpoint or module they exercise. No story ids in
   files, test names or comments.
2. **Flat top-level `test` blocks.** No `describe`, no `setup`/`setup_all`.
3. **Each test arranges its own data inline** with `insert(:factory)`.
   Non-assert fixture builders (`defp`, placed below all tests) are allowed
   when arrangement repeats; helpers containing assertions are not.
4. **One behaviour per test.** Prefer a single pattern-match `assert`. Multiple
   asserts only when they check facets of the same behaviour.
5. **Tests are named by behaviour** in plain words. No "Q1:", no ids, no
   "Scenario:" prefixes.
6. **Happy path first and exhaustive**, then sad paths (validation, not found,
   unauthorized, denied by the access rules in `.claude/project.md`).
   Never interleaved.
7. **Never skipped:** no `@tag :skip`, no exclusion tag, no commenting out.
   New tests run and stay red until the builder implements the behaviour.
   Tests that already pass are guards for existing behaviour; keep them.
8. **At least one test per Feature goes through the real entry point**: the
   router via `ConnCase`, or `Worker.perform/1` for Oban work. Mock external
   APIs with Mox (`stub/3`, `expect/4`); never mock the app's own modules.
   The existing mocks are listed in `.claude/project.md`.
9. **Data rules:** factory sequences and `.external_id` references, never
   hardcoded IDs. Never `Repo.delete_all` seeded reference data. Follow
   the repo's test-data rules in `.claude/project.md`.
10. **Log capture per test only:** never `@moduletag capture_log: true`; put
    `@tag :capture_log` on the individual tests that actually print logs.
    No DB tricks (triggers, DDL, spoofed constraint names) to force failures.
11. Use the domain-language terms (`CONTEXT.md`, per `.claude/project.md`) in
    test names, not generic synonyms (e.g. in Ether: Fixture, not match).

## Templates

- `templates/feature_test.exs`: the shape above with happy and sad paths.

See `references/workflow.md` for the story → tests mapping worked through.
