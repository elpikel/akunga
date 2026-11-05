defmodule MyApp.Repo.Migrations.CreateFavouritePlayers do
  use Ecto.Migration

  def change do
    create table(:favourite_players) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :sportsmonks_player_external_id, :integer, null: false
      add :notification_level, :string, null: false, default: "all"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:favourite_players, [:user_id, :sportsmonks_player_external_id])
    create index(:favourite_players, [:sportsmonks_player_external_id])
  end
end
