defmodule Grapex.Model.Trainers.MarginBasedTrainer do
  require Axon

  alias Axon.Loop.State
  alias Grapex.Meager.Sampler
  alias Grapex.Meager.Corpus
  alias Grapex.Trainer

  defp stringify_loss(loss) do
    # :io_lib.format('~.5f', [Nx.to_scalar(loss)])
    :io_lib.format('~.5f', [Nx.to_number(loss)])
  end

  defp get_epoch_execution_time_for_logging(%State{epoch: epoch, times: times}) do
    epoch_time = times[epoch - 1]

    case epoch_time do
      nil -> {0, 0}
      _ ->
        epoch_time =
          epoch_time
          # |> Nx.to_number
          |> Kernel./(1_000_000)

        train_time = 
          times
          # |> Enum.reduce(0, fn {_k, v}, acc -> acc + Nx.to_number(v) end)
          |> Enum.reduce(0, fn {_k, v}, acc -> acc + v end)
          |> Kernel./(1_000_000)

        {epoch_time, train_time}
    end
  end

  defp get_epoch_execution_time(%State{epoch: epoch, times: times}) do
    epoch_time = 
      times[Nx.to_number(epoch)]
      |> Kernel./(1_000_000)

    train_time = 
      times
      |> Enum.reduce(0, fn {_k, v}, acc -> acc + Nx.to_number(v) end)
      |> Kernel./(1_000_000)

    {epoch_time, train_time}
  end

  defp log_metrics(
         %State{epoch: epoch, iteration: iter, metrics: metrics, step_state: pstate} = state,
         mode
       ) do
    
    {epoch_execution_time, _} = get_epoch_execution_time_for_logging(state)

    loss =
      case mode do
        :train ->
          %{loss: loss} = pstate
          "Loss: #{stringify_loss(loss)}"

        :test ->
          ""
      end

    epoch = Nx.to_number(epoch)

    metrics =
      metrics
      |> Enum.map(fn {k, v} -> "#{k}: #{:io_lib.format('~.5f', [Nx.to_number(v)])}" end)
      |> Enum.join(" ")

    # Grapex.IOutils.clear_lines(1)
    IO.write("\rEpoch: #{epoch}, Batch: #{Nx.to_number(iter)}, #{loss} #{metrics} Execution time: #{epoch_execution_time}")

    {:continue, state}
  end

  defp train_model(
    data,
    %Grapex.Init{
      n_epochs: n_epochs, optimizer: optimizer, min_delta: min_delta, patience: patience,
      n_export_steps: n_export_steps, as_tsv: as_tsv, alpha: alpha, remove: remove, verbose: verbose, model_impl: model_impl,
      compiler_impl: compiler, batch_size: batch_size
    } = params,
    corpus,
    %Trainer{batch_size: batch_size},
    model,
    opts \\ []
  ) do
    # IO.puts '-----------------'
    # IO.inspect compiler
    n_batches =
      Corpus.count_triples!(corpus, :train, verbose)
      |> div(batch_size)

    seed = Keyword.get(opts, :seed)
    
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
      # case optimizer do # TODO: Move to a generalized module
      #   :sgd -> Axon.Optimizers.sgd(alpha)
      #   :adam -> Axon.Optimizers.adam(alpha)
      Axon.Optimizers.adamw(alpha),
      seed: seed
      #   :adagrad -> Axon.Optimizers.adagrad(alpha)
      # end
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
            scalar_epoch = Nx.to_number(epoch)
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
                    |> Map.put(:best_loss, Nx.to_number(loss)) 
                  }
                }
                # state = put_in(state[:step_state][:wait_steps], 0)

                # {:continue, state} 
              {best_loss, wait_steps} ->
                best_loss = Nx.to_number(best_loss)
                wait_steps = Nx.to_number(wait_steps)

                # IO.puts "Loss + delta = #{Nx.to_number(loss) + min_delta}; best-loss = #{best_loss}; wait_steps = #{wait_steps}"
                # IO.inspect step_state

                cond do
                  (loss = Nx.to_number(loss)) + min_delta < best_loss ->
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
      |> Axon.Loop.run(data, %{}, epochs: n_epochs, iterations: n_batches, compiler: compiler) # , compiler: EXLA) # Why effective batch-size = n_batches + epoch_index ?
  end

  def train(
    model,
    %Grapex.Init{
      model_impl: model_impl,
      margin: margin,
      pattern: pattern,
      n_observed_triples_per_pattern_instance: n_observed_triples_per_pattern_instance,
      bern: bern,
      cross_sampling: cross_sampling,
      # entity_negative_rate: entity_negative_rate,
      # relation_negative_rate: relation_negative_rate,
      as_tsv: as_tsv,
      verbose: verbose,
      n_workers: n_workers,
      sampler: sampler,
      batch_size: batch_size,
      entity_negative_rate: entity_negative_rate,
      relation_negative_rate: relation_negative_rate
    } = params,
    corpus,
    trainer,
    opts \\ []
  ) do
    # model = model_impl.model(params)

    if verbose do
      IO.puts "Model architecture:"
      IO.inspect model
    end

    IO.inspect model
    # Axon.Display.as_table(model)

    # Grapex.Meager.init_sampler!(pattern, n_observed_triples_per_pattern_instance, bern, cross_sampling, n_workers, verbose)
    Sampler.init!(sampler, verbose)

    if verbose do
      IO.puts "Completed init sampler"
    end

    # Grapex.Meager.init_evaluator!([{:count, 1}, {:count, 3}, {:count, 10}, {:count, 100}, {:count, 1000}, {:rank}, {:reciprocal_rank}], :test, verbose)

    # Grapex.Meager.import_triples!(:test, verbose)

    # params
    # |> Grapex.Meager.sample!()
    # |> PatternOccurrence.to_tensor(params, make_true_label: fn() -> margin end)
    # |> IO.inspect

    model_state = Stream.repeatedly(
      fn ->
        # IO.puts "start sampling"
        result = sampler
        |> Sampler.sample!(batch_size, entity_negative_rate, relation_negative_rate, verbose)
        |> PatternOccurrence.to_tensor(trainer, make_true_label: fn() -> margin end)
        |> (
          fn(batch) ->
            {%{"entities" => batch.entities, "relations" => batch.relations}, batch.true_labels}
          end
        ).()
        # IO.puts "stop sampling"
        result
        # |> Grapex.Meager.sample
        # |> Grapex.Models.Utils.get_positive_and_negative_triples
        # |> Grapex.Models.Utils.to_model_input(margin, entity_negative_rate, relation_negative_rate) 
      end
    )
    |> train_model(params, corpus, trainer, model, opts)

    case as_tsv do
      false -> IO.puts "" # makes line-break after last train message
      _ -> {:ok, nil}
    end

    {params, model, model_state}
  end
end
