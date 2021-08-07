
defmodule GaveldWeb.DisplayLiveTest do
  use GaveldWeb.ConnCase

  import Phoenix.LiveViewTest

  import Mock
  alias Phoenix.PubSub
  alias Gaveld.Games
  alias Gaveld.Games.Player

  @games_list ["Game 1", "Game 2", "Game 3"]
  @game1 "Game 1"
  @game2 "Game 2"
  @game3 "Game 3"
  @game_code "fancy llama"
  @player "Jorfe"

  def create_player(game, name) do
    {:ok, %Player{uuid: uuid}} = Games.add_player(game, name)
    Games.verify_player(game, name, uuid)
  end

  def create_game_with_controller(_) do
    with_mock Gaveld.Codes, [gen_code: fn -> @game_code end] do
      game = Games.create_game()
      player = create_player(game, @player)
      {:ok, game: game, player: player}
    end
  end

  describe "display page" do
    setup :create_game_with_controller

    test "renders display view if game code and uuid are valid", %{conn: conn, game: game} do
      {:ok, view, _html} = live(conn, Routes.display_path(conn, :index, code: game.code, uuid: game.uuid))
      assert render(view) =~ "The code is: " <> game.code
    end

    test "redirects to homepage if game doesn't exist or no game was input", %{conn: conn} do
      destination = Routes.homepage_path(conn, :index)
      assert {:error, {:live_redirect, %{to: ^destination}}} = live(conn, Routes.display_path(conn, :index, code: "invalid code", uuid: "invalid uuid"))
      assert {:error, {:live_redirect, %{to: ^destination}}} = live(conn, Routes.display_path(conn, :index))
    end

    test "players joining game and game start behaves properly", %{conn: conn, game: game} do
      {:ok, view, _html} = live(conn, Routes.display_path(conn, :index, code: game.code, uuid: game.uuid))
      assert render(view) =~ @player

      #adding players
      Games.add_player(game, "Name1")
      Games.add_player(game, "Name2")
      send(view.pid, {:new_player, "Name1"})
      send(view.pid, {:new_player, "Name2"})
      assert render(view) =~ @player
      assert render(view) =~ "Name1"
      assert render(view) =~ "Name2"

      #reloading page is fine
      {:ok, view, _html} = live(conn, Routes.display_path(conn, :index, code: game.code, uuid: game.uuid))
      assert render(view) =~ @player
      assert render(view) =~ "Name1"
      assert render(view) =~ "Name2"

      #deleting players
      assert not(view |> element("h1", @player) |> render_click() =~ @player)
      assert render(view) =~ "Name1"
      assert render(view) =~ "Name2"

      #setting controller
      assert view |> element("#Name1") |> render_click() =~ "Start Game"
      assert render(view) =~ "Name1"
      assert render(view) =~ "Name2"

      #deleting controller
      assert not(view |> element("h1", "Name1") |> render_click() =~ "Name1")
      assert not(render(view) =~ "Start Game")
      assert render(view) =~ "Name2"

      #add another player
      Games.add_player(game, "Name3")
      send(view.pid, {:new_player, "Name3"})
      assert render(view) =~ "Name2"
      assert render(view) =~ "Name3"

      #starting game
      assert view |> element("#Name2") |> render_click() =~ "Start Game"
      with_mock(PubSub, [:passthrough], [broadcast: fn (_,_,_) -> :ok end]) do
        assert view |> element("button", "Start Game") |> render_click() =~ "Time to Vote!"
        assert_called(PubSub.broadcast(Gaveld.PubSub, Games.player_receiving_channel(game.code, "Name2"), :become_controller))
        assert_called(PubSub.broadcast(Gaveld.PubSub, Games.display_sending_channel(game.code), {:voting, "initialized"}))
      end
    end

    test "voting works properly", %{conn: conn, game: game, player: player1} do
      {:ok, controller} = Games.add_player(game, "Controller")
      {:ok, player2} = Games.add_player(game, "Name 1")
      {:ok, player3} = Games.add_player(game, "Name 2")
      {:ok, game} = Games.start_game(game, controller.name)

      #start vote from signal
      {:ok, view, _html} = live(conn, Routes.display_path(conn, :index, code: game.code, uuid: game.uuid))
      send(view.pid, :start_vote)
      assert render(view) =~ "Time to Vote!"
      assert render(view) =~ "0/3"

      #start vote from reload
      {:ok, view, _html} = live(conn, Routes.display_path(conn, :index, code: game.code, uuid: game.uuid))
      assert render(view) =~ "Time to Vote!"
      assert render(view) =~ "0/3"

      #vote from signal
      Games.add_input(player1, @game1)
      send(view.pid, :new_vote)
      assert render(view) =~ "1/3"

      #vote from reload
      {:ok, view, _html} = live(conn, Routes.display_path(conn, :index, code: game.code, uuid: game.uuid))
      assert render(view) =~ "1/3"

      #Full vote signal ends vote
      Games.add_input(player2, @game2)
      send(view.pid, :new_vote)
      assert render(view) =~ "2/3"

      Games.add_input(player3, @game2)
      send(view.pid, :new_vote)
      assert render(view) =~ @game1 <> " - 1"
      assert render(view) =~ @game2 <> " - 2"

      #finishing vote while display is disconnected reloads into results view
      Games.clear_inputs(game)
      Games.add_input(player1, @game1)
      Games.add_input(player2, @game2)
      Games.add_input(player3, @game3)
      {:ok, game} = Games.update_status(game, "voting")
      {:ok, view, _html} = live(conn, Routes.display_path(conn, :index, code: game.code, uuid: game.uuid))
      assert render(view) =~ @game1 <> " - 1"
      assert render(view) =~ @game2 <> " - 1"
      assert render(view) =~ @game3 <> " - 1"

      #sending stop vote signal also ends vote
      Games.clear_inputs(game)
      Games.add_input(player1, @game1)
      Games.add_input(player3, @game1)
      {:ok, game} = Games.update_status(game, "voting")
      {:ok, view, _html} = live(conn, Routes.display_path(conn, :index, code: game.code, uuid: game.uuid))
      assert render(view) =~ "2/3"
      send(view.pid, :stop_vote)
      assert render(view) =~ @game1 <> " - 2"
    end

    test "game signals display game pages", %{conn: conn, game: game} do
      for game_name <- @games_list do
        {:ok, view, _html} = live(conn, Routes.display_path(conn, :index, code: game.code, uuid: game.uuid))
        send(view.pid, game_name)
        assert render(view) =~ game_name
      end
    end

    test "error in updating status kills game :start_vote version", %{conn: conn, game: game} do
      with_mock Games, [:passthrough], [update_status: fn(_,_) -> {:error, "error"} end] do
        {:ok, view, _html} = live(conn, Routes.display_path(conn, :index, code: game.code, uuid: game.uuid))
        assert Games.get_game(game.code) == game
        send(view.pid, :start_vote)
        assert_redirect view, Routes.homepage_path(conn, :index)
        assert Games.get_game(game.code) == nil
      end
    end

    test "error in updating status kills game game_name version", %{conn: conn, game: game} do
      with_mock Games, [:passthrough], [update_status: fn(_,_) -> {:error, "error"} end] do
        {:ok, view, _html} = live(conn, Routes.display_path(conn, :index, code: game.code, uuid: game.uuid))
        assert Games.get_game(game.code) == game
        send(view.pid, @game1)
        assert_redirect view, Routes.homepage_path(conn, :index)
        assert Games.get_game(game.code) == nil
      end
    end

    test "error in starting game kills game", %{conn: conn, game: game, player: player} do
      with_mock Games, [:passthrough], [start_game: fn(_,_) -> {:error, "error"} end] do
        {:ok, view, _html} = live(conn, Routes.display_path(conn, :index, code: game.code, uuid: game.uuid))
        assert view |> element("#" <> player.name) |> render_click() =~ "Start Game"
        assert Games.get_game(game.code) == game
        view |> element("button", "Start Game") |> render_click()
        assert_redirect view, Routes.homepage_path(conn, :index)
        assert Games.get_game(game.code) == nil
      end
    end
  end

end
