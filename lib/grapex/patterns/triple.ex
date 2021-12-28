defmodule TripleOccurrence do
  defstruct [:heads, :tails, :labels, :relations]

  def describe(%TripleOccurrence{heads: heads, tails: tails, labels: labels, relations: relations}, _opts \\ []) do
    Stream.zip([heads, relations, tails, labels])
    |> Stream.map(
      fn {head, relation, tail, label} ->
        arrow_placeholder = if label == 1, do: "+", else: "-"
        "#{StringUtils.pad(head)} #{arrow_placeholder}#{StringUtils.pad(relation, arrow_placeholder)}#{arrow_placeholder}> #{StringUtils.pad(tail)}"
      end
    )
    |> Enum.join("\n")
  end
end

defimpl Inspect, for: TripleOccurrence do
  def inspect(occurrence, opts \\ []) do
    TripleOccurrence.describe(occurrence, opts)
  end
end

defimpl PatternOccurrence, for: TripleOccurrence do
  @n_triple_classes 2 # positive and negative
  @n_entities_per_triple 2 # head and tail
  @n_relations_per_triple 1

  @spec to_tensor(map, map, list) :: map
  def to_tensor(batch, _patterns, _opts \\ []) do
    # IO.inspect(batch, structs: false)
    batch = Grapex.Models.Utils.get_positive_and_negative_triples(batch)
    n_positive_iterations = trunc(length(batch.negative.heads) / length(batch.positive.heads))
    %{
      entities: Nx.tensor(
        [
          Grapex.Models.Utils.repeat(batch.positive.heads, n_positive_iterations),
          Grapex.Models.Utils.repeat(batch.positive.tails, n_positive_iterations),
          batch.negative.heads,
          batch.negative.tails
        ] 
      )
      |> Nx.reshape({@n_triple_classes, @n_entities_per_triple, :auto})
      |> Nx.transpose(axes: [0, 2, 1]), # make batch size the second axis
      relations: Nx.tensor(
        [
          Grapex.Models.Utils.repeat(batch.positive.relations, n_positive_iterations),
          batch.negative.relations
        ]
      )
      |> Nx.reshape({@n_triple_classes, @n_relations_per_triple, :auto})
      |> Nx.transpose(axes: [0, 2, 1])
    }
  end
end

