defmodule HayagoWeb.GameLive do
  use Phoenix.LiveView

  def render(assigns) do
    HayagoWeb.GameView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    {:ok, assign(socket, state: %Hayago.State{})}
  end
end
