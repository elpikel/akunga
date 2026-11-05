defmodule MyApp.Favourites.FavouritePlayer do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias MyApp.Users.User

  @notification_levels [:all, :goals_only, :none]

  schema "favourite_players" do
    belongs_to :user, User
    field :sportsmonks_player_external_id, :integer
    field :notification_level, Ecto.Enum, values: @notification_levels, default: :all

    timestamps(type: :utc_datetime)
  end

  def notification_levels, do: @notification_levels

  def changeset(%__MODULE__{} = favourite_player, attrs) do
    favourite_player
    |> cast(attrs, [:user_id, :sportsmonks_player_external_id, :notification_level])
    |> validate_required([:user_id, :sportsmonks_player_external_id])
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :sportsmonks_player_external_id])
  end
end
