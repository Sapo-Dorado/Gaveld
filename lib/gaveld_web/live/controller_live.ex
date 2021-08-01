
defmodule GaveldWeb.ControllerLive do
  use GaveldWeb, :live_view

  alias Phoenix.PubSub
  alias Gaveld.Games

  @impl true
  def mount(%{"code" => code, "name" => name, "uuid" => uuid}, _session, socket) do
    case Games.get_game(code) do
      nil -> {:ok, push_redirect(socket, to: Routes.homepage_path(socket, :index))}
      game ->
        case Games.verify_player(game, name, uuid) do
          nil -> {:ok, push_redirect(socket, to: Routes.game_path(socket, :index, code: code))}
          player ->
            if connected?(socket), do: PubSub.subscribe(Gaveld.PubSub, Games.display_sending_channel(code))
            {:ok, assign(socket, game: game, player: player)}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~L'''
    <h1 class="title">You are the controller</h1>
    '''
  end
end
