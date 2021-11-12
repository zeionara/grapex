defmodule Grapex do
  @moduledoc """
  Documentation for `Grapex`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Grapex.hello()
      :world

  """
  def hello do
    :world
  end

  def main(argv) do
    Optimus.new!(
      name: "grapex",
      description: "Graph embeddings management toolkit",
      version: "0.7.0",
      author: "Zeio Nara zeionara@gmail.com",
      about: "A tool for testing graph embedding models",
      allow_unknown_args: false,
      parse_double_dash: true,
      subcommands: [
        test: [
          name: "test",
          about: "Runs model training and subsequent testings, print resulting metric values",
          args: [
            model: [
              value_name: "MODEL",
              help: "Model type to use",
              required: true,
              parser: :atom
            ]
          ]
        ]
      ]
    ) |> Optimus.parse!(argv) |> IO.inspect
  end
end
