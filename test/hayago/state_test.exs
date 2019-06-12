defmodule Hayago.StateTest do
  alias Hayago.State
  use ExUnit.Case
  doctest Hayago.State

  test "has 81 empty positions" do
    %State{positions: positions} = %State{}
    assert length(positions) == 81
    assert Enum.uniq(positions) == [nil]
  end

  test "black is the first to move" do
    assert %State{current: :black} = %State{}
  end

  describe "place/3" do
    test "places a stone" do
      assert %State{positions: ~w{black nil nil nil}a} =
               State.place(%State{positions: ~w{nil nil nil nil}a, current: :black}, 0)
    end

    test "switches turns" do
      assert %State{current: :white} =
               State.place(%State{positions: ~w{nil nil nil nil}a, current: :black}, 0)
    end

    test "does not place a stone without liberties" do
      assert %State{positions: ~w{nil black black nil}a, current: :white} =
               State.place(%State{positions: ~w{nil black black nil}a, current: :white}, 0)
    end

    test "removes an opponent's stone" do
      assert %State{positions: ~w{nil black black nil}a} =
               State.place(%State{positions: ~w{white black nil nil}a, current: :black}, 2)
    end

    test "captures a removed stone" do
      assert %State{captures: %{black: 0, white: 1}} =
               State.place(%State{positions: ~w{white black nil nil}a, current: :black}, 2)
    end

    test "removes an opponent's group" do
      assert %State{positions: ~w{nil nil black black black nil nil nil nil}a} =
               State.place(
                 %State{
                   positions: ~w{white white nil black black nil nil nil nil}a,
                   current: :black
                 },
                 2
               )
    end

    test "removes a group and gains liberties" do
      assert %State{positions: ~w{white nil white nil white nil white nil nil}a} =
               State.place(
                 %State{
                   positions: ~w{nil black white black white nil white nil nil}a,
                   current: :white
                 },
                 0
               )
    end
  end

  describe "legal?/2" do
    test "is legal when placing a stone on an empty board" do
      empty = %State{positions: ~w{nil nil nil nil}a, current: :black}

      assert State.legal?(empty, 0)
      assert State.legal?(empty, 1)
      assert State.legal?(empty, 2)
      assert State.legal?(empty, 3)
    end

    test "is illegal when placing a stone on a point that's occupied" do
      refute State.legal?(%State{positions: ~w{white nil nil nil}a, current: :black}, 0)
    end

    test "is illegal when placing a stone on a point that has no liberties" do
      refute State.legal?(%State{positions: ~w{nil white white nil nil}a, current: :black}, 0)
    end
  end
end
