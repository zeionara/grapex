defmodule TripleOccurrence do
  defstruct [:heads, :tails, :labels, :relations]

  def describe(%TripleOccurrence{heads: heads, tails: tails, labels: labels, relations: relations}, _opts \\ []) do
    Stream.zip([heads, relations, tails, (if labels == nil, do: Stream.repeatedly(fn() -> 1 end), else: labels)])
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
  alias Grapex.Trainer

  # @n_triple_classes 2 # positive and negative
  @n_entities_per_triple 2 # head and tail
  @n_relations_per_triple 1

  @spec to_tensor(map, map, list) :: map
  def to_tensor(batch, trainer, opts \\ []) do
    with_positive_and_negative = Keyword.get(opts, :with_positive_and_negative, false)
    batch_size = Keyword.get(opts, :batch_size, Trainer.group_size(trainer))
    
    # IO.inspect(batch, structs: false)
    if with_positive_and_negative do
      batch = Grapex.Models.Utils.get_positive_and_negative_triples(batch)
      n_positive_iterations = trunc(length(batch.negative.heads) / length(batch.positive.heads))
      # Nx.tensor(
      #   [
      #     Grapex.Models.Utils.repeat(batch.positive.heads, n_positive_iterations),
      #     Grapex.Models.Utils.repeat(batch.positive.tails, n_positive_iterations),
      #     batch.negative.heads,
      #     batch.negative.tails
      #   ] 
      # )
      # |> Nx.reshape({@n_triple_classes, @n_entities_per_triple, :auto})
      # |> Nx.transpose(axes: [0, 2, 1])
      # |> Nx.subtract(
      #   Nx.tensor(
      #     [
      #       Grapex.Models.Utils.repeat(batch.positive.heads, n_positive_iterations),
      #       Grapex.Models.Utils.repeat(batch.positive.tails, n_positive_iterations),
      #       batch.negative.heads,
      #       batch.negative.tails
      #     ] 
      #   )
      #   |> Nx.reshape({@n_triple_classes, :auto, @n_entities_per_triple})
      # )
      # |> Nx.sum
      # |> IO.inspect
      # first_tensor = Nx.tensor(
      #     [
      #       [
      #         Grapex.Models.Utils.repeat(batch.positive.heads, n_positive_iterations),
      #         Grapex.Models.Utils.repeat(batch.positive.tails, n_positive_iterations)
      #       ],
      #       [
      #         batch.negative.heads,
      #         batch.negative.tails
      #       ] 
      #     ]
      #   )

      # first_tensor
      # |> IO.inspect

      # second_tensor = first_tensor
      # |> Nx.transpose(axes: [0, 2, 1])

      # second_tensor
      # |> IO.inspect

      # third_tensor = second_tensor
      # |> Nx.reshape({:auto, batch_size, @n_entities_per_triple})

      # third_tensor
      # |> IO.inspect

      # relations
      #
      # first_tensor = Nx.tensor(
      #   [
      #     Grapex.Models.Utils.repeat(batch.positive.relations, n_positive_iterations),
      #     batch.negative.relations
      #     # for _ <- 1..(n_positive_iterations * length(batch.positive.relations)) do 1 end
      #   ]
      # )
      # IO.inspect first_tensor
      #   # |> IO.inspect
      #   # |> Nx.reshape({@n_triple_classes, @n_relations_per_triple, :auto})
      # second_tensor = first_tensor 
      # |> Nx.reshape({:auto, batch_size, @n_relations_per_triple})

      # IO.inspect second_tensor

      %{
        entities: Nx.tensor(
          [
            [
              Grapex.Models.Utils.repeat(batch.positive.heads, n_positive_iterations),
              Grapex.Models.Utils.repeat(batch.positive.tails, n_positive_iterations)
            ],
            [
              batch.negative.heads,
              batch.negative.tails
            ] 
          ]
        )
        # |> Nx.reshape({@n_triple_classes, @n_entities_per_triple, :auto})
        |> Nx.transpose(axes: [0, 2, 1])
        # |> IO.inspect
        |> Nx.reshape({:auto, batch_size, @n_entities_per_triple}),
        # |> IO.inspect,
        # |> Nx.transpose(axes: [0, 2, 1]), # make batch size the second axis
        relations: Nx.tensor(
          [
            Grapex.Models.Utils.repeat(batch.positive.relations, n_positive_iterations),
            batch.negative.relations
            # for _ <- 1..(n_positive_iterations * length(batch.positive.relations)) do 1 end
          ]
        )
        # |> IO.inspect
        # |> Nx.reshape({@n_triple_classes, @n_relations_per_triple, :auto})
        |> Nx.reshape({:auto, batch_size, @n_relations_per_triple})
        # |> IO.inspect
        # |> Nx.transpose(axes: [0, 2, 1])
      }
    else
      # IO.inspect batch_size
      # Nx.tensor(
      #   [
      #     batch.heads,
      #     batch.tails
      #   ] 
      # )
      # |> Nx.transpose
      # |> IO.inspect
      %{
        entities: Nx.tensor(
          [
            batch.heads,
            batch.tails
          ] 
        )
        |> Nx.transpose
        |> Nx.to_batched_list(batch_size)
        |> Nx.stack,
        relations: Nx.tensor(
          [
            batch.relations
          ] 
        )
        |> Nx.transpose
        |> Nx.to_batched_list(batch_size)
        |> Nx.stack
      }
    end
  end
end

