# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Akunga is a freshly generated Phoenix 1.8 app (`mix phx.new`): LiveView 1.2, Ecto/PostgreSQL, Tailwind v4, esbuild, Bandit. There is no domain code yet: only the generated skeleton (`PageController` home page, core components, layouts, error views).

**Read `AGENTS.md` before writing code.** It holds the Phoenix 1.8, LiveView, HEEx, Ecto, Tailwind and testing rules for this repo; they are not repeated here.

## Commands

```bash
mix setup                    # deps.get, ecto.setup (create, migrate, seeds), assets install + build
mix phx.server               # dev server on localhost:4000 (or: iex -S mix phx.server)
mix test                     # creates + migrates the test DB, then runs the suite
mix test path/to/file_test.exs:LINE   # single test
mix test --failed            # rerun last failures
mix precommit                # compile --warnings-as-errors, deps.unlock --unused, format, test (run in MIX_ENV=test)
mix ecto.gen.migration name_with_underscores
mix ecto.reset               # drop + setup
```

Databases: `akunga_dev` and `akunga_test` (`akunga_test<MIX_TEST_PARTITION>`) on localhost, user `postgres` (see `config/dev.exs`, `config/test.exs`). Dev routes `/dev/dashboard` (LiveDashboard) and `/dev/mailbox` (Swoosh preview) are enabled in dev.

## Architecture

- `lib/akunga/` is the core (`Akunga.*`): `Application` supervises Telemetry, `Akunga.Repo`, DNSCluster, `Akunga.PubSub`, and the endpoint. Put contexts here.
- `lib/akunga_web/` is the web layer (`AkungaWeb.*`). `AkungaWeb` (`lib/akunga_web.ex`) defines the `use AkungaWeb, :controller | :html | :live_view | ...` macros; app-wide template imports go in its `html_helpers`.
- `AkungaWeb.Layouts` (`components/layouts.ex`) provides `<Layouts.app flash={@flash} current_scope={...}>`, `flash_group` and a light/dark `theme_toggle`. The root layout is `components/layouts/root.html.heex`.
- `AkungaWeb.CoreComponents` provides `<.input>`, `<.icon name="hero-...">`, buttons, tables, flash, etc.
- Router (`lib/akunga_web/router.ex`) has `:browser` and `:api` pipelines; the `"/"` scope is aliased to `AkungaWeb`. There is no auth yet (no `phx.gen.auth`, so no `current_scope` is assigned).
- Assets: `assets/css/app.css` uses the Tailwind v4 `@import`/`@source` syntax with the heroicons and daisyUI plugins (daisyUI themes are defined there); `assets/js/app.js` is the only JS bundle. Colocated LiveView hooks/CSS are compiled into `_build/<env>/phoenix-colocated/akunga/`.
- Tests: `AkungaWeb.ConnCase` and `Akunga.DataCase` in `test/support/`, Ecto SQL sandbox in manual mode. LiveView tests use `Phoenix.LiveViewTest` with `LazyHTML`.

## Differences from the user's global instructions

The global `~/.claude/CLAUDE.md` describes another project (Ether). In this repo:
- The main branch is `main`, not `staging`.
- Oban, Mox, ExMachina and Styler are **not** installed; formatting is plain `mix format` with `Phoenix.LiveView.HTMLFormatter`. There is no `test/support/factory.ex`.
- HTTP requests use `Req` (already a dependency).

## Work tracking

There is no issue tracker: tasks are local, one folder per task in `.claude/work/<slug>/` (`plan.md`, `stories.md`; gitignored). Flow: `/brainstorm` → review → `/implement` → review → "accept". See `.claude/README.md` and `.claude/project.md` (repo facts the commands and agents read). Domain terms live in `CONTEXT.md`, decisions in `docs/adr/` and `docs/MEMORY.md`.
