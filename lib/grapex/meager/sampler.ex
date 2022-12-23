defmodule Grapex.Meager.Sampler do
  use Grapex.Meager

  import Grapex.ExceptionHandling
  import Grapex.Patterns.MeagerDecoder
  import Grapex.Meager.Placeholder

  require Grapex.PersistedStruct

  Grapex.PersistedStruct.init [
    required_keys: [
      pattern: nil,
      n_observed_triples_per_pattern_instance: nil,
      bern: nil,
      cross_sampling: nil,
      n_workers: nil
    ]
  ]

  @spec init!(map, boolean) :: map
  def init!(
    %Grapex.Meager.Sampler{
      pattern: pattern,
      n_observed_triples_per_pattern_instance: n_observed_triples_per_pattern_instance,
      bern: bern,
      cross_sampling: cross_sampling,
      n_workers: n_workers
    } = self, verbose \\ false
  ) when pattern in @valid_patterns do
    raise_or_nil init_sampler(pattern, n_observed_triples_per_pattern_instance, bern, cross_sampling, n_workers, verbose)
    self
  end

  def sample!(
    %Grapex.Meager.Sampler{
      pattern: pattern,
      n_observed_triples_per_pattern_instance: n_observed_triples_per_pattern_instance
    }, batch_size, entity_negative_rate, relation_negative_rate, verbose \\ false, opts \\ []
  ) when pattern in @valid_patterns do
    head_batch_flag = Keyword.get(opts, :head_batch_flag, false)
    raise_or_value sample(batch_size, entity_negative_rate, relation_negative_rate, head_batch_flag, verbose),
      as: fn data -> decode(data, batch_size, entity_negative_rate, relation_negative_rate, n_observed_triples_per_pattern_instance, pattern) end
  end

  def sample?(
    %Grapex.Meager.Sampler{
      pattern: pattern,
      n_observed_triples_per_pattern_instance: n_observed_triples_per_pattern_instance
    }, batch_size, entity_negative_rate, relation_negative_rate, verbose \\ false, opts \\ []
  ) when pattern in @valid_patterns do
    head_batch_flag = Keyword.get(opts, :head_batch_flag, false)
    nil_or_value sample(batch_size, entity_negative_rate, relation_negative_rate, head_batch_flag, verbose),
      as: fn data -> decode(data, batch_size, entity_negative_rate, relation_negative_rate, n_observed_triples_per_pattern_instance, pattern) end
  end

end
