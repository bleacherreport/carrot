defmodule Carrot.BackoffTest do
  use ExUnit.Case
  doctest Carrot.Backoff

  alias Carrot.Backoff

  describe "new/1" do
    test "returns a new Backoff struct with defaults" do
      assert %Backoff{min: 1000, max: 30_000, state: nil} = Backoff.new([])
    end

    test "returns a new Backoff struct with min and max set" do
      assert %Backoff{min: 100, max: 1000, state: nil} = Backoff.new(min: 100, max: 1000)
    end
  end

  describe "next/1" do
    test "returns a tuple containing the next value and the new state" do
      backoff = Backoff.new(min: 100, max: 3000)
      assert %Backoff{state: 100} = backoff = Backoff.next(backoff)
      assert %Backoff{state: 200} = backoff = Backoff.next(backoff)
      assert %Backoff{state: 400} = backoff = Backoff.next(backoff)
      assert %Backoff{state: 800} = backoff = Backoff.next(backoff)
      assert %Backoff{state: 1600} = backoff = Backoff.next(backoff)
      assert %Backoff{state: 3000} = backoff = Backoff.next(backoff)
      assert %Backoff{state: nil} = Backoff.next(backoff)
    end
  end

  describe "reset/1" do
    test "sets state field to nil" do
      backoff = Backoff.new(min: 100, max: 3000)
      assert %Backoff{state: 100} = backoff = Backoff.next(backoff)
      assert %Backoff{state: nil} = Backoff.reset(backoff)
    end
  end
end
