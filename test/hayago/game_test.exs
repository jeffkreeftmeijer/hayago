defmodule Hayago.GameTest do
  alias Hayago.{Game, State}
  use ExUnit.Case
  doctest Hayago.Game

  test "state/1 returns the game's current state" do
    state = %State{current: :white}
    assert Game.state(%Game{history: [state, %State{}]}) == state
  end

  test "place/1 adds a state to the history to place a stone on the board" do
    assert Game.place(
             %Game{history: [%State{positions: [nil, nil, nil, nil], current: :black}]},
             0
           ) ==
             %Game{
               history: [
                 %State{positions: [:black, nil, nil, nil], current: :white},
                 %State{positions: [nil, nil, nil, nil], current: :black}
               ]
             }
  end
end
