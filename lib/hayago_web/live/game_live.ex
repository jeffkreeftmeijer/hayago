defmodule HayagoWeb.GameLive do
  alias Hayago.Game
  use Phoenix.LiveView

  def render(assigns) do
    HayagoWeb.GameView.render("index.html", assigns)
  end

  def handle_params(%{"name" => name} = _params, _uri, socket) do
    {:noreply, assign_game(socket, name)}
  end

  def handle_params(_params, _uri, socket) do
    name =
      ?a..?z
      |> Enum.take_random(6)
      |> List.to_string()

    {:ok, _pid} =
      DynamicSupervisor.start_child(Hayago.GameSupervisor, {Game, name: via_tuple(name)})

    {:ok,
     live_redirect(
       socket,
       to: HayagoWeb.Router.Helpers.live_path(socket, HayagoWeb.GameLive, name: name)
     )}
  end

  def handle_event("place", index, %{assigns: %{name: name}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:place, String.to_integer(index)})
    {:noreply, assign_game(socket)}
  end

  def handle_event("jump", destination, %{assigns: %{name: name}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:jump, String.to_integer(destination)})
    {:noreply, assign_game(socket)}
  end

  defp via_tuple(name) do
    {:via, Registry, {Hayago.GameRegistry, name}}
  end

  defp assign_game(socket, name) do
    socket
    |> assign(name: name)
    |> assign_game()
  end

  defp assign_game(%{assigns: %{name: name}} = socket) do
    game = GenServer.call(via_tuple(name), :game)
    assign(socket, game: game, state: Game.state(game))
  end
end
