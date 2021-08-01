defmodule Gaveld.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  alias Gaveld.Games.Player

  schema "games" do
    field :code, :string
    field :uuid, :string
    field :status, :string
    field :controller, :string
    has_many :players, Player

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:code, :uuid, :status, :controller])
    |> validate_required([:code, :uuid, :status])
    |> unique_constraint(:code)
  end
end
