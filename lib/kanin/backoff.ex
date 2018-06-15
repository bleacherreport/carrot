defmodule Kanin.Backoff do
  @moduledoc """
  Provides functions to facilitate exponential backoff.
  """

  import Bitwise

  alias Kanin.Backoff

  @min 1_000
  @max 30_000

  defstruct min: @min,
            max: @max,
            state: nil

  @type option :: {:max, pos_integer()} | {:min, pos_integer()}
  @type options :: [option()]
  @type state :: pos_integer() | nil
  @type t :: %Backoff{
          min: pos_integer(),
          max: pos_integer(),
          state: pos_integer() | nil
        }

  @doc """
  Creates a new `Backoff` struct based on provided options.

  ## Options

    * `:min` - The minimum number of milliseconds for starting the backoff process (default: `1000`)
    * `:max` - The maximum number of milliseconds before restarting the backoff process (default: `30_000`)

  ## Examples

      iex> Kanin.Backoff.new()
      %Kanin.Backoff{min: 1000, max: 30_000, state: nil}

      iex> Kanin.Backoff.new(min: 100, max: 1000)
      %Kanin.Backoff{min: 100, max: 1_000, state: nil}

  """
  @spec new(options()) :: Backoff.t()
  def new(opts \\ []) do
    min = Keyword.get(opts, :min, @min)
    max = Keyword.get(opts, :max, @max)

    %Backoff{min: min, max: max}
  end

  @doc """
  Returns a new `Backoff` struct with updated state.

  ## Examples

      iex> backoff = Kanin.Backoff.new(min: 100, max: 400)
      %Kanin.Backoff{min: 100, max: 400, state: nil}
      iex> backoff = Kanin.Backoff.next(backoff)
      %Kanin.Backoff{min: 100, max: 400, state: 100}
      iex> backoff = Kanin.Backoff.next(backoff)
      %Kanin.Backoff{min: 100, max: 400, state: 200}
      iex> backoff = Kanin.Backoff.next(backoff)
      %Kanin.Backoff{min: 100, max: 400, state: 400}
      iex> _backoff = Kanin.Backoff.next(backoff)
      %Kanin.Backoff{min: 100, max: 400, state: nil}

  """
  @spec next(Backoff.t()) :: Backoff.t()
  def next(%Backoff{min: min, state: nil} = state) do
    %Backoff{state | state: min}
  end

  def next(%Backoff{max: max, state: max} = state) do
    %Backoff{state | state: nil}
  end

  def next(%Backoff{max: max, state: prev} = state) do
    %Backoff{state | state: min(prev <<< 1, max)}
  end

  @doc """
  Resets the backoff state.

  ## Example

      iex> backoff = Kanin.Backoff.new()
      %Kanin.Backoff{min: 1000, max: 30_000, state: nil}
      iex> backoff = Kanin.Backoff.next(backoff)
      %Kanin.Backoff{min: 1000, max: 30_000, state: 1000}
      iex> _backoff = Kanin.Backoff.reset(backoff)
      %Kanin.Backoff{min: 1000, max: 30_000, state: nil}

  """
  @spec reset(Backoff.t()) :: Backoff.t()
  def reset(%Backoff{} = state) do
    %Backoff{state | state: nil}
  end

  @doc """
  Schedules the next backoff interval.

  This function will send the given message to the given PID based on the
  current state of the `Backoff` struct.

  ## Examples

      iex> backoff = Kanin.Backoff.new(min: 100, max: 200)
      %Kanin.Backoff{min: 100, max: 200, state: nil}
      iex> backoff = Kanin.Backoff.next(backoff)
      %Kanin.Backoff{min: 100, max: 200, state: 100}
      iex> _backoff = Kanin.Backoff.schedule(backoff, self(), :connect)
      %Kanin.Backoff{min: 100, max: 200, state: 100}
      iex> receive do
      ...>   :connect ->
      ...>     :ok
      ...> end
      :ok

  """
  @spec schedule(Backoff.t(), pid(), any()) :: Backoff.t()
  def schedule(%Backoff{state: state} = backoff, pid, message) do
    ms = if state, do: state, else: 0
    _ = Process.send_after(pid, message, ms)
    backoff
  end
end
