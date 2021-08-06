defmodule GaveldWeb.HomepageLive do
  use GaveldWeb, :live_view

  alias Gaveld.Games

  @impl true
  def handle_event("join_game", %{"code" => code}, socket) do
    {:noreply, push_redirect(socket, to: Routes.game_path(socket, :index, code: code))}
  end

  @impl true
  def handle_event("create_game", _, socket) do
    game = Games.create_game()
    {:noreply, push_redirect(socket, to: Routes.display_path(socket, :index, code: game.code, uuid: game.uuid))}
  end

  @impl true
  def render(assigns) do
    ~L'''
    <nav class="navbar has-background-primary" role="navigation" aria-label="main navigation">
      <div class="navbar-brand">
        <a class="navbar-item" href="#">
          <img src="<%=Routes.static_path(@socket, "/images/cheese.jpeg") %>" width="50" height="50">
        </a>
      </div>

      <div class="navbar-end">
        <div class="navbar-item">
          <div class="buttons">
            <button class="button is-dark" phx-click="create_game">
              <strong>Create Game</strong>
            </button>
          </div>
        </div>
      </div>
    </nav>
    <section class="section is-medium">
        <div class="columns">
          <div class="column"></div>
          <div class="column is-three-fifths">
            <div class="content has-text-centered">
              <h1 class="title">
                Gavel'd
              </h1>
              <p class="subtitle">
                Mun is fun!
              </p>
            </div>
          </div>
          <div class="column"></div>
        </div>
    </section>
    <section class="section is-small">
      <div class="columns">
        <div class="column"></div>
        <div class="column is-three-fifths">
          <div class="box has-text-centered has-background-link">
            <p>Join a game<p>
            <form phx-submit="join_game">
              <div class="columns">
                <div class="column"></div>
                <div class="column"></div>
                <div class="column is-one-third">
                  <input type="text" name="code" placeholder="Enter Code" class="input is-success has-text-centered"/>
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
    <footer class="footer has-background-primary">
      <div class="content has-text-centered">
        <p>Created by Jordan Tulak and Nicholas Brown</p>
      </div>
    </footer>
    '''
  end
end
