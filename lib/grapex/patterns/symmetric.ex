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

    %{
      entities: Nx.stack([forward_entities, backward_entities]),
      relations: Nx.stack([forward_relations, backward_relations])
    }
  end
end

