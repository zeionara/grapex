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

Some functions from the library work in the interactive terminal (at least except `Meager.sample` which spawns multiple OS threads):

```sh
mix deps.get && iex -S "mix"
iex(1)> model = TransE.model(10, 2, 10)
iex(2)> TransE.run()
```

See scipt `main.ex` for usage examples. To run the main script of the app the following command is useful:

```sh
mix run main.ex
```

The application can be compiled into a binary and launched via command-line interface using following commands:

```sh
mix escript.build
./grapex test transe --n-epochs 100 --n-batches 16
```

To get information about available command-line parameters:

```sh
./grapex help test
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/grapex](https://hexdocs.pm/grapex).

