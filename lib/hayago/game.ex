defmodule Hayago.Game do
  @moduledoc """
  A struct to describe the game's history, and functions to progress the game.

  ## Attributes

  ### History

  The *history* attribute contains a list of `Hayago.State` structs, where the
  first element in the list is the current state. Whenever a move is made, a
  new state is prepended to the list. The history attbibute initally holds a
  single empty State to represent the empty board.
  """
  alias Hayago.{Game, State}
  defstruct history: [%State{}]

  @doc """
  Returns the first element in the history list, as the current state of the
  game.

      iex> Game.state(%Game{history: [
      ...>   %Hayago.State{positions: [:black, nil, nil, nil], current: :white},
      ...>   %Hayago.State{positions: [nil, nil, nil, nil], current: :black}
      ...> ]})
      %Hayago.State{positions: [:black, nil, nil, nil],current: :white}
  """
  def state(%Game{history: [state | _]}) do
    state
  end

  @doc """
  Places a new stone on the board by prepending a new state to the history. The
  new state is created by calling `Hayago.State.place/2` and passing the
  current state, and the position passed to `place/2`.

      iex> Game.place(%Game{history: [%Hayago.State{positions: [nil, nil, nil, nil], current: :black}]}, 0)
      %Game{history: [
        %Hayago.State{positions: [:black, nil, nil, nil], current: :white},
        %Hayago.State{positions: [nil, nil, nil, nil], current: :black}
      ]}

  """
  def place(%Game{history: [state | _] = history} = game, position) do
    %{game | history: [State.place(state, position) | history]}
  end
end
