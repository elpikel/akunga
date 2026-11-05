# Keys and foreign keys

Examples come from the Ether codebase; adapt names to your repo.

Apps fed by external providers have two table families with different identities. Pick the family
first; the keys follow.

## App-owned tables: Ecto default `id`

Users, entitlements, devices, favourites, notification tokens. Ecto's default
`id` (bigserial) is the identity; natural keys get a `unique_index`.

```elixir
create table(:favourite_players) do
  add :user_id, references(:users, on_delete: :delete_all), null: false
  add :sportsmonks_player_external_id, :integer, null: false

  timestamps(type: :utc_datetime)
end

create unique_index(:favourite_players, [:user_id, :sportsmonks_player_external_id])
```

The schema declares nothing for the key (`@primary_key` defaults to `:id`).

## Provider read models: composite unique key, no `id`

Externally fed tables (in Ether: `dat_*`, `dbt_*`, metric tables) are rebuilt by workers from external data.
Their identity is the combination of external IDs, and it must equal the
upsert `conflict_target`:

```elixir
create table(:dat_teams_weekly_metrics, primary_key: false) do
  add :sportsmonks_season_external_id, :integer, null: false
  add :sportsmonks_gameweek_external_id, :integer, null: false
  add :sportsmonks_team_external_id, :integer, null: false
  add :metric_name, :string, null: false
  add :metric_value, :decimal, null: false

  timestamps(type: :utc_datetime)
end

create unique_index(:dat_teams_weekly_metrics, [
         :sportsmonks_season_external_id,
         :sportsmonks_gameweek_external_id,
         :sportsmonks_team_external_id,
         :metric_name
       ])
```

```elixir
Repo.insert_all(TeamWeeklyMetric, rows,
  on_conflict: {:replace, [:metric_value, :updated_at]},
  conflict_target: [
    :sportsmonks_season_external_id,
    :sportsmonks_gameweek_external_id,
    :sportsmonks_team_external_id,
    :metric_name
  ]
)
```

The schema sets `@primary_key false`.

## Pure junctions

`primary_key: false`, both columns `null: false`, a `unique_index` on the pair.
No `id`: the pair is the identity.

## Foreign keys

| Target | Column | DB constraint |
|---|---|---|
| App table (`users`) | `user_id` via `references/2` | Yes. `on_delete` always explicit: `:delete_all` when the row means nothing without the parent, `:nilify_all` only for genuinely optional links (then `null: true`). |
| Provider data | `<source>_<entity>_external_id`, `:integer` | Usually none: provider rows arrive out of order, and a worker must not fail on a missing parent. Index the column. |
| Provider table where order is guaranteed | `references(:sportsmonks_leagues, column: :external_id, type: :integer)` | Allowed when the parent is always written first. |

A missing `on_delete` (defaulting to `:nothing`) is a review finding.

## Don't

- Declare `id serial`; use the default.
- Add a surrogate `id` to a provider read model "just in case".
- Let the upsert `conflict_target` drift from the unique index.
