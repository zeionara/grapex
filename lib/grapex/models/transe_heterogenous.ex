defmodule Grapex.Model.TranseHeterogenous do
  require Axon
   
  # def model(n_entities, n_relations, entity_embedding_size, relation_embedding_size, batch_size \\ 16) do
  def model(%Grapex.Init{entity_dimension: entity_embedding_size, relation_dimension: relation_embedding_size, input_size: batch_size}) do

    entity_embeddings_ = Axon.input({nil, batch_size, 2})
                         |> Axon.embedding(Grapex.Meager.n_entities, entity_embedding_size)

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
                         |> Axon.embedding(Grapex.Meager.n_relations, relation_embedding_size)

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

  defp fix_shape(x, first_dimension) do
    case {x, first_dimension} do
      {%{shape: {_, _, _}}, 1} -> 
        IO.puts "first statement" 
        Nx.new_axis(x, 0)
      {%{shape: {_, _, _}}, _} -> 
        IO.puts "second statement"
        Nx.new_axis(x, 0)
        |> Nx.tile([first_dimension, 1, 1, 1])
      _ -> x
    end
  end

  def compute_score(x) do
    Nx.add(Nx.slice_axis(x, 0, 1, 2), Nx.slice_axis(x, 1, 1, 2))
    |> Nx.subtract(Nx.slice_axis(x, 2, 1, 2))
    |> Nx.abs
    |> Nx.sum(axes: [-1])
    |> Nx.squeeze(axes: [-1])
  end 

  def compute_loss(x) do
    fixed_x = fix_shape(x, 2)

    # IO.inspect x
    # IO.inspect fixed_x

    # {_, _} = 2

    Nx.slice_axis(fixed_x, 0, 1, 0)
    |> compute_score
    |> Nx.flatten
    |> Nx.subtract(
       Nx.slice_axis(fixed_x, 1, 1, 0)
       |> compute_score
       |> Nx.flatten
    )
  end 
end

