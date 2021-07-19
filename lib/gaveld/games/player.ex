defmodule Gaveld.Games.Player do
  use Ecto.Schema
  import Ecto.Changeset

  alias Gaveld.Games.Game

  schema "players" do
    field :name, :string
    field :points, :integer
    field :uid, :string
    belongs_to :game, Game

    timestamps()
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:name, :uid, :game_id])
    |> validate_required([:name, :uid, :game_id])
    |> validate_length(:name, min: 3, message: "must be at least 3 characters")
    |> unique_constraint(:uid, message: "name already taken")
  end
end
