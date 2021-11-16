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
    entity_embeddings_ = Axon.input({batch_size, 4})
                         |> entity_embeddings(n_entities, hidden_size)

    relation_embeddings_ = Axon.input({batch_size, 2})
                         |> relation_embeddings(n_relations, hidden_size)

    Axon.concatenate([entity_embeddings_, relation_embeddings_], axis: 1)
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

    metrics =
      metrics
      |> Enum.map(fn {k, v} -> "#{k}: #{:io_lib.format('~.5f', [Nx.to_scalar(v)])}" end)
      |> Enum.join(" ")

    IO.write("\rEpoch: #{Nx.to_scalar(epoch)}, Batch: #{Nx.to_scalar(iter)}, #{loss} #{metrics}")

    {:continue, state}
  end

  def compute_loss(x) do
    # named_tensor = Nx.tensor(x, names: [:samples, :embeddings, :values])
    # Nx.sum(x, axes: [1])
    heads = Nx.slice_axis(x, 0, 1, -2) # x[[0..((x.shape |> elem(0)) - 1), 0, 0..((x.shape |> elem(2)) - 1)]]
    tails = Nx.slice_axis(x, 1, 1, -2)
    relations = Nx.slice_axis(x, 4, 1, -2)

    negative_heads = Nx.slice_axis(x, 2, 1, -2) # x[[0..((x.shape |> elem(0)) - 1), 0, 0..((x.shape |> elem(2)) - 1)]]
    negative_tails = Nx.slice_axis(x, 3, 1, -2)
    negative_relations = Nx.slice_axis(x, 5, 1, -2)

    negative_sum = Nx.add(negative_heads, negative_relations)
    |> Nx.subtract(negative_tails)
    |> Nx.abs
    |> Nx.sum(axes: [-1])

    Nx.add(heads, relations)
    |> Nx.subtract(tails)
    |> Nx.abs
    |> Nx.sum(axes: [-1])
    |> Nx.subtract(negative_sum)
  end 

  # def sub(x) do
  #   # Nx.sum(x, axes: [2])
  # end 

  def train_model(model, data, n_epochs, n_batches) do
    # {heads, tails, relations} = model
    #                             |> Axon.split(3, axis: 1)

    # Axon.concatenate([heads, tails])
    # |> Axon.nx(&sum/1)
    
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
    |> Axon.Loop.handle(:iteration_completed, &log_metrics(&1, :train), every: 2)
    |> Axon.Loop.run(data, epochs: n_epochs, iterations: n_batches)
  end

  def run(%Grapex.Init{model: :transe, n_epochs: n_epochs, n_batches: n_batches, margin: margin, entity_negative_rate: entity_negative_rate}, hidden_size \\ 10) do
    model = model(Meager.n_entities, Meager.n_relations, hidden_size)

    IO.inspect model

    data = Stream.repeatedly(
      fn ->
        Meager.sample
        |> Models.Utils.get_positive_and_negative_triples
        |> Models.Utils.to_model_input(margin) 
      end
    )

    model_state = train_model(model, data, n_epochs, n_batches)

    IO.puts "" # makes line-break after last train message

    model_state

    # IO.puts("trained!")

    # IO.inspect Axon.predict(model, model_state, {Nx.tensor([[0]]), Nx.tensor([[1]]), Nx.tensor([[0]])})

    # positive_result = Axon.predict(model, model_state, {Nx.tensor([[0]]), Nx.tensor([[1]]), Nx.tensor([[0]]), Nx.tensor([[1]]), Nx.tensor([[2]]), Nx.tensor([[0]])})
    # positive_result = Axon.predict(model, model_state, {Nx.tensor([[0]]), Nx.tensor([[1]]), Nx.tensor([[0]])})

    # IO.puts(compute_loss(positive_result))

    # negative_result = Axon.predict(model, model_state, {Nx.tensor([[1]]), Nx.tensor([[2]]), Nx.tensor([[0]])})

    # IO.puts(compute_loss(negative_result))

    # {compute_loss(positive_result)} # , compute_loss(negative_result)}
    # |> IO.inspect
  end

  def run do
    model = model(4, 1, 10)
    data = Stream.repeatedly(&batch/0)

    model_state = train_model(model, data, 1, 1000)

    IO.inspect Axon.predict(model, model_state, {Nx.tensor([[0]]), Nx.tensor([[1]]), Nx.tensor([[0]])})

    positive_result = Axon.predict(model, model_state, {Nx.tensor([[0]]), Nx.tensor([[1]]), Nx.tensor([[0]]), Nx.tensor([[1]]), Nx.tensor([[2]]), Nx.tensor([[0]])})


    # IO.puts(compute_loss(positive_result))

    # negative_result = Axon.predict(model, model_state, {Nx.tensor([[1]]), Nx.tensor([[2]]), Nx.tensor([[0]])})

    # IO.puts(compute_loss(negative_result))

    {compute_loss(positive_result)} # , compute_loss(negative_result)}
  end
end

