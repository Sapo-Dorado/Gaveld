defmodule GaveldWeb.GameLive do
  use GaveldWeb, :live_view

  alias Gaveld.Games
  alias Gaveld.Games.Player
  alias Phoenix.PubSub

  @games_list ["Game 1", "Game 2", "Game 3"]
  @impl true
  def mount(%{"code" => code, "name" => name, "uuid" => uuid}, _session, socket) do
    case Games.get_game(code) do
      nil -> {:ok, assign(socket, view: "invalid", code: code)}
      game ->
        controller = game.controller
        case Games.verify_player(game, name, uuid) do
          nil -> {:ok, push_redirect(socket, to: Routes.game_path(socket, :index, code: code))}
          %Player{name: ^controller} -> {:ok, push_redirect(socket, to: Routes.controller_path(socket, :index, code: code, name: name, uuid: uuid))}
          player ->
            if connected?(socket) do
              PubSub.subscribe(Gaveld.PubSub, Games.player_receiving_channel(code, name))
              PubSub.subscribe(Gaveld.PubSub, Games.display_sending_channel(code))
            end
            {:ok, assign(socket, view: game.status, game: game, player: player, errors: nil)}
        end
    end

  end

  @impl true
  def mount(%{"code" => code}, _session, socket) do
    case Games.get_game(code) do
      nil -> {:ok, assign(socket, view: "invalid", code: code)}
      game -> {:ok, assign(socket, view: "valid", game: game, errors: nil)}
    end
  end

  @impl true
  def mount(_assigns, _session, socket) do
    {:ok, push_redirect(socket, to: Routes.homepage_path(socket, :index))}
  end

  @impl true
  def handle_event("enter_name", %{"name" => name}, socket) do
    case Games.add_player(socket.assigns.game, name) do
      {:ok, player} ->
        PubSub.broadcast(Gaveld.PubSub, Games.display_receiving_channel(socket.assigns.game.code), {:new_player, name})
        {:noreply, push_redirect(socket, to: Routes.game_path(socket, :index, code: socket.assigns.game.code, name: name, uuid: player.uuid))}
      {:error, changeset} -> {:noreply, assign(socket, errors: changeset.errors)}
    end
  end

  @impl true
  def handle_event("submit", %{"input" => input}, socket) do
    new_vote? = is_nil(socket.assigns.player.input)
    case Games.add_input(socket.assigns.player, input) do
      {:ok, player} ->
        if new_vote?, do: PubSub.broadcast(Gaveld.PubSub, Games.display_receiving_channel(socket.assigns.game.code), :new_vote)
        {:noreply, assign(socket, player: player)}
      {:error, _ } -> {:noreply, push_redirect(socket, to: Routes.homepage_path(socket, :index))}
    end
  end

  @impl true
  def handle_info(:delete, socket) do
    {:noreply, push_redirect(socket, to: Routes.game_path(socket, :index, code: socket.assigns.game.code))}
  end

  @impl true
  def handle_info(:kill_game, socket) do
    {:noreply, push_redirect(socket, to: Routes.homepage_path(socket, :index))}
  end

  @impl true
  def handle_info(:voting, socket) do
    {:noreply, assign(socket, view: "voting")}
  end

  @impl true
  def handle_info(:stop_vote, socket) do
    {:noreply, assign(socket, view: "voting_results")}
  end

  @impl true
  def handle_info(:become_controller, socket) do
    {:noreply, push_redirect(socket, to: Routes.controller_path(socket, :index, code: socket.assigns.game.code, name: socket.assigns.player.name, uuid: socket.assigns.player.uuid))}
  end

  @impl true
  def render(assigns) do
    ~L'''
    <%= case @view do %>
      <% "invalid" -> %>
        <%= render_invalid(assigns) %>
      <% "valid" -> %>
        <%= render_valid(assigns) %>
      <% "initialized" -> %>
        <%= render_joined(assigns) %>
      <% "voting" -> %>
        <%= render_voting(assigns) %>
      <% "voting_results" -> %>
        <%= render_voting_results(assigns) %>
    <%end%>
    '''
  end

  def render_invalid(assigns) do
    ~L'''
    <a href="<%= Routes.homepage_path(@socket, :index) %>">back</a>
    <h1 class="title">Invalid code <%= @code %>!</h1>
    '''
  end

  def render_valid(assigns) do
    ~L'''
    <h1 class="title">Joined Game <%= @game.code %>!</h1>
    <section class="section is-small">
      <div class="columns">
        <div class="column"></div>
        <div class="column is-three-fifths">
          <div class="box has-text-centered has-background-link">
            <p>Enter your name<p>
            <form phx-submit="enter_name">
              <div class="columns">
                <div class="column"></div>
                <div class="column"></div>
                <div class="column is-one-third">
                  <input type="text" name="name" placeholder="Enter Name" class="input is-success has-text-centered"/>
                  <%= print_errors(@errors) %>
                </div>
                <div class="column">
                  <button type="submit" class="button is-success">Enter</button>
                </div>
                <div class="column"></div>
                </div>
            </form>
          </div>
        </div>
        <div class="column"></div>
      </div>
    </section>
    '''
  end

  def print_errors(errors) do
    if not is_nil(errors) do
      Enum.map(errors, fn {_,error} -> content_tag(:span, translate_error(error)) end)
    end
  end

  def render_joined(assigns) do
    ~L'''
    <h1 class="title">Welcome <%= @player.name %>!</h1>
    '''
  end

  def render_voting(assigns) do
    games_list = List.delete(@games_list, assigns.game.prev_game)
    ~L'''
    <h1 class="title">Time to Vote!</h1>
    <section class="section is-small">
      <div class="columns">
        <div class="column"></div>
        <div class="column is-three-fifths">
          <div class="box has-text-centered has-background-link">
            <%= if is_nil(@player.input) do%>
              <p>Select an option:<p>
            <%else%>
              <p>Change your selection:</p>
            <%end%>
            <form phx-submit="submit">
              <%= for game <- games_list do %>
                <input type="radio" name="input" id="<%= game %>" value="<%= game %>">
                <label for="<%= game %>"><%= game %></label><br>
              <%end%>
              <button type="submit" class="button is-success">Enter</button><br>
            </form>
            <%= if not is_nil(@player.input) do %>
              <p class="is-size-4">Your choice: <%=@player.input%></p>
            <%end%>
          </div>
        </div>
        <div class="column"></div>
      </div>
    </section>
    '''
  end

  def render_voting_results(assigns) do
    ~L'''
    <h1 class="title">Voting Results</h1>
    '''
  end
end
