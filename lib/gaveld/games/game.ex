defmodule Gaveld.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  alias Gaveld.Games.Player

  schema "games" do
    field :code, :string
    has_many :players, Player

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:code])
    |> validate_required([:code])
    |> unique_constraint(:code)
  end
end
