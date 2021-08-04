defmodule Gaveld.Games.Player do
  use Ecto.Schema
  import Ecto.Changeset

  alias Gaveld.Games.Game

  schema "players" do
    field :name, :string
    field :points, :integer
    field :uid, :string
    field :uuid, :string
    field :input, :string
    belongs_to :game, Game

    timestamps()
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:name, :points, :uid, :uuid, :input, :game_id, ])
    |> validate_required([:name, :uid, :uuid, :game_id])
    |> validate_length(:name, min: 3, max: 20, message: "must be at between 3 and 20 characters")
    |> unique_constraint(:uid, message: "name already taken")
  end
end
