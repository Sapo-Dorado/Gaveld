defmodule Gaveld.Games do
  import Ecto.Query, warn: false
  alias Gaveld.Repo

  alias Gaveld.Games.Game
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

  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end
end
