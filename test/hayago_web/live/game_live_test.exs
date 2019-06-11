defmodule HayagoWeb.GameLiveTest do
  use ExUnit.Case
  import Phoenix.LiveViewTest, only: [mount: 3]
  alias HayagoWeb.{Endpoint, GameLive}

  setup do
    {:ok, _view, html} = mount(Endpoint, GameLive, session: %{})
    {:ok, html: html}
  end

  test "renders the board", %{html: html} do
    assert html =~ ~r(<div class="board black">.*</div>)s
  end

  test "renders 81 point buttons", %{html: html} do
    assert ~r(<button></button>)s
           |> Regex.scan(html)
           |> length() == 81
  end
end
