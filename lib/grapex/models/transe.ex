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
    IO.puts 'foo'
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

    IO.puts 'bar'

    x = fix_shape(x)

    IO.puts 'baz'

    baz1 = Nx.slice_axis(x, 0, 1, 2)

    IO.puts 'baz1'

    baz2 = Nx.slice_axis(x, 1, 1, 2)

    IO.puts 'baz2'

    addition1 = Nx.add(baz1, baz2)  # head_embedding + tail_embedding

    IO.puts 'qux'

    addition2 =
      addition1
      |> Nx.subtract(Nx.slice_axis(x, 2, 1, 2))  # - relationship_embedding

    IO.puts 'quux'

    addition3 = 
      addition2
      |> Nx.abs

    IO.puts 'corge'

    addition4 =
      addition3
      |> Nx.sum(axes: [-1])

    IO.puts 'grault'

    addition5 =
      addition4
      |> Nx.squeeze(axes: [-1])
    
    IO.puts 'garply'

    addition5
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

