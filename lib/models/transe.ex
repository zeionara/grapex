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
   
  def model(n_entities, n_relations, hidden_size) do
    head_embeddings = Axon.input({nil, 1})
                      |> entity_embeddings(n_entities, hidden_size)

    tail_embeddings = Axon.input({nil, 1})
                      |> entity_embeddings(n_entities, hidden_size)

    relation_embeddings = Axon.input({nil, 1})
                          |> relation_embeddings(n_relations, hidden_size)

    Axon.concatenate([head_embeddings, tail_embeddings, relation_embeddings], axis: 1)
    # input = Axon.input({nil, 3})
    #         |> Axon.split(3)

    # head_embeddings = input
    #                   |> elem(0)
    #                   |> entity_embeddings(n_entities, hidden_size)

    # tail_embeddings = input
    #                   |> elem(1)
    #                   |> entity_embeddings(n_entities, hidden_size)

    # relation_embeddings = input
    #                   |> elem(2)
    #                   |> relation_embeddings(n_relations, hidden_size)


    # Axon.concatenate(head_embeddings, tail_embeddings)

    # Axon.input({nil, 784})
    # |> Axon.dense(128, activation: :relu)
    # |> residual(128)
    # |> Axon.dense(10, activation: :softmax)
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
    relations = Nx.slice_axis(x, 2, 1, -2)

    Nx.add(heads, relations)
    |> Nx.subtract(tails)
    |> Nx.power(2)
    |> Nx.sum(axes: [-1])
  end 

  # def sub(x) do
  #   # Nx.sum(x, axes: [2])
  # end 

  def train_model(model, data, epochs) do
    # {heads, tails, relations} = model
    #                             |> Axon.split(3, axis: 1)

    # Axon.concatenate([heads, tails])
    # |> Axon.nx(&sum/1)
    
    model
    |> Axon.nx(&compute_loss/1) 
    |> Axon.Loop.trainer(:binary_cross_entropy, :sgd)
    |> Axon.Loop.handle(:iteration_completed, &log_metrics(&1, :train), every: 50)
    |> Axon.Loop.run(data, epochs: epochs, iterations: 1000)
  end

  def run do
    model = model(4, 1, 10)
    data = Stream.repeatedly(&batch/0)

    model_state = train_model(model, data, 1)

    IO.inspect Axon.predict(model, model_state, {Nx.tensor([[0]]), Nx.tensor([[1]]), Nx.tensor([[0]])})

    positive_result = Axon.predict(model, model_state, {Nx.tensor([[0]]), Nx.tensor([[1]]), Nx.tensor([[0]])})

    # IO.puts(compute_loss(positive_result))

    negative_result = Axon.predict(model, model_state, {Nx.tensor([[1]]), Nx.tensor([[2]]), Nx.tensor([[0]])})

    # IO.puts(compute_loss(negative_result))

    {compute_loss(positive_result), compute_loss(negative_result)}
  end
end

