defmodule Grapex.Model.Operations do
  require Axon

  @doc """
  Analyzes provided parameters and depending on the analysis results runs model testing either using test subset of a corpus either validation subset
  """
  @spec evaluate({Grapex.Init, Axon, Map}, atom, atom) :: tuple  # , list) :: tuple
  def evaluate({%Grapex.Init{task: task, reverse: reverse, tester: tester, verbose: verbose} = params, model, model_state}, task_, subset) do # , opts \\ []) do
    # IO.puts "Reverse: #{reverse}"
    # reverse = Keyword.get(opts, :reverse, false)

    Grapex.Meager.import_triples!(subset, verbose)
    Grapex.Meager.init_evaluator!([{:top_n, 1}, {:top_n, 3}, {:top_n, 10}, {:top_n, 100}, {:top_n, 1000}, {:rank}, {:reciprocal_rank}], task_, subset, verbose)

    params =
      params
      |> Grapex.Init.set_entity_negative_rate(1)
      |> Grapex.Init.set_relation_negative_rate(1)
      |> Grapex.Init.set_input_size(params.batch_size)

    case task do
      :link_prediction ->
        tester.evaluate({params, model, model_state}, subset, reverse: reverse)
        # case should_run_validation do
        #   true -> tester.validate({params, model, model_state}, reverse: reverse) # implement reverse option
        #   false -> tester.test({params, model, model_state}, reverse: reverse) 
        # end
      _ -> raise "Task #{task} is not supported"
    end
  end

  @doc """
  Saves trained model to an external file in onnx-compatible format
  """
  def save({%Grapex.Init{output_path: output_path, remove: remove, is_imported: is_imported, verbose: verbose} = params, model, model_state}) do
    case is_imported do
      true -> 
        case verbose do
          true -> IO.puts "The model was not saved because it was initialized from pre-trained tensors"
          _ -> {:ok, nil}
        end
      _ ->
        case remove do
          true -> 
            case verbose do
              true -> IO.puts "Trained model was not saved because the appropriate flag was provided"
              _ -> {:ok, nil}
            end
          _ ->
            File.mkdir_p!(Path.dirname(output_path))

            model
            |> AxonOnnx.Serialize.__export__(model_state, filename: output_path)

            case verbose do
              true -> IO.puts "Trained model is saved as #{output_path}"
              _ -> {:ok, nil}
            end
        end
    end
    {params, model, model_state}
  end
  
  @doc """
  Load model from an external file
  """
  def load(%Grapex.Init{import_path: import_path} = params) do
    [params | Tuple.to_list(AxonOnnx.Deserialize.__import__(import_path))]
    |> List.to_tuple
  end

  @doc """
  Analyzes the passed parameters object and according to the analysis results either loads trained model from an external file either trains it from scratch.
  """
  @spec train_or_import(Grapex.Init) :: tuple
  def train_or_import(%Grapex.Init{import_path: import_path, verbose: verbose, trainer: trainer} = params) do
    if verbose do
      IO.puts "Training model..."
      IO.puts "Supported computational platforms:"
      IO.inspect EXLA.NIF.get_supported_platforms()
      IO.puts "Gpu client:"
      IO.inspect EXLA.NIF.get_gpu_client(1.0, 0)
    end
    # IO.puts "Import path:"
    # IO.puts import_path
    case import_path do
      nil ->
        # trainer = Grapex.Init.get_trainer(params)
        # Grapex.Meager.import_triples!(:test, verbose)
        result = trainer.train(params)
        result
      _ ->
        {params, model, state} = load(params)
        {Grapex.Init.set_is_imported(params, true), model, state}
    end
  end
end

