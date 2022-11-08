defmodule Grapex.Model.Transe do
  require Axon
  import Nx.Defn
   
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

  defn get_head(x) do
    Nx.add(Nx.slice_axis(x, 0, 1, 2), Nx.slice_axis(x, 1, 1, 2))  # head_embedding + tail_embedding
    |> Nx.subtract(Nx.slice_axis(x, 2, 1, 2))  # - relationship_embedding
    |> Nx.abs
    |> Nx.sum(axes: [-1])
    |> Nx.squeeze(axes: [-1])
  end

  def compute_score(x, compile \\ false) do
    x = fix_shape(x)

    if compile do
      EXLA.jit(&get_head/1, [x])
    else
      get_head(x)
    end
  end 

  def compute_loss(x) do
    x = fix_shape(x)

    # Nx.slice_axis(x, 0, 1, 0)
    # |> Nx.reshape({1, 512, 3, -1})
    # |> Nx.slice_axis(0, 512, 1)
    # |> compute_score
    # |> IO.inspect

    positive_x = Nx.slice_axis(x, 0, 1, 0)  # positive_score

    # IO.inspect positive_x

    positive_x_subset = Nx.slice_axis(positive_x, 0, 1024, 1)  # 1024 is batch size

    # positive_x = Nx.stack([positive_x_subset, positive_x_subset, positive_x_subset, positive_x_subset], axis: 2)

    # IO.inspect positive_x

    positive_score = positive_x_subset
    |> compute_score

    # positive_score = Nx.stack([positive_score, positive_score, positive_score, positive_score], axis: -1)
    positive_score
    |> Nx.reshape({1, 1024, :auto})
    # |> Nx.mean
    # positive_score
    |> Nx.subtract(
       Nx.slice_axis(x, 1, 1, 0)  # negative_score
       |> compute_score
       |> Nx.reshape({1, 1024, :auto})
    )
    |> Nx.sum
    # |> Nx.sum(axes: [-1])
  end 
end

