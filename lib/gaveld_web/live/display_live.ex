defmodule GaveldWeb.DisplayLive do
  use GaveldWeb, :live_view

  alias Phoenix.PubSub
  alias Gaveld.Games

  @games_list ["Game 1", "Game 2", "Game 3"]

  @impl true
  def mount(%{"code" => code, "uuid" => uuid}, _session, socket) do
    case Games.validate_game(code, uuid) do
      nil -> {:ok, push_redirect(socket, to: Routes.homepage_path(socket, :index))}
      game ->
        if connected?(socket), do: PubSub.subscribe(Gaveld.PubSub, Games.display_receiving_channel(code))
        game = Games.reload_players(game)
        vote_count = Enum.reduce(game.players, 0, fn p, acc -> if is_nil(p.input), do: acc, else: acc + 1 end)
        game = if game.status == "voting" and vote_count == length(game.players) - 1, do: %{game | status: "voting_results"}, else: game
        {:ok, assign(socket, players: Enum.map(game.players, fn p -> p.name end), game: game, controller: nil, view: game.status, vote_count: vote_count)}
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, push_redirect(socket, to: Routes.homepage_path(socket, :index))}
  end

  @impl true
  def handle_event("delete", %{"name" => name}, socket) do
    Games.delete_player(socket.assigns.game, name)
    PubSub.broadcast(Gaveld.PubSub, Games.player_receiving_channel(socket.assigns.game.code, name), :delete)
    socket = if name == socket.assigns.controller, do: assign(socket, controller: nil), else: socket
    {:noreply, assign(socket, players: List.delete(socket.assigns.players, name))}
  end

  @impl true
  def handle_event("select_controller", %{"name" => name}, socket) do
    {:noreply, assign(socket, controller: name)}
  end

  @impl true
  def handle_event("start_game", _, socket) do
    case Games.start_game(socket.assigns.game, socket.assigns.controller) do
      {:ok, game} ->
        PubSub.broadcast(Gaveld.PubSub, Games.player_receiving_channel(socket.assigns.game.code, socket.assigns.controller), :become_controller)
        start_voting(socket, game)
      {:error, _} ->
        kill_game(socket.assigns.game.code)
        {:noreply, push_redirect(socket, to: Routes.homepage_path(socket, :index))}
    end
  end

  @impl true
  def handle_info({:new_player, name}, socket) do
    {:noreply, assign(socket, players: socket.assigns.players ++ [name])}
  end

  @impl true
  def handle_info(:new_vote, socket) do
    if socket.assigns.vote_count == length(socket.assigns.players) - 2 do
      end_vote(socket)
    else
      {:noreply, assign(socket, vote_count: socket.assigns.vote_count + 1)}
    end
  end

  @impl true
  def handle_info(:stop_vote, socket) do
    end_vote(socket)
  end

  @impl true
  def handle_info(:start_vote, socket) do
    start_voting(socket, socket.assigns.game)
  end

  #This needs to be the last defined handle_info for this page
  @impl true
  def handle_info(game_name, socket) do
    case Games.update_status(socket.assigns.game, game_name) do
      {:ok, game} ->
        PubSub.broadcast(Gaveld.PubSub, Games.display_sending_channel(socket.assigns.game.code), game_name)
        {:noreply, assign(socket, game: game, view: game_name)}
      {:error, _} ->
        kill_game(socket.assigns.game.code)
        {:noreply, push_redirect(socket, to: Routes.homepage_path(socket, :index))}
    end
  end

  @impl true
  def render(assigns) do
    ~L'''
    <%= case @view do %>
    <% "initialized" -> %>
      <%= join_screen(assigns) %>
    <% "voting" -> %>
      <%= voting_screen(assigns) %>
    <% "voting_results" -> %>
      <%= voting_results_screen(assigns) %>
    <% game_name ->%>
      <%= game_name %>
    <%end%>
    '''
  end

  def start_voting(socket, game) do
    case Games.update_status(game, "voting") do
      {:ok, game} ->
        Games.clear_inputs(game)
        PubSub.broadcast(Gaveld.PubSub, Games.display_sending_channel(game.code), {:voting, game.prev_game})
        {:noreply, assign(socket, game: game, view: "voting", vote_count: 0)}
      {:error, _} ->
        kill_game(socket.assigns.game.code)
        {:noreply, push_redirect(socket, to: Routes.homepage_path(socket, :index))}
    end
  end

  def end_vote(socket) do
    Games.update_status(socket.assigns.game, "voting_results")
    PubSub.broadcast(Gaveld.PubSub, Games.display_sending_channel(socket.assigns.game.code), :stop_vote)
    {:noreply, assign(socket, game: Games.reload_players(socket.assigns.game), view: "voting_results")}
  end

  def join_screen(assigns) do
    ~L'''
    <section class="section is-medium has-text-centered">
      <div class="container">
        <h1 class="title">The code is: <%= @game.code %></h1>
        <p class="subtitle">Enter the code to join!</p>
      </div>
    </section>
    <section class="section has-text-centered">
      <%= display_title(assigns) %>
      <%= display_players(assigns) %>
    </section>
    '''
  end

  def display_title(assigns) do
    ~L'''
    <%= if is_nil(@controller) do %>
      <h1 class="title">See your name on the screen:</h1>
    <%else%>
      <div class="columns">
        <div class="column"></div>
        <div class="column">
          <button class="button is-success is-large is-fullwidth" phx-click="start_game">Start Game</button>
        </div>
        <div class="column"></div>
      </div>
    <%end%>
    '''
  end
  def display_players(assigns) do
    ~L'''
    <%= for player <- @players do %>
      <div class="columns">
        <div class="column has-text-right">
          <%= if player == @controller do %>
            <div class="promote">
              <%= crown_svg(assigns) %>
            </div>
          <%else%>
            <div class="promote unselected" id="<%=player %>" phx-click="select_controller" phx-value-name="<%= player %>">
              <%= crown_svg(assigns) %>
            </div>
          <%end%>
        </div>
        <div class="column has-text-left">
          <h1 class="title player-button" phx-click="delete" phx-value-name="<%= player %>"><%= player %></h1>
        </div>
        <div class="column"></div>
    </div>
    <%end%>
    '''
  end

  def voting_screen(assigns) do
    ~L'''
    <h1 class="title">Time to Vote!</h1>
    <h2 class="subtitle"><%= @vote_count %>/<%= length(@players) - 1 %> votes cast</h2>
    '''
  end

  def voting_results_screen(assigns) do
    ~L'''
    <h1 class="title">Results:</h1>
    <%= display_voting_results(assigns) %>
    '''
  end

  def display_voting_results(assigns) do
    results = Games.voting_results(assigns.game)
    games_list = @games_list
    ~L'''
    <%= for topic <- games_list do%>
      <%= if not is_nil(results[topic]) do %>
        <h1><%= topic %> - <%= results[topic] %></h1>
      <%end%>
    <%end%>
    '''
  end

  def crown_svg(assigns)do
    ~L'''
    <svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 640 512"><!-- Font Awesome Free 5.15.3 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free (Icons: CC BY 4.0, Fonts: SIL OFL 1.1, Code: MIT License) --><path d="M528 448H112c-8.8 0-16 7.2-16 16v32c0 8.8 7.2 16 16 16h416c8.8 0 16-7.2 16-16v-32c0-8.8-7.2-16-16-16zm64-320c-26.5 0-48 21.5-48 48 0 7.1 1.6 13.7 4.4 19.8L476 239.2c-15.4 9.2-35.3 4-44.2-11.6L350.3 85C361 76.2 368 63 368 48c0-26.5-21.5-48-48-48s-48 21.5-48 48c0 15 7 28.2 17.7 37l-81.5 142.6c-8.9 15.6-28.9 20.8-44.2 11.6l-72.3-43.4c2.7-6 4.4-12.7 4.4-19.8 0-26.5-21.5-48-48-48S0 149.5 0 176s21.5 48 48 48c2.6 0 5.2-.4 7.7-.8L128 416h384l72.3-192.8c2.5.4 5.1.8 7.7.8 26.5 0 48-21.5 48-48s-21.5-48-48-48z"/></svg>
    '''
  end

  def kill_game(code) do
    Games.delete_game(code)
    PubSub.broadcast(Gaveld.PubSub, Games.display_sending_channel(code), :kill_game)
  end
end
