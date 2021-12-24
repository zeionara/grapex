defmodule Grapex.Patterns.MeagerDecoder do
  def decode(batch, batch_size, entity_negative_rate, relation_negative_rate, n_observed_triples_per_pattern_instance, pattern) when pattern == :symmetric do
    pattern_occurrence_size = batch_size * (1 + entity_negative_rate + relation_negative_rate)
    %SymmetricPatternOccurrence{
      forward: %TripleOccurrence{
        heads: Enum.at(batch, 0) |> Enum.take(pattern_occurrence_size),
        tails: Enum.at(batch, 1) |> Enum.take(pattern_occurrence_size),
        relations: Enum.at(batch, 2) |> Enum.take(pattern_occurrence_size),
        labels: Enum.at(batch, 3) |> Enum.take(pattern_occurrence_size)
      },
      backward: %TripleOccurrence{
        heads: Enum.at(batch, 0) |> Enum.take(pattern_occurrence_size * 2) |> Enum.take(-pattern_occurrence_size),
        tails: Enum.at(batch, 1) |> Enum.take(pattern_occurrence_size * 2) |> Enum.take(-pattern_occurrence_size),
        relations: Enum.at(batch, 2) |> Enum.take(pattern_occurrence_size * 2) |> Enum.take(-pattern_occurrence_size),
        labels: Enum.at(batch, 3) |> Enum.take(pattern_occurrence_size * 2) |> Enum.take(-pattern_occurrence_size)
      },
      observed: %TripleOccurrence{
        heads: Enum.at(batch, 0) |> Enum.take(-pattern_occurrence_size * n_observed_triples_per_pattern_instance),
        tails: Enum.at(batch, 1) |> Enum.take(-pattern_occurrence_size * n_observed_triples_per_pattern_instance),
        relations: Enum.at(batch, 2) |> Enum.take(-pattern_occurrence_size * n_observed_triples_per_pattern_instance),
        labels: Enum.at(batch, 3) |> Enum.take(-pattern_occurrence_size * n_observed_triples_per_pattern_instance)
      }
    }
  end

  def decode(batch, _batch_size, _entity_negative_rate, _relation_negative_rate, _n_observed_triples_per_pattern_instance, pattern) when pattern == nil do
    %{
      heads: Enum.at(batch, 0),
      tails: Enum.at(batch, 1),
      relations: Enum.at(batch, 2),
      labels: Enum.at(batch, 3)
    }
  end
end

