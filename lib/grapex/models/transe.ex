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

  @spec compute_loss(Nx.Tensor, integer) :: Nx.Tensor
  def compute_loss(x, batch_size) do
    x = fix_shape(x)

    x
    |> Nx.slice_axis(0, 1, 0)
    |> Nx.slice_axis(0, batch_size, 1)
    |> compute_score
    |> Nx.reshape({1, batch_size, :auto})
    |> Nx.subtract(
       Nx.slice_axis(x, 1, 1, 0)  # negative_score
       |> compute_score
       |> Nx.reshape({1, batch_size, :auto})
    )
    |> Nx.sum
  end
end

