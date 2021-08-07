defmodule GaveldWeb.PageLiveTest do
  use GaveldWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Gaveld.Games
  import Mock

  @valid_code "fancy llama"

  def game_fixture() do
    with_mock Gaveld.Codes, [gen_code: fn -> @valid_code end] do
      Games.create_game()
    end
  end

  test "renders page", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    assert render(view) =~ "Gavel&#39;d"
  end

  test "entering valid or invalid code redirects to game page", %{conn: conn} do
    game_fixture()
    {:ok, view, _html} = live(conn, "/")
    render_submit(view, "join_game", %{code: @valid_code})
    assert_redirect view, Routes.game_path(conn, :index, code: @valid_code)
    {:ok, view, _html} = live(conn, "/")
    render_submit(view, "join_game", %{code: "invalid code"})
    assert_redirect view, Routes.game_path(conn, :index, code: "invalid code")
  end

  test "clicking Create Game button creates a game and redirects to the display page", %{conn: conn} do
    with_mock Gaveld.Codes, [gen_code: fn -> @valid_code end] do
      {:ok, view, _html} = live(conn, "/")
      view |> element("button", "Create Game") |> render_click()
      game = Games.get_game(@valid_code)
      assert_redirect view, Routes.display_path(conn, :index, code: @valid_code, uuid: game.uuid)
    end
  end
end
