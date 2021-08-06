
defmodule GaveldWeb.ControllerLiveTest do
  use GaveldWeb.ConnCase

  import Phoenix.LiveViewTest

  import Mock
  alias Gaveld.Games
  alias Gaveld.Games.Player

  @games_list ["Game 1", "Game 2", "Game 3"]
  @game_code "fancy llama"
  @controller "Jorfe"
  @player1 "Jorfe1"
  @player2 "Jorfe2"

  def create_player(game, name) do
    {:ok, %Player{uuid: uuid}} = Games.add_player(game, name)
    Games.verify_player(game, name, uuid)
  end

  def create_game_with_controller(_) do
    with_mock Gaveld.Codes, [gen_code: fn -> @game_code end] do
      {:ok, game} = Games.create_game() |> Games.start_game(@controller)
      controller = create_player(game, @controller)
      player1 = create_player(game, @player1)
      create_player(game, @player2)
      {:ok, game: game, controller: controller, player1: player1}
    end
  end

  describe "controller page" do
    setup :create_game_with_controller

    test "renders controller view if code is valid", %{conn: conn, game: game, controller: controller} do
      {:ok, view, _html} = live(conn, Routes.controller_path(conn, :index, code: game.code, name: controller.name, uuid: controller.uuid))
      assert render(view) =~ "You are the controller"
    end

    test "redirects to homepage if url params are invalid or missing", %{conn: conn, game: game, controller: controller, player1: player1} do
      destination = Routes.homepage_path(conn, :index)

      assert {:error, {:live_redirect, %{to: ^destination}}} = live(conn, Routes.controller_path(conn, :index, code: "invalid code", name: controller.name, uuid: controller.uuid))
      assert {:error, {:live_redirect, %{to: ^destination}}} = live(conn, Routes.controller_path(conn, :index, code: game.code, name: player1.name, uuid: player1.uuid))
      assert {:error, {:live_redirect, %{to: ^destination}}} = live(conn, Routes.controller_path(conn, :index, code: game.code, name: controller.name, uuid: "invalid uuid"))
      assert {:error, {:live_redirect, %{to: ^destination}}} = live(conn, Routes.controller_path(conn, :index))
    end

    test "clicking stop voting button sends out a stop_vote signal", %{conn: conn, game: game, controller: controller} do
      with_mock(Phoenix.PubSub, [broadcast: fn (_,_,_) -> :ok end, subscribe: fn(_,_) -> :ok end]) do
        Games.update_status(game, "voting")
        {:ok, view, _html} = live(conn, Routes.controller_path(conn, :index, code: game.code, name: controller.name, uuid: controller.uuid))
        view |> element("button", "Stop Vote") |> render_click()
        assert_called(Phoenix.PubSub.broadcast(Gaveld.PubSub, Games.display_receiving_channel(game.code), :stop_vote))
      end
    end

    test "clicking a game button sends out that game's signal", %{conn: conn, game: game, controller: controller} do
      with_mock(Phoenix.PubSub, [broadcast: fn (_,_,_) -> :ok end, subscribe: fn(_,_) -> :ok end]) do
        for game_name <- @games_list do
          Games.update_status(game, "voting_results")
          {:ok, view, _html} = live(conn, Routes.controller_path(conn, :index, code: game.code, name: controller.name, uuid: controller.uuid))
          view |> element("button", game_name) |> render_click()
          assert_called(Phoenix.PubSub.broadcast(Gaveld.PubSub, Games.display_receiving_channel(game.code), game_name))
        end
      end
    end

    test "clicking stop game button sends out a start_vote signal", %{conn: conn, game: game, controller: controller} do
      with_mock(Phoenix.PubSub, [broadcast: fn (_,_,_) -> :ok end, subscribe: fn(_,_) -> :ok end]) do
        for game_name <- @games_list do
          Games.update_status(game, game_name)
          {:ok, view, _html} = live(conn, Routes.controller_path(conn, :index, code: game.code, name: controller.name, uuid: controller.uuid))
          view |> element("button", "Stop Game") |> render_click()
        end
      end
    end

    test "sending voting message starts vote properly", %{conn: conn, game: game, controller: controller} do
      {:ok, view, _html} = live(conn, Routes.controller_path(conn, :index, code: game.code, name: controller.name, uuid: controller.uuid))
      assert render(view) =~ "You are the controller"
      send(view.pid, {:voting, nil})
      assert view |> element("button", "Stop Vote") |> has_element?()
    end

    test "stop vote message stops voting", %{conn: conn, game: game, controller: controller} do
      for prev_game <- [nil | @games_list] do
        Games.update_status(game, "voting")
        {:ok, view, _html} = live(conn, Routes.controller_path(conn, :index, code: game.code, name: controller.name, uuid: controller.uuid))
        assert view |> element("button", "Stop Vote") |> has_element?()
        send(view.pid, :stop_vote)
        for game_name <- List.delete(@games_list, prev_game) do
          assert view |> element("button", game_name) |> has_element?()
        end
      end
    end

    test "game message starts game", %{conn: conn, game: game, controller: controller} do
      for game_name <- @games_list do
        {:ok, view, _html} = live(conn, Routes.controller_path(conn, :index, code: game.code, name: controller.name, uuid: controller.uuid))
        assert render(view) =~ "You are the controller"
        send(view.pid, game_name)
        assert view |> element("button", "Stop Game") |> has_element?()
      end
    end

  end

end
