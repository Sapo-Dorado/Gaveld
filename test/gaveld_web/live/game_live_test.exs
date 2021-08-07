
defmodule GaveldWeb.GameLiveTest do
  use GaveldWeb.ConnCase

  import Phoenix.LiveViewTest

  import Mock
  alias Gaveld.Games
  alias Gaveld.Games.Player
  alias Gaveld.Games.Game

  @games_list ["Game 1", "Game 2", "Game 3"]
  @game1 "Game 1"
  @game2 "Game 2"
  @game_code "fancy llama"
  @controller "Jorfe"
  @player1 "Jorfe1"

  def create_player(game, name) do
    {:ok, %Player{uuid: uuid}} = Games.add_player(game, name)
    Games.verify_player(game, name, uuid)
  end

  def create_game(_) do
    with_mock Gaveld.Codes, [gen_code: fn -> @game_code end] do
      {:ok, game} = Games.create_game() |> Games.start_game(@controller)
      controller = create_player(game, @controller)
      player1 = create_player(game, @player1)
      {:ok, game: game, controller: controller, player1: player1}
    end
  end

  describe "game page" do
    setup :create_game

    test "renders game page correctly or redirects when code name and uuid are passed in", %{conn: conn, game: %Game{code: code}, controller: controller, player1: player} do
      {:ok, view, _html} = live(conn, Routes.game_path(conn, :index, code: code, name: player.name, uuid: player.uuid))
      assert render(view) =~ "Welcome " <> player.name

      {:ok, view, _html} = live(conn, Routes.game_path(conn, :index, code: "invalid code", name: controller.name, uuid: controller.uuid))
      assert render(view) =~ "Invalid code"

      destination = Routes.controller_path(conn, :index, code: code, name: controller.name, uuid: controller.uuid)
      assert {:error, {:live_redirect, %{to: ^destination}}} = live(conn, Routes.game_path(conn, :index, code: code, name: controller.name, uuid: controller.uuid))

      destination = Routes.game_path(conn, :index, code: code)
      assert {:error, {:live_redirect, %{to: ^destination}}} = live(conn, Routes.game_path(conn, :index, code: code, name: "invalid name", uuid: controller.uuid))
    end

    test "renders game page correctly when just code is passed in", %{conn: conn, game: %Game{code: code}} do
      {:ok, view, _html} = live(conn, Routes.game_path(conn, :index, code: code))
      assert render(view) =~ "Joined Game " <> code

      {:ok, view, _html} = live(conn, Routes.game_path(conn, :index, code: "invalid code"))
      assert render(view) =~ "Invalid code"
    end

    test "redirects to home page when no params are passed in", %{conn: conn} do
      destination = Routes.homepage_path(conn, :index)
      assert {:error, {:live_redirect, %{to: ^destination}}} = live(conn, Routes.game_path(conn, :index))
    end

    test "entering valid name joins game and invalid name prints an error", %{conn: conn, game: %Game{code: code}} do
      with_mock(Phoenix.PubSub, [broadcast: fn (_,_,_) -> :ok end, subscribe: fn(_,_) -> :ok end]) do
        {:ok, view, _html} = live(conn, Routes.game_path(conn, :index, code: code))
        {:error, {:live_redirect, %{to: destination}}} = render_submit(view, "enter_name", %{name: "New Player"})
        assert destination =~ Routes.game_path(conn, :index, code: code, name: "New Player")
        assert_called(Phoenix.PubSub.broadcast(Gaveld.PubSub, Games.display_receiving_channel(code), {:new_player, "New Player"}))
      end

      {:ok, view, _html} = live(conn, Routes.game_path(conn, :index, code: code))
      assert render_submit(view, "enter_name", %{name: nil}) =~ "can&#39;t be blank"

      {:ok, view, _html} = live(conn, Routes.game_path(conn, :index, code: code))
      assert render_submit(view, "enter_name", %{name: "aa"}) =~ "must be at between 3 and 20 characters"

      {:ok, view, _html} = live(conn, Routes.game_path(conn, :index, code: code))
      assert render_submit(view, "enter_name", %{name: @player1}) =~ "name already taken"
    end

    test "submitting votes updates the player's vote", %{conn: conn, game: game, player1: player} do
      {:ok, game} = Games.update_status(game, "voting")
      {:ok, view, _html} = live(conn, Routes.game_path(conn, :index, code: game.code, name: player.name, uuid: player.uuid))
      with_mock(Phoenix.PubSub, [:passthrough], [broadcast: fn (_,_,_) -> :ok end]) do
        input = @game1
        assert render_submit(view, "submit", %{input: input}) =~ "Your choice: " <> input
        assert %Player{input: ^input} = Games.verify_player(game, player.name, player.uuid)
        assert_called(Phoenix.PubSub.broadcast(Gaveld.PubSub, Games.display_receiving_channel(game.code), :new_vote))

        input = @game2
        assert render_submit(view, "submit", %{input: input}) =~ "Your choice: " <> input
        assert %Player{input: ^input} = Games.verify_player(game, player.name, player.uuid)
        assert_called_exactly(Phoenix.PubSub.broadcast(Gaveld.PubSub, Games.display_receiving_channel(game.code), :new_vote), 1)
      end

      with_mock(Games, [add_input: fn (_,_) -> {:error, "error"} end]) do
        render_submit(view, "submit", %{input: "val"})
        assert_redirect view, Routes.homepage_path(conn, :index)
      end
    end

    test "delete message redirects to the original game page", %{conn: conn, game: game, player1: player} do
      {:ok, view, _html} = live(conn, Routes.game_path(conn, :index, code: game.code, name: player.name, uuid: player.uuid))
      send(view.pid, :delete)
      assert_redirect view, Routes.game_path(conn, :index, code: game.code)
    end

    test "kill message redirects to the home page", %{conn: conn, game: game, player1: player} do
      {:ok, view, _html} = live(conn, Routes.game_path(conn, :index, code: game.code, name: player.name, uuid: player.uuid))
      send(view.pid, :kill_game)
      assert_redirect view, Routes.homepage_path(conn, :index)
    end

    test "become controller message redirects to the controller page", %{conn: conn, game: game, player1: player, controller: controller} do
      {:ok, view, _html} = live(conn, Routes.game_path(conn, :index, code: game.code, name: player.name, uuid: player.uuid))
      send(view.pid, :become_controller)
      assert_redirect view, Routes.controller_path(conn, :index, code: game.code, name: player.name, uuid: player.uuid)

      #redirecting from status
      destination = Routes.controller_path(conn, :index, code: game.code, name: controller.name, uuid: controller.uuid)
      {:error, {:live_redirect, %{to: ^destination}}} = live(conn, Routes.game_path(conn, :index, code: game.code, name: controller.name, uuid: controller.uuid))
    end

    test "voting displays behave properly", %{conn: conn, game: game, player1: player} do
      for prev_game <- ["initialized" | @games_list] do
        #setting prev_game from signal
        {:ok, game} = Games.update_status(game, prev_game)
        {:ok, view, _html} = live(conn, Routes.game_path(conn, :index, code: game.code, name: player.name, uuid: player.uuid))
        send(view.pid, {:voting, prev_game})
        for game_name <- List.delete(@games_list, prev_game) do
          assert render(view) =~ game_name
        end
        assert not (render(view) =~ prev_game)

        #setting prev_game from status
        {:ok, game} = Games.update_status(game, prev_game)
        {:ok, game} = Games.update_status(game, "voting")
        {:ok, view, _html} = live(conn, Routes.game_path(conn, :index, code: game.code, name: player.name, uuid: player.uuid))
        for game_name <- List.delete(@games_list, prev_game) do
          assert render(view) =~ game_name
        end
        assert not (render(view) =~ prev_game)
      end
    end

    test "stop vote signal stops the vote", %{conn: conn, game: game, player1: player} do
      #stopping vote from signal
      {:ok, game} = Games.update_status(game, "voting")
      {:ok, view, _html} = live(conn, Routes.game_path(conn, :index, code: game.code, name: player.name, uuid: player.uuid))
      send(view.pid, :stop_vote)
      assert render(view) =~ "Voting Results"

      #stopping voite from status
      {:ok, game} = Games.update_status(game, "voting_results")
      {:ok, view, _html} = live(conn, Routes.game_path(conn, :index, code: game.code, name: player.name, uuid: player.uuid))
      assert render(view) =~ "Voting Results"
    end

    test "game name signals switch to that game", %{conn: conn, game: game, player1: player} do
      for game_name <- @games_list do
        #switching game from signal
        game = Games.get_game(game.code)
        {:ok, game} = Games.update_status(game, "initialized")
        {:ok, view, _html} = live(conn, Routes.game_path(conn, :index, code: game.code, name: player.name, uuid: player.uuid))
        assert render(view) =~ "Welcome " <> player.name
        send(view.pid, game_name)
        assert render(view) =~ game_name

        #switching game from status
        {:ok, game} = Games.update_status(game, game_name)
        {:ok, view, _html} = live(conn, Routes.game_path(conn, :index, code: game.code, name: player.name, uuid: player.uuid))
        assert render(view) =~ game_name
       end
    end

  end
end
