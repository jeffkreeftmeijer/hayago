defmodule HayagoWeb.GameLive do
  alias Hayago.Game
  use Phoenix.LiveView

  def render(assigns) do
    HayagoWeb.GameView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    game = %Game{}
    {:ok, assign(socket, game: game, state: Game.state(game))}
  end

  def handle_event("place", index, %{assigns: assigns} = socket) do
    new_game = Game.place(assigns.game, String.to_integer(index))
    {:noreply, assign(socket, game: new_game, state: Game.state(new_game))}
  end

  def handle_event("jump", destination, %{assigns: %{game: game}} = socket) do
    new_game = Game.jump(game, String.to_integer(destination))
    {:noreply, assign(socket, game: new_game, state: Game.state(new_game))}
  end
end
