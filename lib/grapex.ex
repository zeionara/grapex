defmodule Grapex.Macros do
  defmacro choice(alternatives, as: kind) do
    quote do
      fn(chosen_alternative) ->
        if Enum.member?(unquote(alternatives), chosen_alternative) do # "adagrad", "adadelta" - adadelta is not implemented in the axon library, adagrad is implemented but doesn't work
          {
            :ok,
            chosen_alternative
            |> String.downcase
            |> String.replace("-", "_")
            |> String.to_atom
          }
        else
          {:error, unquote(String.capitalize(kind)) <> " #{chosen_alternative} is not (yet) supported"}
        end
      end
    end
  end
end

defmodule Grapex do
  import Grapex.Macros
  @moduledoc """
  Documentation for `Grapex`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Grapex.hello()
      :world

  """

  def main(argv) do
    # params =
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
            input_path: [
              value_name: "INPUT_PATH",
              help: "Path to dataset with input data for training and testing provided model",
              required: true,
              parser: fn path ->
                case path do
                  "/" <> _ = absolute_path -> {:ok, %{absolute: absolute_path, relative: nil}}
                  _ -> {:ok, %{absolute: "#{Path.join([Application.get_env(:grapex, :relentness_root), "Assets/Corpora", path])}/", relative: path}}
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
              long: "--entity-neg-rate",
              parser: :integer,
              required: false,
              default: 1
            ],
            relation_negative_rate: [
              value_name: "RELATION_NEGATIVE_RATE",
              help: "Number of negative triples generated per positive triple during training by corrupting a relation",
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
              default: 10
            ],
            n_workers: [
              value_name: "N_WORKERS",
              help: "Number of workers which run in separate processes during batch generation",
              short: "-n",
              long: "--n-workers",
              parser: :integer,
              required: false,
              default: 8
            ],
            relation_dimension: [
              value_name: "RELATION_DIMENSION",
              help: "Size of vector for representing relation types in the knowledge graph",
              long: "--relation-dimension",
              parser: :integer,
              required: false,
              default: nil
            ],
            entity_dimension: [
              value_name: "ENTITY_DIMENSION",
              help: "Size of vector for representing entities in the knowledge graph",
              long: "--entity-dimension",
              parser: :integer,
              required: false,
              default: nil
            ],
            output_path: [
              value_name: "OUTPUT_PATH",
              help: "Path for saving a trained model",
              short: "-o",
              long: "--output",
              parser: :string,
              required: false,
              default: nil
            ],
            import_path: [
              value_name: "IMPORT_PATH",
              help: "Path for importing a trained model (if given, the train step is skipped and model proceeds to testing right away)",
              short: "-i",
              long: "--import-path",
              parser: :string,
              required: false,
              default: nil
            ],
            export_path: [
              value_name: "EXPORT_PATH",
              help: "Path for saving a trained model (the same as output-path)",
              short: "-x",
              long: "--export-path",
              parser: :string,
              required: false,
              default: nil
            ],
            seed: [
              value_name: "SEED",
              help: "Random seed which must be passed to guarantee the reproducibility of the results",
              short: "-s",
              long: "--seed",
              parser: :integer,
              required: false,
              default: nil
            ],
            margin: [
              value_name: "MARGIN",
              help: "Target margin between scores generated by model for positive and negative triples",
              long: "--margin",
              parser: :float,
              required: false,
              default: 5.0
            ],
            alpha: [
              value_name: "ALPHA",
              help: "(Initial) learning rate for the model optimizer",
              short: "-a",
              long: "--alpha",
              parser: :float,
              required: false,
              default: 0.1
            ],
            lambda: [
              value_name: "LAMBDA",
              help: "Scale of the regularization term in the model loss function",
              short: "-l",
              long: "--lambda",
              parser: :float,
              required: false,
              default: 0.0 # No regularization by default
            ],
            optimizer: [
              value_name: "OPTIMIZER",
              help: "Optimizer type for tuning model parameter during training",
              long: "--optimizer",
              parser: choice(["sgd", "adam"], as: "optimizer"),
              required: false,
              default: :sgd
            ],
            task: [
              value_name: "TASK",
              help: "Task to test a model on",
              long: "--task",
              parser: choice(["link-prediction"], as: "task"), # "triple-classification"
              required: false,
              default: :link_prediction
            ],
            min_delta: [
              value_name: "MIN_DELTA",
              help: "Minimum loss decrease per epoch which is allowed for model to continue training",
              short: "-d",
              long: "--min-delta",
              parser: :float,
              required: false,
              default: nil
            ],
            patience: [
              value_name: "PATIENCE",
              help: "Maximum number of iterations for which model will train without sufficient loss decrease",
              short: "-p",
              long: "--patience",
              parser: :integer,
              required: false,
              default: nil
            ],
            n_export_steps: [
              value_name: "N_EXPORT_STEPS",
              help: "Number of epochs after which new file with serialized model will repeatedly be generated",
              long: "--n-export-steps",
              parser: :integer,
              required: false,
              default: nil
            ]
          ],
          flags: [
            as_tsv: [
              short: "-t",
              long: "--as-tsv",
              help: "Whether the program should output just a concise summary of computed metrics",
              multiple: false
            ],
            remove: [
              short: "-r",
              long: "--remove",
              help: "Do not preserve trained model files on the disk",
              multiple: false
            ],
            verbose: [
              short: "-v",
              long: "--verbose",
              help: "Enable increased amount of information printed by the system during execution",
              multiple: false
            ],
            validate: [
              long: "--validate",
              help: "Use data from validation subset",
              multiple: false
            ],
            bern: [
              long: "--bern",
              help: "Sample negative triples proportionally to the number of entity appearances in the train subset",
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
      |> Grapex.Init.init_randomizer
      |> case do
        # %Grapex.Init{model: :transe, entity_dimension: entity_dimension, relation_dimension: relation_dimension} = params when entity_dimension == relation_dimension ->
        #   IO.inspect params.output_path
        #   params
        #   |> TransE.train
        #   |> TransE.test
        %Grapex.Init{model: :transe} = params ->
          params
          |> TranseHeterogenous.train_or_import
          |> TranseHeterogenous.test_or_validate
          |> TranseHeterogenous.save # TODO: is not required if model was imported 
        %Grapex.Init{model: model} -> raise "Model #{model} is not available"
      end
  end
end

