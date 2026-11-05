# Derived data: functional indexes and materialized views

Examples come from the Ether codebase; adapt names to your repo.

Check the existing migrations for generated columns first (Ether has none). Derived data takes one of two forms.

## Functional indexes (search, normalised lookup)

For case- and accent-insensitive search, index the expression instead of
storing a copy:

```elixir
@disable_ddl_transaction true
@disable_migration_lock true

def up do
  execute("""
  CREATE INDEX CONCURRENTLY IF NOT EXISTS sportsmonks_players_display_name_lower_unaccent_idx
  ON sportsmonks_players (lower(immutable_unaccent(display_name)))
  """)
end

def down do
  execute("DROP INDEX CONCURRENTLY IF EXISTS sportsmonks_players_display_name_lower_unaccent_idx")
end
```

The query must use the identical expression or the index is ignored:

```elixir
Player
|> from(as: :player)
|> where([player: player], fragment("lower(immutable_unaccent(?))", player.display_name) == ^normalised_query)
```

## Materialized views (heavy aggregate reads)

Used for metric comparison (ADR-0007) and similar wide reads. Rules:

- Created and dropped with `execute/2` in `up`/`down`. Changing the definition
  means drop and recreate, in the same migration.
- Needs a `UNIQUE INDEX` so `REFRESH MATERIALIZED VIEW CONCURRENTLY` works.
- Refreshed by an Oban worker (e.g. `Workers.MetricComparisonRefresh`), never
  per request.
- Read through an Ecto schema with `@primary_key false`. Select only the
  columns you need: `metric_comparison` has ~300 columns.
- Profile the defining query with `EXPLAIN ANALYZE` before blaming the
  refresh mechanism (ADR-0007: the cost was the query, not the refresh).

See `templates/materialized_view_migration.exs`.

## A stored generated column?

Allowed if a value is filtered or sorted often and a functional index can't
serve it. Add it with `execute/2` (`ALTER TABLE ... ADD COLUMN ... GENERATED
ALWAYS AS (...) STORED`) and a `down`. If the repo has none yet, note the reason
in the PR.
