defmodule Grapex.Meager.SamplerConfig do
  @enforce_keys [
    :pattern,
    :n_observed_triples_per_pattern_instance,
    :bern,
    :cross_sampling,
    :n_workers
  ]
  defstruct @enforce_keys
end
