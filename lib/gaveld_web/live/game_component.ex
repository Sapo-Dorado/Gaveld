defmodule GaveldWeb.GameComponent do
  use GaveldWeb, :live_component

  alias Gaveld.Games
  alias Phoenix.PubSub

  @impl true
  def update(%{code: code, id: id}, socket) do
    pub_sub_sending = "display_#{String.replace(code, " ", "_")}"
    pub_sub_receiving = "display_#{String.replace(code, " ", "_")}_player"
    PubSub.subscribe(Gaveld.PubSub, pub_sub_receiving)
    case Games.get_game(code) do
      nil -> {:ok, assign(socket, game_view: "invalid", code: code, id: id)}
      game -> {:ok, assign(socket, game_view: "valid", game: game, code: code, id: id, errors: nil, pub_sub_sending: pub_sub_sending)}
    end
  end

  @impl true
  def handle_event("enter_name", %{"name" => name}, socket) do
    case Games.add_player(socket.assigns.game, name) do
      {:ok, player} ->
        PubSub.broadcast(Gaveld.PubSub, socket.assigns.pub_sub_sending, {:new_player, name})
        {:noreply, assign(socket, player: player, game_view: "joined", errors: nil)}
      {:error, changeset} -> {:noreply, assign(socket, errors: changeset.errors)}
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
      |> IO.inspect
    end
  end

  def render_joined(assigns) do
    ~L'''
    <h1 class="title">Welcome <%= @player.name %>!</h1>
    '''
  end
end
