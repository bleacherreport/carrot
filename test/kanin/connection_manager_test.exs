defmodule Kanin.ConnectionManagerTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias Kanin.Backoff
  alias Kanin.ConnectionManager, as: CM

  setup do
    {:ok,
     config: [
       username: System.get_env("RABBITMQ_USER") || "guest",
       password: System.get_env("RABBITMQ_PASSWORD") || "guest",
       host: System.get_env("RABBITMQ_HOST") || "localhost",
       virtual_host: System.get_env("RABBITMQ_VHOST") || "/"
     ]}
  end

  describe "start_link" do
    test "allows name registration" do
      {:ok, pid} = CM.start_link([], name: :amqp_test)
      assert Process.whereis(:amqp_test) == pid
    end

    test "max_backoff_ms defaults to 30_000" do
      {:ok, pid} = CM.start_link([])
      assert %CM.State{backoff: %Backoff{max: 30_000}} = :sys.get_state(pid)
    end

    test "min_backoff_ms defaults to 1000" do
      {:ok, pid} = CM.start_link([])
      assert %CM.State{backoff: %Backoff{min: 1000}} = :sys.get_state(pid)
    end

    test "backoff strategy" do
      output =
        capture_log(fn ->
          {:ok, pid} = CM.start_link(host: "bad.host", backoff: [min: 100, max: 1000])

          assert_backoff(pid, 100)
          assert_backoff(pid, 200)
          assert_backoff(pid, 400)
          assert_backoff(pid, 800)
          assert_backoff(pid, 1000)
          # backoff restarts
          assert_backoff(pid, [nil, 100])
        end)

      assert output =~ "Unable to connect to AMQP server"
    end
  end

  describe "when our process crashes" do
    test "it gracefully shuts down the AMQP connection process", %{config: config} do
      {:ok, pid} = CM.start_link(config)

      %CM.State{state: %AMQP.Connection{pid: conn}} = :sys.get_state(pid)

      true = Process.unlink(pid)
      ref = Process.monitor(pid)

      capture_log(fn ->
        send(pid, :die)

        receive do
          {:DOWN, ^ref, :process, ^pid, _reason} ->
            refute Process.alive?(pid)
            refute Process.alive?(conn)
        end
      end)
    end
  end

  describe "AMQP connection process crashes" do
    test "handles :DOWN message and starts reconnect process", %{config: config} do
      {:ok, pid} = CM.start_link(config)

      %CM.State{state: %AMQP.Connection{pid: conn}} = :sys.get_state(pid)

      capture_log(fn ->
        ref = Process.monitor(conn)

        Process.exit(conn, :shutdown)

        receive do
          {:DOWN, ^ref, :process, ^conn, _reason} ->
            refute Process.alive?(conn)

            assert_backoff(pid, [nil, 1000])
        end
      end)
    end
  end

  describe "open_channel" do
    test "returns a channel when connected", %{config: config} do
      {:ok, pid} = CM.start_link(config)
      assert {:ok, %AMQP.Channel{}} = CM.open_channel(pid)
    end

    test "returns an error when disconnected" do
      output =
        capture_log(fn ->
          {:ok, pid} = CM.start_link(host: "bad.host")
          assert {:error, :disconnected} = CM.open_channel(pid)
        end)

      assert output =~ "Unable to connect to AMQP server"
    end
  end

  def assert_backoff(pid, list) when is_list(list) do
    state = :sys.get_state(pid)
    assert %CM.State{state: :disconnected, backoff: %Backoff{state: state}} = state
    # depending on the timing of the test we could either be retrying
    # immediately or have already started backoff.
    assert state in list
  end

  def assert_backoff(pid, ms) do
    state = :sys.get_state(pid)
    assert %CM.State{state: :disconnected, backoff: %Backoff{state: ^ms}} = state
    if ms, do: Process.sleep(ms)
  end
end
