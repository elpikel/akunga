defmodule MyApp.Repo.Migrations.AddRankTypeUpdatedOnIndexToGradientRankingsHistory do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create index(:dat_gradient_rankings_history, [:rank_type, :updated_on], concurrently: true)
  end
end
