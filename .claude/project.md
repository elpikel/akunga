# 🔧 Project settings for the Claude kit

The kit's commands, agents and skills are generic Elixir/Phoenix. Everything specific to this repo lives here. Edit by hand when a fact changes; the project is new, so most rows will grow.

## App

| Setting | Value |
|---|---|
| Name | Akunga (new Phoenix 1.8 app, no domain code yet) |
| OTP app | `:akunga` |
| Context root | `lib/akunga/` (`Akunga.*`) |
| Web root | `lib/akunga_web/` (`AkungaWeb.*`) |
| Repo | `Akunga.Repo` |

## Git and tracking

| Setting | Value |
|---|---|
| Trunk branch | `main` |
| Issue tracker | None: tasks are local, in `.claude/work/<slug>/` (`plan.md`, `stories.md`) |
| Slug | Short kebab-case name, e.g. `user-signup` (no issue id) |
| Commit reference | None |

## Databases

| Setting | Value |
|---|---|
| Dev DB (never migrate or roll back) | `akunga_dev` |
| Test DB (`mix test` migrates it) | `akunga_test` |
| Table prefixes | None yet; no migrations |

## Tests

| Setting | Value |
|---|---|
| Endpoint test case | `AkungaWeb.ConnCase` |
| Data test case | `Akunga.DataCase` |
| Factory | None yet (no ExMachina). Add `test/support/factory.ex` when the first schema lands. |
| Endpoint test file | `test/akunga_web/controllers/<controller>/<action>_test.exs`, module `AkungaWeb.Controllers.<Controller>.<Action>Test` |
| LiveView test file | `test/akunga_web/live/<live_view>_test.exs` |
| Module test file | `test/akunga/…` mirroring `lib/akunga/…` |
| Mox mocks (external APIs) | None (Mox not installed) |
| Known flaky | None |

## API

| Setting | Value |
|---|---|
| Router | `lib/akunga_web/router.ex` |
| Path prefixes | `/` (browser); `/dev` (LiveDashboard, mailbox; dev only). `/api` scope is stubbed but not mounted. |
| Pipelines (reviewer checks placement) | `:browser` (session, CSRF, secure headers), `:api` (JSON only, no auth) |
| API spec | None |
| API docs for clients | `docs/api/<slug>.md` (create when the first API endpoint lands) |

## Access rules (reviewer fails on any leak)

None yet: there is no authentication or authorization. Add rules here when auth (e.g. `phx.gen.auth`, `current_scope`) is introduced.

## Docs

| Doc | Path |
|---|---|
| Domain language | `CONTEXT.md` |
| ADRs | `docs/adr/` |
| Architecture | `docs/architecture.md` (not written yet; run `/document` once there's code) |
| Decision log | `docs/MEMORY.md` |
