defmodule Hayago.Game do
  @moduledoc """
  A struct to describe the game's history, and functions to progress the game.

  ## Attributes

  ### History

  The *history* attribute contains a list of `Hayago.State` structs, where the
  first element in the list is the current state. Whenever a move is made, a
  new state is prepended to the list. The history attbibute initally holds a
  single empty State to represent the empty board.

  ### Index

  The *index* represents the current index in the history list. On
  initialization, the index is 0, as the current state is the first element in
  the history list. To jump back one turn, the index is increased to 1. The
  `state/1` function uses the index to get the state that corresponds to the
  index.
  """
  alias Hayago.{Game, State}
  defstruct history: [%State{}], index: 0
  use GenServer

  def start_link(options) do
    GenServer.start_link(__MODULE__, %Game{}, options)
  end

  @impl true
  def init(game) do
    {:ok, game}
  end

  @impl true
  def handle_call(:game, _from, game) do
    {:reply, game, game}
  end

  @impl true
  def handle_cast({:place, position}, game) do
    {:noreply, Game.place(game, position)}
  end

  @impl true
  def handle_cast({:jump, destination}, game) do
    {:noreply, Game.jump(game, destination)}
  end

  @doc """
  Returns the element in the history list that corresponds to the `:index`
  attribute as the current state of the game. The index defaults to 0, so the
  first state is returned by default.

      iex> Game.state(%Game{history: [
      ...>   %Hayago.State{positions: [:black, nil, nil, nil], current: :white},
      ...>   %Hayago.State{positions: [nil, nil, nil, nil], current: :black}
      ...> ]})
      %Hayago.State{positions: [:black, nil, nil, nil],current: :white}

  If the index is set, it takes the element that corresponds to the index from
  the history list.

      iex> Game.state(%Game{
      ...>   history: [
      ...>     %Hayago.State{positions: [:black, nil, nil, nil], current: :white},
      ...>     %Hayago.State{positions: [nil, nil, nil, nil], current: :black}
      ...>   ],
      ...>   index: 1
      ...> })
      %Hayago.State{positions: [nil, nil, nil, nil],current: :black}
  """
  def state(%Game{history: history, index: index}) do
    Enum.at(history, index)
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

  If the Game's `:index` attribute is higher than 0, the history is sliced
  before prepending the new state, to allow the game to branch off its history
  when it's reverted.

      iex> Game.place(%Game{
      ...>     history: [
      ...>       %Hayago.State{positions: [:black, nil, nil, nil], current: :white},
      ...>       %Hayago.State{positions: [nil, nil, nil, nil], current: :black}
      ...>     ],
      ...>     index: 1
      ...>   },
      ...>   1
      ...> )
      %Game{history: [
        %Hayago.State{positions: [nil, :black, nil, nil], current: :white},
        %Hayago.State{positions: [nil, nil, nil, nil], current: :black}
      ]}
  """
  def place(%Game{history: history, index: index} = game, position) do
    new_state =
      game
      |> Game.state()
      |> State.place(position)

    %{game | history: [new_state | Enum.slice(history, index..-1)], index: 0}
  end

  @doc """
  Validates a potential move by checking it against the current and previous
  states.

      iex> Game.legal?(%Game{}, 0)
      true

  The move is checked against the current state using `Hayago.State.legal?/2`
  first, which returns true if the current player can place a stone their
  without it being immediately captured.

      iex> Game.legal?(
      ...>   %Game{history: [%State{positions: [nil, :white, :white, nil], current: :black}]},
      ...>   0
      ...> )
      false

  If the stone could be placed on the passed position, the result of that move
  is checked against all states in the board's history, to prevent repeated
  board states (the ko rule).

      iex> Game.legal?(
      ...>   %Game{
      ...>     history: [
      ...>       %State{
      ...>         positions: ~w(
      ...>           nil   black white nil
      ...>           black white nil   white
      ...>           nil   black white nil
      ...>           nil   nil   nil   nil
      ...>         )a,
      ...>         current: :black
      ...>       },
      ...>       %State{
      ...>         positions: ~w(
      ...>           nil   black white nil
      ...>           black nil   black white
      ...>           nil   black white nil
      ...>           nil   nil   nil   nil
      ...>         )a,
      ...>         current: :white
      ...>       }
      ...>     ]
      ...>   },
      ...>   6
      ...> )
      false
  """
  def legal?(game, position) do
    State.legal?(Game.state(game), position) and not repeated_state?(game, position)
  end

  defp repeated_state?(game, position) do
    %Game{history: [%State{positions: tentative_positions} | history]} =
      Game.place(game, position)

    Enum.any?(history, fn %State{positions: positions} ->
      positions == tentative_positions
    end)
  end

  @doc """
  Jumps in history by updating the `:index` attribute.

      iex> Game.jump(%Game{index: 0}, 1)
      %Game{index: 1}
  """
  def jump(game, destination) do
    %{game | index: destination}
  end

  @doc """
  Determines if a history index is valid for the current game.

      iex> Game.history?(%Game{}, 0)
      true

      iex> Game.history?(%Game{}, 1)
      false

      iex> Game.history?(%Game{}, -1)
      false
  """
  def history?(%Game{history: history}, index) when index >= 0 and length(history) > index do
    true
  end

  def history?(_game, _index), do: false
end
