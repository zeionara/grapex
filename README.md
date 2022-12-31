# Grapex

<p align="center">
    <img src="assets/images/logo.png"/>
</p>

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
TF_CPP_MIN_LOG_LEVEL=3 ./grapex test wordnet-11 --n-epochs 2 --n-batches 10000 -m logicenn -h 5 --relation-dimension 4 --entity-dimension 6 --margin 0.5 -a 0.085 -l 0.02 -c xla --max-n-test-triples 10 -rt
```

To get information about available command-line parameters:

```sh
./grapex help test
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/grapex](https://hexdocs.pm/grapex).

