defmodule Grapex.Model.Operations do
  require Axon
  alias Axon.Loop.State

  defp log_metrics(
         %State{epoch: epoch, iteration: iter, metrics: metrics, step_state: pstate} = state,
         mode
       ) do
    loss =
      case mode do
        :train ->
          %{loss: loss} = pstate
          "Loss: #{:io_lib.format('~.5f', [Nx.to_scalar(loss)])}"

        :test ->
          ""
      end

    epoch = Nx.to_scalar(epoch)

    metrics =
      metrics
      |> Enum.map(fn {k, v} -> "#{k}: #{:io_lib.format('~.5f', [Nx.to_scalar(v)])}" end)
      |> Enum.join(" ")

    IO.write("\rEpoch: #{epoch}, Batch: #{Nx.to_scalar(iter)}, #{loss} #{metrics}")

    {:continue, state}
  end

  defp train_model(
    data,
    %Grapex.Init{
      n_epochs: n_epochs, n_batches: n_batches, optimizer: optimizer, min_delta: min_delta, patience: patience,
      n_export_steps: n_export_steps, as_tsv: as_tsv, alpha: alpha, remove: remove, verbose: verbose, model_impl: model_impl,
      compiler_impl: compiler
    } = params,
    model
  ) do
    model
    # |> Axon.init(compiler: EXLA, client: :default)
    |> Axon.nx(&model_impl.compute_loss/1) 
    |> Axon.Loop.trainer(
      fn (y_predicted, y_true) -> 
        Nx.add(y_true, y_predicted)
        |> Nx.max(0)
        |> Nx.mean
      end,
      case optimizer do # TODO: Move to a generalized module
        :sgd -> Axon.Optimizers.sgd(alpha)
        :adam -> Axon.Optimizers.adam(alpha)
        :adagrad -> Axon.Optimizers.adagrad(alpha)
      end
    )
    |> Axon.Loop.handle(
      :iteration_completed,
      case as_tsv do
        true ->
          fn state -> {:continue, state} end
        _ -> &log_metrics(&1, :train)
      end,
      every: 2
    )
    |> Axon.Loop.handle(
      :iteration_completed,
      case {min_delta, patience} do
        {min_delta, patience} when min_delta != nil and patience != nil ->
          fn(%State{step_state: %{loss: loss} = step_state} = state) ->
            case {step_state[:best_loss], step_state[:wait_steps]} do
              {nil, nil} ->
                # step_state = Map.put(step_state, :best_loss, loss)
                # state = %State{state | step_state: step_state}
                # state = put_in(state[:step_state][:best_loss], loss)
                # IO.puts "No best loss in state"
                # IO.inspect state, structs: false
                {:continue,
                  %State{
                    state |
                    step_state: step_state 
                    |> Map.put(:wait_steps, 0)
                    |> Map.put(:best_loss, Nx.to_scalar(loss)) 
                  }
                }
                # state = put_in(state[:step_state][:wait_steps], 0)

                # {:continue, state} 
              {best_loss, wait_steps} ->
                best_loss = Nx.to_scalar(best_loss)
                wait_steps = Nx.to_scalar(wait_steps)

                # IO.puts "Loss + delta = #{Nx.to_scalar(loss) + min_delta}; best-loss = #{best_loss}; wait_steps = #{wait_steps}"
                # IO.inspect step_state

                cond do
                  (loss = Nx.to_scalar(loss)) + min_delta < best_loss ->
                    # state = put_in(state[:step_state][:best_loss], loss)
                    # state = %State{state | step_state: step_state = %{step_state | best_loss: loss}}
                    # state = put_in(state[:step_state][:wait_steps], 0)
                    # state = %State{state | step_state: %{step_state | wait_steps: 0}}
                    state = %State{state | step_state: %{step_state | best_loss: loss, wait_steps: 0}}

                    {:continue, state}
                  wait_steps < patience ->
                    # state = put_in(state[:step_state][:wait_steps], wait_steps + 1)
                    state = %State{state | step_state: %{step_state | wait_steps: wait_steps + 1}}

                    {:continue, state}
                  true -> 
                    if as_tsv == false do
                      IO.puts "Stop training since loss was not improving for #{wait_steps} iterations"
                    end

                    {:halt_loop, state}
                end
            end
          end
        {_, _} -> fn state -> {:continue, state} end
      end
      )
      |> (
        fn(loop) ->
          # IO.puts "Choosing appropriate saver..."
          if remove do
            if verbose and n_export_steps != nil do
              IO.puts "The model will not be saved during training because model saving has been explicitly disabled" 
            end

            loop
          else
            case n_export_steps do
              nil -> 
                if verbose do
                  IO.puts "The model will not be saved during training because n-export-steps parameter has not been provided."
                end

                loop
              _ ->
                if verbose do
                  IO.puts "The model will be refreshed on disk after every #{n_export_steps} epochs"
                end

                Axon.Loop.handle(
                  loop,
                  :epoch_completed,
                  fn %State{step_state: %{model_state: model_state}} = state ->
                    if verbose do
                      IO.puts "Refreshing model on disk..."
                    end
                    save({params, model, model_state})  
                    
                    {:continue, state}
                  end,
                  every: n_export_steps
                )
            end
          end
        end
      ).()
      |> Axon.Loop.run(data, epochs: n_epochs, iterations: n_batches, compiler: compiler) # , compiler: EXLA) # Why effective batch-size = n_batches + epoch_index ?
  end

  def train(
    %Grapex.Init{
      model_impl: model_impl,
      margin: margin,
      entity_negative_rate: entity_negative_rate,
      relation_negative_rate: relation_negative_rate,
      as_tsv: as_tsv,
      verbose: verbose
    } = params
  ) do
    model = model_impl.model(params)

    if verbose do
      IO.puts "Model architecture:"
      IO.inspect model
    end

    model_state = Stream.repeatedly(
      fn ->
        params
        |> Grapex.Meager.sample
        |> Grapex.Models.Utils.get_positive_and_negative_triples
        |> Grapex.Models.Utils.to_model_input(margin, entity_negative_rate, relation_negative_rate) 
      end
    )
    |> train_model(params, model)

    case as_tsv do
      false -> IO.puts "" # makes line-break after last train message
      _ -> {:ok, nil}
    end


    {params, model, model_state}
  end

  defp generate_predictions_for_testing(batches, model_impl, model, state) do
    Axon.predict(model, state, batches)
    |> model_impl.compute_score
    |> Nx.flatten
  end

  def test({%Grapex.Init{model_impl: model_impl} = params, model, model_state}) do
    Grapex.Meager.init_testing

    for _ <- 1..Grapex.Meager.n_test_triples do
      Grapex.Meager.sample_head_batch
      |> Grapex.Models.Utils.to_model_input_for_testing(params.input_size)
      |> generate_predictions_for_testing(model_impl, model, model_state)
      |> Nx.slice([0], [Grapex.Meager.n_entities])
      |> Nx.to_flat_list
      # |> IO.inspect
      |> Grapex.Meager.test_head_batch

      Grapex.Meager.sample_tail_batch
      |> Grapex.Models.Utils.to_model_input_for_testing(params.input_size)
      |> generate_predictions_for_testing(model_impl, model, model_state)
      |> Nx.slice([0], [Grapex.Meager.n_entities])
      |> Nx.to_flat_list
      |> Grapex.Meager.test_tail_batch
    end

    Grapex.Meager.test_link_prediction(params.as_tsv)

    {params, model, model_state}
  end

  def validate({%Grapex.Init{verbose: verbose, model_impl: model_impl} = params, model, model_state}) do
    Grapex.Meager.init_testing

    n_triples = Grapex.Meager.n_valid_triples

    case verbose do
      true -> IO.puts "Total number of validation triples: #{n_triples}"
      _ -> {:ok, nil}
    end 

    for _ <- 1..n_triples do
      Grapex.Meager.sample_validation_head_batch
      |> Grapex.Models.Utils.to_model_input_for_testing(params.input_size)
      |> generate_predictions_for_testing(model_impl, model, model_state)
      |> Nx.slice([0], [Grapex.Meager.n_entities])
      |> Nx.to_flat_list
      |> Grapex.Meager.validate_head_batch

      Grapex.Meager.sample_validation_tail_batch
      |> Grapex.Models.Utils.to_model_input_for_testing(params.input_size)
      |> generate_predictions_for_testing(model_impl, model, model_state)
      |> Nx.slice([0], [Grapex.Meager.n_entities])
      |> Nx.to_flat_list
      |> Grapex.Meager.validate_tail_batch
    end

    Grapex.Meager.test_link_prediction(params.as_tsv)

    {params, model, model_state}
  end

  @doc """
  Analyzes provided parameters and depending on the analysis results runs model testing either using test subset of a corpus either validation subset
  """
  @spec test_or_validate({Grapex.Init, Axon, Map}) :: tuple
  def test_or_validate({%Grapex.Init{validate: should_run_validation, task: task} = params, model, model_state}) do
    case task do
      :link_prediction ->
        case should_run_validation do
          true -> validate({params, model, model_state})
          false -> test({params, model, model_state}) 
        end
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
  def train_or_import(%Grapex.Init{import_path: import_path, verbose: verbose} = params) do
    if verbose do
      IO.puts "Supported computational platforms:"
      IO.inspect EXLA.NIF.get_supported_platforms()
      IO.puts "Gpu client:"
      IO.inspect EXLA.NIF.get_gpu_client(1.0, 0)
    end
    case import_path do
      nil -> train(params)
      _ ->
        {params, model, state} = load(params)
        {Grapex.Init.set_is_imported(params, true), model, state}
    end
  end
end

