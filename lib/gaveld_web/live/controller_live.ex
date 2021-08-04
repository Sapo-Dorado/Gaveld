
defmodule GaveldWeb.ControllerLive do
  use GaveldWeb, :live_view

  alias Phoenix.PubSub
  alias Gaveld.Games

  @games_list ["Game 1", "Game 2", "Game 3"]

  @impl true
  def mount(%{"code" => code, "name" => name, "uuid" => uuid}, _session, socket) do
    case Games.get_game(code) do
      nil -> {:ok, push_redirect(socket, to: Routes.homepage_path(socket, :index))}
      game ->
        case Games.verify_player(game, name, uuid) do
          nil -> {:ok, push_redirect(socket, to: Routes.game_path(socket, :index, code: code))}
          player ->
            if connected?(socket), do: PubSub.subscribe(Gaveld.PubSub, Games.display_sending_channel(code))
            {:ok, assign(socket, game: game, player: player, view: game.status)}
        end
    end
  end

  @impl true
  def handle_event("stop_vote", _, socket) do
    PubSub.broadcast(Gaveld.PubSub, Games.display_receiving_channel(socket.assigns.game.code), :stop_vote)
    {:noreply, socket}
  end

  @impl true
  def handle_event("start_vote", _, socket) do
    PubSub.broadcast(Gaveld.PubSub, Games.display_receiving_channel(socket.assigns.game.code), :start_vote)
    {:noreply, socket}
  end

  #This needs to be the last handle_event defined for this page
  @impl true
  def handle_event(game_name , _, socket) do
    PubSub.broadcast(Gaveld.PubSub, Games.display_receiving_channel(socket.assigns.game.code), game_name)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:voting, socket) do
    case Games.get_game(socket.assigns.game.code) do
      nil ->
        {:noreply, push_redirect(socket, to: Routes.homepage_path(socket, :index))}
      game ->
        {:noreply, assign(socket, game: game, view: "voting")}
    end
  end

  @impl true
  def handle_info(:stop_vote, socket) do
    {:noreply, assign(socket, view: "voting_results")}
  end

  #This needs to be the last defined handle_info on this page
  @impl true
  def handle_info(game_name , socket) do
    {:noreply, assign(socket, view: game_name)}
  end

  @impl true
  def render(assigns) do
    ~L'''
    <%= case @view do %>
      <% "initialized" -> %>
        <%= render_start(assigns) %>
      <% "voting" -> %>
        <%= render_voting(assigns) %>
      <% "voting_results" -> %>
        <%= render_voting_results(assigns) %>
      <% game_name ->%>
        <%= game_name %><br><button class="button is-success" phx-click="start_vote">Stop Game</button>
    <%end%>
    '''
  end

  def render_start(assigns) do
    ~L'''
    <h1 class="title">You are the controller</h1>
    '''
  end

  def render_voting(assigns) do
    ~L'''
    <button class="button is-success" phx-click="stop_vote">Stop Vote</button>
    '''
  end

  def render_voting_results(assigns) do
    games_list = List.delete(@games_list, assigns.game.prev_game)
    ~L'''
    <%= for game <- games_list do %>
      <button class="button is-success" phx-click="<%= game %>"><%= game %></button><br>
    <%end%>
    '''
  end

end
