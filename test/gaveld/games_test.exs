defmodule Gaveld.GamesTest do
  use Gaveld.DataCase

  import Ecto.Query, warn: false
  alias Gaveld.Repo
  alias Gaveld.Games
  import Mock

  describe "games" do
    alias Gaveld.Games.Player

    @code_a "fancy llama"
    @code_b "lame llama"
    @name_a "Jorfe"
    @name_b "Billy"
    @input "game 1"

    def game_fixture(code) do
      with_mock Gaveld.Codes, [gen_code: fn -> code end] do
        Games.create_game()
      end
    end

    def player_fixture(game, name) do
      {:ok, %Player{uuid: uuid}} = Games.add_player(game, name)
      Games.verify_player(game, name, uuid)
    end


    test "get_game/1 returns the game with given id or nil if game doesn't exist" do
      game = game_fixture(@code_a)
      assert Games.get_game(@code_a) == game
      assert is_nil(Games.get_game(@code_b))
    end


    test "validate_game/1 with valid data returns the game otherwise nil" do
      game = game_fixture(@code_a)
      assert Games.validate_game(@code_a, game.uuid) == game
      assert is_nil(Games.validate_game(@code_a, "invalid uuid"))
      assert is_nil(Games.validate_game(@code_b, game.uuid))
    end

    test "reload_players/1 reloads players from game" do
      game = game_fixture(@code_a)
      game = Games.reload_players(game)
      assert game.players == []
      player = player_fixture(game, @name_a)
      game = Games.reload_players(game)
      assert game.players == [player]
      assert hd(game.players).input == nil
      Games.add_input(player, @input)
      game = Games.reload_players(game)
      assert hd(game.players).input == @input
    end

    def mock_gen() do
    end
    test "create_game/1 creates a game with a unique code" do
      with_mock Gaveld.Codes, [gen_code: fn -> Enum.random(["a","a","a","a","a","a","a","a","a","a","a","a","b","c"]) end] do
        game1 = Games.create_game()
        game2 = Games.create_game()
        game3 = Games.create_game()
        assert game1.code != game2.code
        assert game2.code != game3.code
        assert game1.code != game3.code

        #Returns the changeset if there are errors other than the code uniqueness
        with_mock Gaveld.Repo, [insert: fn _ -> {:error, %{errors: [code: "other messae"]}} end] do
          game = Games.create_game()
          assert game == %{errors: [code: "other messae"]}
        end
      end

    end

    test "add_player/2 adds players to a game" do
      game = game_fixture(@code_a)
      {:ok, %Player{uuid: uuid1}} = Games.add_player(game, @name_a)
      {:ok, %Player{uuid: uuid2}} = Games.add_player(game, @name_b)
      player1 = Games.verify_player(game, @name_a, uuid1)
      player2 = Games.verify_player(game, @name_b, uuid2)
      game = Games.reload_players(game)
      assert Enum.member?(game.players, player1)
      assert Enum.member?(game.players, player2)
    end

    test "start_game/2 updates the game's controller value" do
      game = game_fixture(@code_a)
      assert game.controller == nil
      {:ok, game} = Games.start_game(game, @code_a)
      assert game.controller == @code_a
    end

    test "voting_results/2, clear_inputs/1, and add_input/2 work correctly" do
      game = game_fixture(@code_a)
      player1 = player_fixture(game, @name_a)
      player2 = player_fixture(game, @name_b)
      player3 = player_fixture(game, "Hubert")
      game = Games.reload_players(game)
      assert Games.voting_results(game) == %{nil: 3}
      Games.add_input(player1, "Game 1")
      Games.add_input(player2, "Game 1")
      Games.add_input(player3, "Game 1")
      Games.add_input(player2, "Game 2")
      game = Games.reload_players(game)
      assert Games.voting_results(game) == %{"Game 1" => 2, "Game 2" => 1}
      Games.clear_inputs(game)
      game = Games.reload_players(game)
      assert Games.voting_results(game) == %{nil: 3}
    end

    test "update_status/2 updates the status of a game" do
      game = game_fixture(@code_a)
      assert game.status == "initialized"
      {:ok, game} = Games.update_status(game, "new status")
      assert game.status == "new status"
    end

    test "verify_player/3 returns the player with valid input otherwise nil" do
      game = game_fixture(@code_a)
      player = player_fixture(game, @name_a)
      assert Games.verify_player(game, @name_a, player.uuid) == player
      assert Games.verify_player(game, @name_b, player.uuid) == nil
      assert Games.verify_player(game, @name_a, "invalid uuid") == nil
    end

    test "compute_uid gives uids that are unique to the game + name combo" do
      game1 = game_fixture(@code_a)
      game2 = game_fixture(@code_b)
      assert Games.compute_uid(game1, @name_a) == Games.compute_uid(game1, @name_a)
      assert Games.compute_uid(game1, @name_a) != Games.compute_uid(game1, @name_b)
      assert Games.compute_uid(game1, @name_a) != Games.compute_uid(game2, @name_a)
    end

    test "delete_player/2 deletes the player from the game" do
      game = game_fixture(@code_a)
      player1 = player_fixture(game, @name_a)
      player2 = player_fixture(game, @name_b)
      game = Games.reload_players(game)
      assert length(game.players) == 2
      assert Enum.member?(game.players, player1)
      assert Enum.member?(game.players, player2)
      Games.delete_player(game, @name_a)
      game = Games.reload_players(game)
      assert length(game.players) == 1
      assert not Enum.member?(game.players, player1)
      assert Enum.member?(game.players, player2)
    end

    test "delete_game/1 deletes the game and all players in the game" do
      game = game_fixture(@code_a)
      player_fixture(game, @name_a)
      player_fixture(game, @name_b)
      query =
        from p in Player,
        where: p.game_id == ^game.id

      assert Games.get_game(game.code) == game
      assert length(Repo.all(query)) == 2
      Games.delete_game(game.code)
      assert Games.get_game(game.code) == nil
      assert length(Repo.all(query)) == 0
    end

    test "PubSub channel functions behave properly" do
      code_a = "code a"
      code_b = "code b"
      assert Games.display_receiving_channel(code_a) != Games.display_receiving_channel(code_b)
      assert Games.display_sending_channel(code_a) != Games.display_sending_channel(code_b)
      assert Games.display_receiving_channel(code_a) != Games.display_sending_channel(code_a)
      assert Games.player_receiving_channel(code_a, "name1") != Games.player_receiving_channel(code_a, "name2")
      assert Games.player_receiving_channel(code_a, "name1") != Games.player_receiving_channel(code_b, "name1")
      assert Games.display_receiving_channel(code_a) != Games.player_receiving_channel(code_a, "name1")
      assert Games.display_sending_channel(code_a) != Games.player_receiving_channel(code_a, "name1")
    end
  end



end
