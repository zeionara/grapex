defmodule TranseHeterogenous do
  require Axon
  alias Axon.Loop.State

  def entity_embeddings(x, vocab_size, embedding_size) do
    Axon.embedding(x, vocab_size, embedding_size)
  end

  def relation_embeddings(x, vocab_size, embedding_size) do
    Axon.embedding(x, vocab_size, embedding_size)
  end
   
  def model(n_entities, n_relations, entity_embedding_size, relation_embedding_size, batch_size \\ 16) do
    entity_embeddings_ = Axon.input({nil, batch_size, 2})
                         |> entity_embeddings(n_entities, entity_embedding_size)
                         # |> Axon.pad([{0, 0}, {max(0, relation_embedding_size - entity_embedding_size), 0}])

    size_difference = entity_embedding_size - relation_embedding_size

    entity_vs_relation_size_difference = max(0, size_difference)
    relation_vs_entity_size_difference = max(0, -size_difference)

    entity_embeddings_ = case relation_vs_entity_size_difference do
      
      non_zero_value when non_zero_value > 0 -> 
        entity_embeddings_missing_dimensions = entity_embeddings_
                                               |> Axon.flatten
                                               |> Axon.dense(relation_vs_entity_size_difference * 2 * batch_size)
                                               |> Axon.reshape({batch_size, 2, relation_vs_entity_size_difference})
        Axon.concatenate(
          [
            entity_embeddings_,
            entity_embeddings_missing_dimensions
          ],
          axis: 3
        )

      _ -> entity_embeddings_
    end

    relation_embeddings_ = Axon.input({nil, batch_size, 1})
                         |> relation_embeddings(n_relations, relation_embedding_size)
                         # |> IO.inspect

    relation_embeddings_ = case entity_vs_relation_size_difference do
      non_zero_value when non_zero_value > 0 ->
        relation_embeddings_missing_dimensions = relation_embeddings_
                                                 |> Axon.flatten
                                                 |> Axon.dense(entity_vs_relation_size_difference * batch_size)
                                                 |> Axon.reshape({batch_size, 1, entity_vs_relation_size_difference})

        Axon.concatenate(
          [
            relation_embeddings_,
            relation_embeddings_missing_dimensions
          ],
          axis: 3
        )

      _ -> relation_embeddings_
    end

    Axon.concatenate(
      [
        entity_embeddings_,
        relation_embeddings_
      ], axis: 2, name: "transe"
    )
  end

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

  defp fix_shape(x, first_dimension) do
  # defp fix_shape(x, first_dimension \\ nil) do
    case {x, first_dimension} do
      {%{shape: {_, _, _}}, 1} -> Nx.new_axis(x, 0)
      {%{shape: {_, _, _}}, _} -> 
        # for _ <- 1..first_dimension do
        #   Nx.new_axis(x, 0)
        # end
        # |> Nx.concatenate
        Nx.new_axis(x, 0)
        |> Nx.tile([first_dimension, 1, 1, 1])
      _ -> x
    end
  end

  # defp fix_shape(x, _ \\ nil) do
  #   x
  # end

  def compute_score(x) do
    Nx.add(Nx.slice_axis(x, 0, 1, 2), Nx.slice_axis(x, 1, 1, 2))
    |> Nx.subtract(Nx.slice_axis(x, 2, 1, 2))
    |> Nx.abs
    |> Nx.sum(axes: [-1])
    |> Nx.squeeze(axes: [-1])
  end 

  def compute_loss(x) do
    fixed_x = fix_shape(x, 2)

    Nx.slice_axis(fixed_x, 0, 1, 0)
    |> compute_score
    |> Nx.flatten
    |> Nx.subtract(
       Nx.slice_axis(fixed_x, 1, 1, 0)
       |> compute_score
       |> Nx.flatten
    )
  end 

  def train_model(
    data,
    %Grapex.Init{
      n_epochs: n_epochs, n_batches: n_batches, optimizer: optimizer, min_delta: min_delta, patience: patience,
      n_export_steps: n_export_steps, as_tsv: as_tsv, alpha: alpha, remove: remove, verbose: verbose
    } = params,
    model
  ) do
    model
    |> Axon.nx(&compute_loss/1) 
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
      |> Axon.Loop.run(data, epochs: n_epochs, iterations: n_batches) # Why effective batch-size = n_batches + epoch_index ?
  end

  def train(
    %Grapex.Init{
      model: :transe,
      # n_epochs: n_epochs,
      # n_batches: n_batches,
      margin: margin,
      # alpha: alpha,
      entity_negative_rate: entity_negative_rate,
      relation_negative_rate: relation_negative_rate,
      input_size: batch_size,
      as_tsv: as_tsv,
      entity_dimension: entity_dimension,
      relation_dimension: relation_dimension,
      # optimizer: optimizer,
      # lambda: lambda,
      # min_delta: min_delta,
      # patience: patience,
      # n_export_steps: n_export_steps
    } = params
  ) do
    model = model(Meager.n_entities, Meager.n_relations, entity_dimension, relation_dimension, batch_size)

    model_state = Stream.repeatedly(
      fn ->
        params
        |> Meager.sample
        |> Models.Utils.get_positive_and_negative_triples
        |> Models.Utils.to_model_input(margin, entity_negative_rate, relation_negative_rate) 
      end
    )
    |> train_model(params, model)

    case as_tsv do
      false -> IO.puts "" # makes line-break after last train message
      _ -> {:ok, nil}
    end

    # Axon.predict(model, model_state, {Nx.tensor([for _ <- 1..batch_size do [0, 1] end ]), Nx.tensor([for _ <- 1..batch_size do [0] end ])})
    # |> compute_score
    # |> Nx.mean
    # |> IO.inspect

    # Axon.predict(model, model_state, {Nx.tensor([for _ <- 1..batch_size do [0, 5] end ]), Nx.tensor([for _ <- 1..batch_size do [0] end ])})
    # |> compute_score
    # |> Nx.mean
    # |> IO.inspect

    {params, model, model_state}
  end

  defp generate_predictions_for_testing(batches, model, state) do
    Axon.predict(model, state, batches)
    |> compute_score
    |> Nx.flatten
  end

  def test({params, model, model_state}) do
    Meager.init_testing

    for _ <- 1..Meager.n_test_triples do
      Meager.sample_head_batch
      |> Models.Utils.to_model_input_for_testing(params.input_size)
      |> generate_predictions_for_testing(model, model_state)
      |> Nx.slice([0], [Meager.n_entities])
      |> Nx.to_flat_list
      |> Meager.test_head_batch

      Meager.sample_tail_batch
      |> Models.Utils.to_model_input_for_testing(params.input_size)
      |> generate_predictions_for_testing(model, model_state)
      |> Nx.slice([0], [Meager.n_entities])
      |> Nx.to_flat_list
      |> Meager.test_tail_batch
    end

    Meager.test_link_prediction(params.as_tsv)

    {params, model, model_state}
  end

  def validate({%Grapex.Init{verbose: verbose} = params, model, model_state}) do
    Meager.init_testing

    n_triples = Meager.n_valid_triples

    case verbose do
      true -> IO.puts "Total number of validation triples: #{n_triples}"
      _ -> {:ok, nil}
    end 

    for _ <- 1..n_triples do
      Meager.sample_validation_head_batch
      |> Models.Utils.to_model_input_for_testing(params.input_size)
      |> generate_predictions_for_testing(model, model_state)
      |> Nx.slice([0], [Meager.n_entities])
      |> Nx.to_flat_list
      |> Meager.validate_head_batch

      Meager.sample_validation_tail_batch
      |> Models.Utils.to_model_input_for_testing(params.input_size)
      |> generate_predictions_for_testing(model, model_state)
      |> Nx.slice([0], [Meager.n_entities])
      |> Nx.to_flat_list
      |> Meager.validate_tail_batch
    end

    Meager.test_link_prediction(params.as_tsv)

    {params, model, model_state}
  end

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

  def load(%Grapex.Init{import_path: import_path} = params) do
    [params | Tuple.to_list(AxonOnnx.Deserialize.__import__(import_path))]
    |> List.to_tuple
  end

  def train_or_import(%Grapex.Init{import_path: import_path} = params) do
    case import_path do
      nil -> train(params)
      _ ->
        {params, model, state} = load(params)
        {Grapex.Init.set_is_imported(params, true), model, state}
    end
  end
end

