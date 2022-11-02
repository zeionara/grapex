defmodule Grapex.Model.Transe do
  require Axon
   
  # def model(n_entities, n_relations, hidden_size, batch_size \\ 16) do
  def model(%Grapex.Init{hidden_size: hidden_size, input_size: batch_size}) do
    entity_embeddings_ = Axon.input({nil, batch_size, 2})
                         |> Axon.embedding(Grapex.Meager.n_entities, hidden_size)

    relation_embeddings_ = Axon.input({nil, batch_size, 1})
                         |> Axon.embedding(Grapex.Meager.n_relations, hidden_size)

    Axon.concatenate([entity_embeddings_, relation_embeddings_], axis: 2, name: "transe")
  end

  defp fix_shape(%{shape: {_, _, _}} = x) do
    Nx.new_axis(x, 0)
  end

  defp fix_shape(x) do
    x
  end

  def compute_score(x, verbose \\ false) do
    case verbose do
      true ->
        x = fix_shape(x)
        Nx.add(Nx.slice_axis(x, 0, 1, 2), Nx.slice_axis(x, 1, 1, 2))
        |> Nx.subtract(Nx.slice_axis(x, 2, 1, 2))
        |> Nx.abs
        |> Nx.mean(axes: [-1])
        |> Nx.squeeze(axes: [-1])
      _ -> {:ok, nil}
    end

    x = fix_shape(x)
    Nx.add(Nx.slice_axis(x, 0, 1, 2), Nx.slice_axis(x, 1, 1, 2))  # head_embedding + tail_embedding
    |> Nx.subtract(Nx.slice_axis(x, 2, 1, 2))  # - relationship_embedding
    |> Nx.abs
    |> Nx.sum(axes: [-1])
    |> Nx.squeeze(axes: [-1])
  end 

  def compute_loss(x) do
    Nx.slice_axis(x, 0, 1, 0)  # positive_score
    |> compute_score
    |> Nx.flatten
    |> Nx.subtract(
       Nx.slice_axis(x, 1, 1, 0)  # negative_score
       |> compute_score
       |> Nx.flatten
    )
  end 
end

