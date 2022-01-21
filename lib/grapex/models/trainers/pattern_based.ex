defmodule Grapex.Model.Trainers.PatternBasedTrainer do
  require Axon
  alias Axon.Loop.State
  alias Grapex.IOutils, as: IO_

  defp log_metrics(
         %State{epoch: epoch, iteration: iter, metrics: metrics, step_state: pstate} = state,
         mode
       ) do
    {loss, state} =
      case mode do
        :train ->
          %{loss: loss} = pstate
          try do
            {"Loss: #{:io_lib.format('~.5f', [Nx.to_scalar(loss)])}", state}
          rescue
            # _ -> "Loss: #{Nx.to_scalar(loss |> Nx.sum)}"
            # _ -> "Loss: #{IO.inspect(loss)}"
            _ ->
              IO.inspect loss
              {
                "Loss: -", 
                %State{
                  state | step_state: case pstate[:step_state] do
                    nil -> pstate |> Map.put(:broken_loss, true)
                    false -> %{pstate | broken_loss: true}
                    _ -> pstate
                  end
                }
              } 
          end

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
      compiler_impl: compiler, lambda: lambda, margin: margin
    } = params,
    model
  ) do
    model
    |> Axon.nx(
      fn(data) ->
          model_impl.compute_loss(data, pattern: :inverse, lambda: lambda, margin: margin) # TODO: add support for both patterns - symmetric and inverse
        end
      )
      |> Axon.Loop.trainer(
        fn (_y_true, y_predicted) -> 
          y_predicted
          |> Nx.sum
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
                  {:continue,
                    %State{
                      state |
                      step_state: step_state 
                      |> Map.put(:wait_steps, 0)
                      |> Map.put(:best_loss, Nx.to_scalar(loss)) 
                    }
                  }
                {best_loss, wait_steps} ->
                  best_loss = Nx.to_scalar(best_loss)
                  wait_steps = Nx.to_scalar(wait_steps)

                  cond do
                    (loss = Nx.to_scalar(loss)) + min_delta < best_loss ->
                      state = %State{state | step_state: %{step_state | best_loss: loss, wait_steps: 0}}

                      {:continue, state}
                    wait_steps < patience ->
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
            {_, _} -> fn state -> 
                # IO.inspect state.step_state.model_state["logicenn_inner_product"]
                {:continue, state}
            end
        end
        )
        |> (
          fn(loop) ->
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
                    Grapex.Model.Operations.save({params, model, model_state})  
                    
                    {:continue, state}
                  end,
                  every: n_export_steps
                )
            end
          end
        end
      ).()
      |> Axon.Loop.run(data, epochs: n_epochs, iterations: n_batches, compiler: compiler, excluding: [:broken_loss]) # , compiler: EXLA) # Why effective batch-size = n_batches + epoch_index ?
  end

  defp sample_pattern_occurrence_for_training(params, pattern) do
    params
    |> Grapex.Meager.sample?(pattern, 1)
    |> case do
      nil -> nil
      data -> 
        data
        |> PatternOccurrence.to_tensor(params, make_true_label: fn() -> 0 end)
        |> (
          fn(batch) ->
            {{batch.entities, batch.relations}, batch.true_labels}
          end
        ).()
    end
  end

  def train(
    %Grapex.Init{
      model_impl: model_impl,
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
        [
          sample_pattern_occurrence_for_training(params, :symmetric),
          sample_pattern_occurrence_for_training(params, :inverse)
        ]
      end
    )
    |> Stream.concat
    |> Stream.filter(&(&1 != nil)) # Skip cases in which some pattern is not present in the dataset and hence such pattern occurrences cannot be generated
    |> train_model(params, model)

    case as_tsv do
      false -> IO.puts "" # makes line-break after last train message
      _ -> {:ok, nil}
    end

    {params, model, model_state} # model_state}
  end
end

