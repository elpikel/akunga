# Where logic lives: constraints vs. contexts

Examples come from the Ether codebase; adapt names to your repo.

The database guarantees what must hold for **every writer**. Everything else
is Elixir in a context module.

| Concern | Home |
|---|---|
| Column must be present | `null: false` + `validate_required/2` |
| Uniqueness | `unique_index` + `unique_constraint/3` |
| Parent row must exist (app tables) | `references/2` + `foreign_key_constraint/3` |
| Value in a fixed set | `Ecto.Enum` (+ check constraint only if non-Ecto writers exist) |
| Range or shape rules | changeset validations; a `create constraint(..., check: ...)` only if non-Ecto writers exist |
| Business rules (paid vs. unpaid, lineup fallback, current club) | Context modules (`Ether.Rankings`, `Ether.Players`, …) |
| Multi-row writes that must succeed together | `Ecto.Multi` or `Repo.transaction/1` in the context |
| Heavy derived reads | Materialized view (see `derived-data.md`) |

## Changeset maps every DB constraint

```elixir
def changeset(%__MODULE__{} = favourite_player, attrs) do
  favourite_player
  |> cast(attrs, [:user_id, :sportsmonks_player_external_id])
  |> validate_required([:user_id, :sportsmonks_player_external_id])
  |> foreign_key_constraint(:user_id)
  |> unique_constraint([:user_id, :sportsmonks_player_external_id])
end
```

An unmapped constraint raises instead of returning `{:error, changeset}`.

## Database functions

Not a home for business logic. Ether's only function, for example, is `immutable_unaccent`,
a one-line `LANGUAGE sql IMMUTABLE` wrapper that functional indexes require.
A new function, plpgsql or otherwise, needs an ADR. Triggers: don't.
