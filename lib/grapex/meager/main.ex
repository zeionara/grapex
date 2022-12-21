defmodule Grapex.Meager do
  import Grapex.ExceptionHandling
  import Grapex.Patterns.MeagerDecoder
  import Grapex.Meager.Placeholder

  @valid_subsets [
    :train,
    :test,
    :valid
  ]

  @valid_patterns [
    nil,
    :none,
    :symmetric,
    :inverse
  ]

  @valid_tasks [
    :link_prediction,
    :triple_classification
  ]

  @valid_triple_components [
    :head,
    :tail
  ]

  #
  # Corpus
  #

  @spec init_corpus!(charlist, boolean, boolean) :: atom
  def init_corpus!(path, enable_filters \\ false, verbose \\ false) do
    raise_or_nil init_corpus(String.to_charlist(path), String.length(path), enable_filters, verbose)
  end

  @spec import_filter!(boolean, boolean) :: atom
  def import_filter!(drop_duplicates \\ true, verbose \\ false) do
    raise_or_nil import_filter(drop_duplicates, verbose)
  end

  @spec import_pattern!(boolean) :: atom
  def import_pattern!(verbose \\ false) do
    raise_or_nil import_pattern(verbose)
  end

  @spec import_train!(boolean, boolean) :: atom
  def import_train!(drop_pattern_duplicates \\ true, verbose \\ false) do
    raise_or_nil import_train(drop_pattern_duplicates, verbose)
  end

  @spec import_triples!(atom, boolean) :: atom
  def import_triples!(subset, verbose \\ false) when subset in @valid_subsets do
    raise_or_nil import_triples(subset, verbose)
  end

  @spec import_types!(boolean) :: atom
  def import_types!(verbose \\ false) do
    raise_or_nil import_types(verbose)
  end

  @spec count_entities!(boolean) :: atom
  def count_entities!(verbose \\ false) do
    raise_or_value count_entities(verbose)
  end

  @spec count_relations!(boolean) :: atom
  def count_relations!(verbose \\ false) do
    raise_or_value count_relations(verbose)
  end

  @spec count_triples!(boolean) :: atom
  def count_triples!(verbose \\ false) do
    raise_or_value count_triples(verbose)
  end

  @spec count_triples!(atom, boolean) :: atom
  def count_triples!(subset, verbose) when subset in @valid_subsets do
    case subset do
      nil -> count_triples(verbose)
      value -> count_triples(value, verbose)
    end
    |> raise_or_value
  end

  #
  # Sampler
  #

  @spec init_sampler!(atom, integer, boolean, boolean, integer, boolean) :: atom
  def init_sampler!(pattern, n_observed_triples_per_pattern_instance, bern \\ false, crossSampling \\ false, nWorkers \\ 8, verbose \\ false) when pattern in @valid_patterns do
    raise_or_nil init_sampler(pattern, n_observed_triples_per_pattern_instance, bern, crossSampling, nWorkers, verbose)
  end

  @spec sample_!(integer, integer, integer, boolean, boolean, integer, atom) :: list
  defp sample_!(batch_size, entity_negative_rate, relation_negative_rate, head_batch_flag, verbose, n_observed_triples_per_pattern_instance, pattern) when pattern in @valid_patterns do
    raise_or_value sample(batch_size, entity_negative_rate, relation_negative_rate, head_batch_flag, verbose),
      as: fn data -> decode(data, batch_size, entity_negative_rate, relation_negative_rate, n_observed_triples_per_pattern_instance, pattern) end
  end

  def sample!(
    %Grapex.Init{
      batch_size: batch_size, entity_negative_rate: entity_negative_rate, relation_negative_rate: relation_negative_rate, verbose: verbose,
      pattern: pattern, n_observed_triples_per_pattern_instance: n_observed_triples_per_pattern_instance
    },
    head_batch_flag \\ false
  ) do
    sample_!(batch_size, entity_negative_rate, relation_negative_rate, head_batch_flag, verbose, n_observed_triples_per_pattern_instance, pattern)
  end

  @spec sample_?(integer, integer, integer, boolean, boolean, integer, atom) :: list
  defp sample_?(batch_size, entity_negative_rate, relation_negative_rate, head_batch_flag, verbose, n_observed_triples_per_pattern_instance, pattern) when pattern in @valid_patterns do
    nil_or_value sample(batch_size, entity_negative_rate, relation_negative_rate, head_batch_flag, verbose),
      as: fn data -> decode(data, batch_size, entity_negative_rate, relation_negative_rate, n_observed_triples_per_pattern_instance, pattern) end
  end

  def sample?(
    %Grapex.Init{
      batch_size: batch_size, entity_negative_rate: entity_negative_rate, relation_negative_rate: relation_negative_rate, verbose: verbose,
      pattern: pattern, n_observed_triples_per_pattern_instance: n_observed_triples_per_pattern_instance
    },
    head_batch_flag \\ false
  ) do
    sample_?(batch_size, entity_negative_rate, relation_negative_rate, head_batch_flag, verbose, n_observed_triples_per_pattern_instance, pattern)
  end

  #
  # Evaluator
  #

  @spec init_evaluator!(list, atom, atom, boolean) :: atom
  def init_evaluator!(metrics, task, subset, verbose \\ false) when task in @valid_tasks and subset in @valid_subsets do
    raise_or_nil init_evaluator(metrics, task, subset, verbose)
  end

  @spec trial!(atom, boolean) :: atom
  def trial!(component, verbose \\ false) when component in @valid_triple_components do 
    raise_or_value trial(component, verbose), as: fn data -> decode(data) end
  end

  @spec evaluate!(atom, list, boolean, list) :: atom
  def evaluate!(component, predictions, verbose \\ false, opts \\ []) when component in @valid_triple_components do
    reverse = Keyword.get(opts, :reverse, false)  # reverse = higher values are better
    raise_or_nil evaluate(component, predictions, reverse, verbose)
  end

  @spec compute_metrics!(bool) :: atom
  def compute_metrics!(verbose \\ false) do
    raise_or_value compute_metrics(verbose)
  end

end
