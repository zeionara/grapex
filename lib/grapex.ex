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
    params = Optimus.new!(
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
            input_path: [
              value_name: "INPUT_PATH",
              help: "Path to dataset with input data for training and testing provided model",
              required: true,
              parser: fn path ->
                case path do
                  "/" <> _ = absolute_path -> {:ok, absolute_path}
                  _ -> {:ok, "#{Path.join([Application.get_env(:grapex, :relentness_root), "Assets/Corpora", path])}/"}
                end
              end
            ]
          ],
          options: [
            n_epochs: [
              value_name: "N_EPOCHS",
              help: "Number of epochs to perform training for",
              short: "-e",
              long: "--n-epochs",
              parser: :integer,
              required: false,
              default: 100
            ],
            n_batches: [
              value_name: "N_BATCHES",
              help: "Number of batches to pass during training per epoch",
              short: "-b",
              long: "--n-batches",
              parser: :integer,
              required: false,
              default: 10
            ],
            entity_negative_rate: [
              value_name: "ENTITY_NEGATIVE_RATE",
              help: "Number of negative triples generated per positive triple during training by corrupting an entity",
              short: "-x",
              long: "--entity-neg-rate",
              parser: :integer,
              required: false,
              default: 1
            ],
            relation_negative_rate: [
              value_name: "RELATION_NEGATIVE_RATE",
              help: "Number of negative triples generated per positive triple during training by corrupting a relation",
              short: "-r",
              long: "--relation-neg-rate",
              parser: :integer,
              required: false,
              default: 0
            ],
            model: [
              value_name: "MODEL",
              help: "Model type to use",
              short: "-m",
              long: "--model",
              parser: fn(model) ->
                case Grapex.Init.get_model_by_name(model) do
                  {:error, _} = error -> error
                  model -> {:ok, model}
                end
              end,
              required: true
            ],
            hidden_size: [
              value_name: "HIDDEN_SIZE",
              help: "Number of neurons per hidden layer in the network",
              short: "-h",
              long: "--hidden-size",
              parser: :integer,
              required: false,
              default: 1
            ],
            n_workers: [
              value_name: "N_WORKERS",
              help: "Number of workers which run in separate processes during batch generation",
              short: "-n",
              long: "--n-workers",
              parser: :integer,
              required: false,
              default: 1
            ],
            relation_dimension: [
              value_name: "RELATION_DIMENSION",
              help: "Size of vector for representing relation types in the knowledge graph",
              short: "-d",
              long: "--relation-dimension",
              parser: :integer,
              required: false,
              default: 1
            ],
            entity_dimension: [
              value_name: "ENTITY_DIMENSION",
              help: "Size of vector for representing entities in the knowledge graph",
              short: "-y",
              long: "--entity-dimension",
              parser: :integer,
              required: false,
              default: 1
            ]
          ],
          flags: [
            as_tsv: [
              short: "-t",
              long: "--as-tsv",
              help: "Whether the program should output just a concise summary of computed metrics",
              multiple: false
            ]
          ]
        ]
      ]
      )
      |> Optimus.parse!(argv)
      |> Grapex.Init.from_cli_params
      |> Grapex.Init.init_meager
      |> Grapex.Init.init_computed_params
      |> case do
        %Grapex.Init{model: :transe, entity_dimension: entity_dimension, relation_dimension: relation_dimension} = params when entity_dimension == relation_dimension ->
          params
          |> TransE.train
          |> TransE.test
        %Grapex.Init{model: :transe} = params ->
          params
          |> TranseHeterogenous.train
          |> TranseHeterogenous.test
        %Grapex.Init{model: model} -> raise "Model #{model} is not available"
      end
  end
end

