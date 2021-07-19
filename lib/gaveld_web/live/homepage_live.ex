defmodule GaveldWeb.HomepageLive do
  use GaveldWeb, :live_view

  alias Gaveld.Games

  @impl true
  def mount(%{"code" => code}, _session, socket) do
    {:ok, assign(socket, view: "game", code: code)}
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, view: "home")}
  end

  @impl true
  def handle_event("join_game", %{"code" => code}, socket) do
    {:noreply, push_redirect(socket, to: Routes.homepage_path(socket, :index, code: code))}
  end

  @impl true
  def handle_event("create_game", _, socket) do
    game = Games.create_game()
    {:noreply, push_redirect(socket, to: Routes.display_path(socket, :display, code: game.code))}
  end

  @impl true
  def render(assigns) do
    ~L'''
    <%= cond do%>
      <% @view == "home" ->%>
        <%= live_component GaveldWeb.HomeComponent, id: "home"%>
      <% @view == "game" ->%>
        <%= live_component GaveldWeb.GameComponent, id: "game", code: @code%>
    <%end%>
    '''
  end
end
