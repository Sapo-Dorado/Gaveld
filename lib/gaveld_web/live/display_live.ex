defmodule GaveldWeb.DisplayLive do
  use GaveldWeb, :live_view

  alias Phoenix.PubSub
  alias Gaveld.Games

  @impl true
  def mount(%{"code" => code, "uuid" => uuid}, _session, socket) do
    case Games.validate_game(code, uuid) do
      nil -> {:ok, push_redirect(socket, to: Routes.homepage_path(socket, :index))}
      game ->
        if connected?(socket), do: PubSub.subscribe(Gaveld.PubSub, Games.display_receiving_channel(code))
        game = Games.reload_players(game)
        {:ok, assign(socket, players: Enum.map(game.players, fn p -> p.name end), game: game)}
    end
  end

  def mount(_params, _session, socket) do
    {:ok, push_redirect(socket, to: Routes.homepage_path(socket, :index))}
  end

  @impl true
  def handle_info({:new_player, name}, socket) do
    {:noreply, assign(socket, players: socket.assigns.players ++ [name])}
  end

  @impl true
  def render(assigns) do
    ~L'''
    <section class="section is-medium has-text-centered">
      <div class="container">
        <h1 class="title">The code is: <%= @game.code %></h1>
        <p class="subtitle">Enter the code to join!</p>
      </div>
    </section>
    <section class="section has-text-centered">
      <h1 class="title">See your name on the screen:</h1>
      <%= for player <- @players do %>
        <h1 class="title"><%= player %></h1>
      <%end%>
    </section>
    '''
  end
end
