defmodule Grapex.MeagerPlaceholderFunctions do
  @on_load :load_nifs

  defp load_nifs do
    :erlang.load_nif(Application.get_env(:grapex, :meager_path), 0)
  end

  #
  # Corpus
  #

  def _init_corpus(_a, _b, _c, _d) do
    raise "NIF init_corpus/4 not implemented"
  end

  def _import_filter(_a, _b) do
    raise "NIF import_filter/2 not implemented"
  end

  def _import_pattern(_a) do
    raise "NIF _import_pattern/1 not implemented"
  end

  def _import_train(_a, _b) do
    raise "NIF _import_train/2 not implemented"
  end

  def _import_triples(_a, _b) do
    raise "NIF _import_triples/2 not implemented"
  end

  def _import_types(_a) do
    raise "NIF _import_types/1 not implemented"
  end

  def _count_entities(_a) do
    raise "NIF _count_entities/1 not implemented"
  end

  def _count_relations(_a) do
    raise "NIF _count_relations/1 not implemented"
  end

  def _count_triples(_a) do
    raise "NIF _count_triples/1 not implemented"
  end

  def _count_triples(_a, _b) do
    raise "NIF _count_triples/2 not implemented"
  end

  #
  # Sampler
  #

  def _init_sampler(_a, _b, _c, _d, _e, _f) do
    raise "NIF _init_sampler/6 not implemented"
  end

  def _sample(_a, _b, _c, _d, _e) do
    raise "NIF _sample/5 not implemented"
  end

  #
  # Evaluator
  #

  def _init_evaluator(_a, _b, _c, _d) do
    raise "NIF _init_evaluator/4 not implemented"
  end

  def _trial(_a, _b) do
    raise "NIF _trial/2 not implemented"
  end

  def _evaluate(_a, _b, _c, _d) do
    raise "NIF _evaluate/4 not implemented"
  end

  def _compute_metrics(_a) do
    raise "NIF _compute_metrics/1 not implemented"
  end

end
