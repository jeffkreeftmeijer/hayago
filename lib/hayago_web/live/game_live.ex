defmodule HayagoWeb.GameLive do
  alias Hayago.State
  use Phoenix.LiveView

  def render(assigns) do
    HayagoWeb.GameView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    {:ok, assign(socket, state: %State{})}
  end

  def handle_event("place", index, %{assigns: assigns} = socket) do
    new_state = State.place(assigns.state, String.to_integer(index))
    {:noreply, assign(socket, state: new_state)}
  end
end
