# Naming

Examples come from the Ether codebase; adapt names to your repo.

Lowercase `snake_case`, unquoted, everywhere. If an identifier ever needs
double quotes, it's wrong.

## Tables

- Plural: `entitlements`, `favourite_players`.
- Prefixed by owner when the data comes from a source. The repo's prefixes
  are in `.claude/project.md`; Ether's, as an example:

| Prefix | Owner |
|---|---|
| `sportsmonks_*` | `Workers.Sportsmonks` |
| `dbt_*` | external dbt pipeline (read-only for the app) |
| `dat_*` | app workers, from `dbt_*` after ID mapping |
| `idmap_*` | `Workers.Idmap` |
| `rotowire_*` | `Workers.Rotowire*` |
| `fpl_*` | `Workers.Fpl*` |
| `social_media_*` | `Workers.SocialMedia.*` |

- App-owned tables (users, entitlements, devices, favourites) have no prefix.

## Columns

- Singular, descriptive, full words: `percentile_rank_desc_p90`, not `pr_d90`.
- External references: `<source>_<entity>_external_id`
  (`sportsmonks_team_external_id`); app FKs: `<table_singular>_id` (`user_id`).
- Timestamps end in `_at` (`expires_at`); dates end in `_on` (`updated_on`).
- Booleans read as predicates: `has_media`, `is_confirmed`.

## Schemas match columns

The Ecto field name is the column name. Don't rename with `source:` unless the
column is provider-owned and can't change. Before writing any query or
migration, read the schema to get the real table and column names.

## Indexes and constraints

- DSL indexes: let Ecto name them.
- `execute/2` indexes: `<table>_<columns>_<purpose>_idx`.
- Check constraints: `<table>_<column>_check`.

## Domain terms

Use the domain vocabulary (`CONTEXT.md`) in new names, e.g. in Ether `fixture` over `match`,
`sidelined` over `injured`, `gradient_rankings` over `global_rankings`.
Existing names (e.g. `games`, `global_rankings`) stay until a deliberate
migration renames them.
