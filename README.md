# Kanin

> AMQP connection manager

[![Build Status](https://www.travis-ci.org/bleacherreport/kanin.svg?branch=master)](https://www.travis-ci.org/bleacherreport/kanin)
[![codecov](https://codecov.io/gh/bleacherreport/kanin/branch/master/graph/badge.svg)](https://codecov.io/gh/bleacherreport/kanin)

## Naming

Kanin is Swedish for rabbit.

## Installation

The package can be installed by adding `kanin` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:kanin, "~> 1.0"}]
end
```

## Configuration and startup

Kanin does not use `Mix` or `Application` configuration. The `ConnectionManager`
simply takes a `Keyword` list of connection options as the first argument to
`start_link/2`:

```elixir
{:ok, pid} = Kanin.ConnectionManager.start_link([
  host: "localhost",
  password: "guest",
  username: "guest",
  virtual_host: "/"
])
```

## Supervision

The `ConnectionManager` is meant to be started as part of a supervision tree.
Therefore, it is most common to register the process with a name. The second
argument to `start_link/2` is a list of `GenServer`
[options](https://hexdocs.pm/elixir/GenServer.html#t:option/0).

See [Name Registration](https://hexdocs.pm/elixir/GenServer.html#module-name-registration)
for more details.

```elixir
...
worker(Kanin.ConnectionManager, [
  [
    host: "localhost",
    password: "guest",
    username: "guest",
    virtual_host: "/"
  ],
  [
    name: Kanin.ConnectionManager
  ]
]),
...
```

## Potential gotchas

If your application dependends on `cowboy` at `v1.x`, you may need to add a
dependency override for `ranch`:

```elixir
{:ranch, "~> 1.4", override: true}
```

It appears there are no breaking changes between `ranch` `1.3` and `1.5`.

Another issue you might come across is from a dependency on `lager`. You may
need to ensure that `lager` is started before Elixir's `logger`:

```elixir
# mix.exs
def application do
  [applications: [:lager, :logger]]
end
```

You can also silence `lager` by setting its log level to `critical`:

```elixir
config :lager,
  handlers: [level: :critical]
```

## Documentation

Documentation can be be found on [HexDocs](https://hexdocs.pm/kanin).
