# Kanin

> AMQP connection manager

## Naming

Kanin is Swedish for rabbit.

## Installation

The package can be installed by adding `kanin` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:kanin, "~> 1.0"}]
end
```

And placing a worker in your supervision tree:

```elixir
worker(Kanin.ConnectionManager, [connection_opts(), name: Kanin.ConnectionManager])
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/kanin](https://hexdocs.pm/kanin).
