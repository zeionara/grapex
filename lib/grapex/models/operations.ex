defmodule Grapex.Model.Operations do

  alias Grapex.Meager.Corpus
  alias Grapex.Meager.Evaluator
  alias Grapex.Model

  alias Grapex.Config
  alias Grapex.Checkpoint
  alias Grapex.Trainer
  alias Grapex.State

  @doc """
  Analyzes provided parameters and depending on the analysis results runs model testing either using test subset of a corpus either validation subset
  """
  @spec evaluate({Grapex.Init, Axon, Map, Map}, atom, list) :: tuple
  def evaluate(
    %State{
      config: %Grapex.Config{
        model: %Model{
          model: model_type
        },
        corpus: corpus,
        evaluator: %Evaluator{
          task: task
        } = evaluator
      }
    } = state,
    subset,
    opts \\ []
  ) do
    Corpus.import_triples!(corpus, subset, opts)
    Evaluator.init!(evaluator, subset, opts)

    case task do
      :link_prediction ->
        case model_type do
          :transe -> Grapex.Models.Testers.EntityBased.evaluate(state, subset, opts) # , reverse: reverse)
          _ -> raise "Unknown model"
        end
      _ -> raise "Task #{task} is not supported"
    end
  end

  @doc """
  Saves trained model to an external file in onnx-compatible format
  """
  def save(
    %State{
      config: %Config{
        checkpoint: checkpoint
      },
      weights: model_state,
    } = state,
    opts \\ []
  ) do
    verbose = Keyword.get(opts, :verbose, false)
    format = Keyword.get(opts, :format, :binary)

    case checkpoint do
      nil ->
        case verbose do
          true -> IO.puts "Trained model was not saved because the checkpoint configuration was not provided"
          _ -> {:ok, nil}
        end
      _ ->
        path = Checkpoint.path(checkpoint, format)

        path
        |> Path.dirname
        |> File.mkdir_p!

        case format do
          :binary -> 
            File.write! path, Nx.serialize(model_state)
          _ -> raise "Unsupported format #{format}"
        end

        case verbose do
          true -> IO.puts "Trained model is saved as #{path}"
          _ -> {:ok, nil}
        end
    end

    state
  end

  def load(
    %Config{
      checkpoint: checkpoint,
    } = config,
    opts \\ []
  ) do
    verbose = Keyword.get(opts, :verbose, false)
    format = Keyword.get(opts, :format, :binary)

    model_state = case checkpoint do
      nil -> raise "Cannot load model from null checkpoint"
      _ ->
        path = Checkpoint.path(checkpoint, format)

        path
        |> Path.dirname
        |> File.mkdir_p!

        model_state = case format do
          :binary -> 
            Nx.deserialize File.read!(path)
          _ -> raise "Unsupported format #{format}"
        end

        case verbose do
          true -> IO.puts "Loaded trained model from #{path}"
          _ -> {:ok, nil}
        end

        model_state
    end

    {model_instance, model_module} = Model.init(config, opts)

    %State{config: config, instance: model_instance, weights: model_state, module: model_module}
  end
  
  @doc """
  Analyzes the passed parameters object and according to the analysis results either loads trained model from an external file either trains it from scratch.
  """
  @spec train(Grapex.Config, list) :: tuple
  def train(%Config{corpus: corpus} = config, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, false)

    corpus
    |> Corpus.init!(opts)
    |> Corpus.import_filter!(opts)
    |> Corpus.import_pattern!(opts)
    |> Corpus.import_types!(opts)
    |> Corpus.import_triples!(:train, opts)

    if verbose do
      IO.puts "Training model..."
      IO.puts "Supported computational platforms:"
      IO.inspect EXLA.NIF.get_supported_platforms()
      IO.puts "Gpu client:"
      IO.inspect EXLA.NIF.get_gpu_client(1.0, 0)
    end

    Model.init(config, opts)
    |> Trainer.train(config, opts)

  end
end
