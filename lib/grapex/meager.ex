defmodule Grapex.Meager do
  import Grapex.ExceptionHandling
  import Grapex.Patterns.MeagerDecoder

  require Grapex.MeagerPlaceholderFunctions, as: Meager

  #
  # Corpus
  #

  @spec init_corpus!(charlist, boolean, boolean) :: atom
  def init_corpus!(path, enable_filters \\ false, verbose \\ false) do
    raise_or_nil Meager._init_corpus(String.to_charlist(path), String.length(path), enable_filters, verbose)
  end

  @spec import_filter!(boolean, boolean) :: atom
  def import_filter!(drop_duplicates \\ true, verbose \\ false) do
    raise_or_nil Meager._import_filter(drop_duplicates, verbose)
  end

  @spec import_pattern!(boolean) :: atom
  def import_pattern!(verbose \\ false) do
    raise_or_nil Meager._import_pattern(verbose)
  end

  @spec import_train!(boolean, boolean) :: atom
  def import_train!(drop_pattern_duplicates \\ true, verbose \\ false) do
    raise_or_nil Meager._import_train(drop_pattern_duplicates, verbose)
  end

  @spec import_triples!(atom, boolean) :: atom
  def import_triples!(subset, verbose \\ false) do
    raise_or_nil Meager._import_triples(subset, verbose)
  end

  @spec import_types!(boolean) :: atom
  def import_types!(verbose \\ false) do
    raise_or_nil Meager._import_types(verbose)
  end

  @spec count_entities!(boolean) :: atom
  def count_entities!(verbose \\ false) do
    raise_or_value Meager._count_entities(verbose)
  end

  @spec count_relations!(boolean) :: atom
  def count_relations!(verbose \\ false) do
    raise_or_value Meager._count_relations(verbose)
  end

  @spec count_triples!(boolean) :: atom
  def count_triples!(verbose \\ false) do
    raise_or_value Meager._count_triples(verbose)
  end

  @spec count_triples!(atom, boolean) :: atom
  def count_triples!(subset, verbose) do
    case subset do
      nil -> Meager._count_triples(verbose)
      value -> Meager._count_triples(value, verbose)
    end
    |> raise_or_value
  end

  #
  # Sampler
  #

  @spec init_sampler!(atom, integer, boolean, boolean, integer, boolean) :: atom
  def init_sampler!(pattern, n_observed_triples_per_pattern_instance, bern \\ false, crossSampling \\ false, nWorkers \\ 8, verbose \\ false) do
    raise_or_nil Meager._init_sampler(pattern, n_observed_triples_per_pattern_instance, bern, crossSampling, nWorkers, verbose)
  end

  @spec sample_!(integer, integer, integer, boolean, boolean, integer, atom) :: list
  defp sample_!(batch_size, entity_negative_rate, relation_negative_rate, head_batch_flag, verbose, n_observed_triples_per_pattern_instance, pattern) do
    raise_or_value Meager._sample(batch_size, entity_negative_rate, relation_negative_rate, head_batch_flag, verbose),
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
  defp sample_?(batch_size, entity_negative_rate, relation_negative_rate, head_batch_flag, verbose, n_observed_triples_per_pattern_instance, pattern) do
    nil_or_value Meager._sample(batch_size, entity_negative_rate, relation_negative_rate, head_batch_flag, verbose),
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
  def init_evaluator!(metrics, task, subset, verbose \\ false) do
    raise_or_nil Meager._init_evaluator(metrics, task, subset, verbose)
  end

  @spec trial!(atom, boolean) :: atom
  def trial!(element, verbose \\ false) do 
    raise_or_value Meager._trial(element, verbose), as: fn data -> decode(data) end
  end

  @spec evaluate!(atom, list, boolean, list) :: atom
  def evaluate!(element, predictions, verbose \\ false, opts \\ []) do
    reverse = Keyword.get(opts, :reverse, false)  # reverse = higher values are better
    raise_or_nil Meager._evaluate(element, predictions, reverse, verbose)
  end

  @spec compute_metrics!(bool) :: atom
  def compute_metrics!(verbose \\ false) do
    raise_or_value Meager._compute_metrics(verbose)
  end

end
