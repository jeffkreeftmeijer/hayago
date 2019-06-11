defmodule HayagoWeb.PageController do
  use HayagoWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
