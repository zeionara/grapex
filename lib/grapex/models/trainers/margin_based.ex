defmodule Grapex.Model.Trainers.MarginBasedTrainer do
  require Axon
  alias Axon.Loop.State

  defp stringify_loss(loss) do
    :io_lib.format('~.5f', [Nx.to_scalar(loss)])
  end

  defp get_epoch_execution_time(%State{epoch: epoch, times: times}) do
    epoch_time = 
      times[Nx.to_scalar(epoch)]

    case epoch_time do
      nil -> {0, 0}
      _ ->
        epoch_time =
          epoch_time
          |> Kernel./(1_000_000)

        train_time = 
          times
          |> Enum.reduce(0, fn {_k, v}, acc -> acc + Nx.to_scalar(v) end)
          |> Kernel./(1_000_000)

        {epoch_time, train_time}
    end
  end

  defp log_metrics(
         %State{epoch: epoch, iteration: iter, metrics: metrics, step_state: pstate} = state,
         mode
       ) do
    
    {epoch_execution_time, _} = get_epoch_execution_time(state)

    loss =
      case mode do
        :train ->
          %{loss: loss} = pstate
          "Loss: #{stringify_loss(loss)}"

        :test ->
          ""
      end

    epoch = Nx.to_scalar(epoch)

    metrics =
      metrics
      |> Enum.map(fn {k, v} -> "#{k}: #{:io_lib.format('~.5f', [Nx.to_scalar(v)])}" end)
      |> Enum.join(" ")

    IO.write("\rEpoch: #{epoch}, Batch: #{Nx.to_scalar(iter)}, #{loss} #{metrics} Execution time: #{epoch_execution_time}")

    {:continue, state}
  end

  defp train_model(
    data,
    %Grapex.Init{
      n_epochs: n_epochs, n_batches: n_batches, optimizer: optimizer, min_delta: min_delta, patience: patience,
      n_export_steps: n_export_steps, as_tsv: as_tsv, alpha: alpha, remove: remove, verbose: verbose, model_impl: model_impl,
      compiler_impl: compiler, batch_size: batch_size
    } = params,
    model
  ) do
    # IO.puts '-----------------'
    # IO.inspect compiler
    
    loss_tracing_path = 'assets/losses/fb13-se-100-epochs.tsv'

    File.write!(loss_tracing_path, 'epoch\tloss\ttime\tcomulative_time\n', [:write])

    model
    # |> Axon.init(compiler: EXLA, client: :default)
    |> Axon.nx(fn x -> model_impl.compute_loss(x, batch_size) end)
    |> Axon.Loop.trainer(
      fn (y_true, y_predicted) -> 
        Nx.add(y_predicted, y_true)
        # Nx.add(y_predicted, 5)
        |> Nx.max(0)
        |> Nx.mean
        # Nx.subtract(y_predicted, 5)
        # y_predicted
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
      :epoch_completed,
      case as_tsv do
        true ->
          fn state -> {:continue, state} end
        _ ->
          fn %State{epoch: epoch, step_state: %{loss: loss}} = state ->
            scalar_epoch = Nx.to_scalar(epoch)
            # IO.inspect times[scalar_epoch]
            {epoch_time, train_time} = get_epoch_execution_time(state)
            # %State{epoch: epoch, step_state: %{loss: loss}, epoch_start_timestamp: epoch_start_timestamp} = state
            # {epoch_time, train_time} = case epoch_start_timestamp do
            #   nil -> {:timer.tc - train_start_timestamp, :timer.tc - train_start_timestamp}
            #   _ -> {:timer.tc - epoch_start_timestamp, :timer.tc - train_start_timestamp}
            # end
            File.write!(loss_tracing_path, '#{scalar_epoch}\t#{stringify_loss(loss)}\t#{epoch_time}\t#{train_time}\n', [:append])
            IO.puts ''
            {:continue, state}
          end
      end
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
                    Grapex.Model.Operations.save({params, model, model_state})  
                    
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
      # entity_negative_rate: entity_negative_rate,
      # relation_negative_rate: relation_negative_rate,
      as_tsv: as_tsv,
      verbose: verbose
    } = params
  ) do
    model = model_impl.model(params)

    if verbose do
      IO.puts "Model architecture:"
      IO.inspect model
    end

    # params
    # |> Grapex.Meager.sample!(nil, 0)
    # |> PatternOccurrence.to_tensor(params, make_true_label: fn() -> margin end)
    # |> IO.inspect

    model_state = Stream.repeatedly(
      fn ->
        params
        |> Grapex.Meager.sample!(nil, 0)
        |> PatternOccurrence.to_tensor(params, make_true_label: fn() -> margin end)
        |> (
          fn(batch) ->
            {{batch.entities, batch.relations}, batch.true_labels}
          end
        ).()
        # |> Grapex.Meager.sample
        # |> Grapex.Models.Utils.get_positive_and_negative_triples
        # |> Grapex.Models.Utils.to_model_input(margin, entity_negative_rate, relation_negative_rate) 
      end
    )
    |> train_model(params, model)

    case as_tsv do
      false -> IO.puts "" # makes line-break after last train message
      _ -> {:ok, nil}
    end

    {params, model, model_state}
  end
end

