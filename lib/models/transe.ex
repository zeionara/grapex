defmodule TransE do
  require Axon
  alias Axon.Loop.State

  def entity_embeddings(x, vocab_size, embedding_size) do
    Axon.embedding(x, vocab_size, embedding_size)
  end

  def relation_embeddings(x, vocab_size, embedding_size) do
    Axon.embedding(x, vocab_size, embedding_size)
  end

  # def residual(x, units) do
  #   x
  #   |> Axon.dense(units, activation: :relu)
  #   |> Axon.add(x)
  # end

  def batch do
    tensor = Nx.tensor(
      [
        [0, 0, 1],
        [1, 0, 0],
        [2, 0, 3],
        [3, 0, 2]
      ],
      names: [:rows, :cols]
    )

    # {
    #   tensor[rows: 0..3, cols: 0],
    #   tensor[rows: 0..3, cols: 1],
    #   tensor[rows: 0..3, cols: 2]
    # } 

    samples = [
      heads: Nx.reshape(tensor[rows: 0..3, cols: 0], {4, 1}),
      tails: Nx.reshape(tensor[rows: 0..3, cols: 2], {4, 1}),
      relations: Nx.reshape(tensor[rows: 0..3, cols: 1], {4, 1}),
      reference: Nx.tensor(for _ <- 1..4, do: [0])
    ] 

    {
      { samples[:heads], samples[:tails], samples[:relations] },
      samples[:reference]
    }
  end
   
  def model(n_entities, n_relations, hidden_size, batch_size \\ 16) do
    entity_embeddings_ = Axon.input({nil, batch_size, 2})
                         |> entity_embeddings(n_entities, hidden_size)

    relation_embeddings_ = Axon.input({nil, batch_size, 1})
                         |> relation_embeddings(n_relations, hidden_size)

    Axon.concatenate([entity_embeddings_, relation_embeddings_], axis: 2)
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

    epoch = Nx.to_scalar(state.epoch)

    metrics =
      metrics
      |> Enum.map(fn {k, v} -> "#{k}: #{:io_lib.format('~.5f', [Nx.to_scalar(v)])}" end)
      |> Enum.join(" ")

    IO.write("\rEpoch: #{epoch}, Batch: #{Nx.to_scalar(iter)}, #{loss} #{metrics}")
    # IO.puts "#{Nx.to_scalar(iter)}"
    
    # IO.inspect(state, structs: false)
    # IO.inspect(iter)

    # state = %State{state | max_iteration: Nx.subtract(state.max_iteration, state.epoch)}
    # state = case Nx.to_scalar(iter) do
    #   2 when epoch > 0 -> %State{state | max_iteration: Nx.subtract(state.max_iteration, 1)}
    #   _ -> state
    # end

    # IO.inspect(Map.take(state, [:iteration, :max_iteration]))

    {:continue, state}
  end

  defp fix_shape(%{shape: {_, _, _}} = x) do
    Nx.new_axis(x, 0)
    # Nx.reshape(x, {1, a, b, c})
  end

  defp fix_shape(x) do
    x
  end

  def compute_score(x, verbose \\ false) do
    # heads = Nx.slice_axis(x, 0, 1, 2)
    #         |> Nx.squeeze 
    # tails = Nx.slice_axis(x, 1, 1, 2)
    #         |> Nx.squeeze
    # relations = Nx.slice_axis(x, 2, 1, 2)
    #             |> Nx.squeeze

    case verbose do
      true ->
        # x |> IO.inspect(structs: false)
        # x = case x.shape do
        #   {a, b, c} -> Nx.reshape(x, {1, a, b, c})
        #   _ -> x
        # end
        # Nx.slice_axis(x, 0, 1, 2) |> IO.inspect
        x = fix_shape(x)
        Nx.add(Nx.slice_axis(x, 0, 1, 2), Nx.slice_axis(x, 1, 1, 2))
        |> Nx.subtract(Nx.slice_axis(x, 2, 1, 2))
        |> Nx.abs
        |> Nx.mean(axes: [-1])
        |> Nx.squeeze(axes: [-1])
        # |> IO.inspect
      _ -> {:ok, nil}
    end
    # IO.puts "heads embs"
    # Nx.add(heads, relations)
    # # |> Nx.subtract(tails)
    # # |> Nx.abs
    # |> IO.inspect

    # Nx.add(heads, relations)
    # |> Nx.subtract(tails)
    # |> Nx.abs
    # |> Nx.sum(axes: [-1])

    x = fix_shape(x)
    Nx.add(Nx.slice_axis(x, 0, 1, 2), Nx.slice_axis(x, 1, 1, 2))
    |> Nx.subtract(Nx.slice_axis(x, 2, 1, 2))
    |> Nx.abs
    |> Nx.sum(axes: [-1])
    |> Nx.squeeze(axes: [-1])
  end 

  def compute_loss(x) do
    # IO.inspect(x)
    # IO.puts "^^^ ----"
    Nx.slice_axis(x, 0, 1, 0)
    # |> IO.inspect
    |> compute_score(true)
    |> Nx.flatten
    |> Nx.subtract(
       Nx.slice_axis(x, 1, 1, 0)
       |> compute_score
       |> Nx.flatten
    )
  end 

  # def sub(x) do
  #   # Nx.sum(x, axes: [2])
  # end 

  def train_model(model, data, n_epochs, n_batches, as_tsv \\ false) do
    # {heads, tails, relations} = model
    #                             |> Axon.split(3, axis: 1)

    # Axon.concatenate([heads, tails])
    # |> Axon.nx(&sum/1)
    # IO.puts n_batches
    
    model
    |> Axon.nx(&compute_loss/1) 
    # |> Axon.Loop.trainer(:binary_cross_entropy, :sgd)
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
    model = model(Meager.n_entities, Meager.n_relations, hidden_size, batch_size)

    # IO.inspect model

    data = Stream.repeatedly(
      fn ->
        # IO.puts "sampling..."
        params
        |> Meager.sample
        |> Models.Utils.get_positive_and_negative_triples
        |> Models.Utils.to_model_input(margin, entity_negative_rate, relation_negative_rate) 
        # |> IO.inspect
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

    # IO.puts("trained!")

    # IO.inspect Axon.predict(model, model_state, {Nx.tensor([[0]]), Nx.tensor([[1]]), Nx.tensor([[0]])})

    # positive_result = Axon.predict(model, model_state, {Nx.tensor([[0]]), Nx.tensor([[1]]), Nx.tensor([[0]]), Nx.tensor([[1]]), Nx.tensor([[2]]), Nx.tensor([[0]])})
    # positive_result = Axon.predict(model, model_state, {Nx.tensor([[0]]), Nx.tensor([[1]]), Nx.tensor([[0]])})

    # IO.puts(compute_loss(positive_result))

    # negative_result = Axon.predict(model, model_state, {Nx.tensor([[1]]), Nx.tensor([[2]]), Nx.tensor([[0]])})

    # IO.puts(compute_loss(negative_result))

    # {compute_loss(positive_result)} # , compute_loss(negative_result)}
    # |> IO.inspect
    {params, model, model_state}
  end

  def run do
    model = model(4, 1, 10)
    data = Stream.repeatedly(&batch/0)

    model_state = train_model(model, data, 1, 1000)

    # IO.inspect Axon.predict(model, model_state, {Nx.tensor([[0]]), Nx.tensor([[1]]), Nx.tensor([[0]])})



    # IO.puts(compute_loss(positive_result))

    # negative_result = Axon.predict(model, model_state, {Nx.tensor([[1]]), Nx.tensor([[2]]), Nx.tensor([[0]])})

    # IO.puts(compute_loss(negative_result))

    # {compute_loss(positive_result)} # , compute_loss(negative_result)}
    # |> IO.inspect
  end

  defp generate_predictions_for_testing(batches, model, state) do
    Axon.predict(model, state, batches)
    # |> IO.inspect
    # |> Nx.slice_axis(0, 1, 0)
    |> compute_score(true)
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
    # |> IO.inspect

      Meager.sample_tail_batch
      |> Models.Utils.to_model_input_for_testing(params.input_size)
      |> generate_predictions_for_testing(model, model_state)
      |> Nx.slice([0], [Meager.n_entities])
      |> Nx.to_flat_list
      |> Meager.test_tail_batch
    # |> IO.inspect
    end

    Meager.test_link_prediction(params.as_tsv)
  end
end

