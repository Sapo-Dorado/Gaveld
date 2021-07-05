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
    |> validate_length(:name, min: 3)
    |> unique_constraint(:uid)
  end
end
