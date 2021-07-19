defmodule Gaveld.Games do
  import Ecto.Query, warn: false
  alias Gaveld.Repo

  alias Gaveld.Games.Game
  alias Gaveld.Games.Player
  alias Gaveld.Codes

  def get_game(code) do
    query =
      from g in Game,
      where: g.code == ^code
    Repo.one(query)
  end

  def create_game() do
    game_changeset = Game.changeset(%Game{}, %{code: Codes.gen_code()})
    case Repo.insert(game_changeset) do
      {:ok, game} -> game
      {:error, changeset} ->
        case changeset.errors do
          [code: _] ->
            create_game()
          _ -> changeset
        end
    end
  end

  def add_player(%Game{} = game, name) do
    %Player{}
    |> Player.changeset(%{name: name, uid: compute_uid(game, name), game_id: game.id})
    |> Repo.insert()
  end

  def compute_uid(%Game{} = game, name) do
    name <> "/" <> to_string(game.id)
  end

  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end

  def display_receiving_channel(code) do
    "display_#{String.replace(code, " ", "_")}"
  end

  def display_sending_channel(code) do
    display_receiving_channel(code) <> "_player"
  end
end
