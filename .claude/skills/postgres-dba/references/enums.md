# Value sets: `Ecto.Enum`

Examples come from the Ether codebase; adapt names to your repo.

Don't add Postgres enum types (Ether has none). Small, code-driven value sets (provider,
type, priority, status) are `Ecto.Enum` over a `:string` column.

## Migration

```elixir
alter table(:social_media_accounts) do
  add :priority, :string, null: false, default: "medium"
end
```

## Schema

```elixir
@priorities [:high, :medium, :low]

schema "social_media_accounts" do
  field :priority, Ecto.Enum, values: @priorities, default: :medium
end

def priorities, do: @priorities
```

Callers use the module function (`Account.priorities()`), never the literal
strings.

## When to add a check constraint

Only when something other than Ecto writes the column (SQL backfills, an
external pipeline). Ether, for example, has one, on `social_media_accounts.priority`:

```elixir
create constraint(:social_media_accounts, :social_media_accounts_priority_check,
         check: "priority IN ('high', 'medium', 'low')"
       )
```

Map it in the changeset with `check_constraint/3` so a violation becomes a
changeset error, not an exception.

## Adding or removing a value

- Add: extend `values:`. No migration unless a check constraint exists (then
  drop and recreate it in `up`/`down`).
- Remove: backfill existing rows first in a migration, then drop the value.

## Lookup table instead?

Only when the set carries extra columns, is edited without a deploy, or churns
often. The static role and position vocabularies stay in code
(`Ether.Players.Roles`, `Ether.Players.Positions`), not tables.

## Don't

- `execute("CREATE TYPE ...")`.
- Hardcode the string values anywhere outside the schema module.
