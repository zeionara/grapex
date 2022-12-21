defmodule Grapex.Meager.Sampler do
  import Grapex.ExceptionHandling
  import Grapex.Patterns.MeagerDecoder
  import Grapex.Meager.Placeholder

  @enforce_keys [
    :pattern,
    :n_observed_triples_per_pattern_instance,
    :bern,
    :cross_sampling,
    :n_workers
  ]
  defstruct @enforce_keys

  @spec init_sampler!(map, boolean) :: atom
  def init_sampler!(
    %Grapex.Meager.Sampler{
      pattern: pattern,
      n_observed_triples_per_pattern_instance: n_observed_triples_per_pattern_instance,
      bern: bern,
      cross_sampling: cross_sampling,
      n_workers: n_workers
    }, verbose \\ false
  ) do  # when pattern in @valid_patterns do
    raise_or_nil init_sampler(pattern, n_observed_triples_per_pattern_instance, bern, cross_sampling, n_workers, verbose)
  end

  def sample!(
    %Grapex.Meager.Sampler{
      pattern: pattern,
      n_observed_triples_per_pattern_instance: n_observed_triples_per_pattern_instance
    }, batch_size, entity_negative_rate, relation_negative_rate, head_batch_flag, verbose \\ false
  ) do
    raise_or_value sample(batch_size, entity_negative_rate, relation_negative_rate, head_batch_flag, verbose),
      as: fn data -> decode(data, batch_size, entity_negative_rate, relation_negative_rate, n_observed_triples_per_pattern_instance, pattern) end
  end

  def sample?(
    %Grapex.Meager.Sampler{
      pattern: pattern,
      n_observed_triples_per_pattern_instance: n_observed_triples_per_pattern_instance
    }, batch_size, entity_negative_rate, relation_negative_rate, head_batch_flag, verbose \\ false
  ) do
    nil_or_value sample(batch_size, entity_negative_rate, relation_negative_rate, head_batch_flag, verbose),
      as: fn data -> decode(data, batch_size, entity_negative_rate, relation_negative_rate, n_observed_triples_per_pattern_instance, pattern) end
  end

end
