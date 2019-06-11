defmodule HayagoWeb.GameLiveTest do
  use ExUnit.Case
  import Phoenix.LiveViewTest, only: [mount: 3, render_click: 3]
  alias HayagoWeb.{Endpoint, GameLive}

  setup do
    {:ok, view, html} = mount(Endpoint, GameLive, session: %{})
    {:ok, html: html, view: view}
  end

  test "renders the board", %{html: html} do
    assert html =~ ~r(<div class="board black">.*</div>)s
  end

  test "renders 81 point buttons", %{html: html} do
    assert ~r(<button.*?></button>)s
           |> Regex.scan(html)
           |> length() == 81
  end

  test "places a stone", %{view: view} do
    assert render_click(view, :place, "0") =~
             ~s(<button phx-click="place" phx-value="0" class="black"></button>)
  end
end
