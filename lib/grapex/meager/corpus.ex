defmodule Grapex.Meager.Corpus do
  use Grapex.Meager

  import Grapex.ExceptionHandling
  import Grapex.Meager.Placeholder

  alias Grapex.Meager.Corpus

  @enforce_keys [
    :path,
    :enable_filter,
    :drop_pattern_duplicates,
    :drop_filter_duplicates
  ]

  defstruct @enforce_keys

  @spec init!(map, boolean) :: map
  def init!(%Grapex.Meager.Corpus{path: path, enable_filter: enable_filter} = self, verbose \\ false) do
    raise_or_nil init_corpus(String.to_charlist(path), String.length(path), enable_filter, verbose)
    self
  end

  @spec import_filter!(map, boolean) :: map
  def import_filter!(%Grapex.Meager.Corpus{drop_filter_duplicates: drop_duplicates} = self, verbose \\ false) do
    raise_or_nil import_filter(drop_duplicates, verbose)
    self
  end

  @spec import_pattern!(map, boolean) :: map
  def import_pattern!(self, verbose \\ false) do
    raise_or_nil import_pattern(verbose)
    self
  end

  @spec import_train!(map, boolean) :: map
  def import_train!(%Grapex.Meager.Corpus{drop_pattern_duplicates: drop_duplicates} = self, verbose \\ false) do
    raise_or_nil import_train(drop_duplicates, verbose)
    self
  end

  @spec import_triples!(map, atom, boolean) :: map
  def import_triples!(self, subset, verbose \\ false) when subset in @valid_subsets do
    raise_or_nil import_triples(subset, verbose)
    self
  end

  @spec import_types!(map, boolean) :: map
  def import_types!(self, verbose \\ false) do
    raise_or_nil import_types(verbose)
    self
  end

  @spec count_entities!(map, boolean) :: number
  def count_entities!(_self, verbose \\ false) do
    raise_or_value count_entities(verbose)
  end

  @spec count_relations!(map, boolean) :: number
  def count_relations!(_self, verbose \\ false) do
    raise_or_value count_relations(verbose)
  end

  @spec count_triples!(map, boolean) :: number
  def count_triples!(_self, verbose \\ false) do
    raise_or_value count_triples(verbose)
  end

  @spec count_triples!(map, atom, boolean) :: number
  def count_triples!(_self, subset, verbose) when subset in @valid_subsets do
    case subset do
      nil -> count_triples(verbose)
      value -> count_triples(value, verbose)
    end
    |> raise_or_value
  end

  def count_eval_triples(self, subset, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, false)
    max_n_eval_triples = Keyword.get(opts, :max_n_eval_triples)

    case max_n_eval_triples do
      # nil -> Grapex.Meager.count_triples!(subset, verbose)
      nil -> Corpus.count_triples!(self, subset, verbose)
      # _ -> min(max_n_test_triples, Grapex.Meager.count_triples!(subset, verbose))
      _ -> min(max_n_eval_triples, Corpus.count_triples!(self, subset, verbose))
    end
  end

end
