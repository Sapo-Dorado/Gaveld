defmodule GameComponent do
  use GaveldWeb, :live_component

  alias Gaveld.Games

  @impl true
  def update(%{code: code, id: id}, socket) do
    case Games.get_game(code) do
      nil -> {:ok, assign(socket, game_view: "invalid", code: code, id: id)}
      game -> {:ok, assign(socket, game_view: "valid", game: game, code: code, id: id, error: false)}
    end
  end

  @impl true
  def handle_event("enter_name", %{"name" => name}, socket) do
    case Games.add_player(socket.assigns.game, name) do
      {:ok, player} -> {:noreply, assign(socket, player: player, game_view: "joined")}
      {:error, changeset} ->
        case changeset.errors do
          [name: _ ] -> {:noreply, assign(socket, error: true, error_message: "Must be at least 3 characters!")}
          [uid: _ ] -> {:noreply, assign(socket, error: true, error_message: "Name already taken!")}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~L'''
    <%= cond do %>
      <% @game_view == "invalid" -> %>
        <%= render_invalid(assigns) %>
      <% @game_view == "valid" -> %>
        <%= render_valid(assigns) %>
      <% @game_view == "joined" -> %>
        <%= render_joined(assigns) %>
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
    <h1 class="title">Joined Game <%= @code %>!</h1>
    <section class="section is-small">
      <div class="columns">
        <div class="column"></div>
        <div class="column is-three-fifths">
          <div class="box has-text-centered has-background-link zoom">
            <p>Enter your name<p>
            <form phx-submit="enter_name" phx-target="<%= @myself %>">
              <div class="columns">
                <div class="column"></div>
                <div class="column"></div>
                <div class="column is-one-third">
                  <input type="text" name="name" placeholder="Enter Name" class="input is-success has-text-centered"/>
                </div>
                <div class="column">
                  <button type="submit" class="button is-success">Enter</button>
                </div>
                <div class="column"></div>
                </div>
            </form>
            <%= if @error do %>
              <p><%= @error_message %></p>
            <%end%>
          </div>
        </div>
        <div class="column"></div>
      </div>
    </section>
    '''
  end

  def render_joined(assigns) do
    ~L'''
    <h1 class="title">Welcome <%= @player.name %>!</h1>
    '''
  end
end
