defmodule Models.Utils do

  @spec filter_by_label(map, integer) :: map
  defp filter_by_label(batch, target_label) do 
    case Stream.zip([batch.heads, batch.tails, batch.relations, batch.labels])
    |> Stream.filter(fn {_, _, _, label} -> label == target_label end)
    |> Stream.map(fn {head, tail, relation, label} -> [head, tail, relation, label] end)
    |> Stream.zip
    |> Stream.map(&Tuple.to_list/1)
    |> Enum.to_list do
      [heads, tails, relations, _] -> %{heads: heads, tails: tails, relations: relations}
    end
  end

  @spec get_positive_and_negative_triples(map) :: map
  def get_positive_and_negative_triples(batch) do
    %{
      positive: filter_by_label(batch, 1),
      negative: filter_by_label(batch, -1)
    }
  end

  def to_model_input(batch, margin \\ 2.0) do
    {
      {
        Nx.tensor(
          [
            batch.positive.heads,
            batch.positive.tails,
            batch.negative.heads,
            batch.negative.tails
          ] 
        )
        |> Nx.reshape({2, 2, :auto})
        |> Nx.transpose(axes: [0, 2, 1]),
        # |> Nx.reshape({2, 
        Nx.tensor(
          [
            batch.positive.relations,
            batch.negative.relations
          ]
        )
        |> Nx.reshape({2, 1, :auto})
        |> Nx.transpose(axes: [0, 2, 1]),
        # |> Nx.transpose
      },
      Nx.tensor(for _ <- 0..(length(batch.positive.heads) - 1) do [margin] end)
    }
  end

end
