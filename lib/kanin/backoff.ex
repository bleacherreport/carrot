defmodule Kanin.Backoff do
  @moduledoc false

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

  @spec new(options()) :: Backoff.t()
  def new(opts \\ []) do
    min = Keyword.get(opts, :min, @min)
    max = Keyword.get(opts, :max, @max)

    %Backoff{min: min, max: max}
  end

  @spec next(Backoff.t()) :: {pos_integer() | nil, Backoff.t()}
  def next(%Backoff{min: min, state: nil} = state) do
    {min, %Backoff{state | state: min}}
  end

  def next(%Backoff{max: max, state: max} = state) do
    {nil, %Backoff{state | state: nil}}
  end

  def next(%Backoff{max: max, state: prev} = state) do
    next = min(prev <<< 1, max)
    {next, %Backoff{state | state: next}}
  end

  @spec reset(Backoff.t()) :: Backoff.t()
  def reset(%Backoff{} = state) do
    %Backoff{state | state: nil}
  end
end
