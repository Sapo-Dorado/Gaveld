defmodule GameComponent do
  use GaveldWeb, :live_component

  @impl true
  def render(assigns) do
    ~L'''
    <h1 class="title">You joined game <%= @code %>!</h1>
    '''
  end
end
