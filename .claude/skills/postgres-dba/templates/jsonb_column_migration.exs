defmodule MyApp.Repo.Migrations.AddPayloadToRotowireNews do
  use Ecto.Migration

  def change do
    alter table(:rotowire_news) do
      add :payload, :map, null: false, default: %{}
      add :is_injury_related, :boolean, null: false, default: false
    end

    create index(:rotowire_news, [:is_injury_related])
  end
end

# Schema fields:
#
#   field :payload, :map, default: %{}
#   field :is_injury_related, :boolean, default: false
#
# The worker that writes `payload` also sets `is_injury_related`, because
# queries filter on it. Fields only displayed stay inside `payload`.
