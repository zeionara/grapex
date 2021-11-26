defmodule Grapex.Models.Utils do

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

  @spec repeat(list) :: list
  defp repeat(items) do
    items
  end

  defp repeat(_, times) when times <= 0 do
    {:error, "Cannot repeat collection negative or zero number of times"}
  end

  defp repeat(items, times) when times == 1 do
    repeat items
  end

  @spec repeat(list, integer) :: list
  defp repeat(items, times) do
    Stream.cycle(items)
    |> Stream.take(times * length(items))
    |> Enum.to_list
  end

  @spec to_model_input(map, float, integer, integer) :: tuple
  def to_model_input(batch, margin \\ 2.0, entity_negative_rate \\ 1, relation_negative_rate \\ 0) do
    n_positive_iterations = entity_negative_rate + relation_negative_rate
    {
      {
        Nx.tensor(
          [
            repeat(batch.positive.heads, n_positive_iterations),
            repeat(batch.positive.tails, n_positive_iterations),
            batch.negative.heads,
            batch.negative.tails
          ] 
        )
        |> Nx.reshape({2, 2, :auto})
        |> Nx.transpose(axes: [0, 2, 1]),
        # |> Nx.reshape({2, 
        Nx.tensor(
          [
            repeat(batch.positive.relations, n_positive_iterations),
            batch.negative.relations
          ]
        )
        |> Nx.reshape({2, 1, :auto})
        |> Nx.transpose(axes: [0, 2, 1]),
        # |> Nx.transpose
      },
      Nx.tensor(for _ <- 1..(length(batch.positive.heads) * n_positive_iterations) do [margin] end)
    }
  end

  def to_model_input_for_testing(batch, batch_size \\ 17) do
    {
      Nx.tensor(
        [
          batch.heads,
          batch.tails
        ] 
      )
      # |> Nx.reshape({1, 2, :auto})
      # |> Nx.transpose(axes: [0, 2, 1]),
      |> Nx.transpose
      |> Nx.to_batched_list(batch_size)
      |> Stream.map(fn x ->
        x
        |> Nx.transpose
        |> Nx.reshape({1, 2, :auto})
        |> Nx.transpose(axes: [0, 2, 1])
      end
      )
      |> Enum.to_list
      |> Nx.concatenate,
      # |> Nx.tensor,
      Nx.tensor(
        [
          batch.relations
        ]
      )
      # |> Nx.reshape({1, 1, :auto})
      # |> Nx.transpose(axes: [0, 2, 1]),
      |> Nx.transpose
      |> Nx.to_batched_list(batch_size)
      |> Stream.map(fn x ->
        x
        |> Nx.transpose
        |> Nx.reshape({1, 1, :auto})
        |> Nx.transpose(axes: [0, 2, 1])
      end
      )
      |> Enum.to_list
      |> Nx.concatenate
      # |> Nx.tensor
    }
    # |> Stream.zip
    # |> Enum.to_list
  end
end

