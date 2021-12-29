defmodule SymmetricPatternOccurrence do
  defstruct [:forward, :backward, :observed]
end

defimpl Inspect, for: SymmetricPatternOccurrence do
  # import Inspect.Algebra

  def inspect(occurrence, _opts \\ []) do
    "\nforward\n#{TripleOccurrence.describe(occurrence.forward)}\n\nbackward\n#{TripleOccurrence.describe(occurrence.backward)}\n\nobserved\n#{TripleOccurrence.describe(occurrence.observed)}\n"
  end
end  

defimpl PatternOccurrence, for: SymmetricPatternOccurrence do
  def to_tensor(occurrence, %Grapex.Init{entity_negative_rate: entity_negative_rate, relation_negative_rate: relation_negative_rate} = params, opts \\ []) do # , batch_size: batch_size
    n_positive_iterations = entity_negative_rate + relation_negative_rate

    opts = [{:with_positive_and_negative, true} | opts]

    %{entities: forward_entities, relations: forward_relations} = PatternOccurrence.to_tensor(occurrence.forward, params, opts)
    %{entities: backward_entities, relations: backward_relations} = PatternOccurrence.to_tensor(occurrence.backward, params, opts)
    %{entities: observed_entities, relations: observed_relations} = PatternOccurrence.to_tensor(occurrence.observed, params, opts)

    with_true_labels = Keyword.get(opts, :with_true_labels, false)

    {_, batch_size, _} = Nx.shape(forward_entities)
    {_, n_observed_triple_pairs, _} = Nx.shape(observed_entities)


    result = %{
      entities: Nx.concatenate(
        [
          Nx.stack([forward_entities, backward_entities]), # |> IO.inspect,
          for i <- 0..(trunc(n_observed_triple_pairs / batch_size) - 1) do
            observed_entities
            |> Nx.slice_axis(i * batch_size, batch_size, 1)
          end
          |> Nx.stack
        ]
      )
      |> NxTools.flatten_leading_dimensions(2),
      relations: Nx.concatenate(
        [
          Nx.stack([forward_relations, backward_relations]),
          for i <- 0..(trunc(n_observed_triple_pairs / batch_size) - 1) do
            observed_relations
            |> Nx.slice_axis(i * batch_size, batch_size, 1)
          end
          |> Nx.stack
        ]
      )
      |> NxTools.flatten_leading_dimensions(2)
    }
    
    if with_true_labels do
      Map.put(result, :true_labels, Nx.tensor(for _ <- 1..(batch_size * n_positive_iterations) do [0.0] end))
    else
      result
    end
  end
end

