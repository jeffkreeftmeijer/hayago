defmodule Hayago.State do
  @moduledoc """
  A struct to describe the current state in the game, and functions to update
  the state by placing stones and to check if a certain move is legal.

  ## Attributes
  ### Positions

  The *positions* attribute is a list of positions on the board. Initially,
  it's generated as a list of 81 `nil` values, which represent all positions on
  an empty 9 × 9 board.  When a stone is added on one of the positions, the
  value corresponding to that position gets updated to either `:black`, or
  `:white`.

  ### Current

  The *current* attribute holds the current player's color, and switches to the
  other color after every successful move. The player with the black stones
  always starts, so the initial value is `:black`.

  ### Captures

  A stone is captured when it has no more liberties, meaning it's surrounded by
  the opponent's stones. A captured stone is removed from the board, and the
  *captures* list is incremented for the captured stone's color.
  """

  alias Hayago.State

  defstruct positions: Enum.map(1..81, fn _ -> nil end),
            current: :black,
            captures: %{black: 0, white: 0}

  @doc """
  Places a new stone on the board, captures any surrounded stones, and swaps
  the current attribute to switch the turn to the other player.

  `place/2` takes a `Hayago.State` struct and an *index* to place a new stone.
  When called, it replaces the state's positions list by replacing the value at
  the passed index with the current value in the state.

  After placing the stone on the board, the current player is swapped, to
  prepare the state for the other player's move.

      iex> State.place(%State{positions: [nil, nil, nil, nil], current: :black}, 0)
      %State{positions: [:black, nil, nil, nil], current: :white}

  Stones are captured if they're surrounded by the opponent's stones. After
  placing a new stone, all stones on the board are checked to see if they have
  any liberties left. If they don't they're removed from the board.

  > A *liberty* is an empty position adjacent to a stone. If a stone is
  surrounded by the opponent's stones, it has no liberties left. If two stones
  of the same color are in adjacent positions, they form a group and share
  their liberties.

  After removing a stone from the board, `place/2` increments the key
  corresponding to the captured stone in the captures counter.

      iex> State.place(
      ...>   %State{
      ...>     positions: [
      ...>       :white, :black, nil,
      ...>       nil,    nil,    :white,
      ...>       nil,    nil,    nil
      ...>     ],
      ...>     current: :black
      ...>   },
      ...> 3)
      %State{
        positions: [
          nil,   :black,  nil,
          :black, nil,    :white,
          nil,    nil,    nil
        ],
        current: :white,
        captures: %{black: 0, white: 1}
      }

  When placing a stone `place/2` iterates over the opponents' stones to check
  for captures first. After that, it checks all of the current player's stones.

  Moves aren't validated in the `place/2` function. This means a placing a
  stone on a position without liberties will immediately remove it from the
  board.

      iex> State.place(
      ...>   %State{
      ...>     positions: [
      ...>       nil,    :black, nil,
      ...>       :black, nil,    :white,
      ...>       nil,    nil,    nil
      ...>     ],
      ...>     current: :white
      ...>   },
      ...> 0)
      %State{
        positions: [
          nil,   :black,  nil,
          :black, nil,    :white,
          nil,    nil,    nil
        ],
        current: :white,
        captures: %{black: 0, white: 0}
      }

  Making a move that captures one of your own stones is illegal in Go. The
  `legal?/2` function, which validates moves before they happen, uses the
  `place/2` function to check if making a move actually results in a stone in
  the corect position. If it doesn't, the move is illegal.
  """
  def place(%State{positions: positions, current: current, captures: captures} = state, index) do
    opponent = next(current)

    new_positions = List.replace_at(positions, index, current)
    {new_positions, fresh_captures} = capture(new_positions, opponent)
    {new_positions, _} = capture(new_positions, current)

    {_, new_captures} =
      Map.get_and_update(captures, opponent, fn current ->
        {current, current + fresh_captures}
      end)

    new_current =
      case new_positions do
        ^positions -> current
        _ -> opponent
      end

    %{state | positions: new_positions, current: new_current, captures: new_captures}
  end

  @doc """
  Validates a potential move by trying it on the current state, and evaluating
  the result.

  The `legal?/2` function does two checks to make sure a move is legal. First,
  it checks if the position in the current state is empty, making sure there
  position a new stone is placed on is empty.

      iex> State.legal?(%State{positions: [nil, nil, nil, nil]}, 0)
      true
      iex> State.legal?(%State{positions: [:black, nil, nil, nil]}, 0)
      false

  The next check makes sure the position has liberties for the placed stone,
  meaning the stone can be placed there with at least one liberty, or part of a
  group that has at least one liberty.

  To determine if a newly placed stone will have liberties, `legal?/2` uses the
  `place/2` function to try placing a stone on the position that's being
  validated. Since placing a stone will remove any stones without liberties
  from the board, it checks if the stone is still there after placing it. If it
  is, the move is legal.

      iex> State.legal?(%State{positions: [nil, :black, :black, nil], current: :black}, 0)
      true
      iex> State.legal?(%State{positions: [nil, :white, :white, nil], current: :black}, 0)
      false

  Because the `place/2` function captures enemy stones first, moves on places
  that don't have any liberties but gain them by capturing the opponent's
  stones are legal as well.

      iex> State.legal?(
      ...>   %State{
      ...>     positions: [
      ...>       nil,    :black, :white,
      ...>       :black, :white, nil,
      ...>       :white, nil,    nil
      ...>     ],
      ...>     current: :white
      ...>   },
      ...> 0)
      true
      iex> State.legal?(
      ...>   %State{
      ...>     positions: [
      ...>       nil,    :black, :white,
      ...>       :black, :white, nil,
      ...>       :white, nil,    nil
      ...>     ],
      ...>     current: :black
      ...>   },
      ...> 0)
      false
  """
  def legal?(%State{positions: positions, current: current} = state, index) do
    %State{positions: tentative_positions} = State.place(state, index)

    Enum.at(positions, index) == nil and Enum.at(tentative_positions, index) == current
  end

  defp capture(positions, color) do
    positions
    |> Enum.with_index()
    |> Enum.map_reduce(0, fn {value, index}, captures ->
      case {value, liberties?(positions, index, color)} do
        {^color, false} -> {nil, captures + 1}
        {_, _} -> {value, captures}
      end
    end)
  end

  defp liberties?(positions, index, color, checked \\ []) do
    size =
      positions
      |> length()
      |> :math.sqrt()
      |> round()

    index
    |> liberty_indexes(size)
    |> Enum.reject(&(&1 in checked))
    |> Enum.any?(fn liberty ->
      case Enum.at(positions, liberty) do
        ^color -> liberties?(positions, liberty, color, [index | checked])
        nil -> true
        _ -> false
      end
    end)
  end

  defp liberty_indexes(index, size) do
    row = div(index, size)
    column = rem(index, size)

    [
      {row - 1, column},
      {row, column + 1},
      {row + 1, column},
      {row, column - 1}
    ]
    |> Enum.reduce([], fn {row, column}, acc ->
      case row < 0 or row >= size or column < 0 or column >= size do
        true -> acc
        false -> [row * size + column | acc]
      end
    end)
  end

  defp next(:black), do: :white
  defp next(:white), do: :black
end
