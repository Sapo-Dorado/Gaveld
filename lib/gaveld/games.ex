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

  def validate_game(code, uuid) do
    case get_game(code) do
      %Game{uuid: ^uuid} = game -> game
      _ -> nil
    end
  end

  def reload_players(game) do
    Repo.preload(game, :players, force: true)
  end

  def create_game() do
    game_changeset = Game.changeset(%Game{}, %{code: Codes.gen_code(), uuid: Ecto.UUID.generate(), status: "initialized"})
    case Repo.insert(game_changeset) do
      {:ok, game} -> game
      {:error, changeset} ->
        case changeset.errors do
          [code: {"has already been taken", [constraint: :unique, constraint_name: "games_code_index"]}] ->
            create_game()
          _ -> changeset
        end
    end
  end

  def add_player(%Game{} = game, name) do
    %Player{}
    |> Player.changeset(%{name: name, uid: compute_uid(game, name), uuid: Ecto.UUID.generate(), game_id: game.id})
    |> Repo.insert()
  end

  def start_game(%Game{} = game, name) do
    game
    |> Game.changeset(%{controller: name})
    |> Repo.update()
  end

  def clear_inputs(game) do
    game_id = game.id
    query =
      from p in Player,
      where: p.game_id == ^game_id
    Repo.update_all(query, set: [input: nil])
  end

  def add_input(player, input) do
    player
    |> Player.changeset(%{input: input})
    |> Repo.update()
  end

  def voting_results(%Game{} = game) do
    game.players
    |> Enum.reduce(%{}, fn p, acc -> Map.update(acc, p.input, 1, &(&1 + 1)) end)
  end

  def update_status(%Game{} = game, status) do
    attrs = %{status: status}
    attrs = if status == "voting", do: Map.put(attrs, :prev_game, game.status), else: attrs
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end


  def verify_player(game, name, uuid) do
    uid = compute_uid(game, name)
    query =
      from p in Player,
      where: p.uid == ^uid and p.uuid == ^uuid

    Repo.one(query)
  end

  def compute_uid(%Game{} = game, name) do
    name <> "/" <> to_string(game.id)
  end

  def delete_player(game, name) do
    uid = compute_uid(game, name)
    query =
      from p in Player,
      where: p.uid == ^uid
    Repo.delete_all(query)
  end

  def delete_game(code) do
    query =
      from g in Game,
      where: g.code == ^code
    Repo.delete_all(query)
  end
  def display_receiving_channel(code) do
    "display_#{String.replace(code, " ", "_")}"
  end

  def player_receiving_channel(code, name) do
    "player_#{String.replace(code, " ", "_")}_#{name}"
  end

  def display_sending_channel(code) do
    display_receiving_channel(code) <> "_player"
  end
end
