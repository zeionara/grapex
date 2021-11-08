# Grapex

An experimental library for implementing knowledge graph embedding models using `elixir`.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `grapex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:grapex, "~> 0.1.0"}
  ]
end
```

## Usage

```sh
mix deps.get && iex -S "mix"
iex(1)> model = TransE.model(10, 2, 10)
iex(2)> TransE.run()
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/grapex](https://hexdocs.pm/grapex).

