defmodule Grapex.Patterns.Symmetric do
  defstruct [:forward, :backward, :observed]
end

defimpl Inspect, for: [Grapex.Patterns.Symmetric, Grapex.Patterns.Inverse] do
  # import Inspect.Algebra

  def inspect(occurrence, _opts \\ []) do
    "\nforward\n#{TripleOccurrence.describe(occurrence.forward)}\n\nbackward\n#{TripleOccurrence.describe(occurrence.backward)}\n\nobserved\n#{TripleOccurrence.describe(occurrence.observed)}\n"
  end
end  

defimpl PatternOccurrence, for: [Grapex.Patterns.Symmetric, Grapex.Patterns.Inverse] do
  def to_tensor(occurrence, %Grapex.Init{entity_negative_rate: entity_negative_rate, relation_negative_rate: relation_negative_rate} = params, opts \\ []) do # , batch_size: batch_size
    n_positive_iterations = entity_negative_rate + relation_negative_rate

    opts = [{:with_positive_and_negative, true} | opts]

    %{entities: forward_entities, relations: forward_relations} = PatternOccurrence.to_tensor(occurrence.forward, params, opts)
    %{entities: backward_entities, relations: backward_relations} = PatternOccurrence.to_tensor(occurrence.backward, params, opts)
    %{entities: observed_entities, relations: observed_relations} = PatternOccurrence.to_tensor(occurrence.observed, params, opts)

    make_true_label = Keyword.get(opts, :make_true_label, nil)

    {_, batch_size, _} = Nx.shape(forward_entities)
    {_, n_observed_triple_pairs, _} = Nx.shape(observed_entities)

    # IO.puts 'Concatenated pattern entities'

    # Nx.concatenate(
    #     [
    #       Nx.stack([forward_entities, backward_entities]), # |> IO.inspect,
    #       for i <- 0..(trunc(n_observed_triple_pairs / batch_size) - 1) do
    #         observed_entities
    #         |> Nx.slice_axis(i * batch_size, batch_size, 1)
    #       end
    #       |> Nx.stack
    #     ]
    # ) |> IO.inspect

    # IO.puts 'Concatenated pattern relations'

    # Nx.concatenate(
    #     [
    #       Nx.stack([forward_relations, backward_relations]),
    #       for i <- 0..(trunc(n_observed_triple_pairs / batch_size) - 1) do
    #         observed_relations
    #         |> Nx.slice_axis(i * batch_size, batch_size, 1)
    #       end
    #       |> Nx.stack
    #     ]
    # ) |> IO.inspect

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
      |> Grapex.NxUtils.flatten_leading_dimensions(2),
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
      |> Grapex.NxUtils.flatten_leading_dimensions(2)
    }

    # IO.inspect result.entities
    
    unless make_true_label == nil do
      # Map.put(result, :true_labels, Nx.tensor(for _ <- 1..(batch_size * n_positive_iterations) do [0.0] end))
      Map.put(result, :true_labels, Nx.tensor(for _ <- 1..(batch_size * n_positive_iterations) do [make_true_label.()] end))
    else
      result
    end
  end
end

