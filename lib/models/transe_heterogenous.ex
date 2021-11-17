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
      ], axis: 2
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

  defp fix_shape(x, first_dimension \\ nil) do
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

  def train_model(model, data, n_epochs, n_batches, as_tsv \\ false) do
    
    model
    |> Axon.nx(&compute_loss/1) 
    |> Axon.Loop.trainer(
      fn (y_predicted, y_true) -> 
        Nx.add(y_true, y_predicted)
        |> Nx.max(0)
        |> Nx.mean
      end, :sgd
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
    |> Axon.Loop.run(data, epochs: n_epochs, iterations: n_batches) # Why effective batch-size = n_batches + epoch_index ?
  end

  def train(
    %Grapex.Init{
      model: :transe,
      n_epochs: n_epochs,
      n_batches: n_batches,
      margin: margin,
      entity_negative_rate: entity_negative_rate,
      relation_negative_rate: relation_negative_rate,
      input_size: batch_size,
      as_tsv: as_tsv
    } = params,
    hidden_size \\ 10
  ) do
    IO.puts "creating model"

    model = model(Meager.n_entities, Meager.n_relations, hidden_size, hidden_size + 5, batch_size)

    IO.puts "created model"

    data = Stream.repeatedly(
      fn ->
        params
        |> Meager.sample
        |> Models.Utils.get_positive_and_negative_triples
        |> Models.Utils.to_model_input(margin, entity_negative_rate, relation_negative_rate) 
      end
    )

    model_state = train_model(model, data, n_epochs, div(n_batches , 1), as_tsv) # FIXME: Delete div

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
  end
end
