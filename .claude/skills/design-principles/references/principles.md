# Design Principles — Elixir Reference

Each section: the rule → wrong → right → when it's over-engineering.
Examples come from the Ether codebase; adapt names to your repo.
Module names marked *(illustrative)* don't exist in Ether; the rest do.
Examples follow `.claude/agents/builder.md` conventions.

---

## Coupling — keep it loose; measure it with connascence

**Rule.** Minimise what a module must know about another. Connascence ranks
the knowledge, weakest to strongest: *name* < *type* < *meaning* <
*position* < *algorithm* < *timing*. Weaken it where it crosses modules;
keep strong forms inside one module. Dependencies point toward stable code:
web → contexts → schemas, never back.

**Wrong** — connascence of position and meaning across a context boundary:

```elixir
Rankings.list("TOP_5", "2024/2025", ["FB"], 20, true)
```

**Right** — named params in one map; the meaning of `true` becomes a Viewer:

```elixir
Rankings.list(%{
  competition_group: "TOP_5",
  season_name: "2024/2025",
  positions: ["FB"],
  viewer: viewer
})
```

**Over-engineering when** both sides live in the same module and change
together; a private two-argument helper doesn't need a params map.

---

## Cohesion — one reason to change

**Rule.** A module groups functions that change for the same reason and are
used together (single responsibility at module scale).

**Wrong** — a grab-bag `Ether.Helpers.Misc` *(illustrative)* holding role
lookups, date formatting and FPL price maths: three reasons to change, every
caller depends on all of them.

**Right** — each piece lives with its concept: role vocabulary in
`Ether.Players.Roles`, position vocabulary in `Ether.Players.Positions`, FPL
maths in the `Ether.Fpl` context.

**Over-engineering when** you split a 60-line module that only ever changes
as a unit into four files.

---

## DRY — one authoritative home for each piece of knowledge

**Rule.** Duplicate *knowledge* (a rule, a mapping, a vocabulary) is the
problem; duplicate *characters* aren't.

**Wrong** — two hand-maintained tables encoding the same role→position fact
(as `Ether.Players.Roles` has with `@roles_by_group` and `@roles_by_bucket`):

```elixir
@roles_by_group [{"Full Backs", ["Overlapping Full Back"]}]
@roles_by_bucket [%{label: "Defenders", roles: ["Overlapping Full Back"]}]
```

**Right** — derive the second view from the first (`Positions.bucket_groups/0`
is *illustrative*; it doesn't exist yet):

```elixir
def hierarchy(%{selected_roles: selected_roles, locked: locked}) do
  Positions.bucket_groups()
  |> Enum.map(&bucket_roles(&1, %{selected_roles: selected_roles, locked: locked}))
end
```

**False DRY.** Two functions with identical bodies that encode *different*
decisions (e.g. the free-filter list for Rankings vs. Skill Leaderboards,
ADR-0036) stay separate. Merging them couples two product decisions. Rule of
Three before extracting.

---

## YAGNI — You Aren't Gonna Need It

**Rule.** Build for today's requirement; keep the seam cheap to add later.

**Wrong** — a `RoleProvider` behaviour with one static implementation, "in
case roles come from DAT one day".

**Right** — a plain module with a module attribute. If DAT ever supplies
roles, the change is local to `Ether.Players.Roles`.

**Over-engineering signal:** a behaviour, config key, or option with exactly
one implementation and no test that needs to swap it.

---

## KISS — keep it simple

**Rule.** The simplest design that works; complexity must pay rent.

**Wrong** — a `__using__` macro generating filter functions per facet, so
nobody can grep where `filter_by_nationality/2` is defined.

**Right** — explicit functions, one per facet, pattern-matched on the param:

```elixir
def filter_by_nationality(query, []), do: query

def filter_by_nationality(query, nationalities) do
  where(query, [profile: profile], profile.nationality in ^nationalities)
end
```

**Over-engineering when** "simple" means copying a 40-line query five times —
then DRY wins.

---

## Separation of Concerns

**Rule.** Controller parses and authorises, context decides, query module
fetches, JSON view renders. Raw params stop at the controller.

**Wrong** — a context reading request params and building the response:

```elixir
def list(conn) do
  conn.params["positions"]
  |> build_query()
  |> Repo.all()
  |> Enum.map(&%{"name" => &1.name})
end
```

**Right** — each layer owns one concern:

```elixir
def list(conn, params) do
  viewer = Viewer.from_identity(conn.assigns.identity_provider_id)
  rankings = Rankings.list(%{positions: Map.get(params, "positions", []), viewer: viewer})
  render(conn, :list, rankings: rankings)
end
```

**Over-engineering when** a one-off internal task gets controller/context/view
layering it will never need.

---

## Information Hiding — a context's schemas are private

**Rule.** Other contexts call functions, not join on your schemas. The
representation (tables, joins, materialised views) can then change freely.

**Wrong** — `Ether.SkillsLeaderboard` joining `dat_gradient_rankings` with
its own query, duplicating how Rankings scopes seasons (ADR-0032).

**Right** — ask Rankings for what you need:

```elixir
ranked_season_ids = Rankings.ranked_season_ids(%{league_ids: league_ids})
```

**Over-engineering when** you add an accessor for every field of a schema
only one context ever reads.

---

## Tell, Don't Ask

**Rule.** Ask the owning module for the decision; don't pull its data out and
decide for it.

**Wrong** — callers interpret entitlements themselves:

```elixir
if Enum.any?(entitlements, &(&1.name == "gradient_fc_premium")), do: full_rows, else: trimmed_rows
```

**Right** — the Viewer owns the interpretation (ADR-0033):

```elixir
if Viewer.paid?(viewer), do: full_rows, else: trimmed_rows
```

**Over-engineering when** the "decision" is rendering — JSON views legitimately
read fields.

---

## Law of Demeter — don't navigate other contexts' graphs

**Rule.** Talk to your immediate collaborator; don't walk preloaded
associations across context boundaries.

**Wrong:**

```elixir
player.current_team.primary_league.current_season.external_id
```

**Right** — one function answers the question:

```elixir
Teams.current_season_external_id(%{team_id: player.current_team_id})
```

**Over-engineering when** the chain stays inside one context's own schemas
and is already preloaded for that purpose.

---

## Composition — functions and behaviours, no inheritance

**Rule.** Elixir has no inheritance. Build behaviour by composing small
functions in pipelines and by implementing behaviours. Avoid `use` macros
that inject overridable functions — they recreate inheritance's coupling.

**Wrong** — `use Ether.BaseFilter` *(illustrative)* injecting `apply/2` with
`defoverridable`, so each filter's real behaviour is split across two files.

**Right** — a pipeline of explicit filter steps:

```elixir
def filter(query, filters) do
  query
  |> filter_by_positions(filters.positions)
  |> filter_by_roles(filters.player_roles)
  |> filter_by_nationality(filters.nationalities)
end
```

**Over-engineering when** you invent a pipeline DSL for three steps.

---

## Program to a Behaviour

**Rule.** External systems sit behind a `@callback` contract. Callers depend
on the contract module; the implementation is chosen by config, and tests
swap in a Mox mock. This is dependency inversion: the context owns the
contract, the HTTP adapter depends on it.

**Right** — Ether's existing shape (`Ether.Fpl.Client`):

```elixir
defmodule Ether.Fpl.Client do
  @callback bootstrap_static() :: map()

  def bootstrap_static, do: client().bootstrap_static()

  defp client, do: Application.get_env(:ether, :fpl_client, Ether.Fpl.Client.Http)
end
```

**Wrong** — a worker calling `Req.get!/1` against the FPL API directly,
untestable without the network.

**Over-engineering when** you add a behaviour around the app's own contexts or
the Repo. Test those for real against the sandboxed DB.

---

## Command–Query Separation

**Rule.** A function either changes state (returns `{:ok, _}` / `{:error, _}`
or `:ok`) or answers a question (returns data) — not both.

**Wrong** — a getter that writes:

```elixir
def get_device(device_id) do
  Repo.get_by(Device, device_id: device_id) || Repo.insert!(%Device{device_id: device_id})
end
```

**Right** — name the command honestly:

```elixir
def get_or_create_device(device_id) do
  Device
  |> Repo.get_by(device_id: device_id)
  |> ensure_device(device_id)
end
```

**Over-engineering when** an upsert's returned row is genuinely what the
caller needs — return it, but name the function as a command.

---

## Least Astonishment

**Rule.** Names and return shapes match conventions:
- `get_*` returns the value or `nil`; `get_*!` raises.
- `fetch_*` returns `{:ok, value}` / `{:error, reason}`.
- `list_*` returns a list, never `nil`.
- `*?` returns a boolean and has no side effects.

**Wrong** — `fetch_player/1` returning `nil`, or `paid?/1` that writes a log
row.

**Right** — `fetch_player/1` returns `{:error, :not_found}`; `paid?/1` is a
pure read (as `Ether.Accounts.Viewer.paid?/1` is).

**Over-engineering when** you rename a stable, widely used function purely
for convention without other reason to touch it.

---

## Fail Fast

**Rule.** Validate at the boundary (controller params, OpenApiSpex, changesets,
webhook payloads), return `{:error, _}` for expected failures, and let
impossible states crash via pattern matching. Fail *closed* where safety
matters: an access check that errors resolves to the most restricted access
(see the access rules in `.claude/project.md`; in Ether, a paywall check that
errors resolves unpaid, ADR-0033).

**Wrong** — accepting anything and discovering `nil` three calls deep:

```elixir
def list_rankings(params), do: build_query(params["season"])
```

**Right** — match the accepted shape and chain dependent steps with `with`:

```elixir
def list_rankings(%{season_name: season_name, league_ids: league_ids}) do
  with {:ok, season} <- Seasons.fetch_by_name(season_name),
       {:ok, leagues} <- Leagues.fetch_all(league_ids) do
    {:ok, query_rankings(%{season: season, leagues: leagues})}
  end
end
```

**Over-engineering when** you add defensive `nil` checks for values the
type, schema or pattern match already guarantees.
