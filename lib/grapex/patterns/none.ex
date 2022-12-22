defmodule Grapex.Patterns.None do
  defstruct [:triples]
end

defimpl Inspect, for: Grapex.Patterns.None do
  def inspect(occurrence, _opts \\ []) do
    "\ntriples\n#{TripleOccurrence.describe(occurrence.triples)}\n"
  end
end  

defimpl PatternOccurrence, for: Grapex.Patterns.None do
  alias Grapex.Trainer

  def to_tensor(occurrence, %Trainer{entity_negative_rate: entity_negative_rate, relation_negative_rate: relation_negative_rate} = params, opts \\ []) do # , batch_size: batch_size
    n_positive_iterations = entity_negative_rate + relation_negative_rate

    # IO.inspect occurrence

    result = PatternOccurrence.to_tensor(occurrence.triples, params, opts)

    make_true_label = Keyword.get(opts, :make_true_label, nil)

    {_, batch_size, _} = Nx.shape(result.entities)
    
    unless make_true_label == nil do
      # Map.put(result, :true_labels, Nx.tensor(for _ <- 1..(batch_size * n_positive_iterations) do [0.0] end))
      Map.put(result, :true_labels, Nx.tensor(for _ <- 1..(batch_size * n_positive_iterations) do [make_true_label.()] end))
    else
      result
    end
    # if with_true_labels do
    #   Map.put(result, :true_labels, Nx.tensor(for _ <- 1..(batch_size * n_positive_iterations) do [0.0] end))
    # else
    #   result
    # end
  end
end

