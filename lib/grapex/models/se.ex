defmodule Grapex.Model.Se do
  require Axon

  # def lhs <~> rhs when is_tuple(lhs) and is_tuple(rhs) do
  #   List.to_tuple(
  #     Tuple.to_list(lhs) ++ Tuple.to_list(rhs)
  #   )
  # end

  # def tensor_embedding(%Axon{output_shape: shape} = x, vocab_size, embedding_shape, opts \\ []) do
  #   kernel_initializer = opts[:kernel_initializer] || :uniform
  #   kernel = Axon.param("kernel", Tuple.insert_at(embedding_shape, 0, vocab_size), initializer: kernel_initializer)

  #   Axon.layer(x, :embedding, shape <~> embedding_shape, %{"kernel" => kernel}, opts[:name])
  # end
   
  # def model(n_entities, n_relations, hidden_size, batch_size \\ 16) do
  def model(%Grapex.Init{hidden_size: hidden_size, input_size: batch_size}) do
    entity_embeddings = Axon.input({nil, batch_size, 2})
                         |> Axon.embedding(Grapex.Meager.n_entities, hidden_size)
                         |> Axon.reshape({batch_size, 2, 1, 1, hidden_size})
                         |> Axon.pad([{0, 0}, {0, 1}, {0, hidden_size - 1}, {0, 0}])

    relation_embeddings = Axon.input({nil, batch_size, 1})
                         |> Axon.embedding(Grapex.Meager.n_relations, 2 * hidden_size * hidden_size) # Each embedding consists of two square matrices - one for head node and another for tail
                         |> Axon.reshape({batch_size, 1, 2, hidden_size, hidden_size})

    Axon.concatenate([entity_embeddings, relation_embeddings], axis: 2, name: "se")
  end

  defp fix_shape(%{shape: {_, _, _}} = x) do
    Nx.new_axis(x, 0)
  end

  defp fix_shape(x) do
    x
  end

  defp unpad(x, start_index) do
    Nx.slice_axis(x, start_index, 1, 2)
    |> Nx.slice_axis(0, 1, 3)
    |> Nx.slice_axis(0, 1, 4)
    |> Nx.squeeze(axes: [2, 3])
  end

  defp multiply(vectors, matrices) do
    vector_batches = Nx.reshape(vectors, {:auto, elem(Nx.shape(vectors), 2)}) #  Nx.to_batched_list(head, 1)
    matrix_batches = Nx.reshape(matrices, {:auto, elem(Nx.shape(matrices), 2), elem(Nx.shape(matrices), 3)}) #  Nx.to_batched_list(head, 1)
    # IO.inspect head_batches
    
    for dim <- 1..elem(matrix_batches.shape, 1) do
      matrix_batch = matrix_batches 
                         |> Nx.slice_axis(dim - 1, 1, 1)
                         |> Nx.squeeze
      Nx.multiply(matrix_batch, vector_batches) |> Nx.sum(axes: [-1])
    end
    |> Nx.stack |> Nx.transpose |> Nx.reshape(vectors.shape)
  end

  def compute_score(x, verbose \\ false) do
    relation = Nx.slice_axis(x, 2, 1, 2)
               |> Nx.squeeze(axes: [2])

    head = unpad(x, 0) |> Nx.tile([1, 1, elem(relation.shape, 3), 1])

    head_multiplier = relation
                      |> Nx.slice_axis(0, 1, 2)
                      |> Nx.squeeze(axes: [2])

    tail = unpad(x, 1) |> Nx.tile([1, 1, elem(relation.shape, 3), 1])

    tail_multiplier = relation
                      |> Nx.slice_axis(1, 1, 2)
                      |> Nx.squeeze(axes: [2])

    # IO.inspect head
    # IO.inspect head_multiplier
    # IO.inspect Nx.dot(Nx.iota({2, 2}) |> IO.inspect, [-1], Nx.iota({2, 2, 2}) |> IO.inspect, [-1])
    
    # multiplied_head = multiply(head, head_multiplier)
    # multiplied_tail = multiply(tail, tail_multiplier)

    # multiplied_head = Nx.dot(head_batches, head_multiplier_batches) # TODO: tensor has inappropriate shape
    #
    multiplied_head =
      head
      |> Nx.multiply(head_multiplier)
      |> Nx.sum(axes: [-1])
      # |> IO.inspect

    multiplied_tail =
      tail
      |> Nx.multiply(tail_multiplier)
      |> Nx.sum(axes: [-1])
      # |> IO.inspect

    # {_, _} = 2

    # multiplied_tail = Nx.dot(tail, tail_multiplier) # TODO: tensor has inappropriate shape

    Nx.subtract(multiplied_head, multiplied_tail)
    |> Nx.abs
    |> Nx.sum(axes: [-1])
    # |> IO.inspect

    # {_, _} = 2

    # Nx.add(Nx.slice_axis(x, 0, 1, 2), Nx.slice_axis(x, 1, 1, 2))
    # |> Nx.subtract(Nx.slice_axis(x, 2, 1, 2))
    # |> Nx.abs
    # |> Nx.sum(axes: [-1])
    # |> Nx.squeeze(axes: [-1])
  end 

  defp fix_shape(x, first_dimension) do
    case {x, first_dimension} do
      {%{shape: {_, _, _, _, _}}, 1} -> Nx.new_axis(x, 0)
      {%{shape: {_, _, _, _, _}}, _} -> 
        Nx.new_axis(x, 0)
        |> Nx.tile([first_dimension, 1, 1, 1, 1, 1])
      _ -> x
    end
  end

  def compute_loss(x) do
    x = fix_shape(x, 2)

    Nx.slice_axis(x, 0, 1, 0)
    |> compute_score
    |> Nx.flatten
    |> Nx.subtract(
       Nx.slice_axis(x, 1, 1, 0)
       |> compute_score
       |> Nx.flatten
    )
  end 
end

