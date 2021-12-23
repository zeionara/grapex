defmodule SymmetricPatternOccurrence do
  defstruct [:forward, :backward, :observed]
end

defimpl Inspect, for: SymmetricPatternOccurrence do
  import Inspect.Algebra

  def inspect(occurrence, _opts \\ []) do
    # "#{IO.inspect to_string(occurrence.forward)}"
    "\nforward\n#{TripleOccurrence.describe(occurrence.forward)}\n\nbackward\n#{TripleOccurrence.describe(occurrence.backward)}\n\nobserved\n#{TripleOccurrence.describe(occurrence.observed)}\n"
  end
end  

defimpl PatternOccurrence, for: SymmetricPatternOccurrence do
  def to_tensor(occurrence) do
    %{entities: forward_entities, relations: forward_relations} = PatternOccurrence.to_tensor(occurrence.forward)
    %{entities: backward_entities, relations: backward_relations} = PatternOccurrence.to_tensor(occurrence.backward)
    %{entities: observed_entities, relations: observed_relations} = PatternOccurrence.to_tensor(occurrence.observed)

    # IO.inspect(observed_entities);

    {_, batch_size, _} = Nx.shape(forward_entities)
    {_, n_observed_triple_pairs, _} = Nx.shape(observed_entities)


    %{
      entities: Nx.concatenate(
        [
          Nx.stack([forward_entities, backward_entities]), # |> IO.inspect,
          for i <- 0..(trunc(n_observed_triple_pairs / batch_size) - 1) do
            observed_entities
            |> Nx.slice_axis(i * batch_size, batch_size, 1)
          end
          |> Nx.stack
          # |> IO.inspect
          # observed_entities
          # |> IO.inspect
          # |> Nx.reshape(
          #   forward_entities
          #   |> Nx.shape
          #   |> Tuple.insert_at(0, :auto)
            # |> IO.inspect
          # )
          # |> Nx.transpose(axes: [1, 0, 2, 3])
          # |> IO.inspect
          # observed_entities
          # |> Nx.reshape(
          #   forward_entities
          #   |> Nx.shape
          #   |> Tuple.delete_at(0)
          #   |> Tuple.insert_at(0, :auto) 
          # ) |> IO.inspect
        ]
      ),
      # entities: Nx.stack([forward_entities, backward_entities]),
      relations: Nx.concatenate(
        [
          Nx.stack([forward_relations, backward_relations]),
          for i <- 0..(trunc(n_observed_triple_pairs / batch_size) - 1) do
            observed_relations
            |> Nx.slice_axis(i * batch_size, batch_size, 1)
          end
          |> Nx.stack
          # observed_relations
          # |> Nx.reshape(
          #   forward_relations
          #   |> Nx.shape
          #   |> Tuple.insert_at(0, :auto)
          # )
          # |> Nx.transpose(axes: [1, 0, 2, 3])
        ]
      )
    }
  end
end

