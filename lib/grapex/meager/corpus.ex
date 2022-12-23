defmodule Grapex.Meager.Corpus do
  use Grapex.Meager

  import Grapex.ExceptionHandling
  import Grapex.Meager.Placeholder
  import Grapex.Option, only: [is: 1, opt: 1]

  alias Grapex.Meager.Corpus

  require Grapex.PersistedStruct

  Grapex.PersistedStruct.init [
    required_keys: [
      path: &Corpus.parse_path/1,
      enable_filter: nil,
      drop_pattern_duplicates: nil,
      drop_filter_duplicates: nil
    ]
  ]

  def parse_path(path) do
    Path.join([Application.get_env(:grapex, :relentness_root), "Assets", "Corpora", path]) <> "/"
  end

  @spec init!(map, list) :: map
  def init!(%Grapex.Meager.Corpus{path: path, enable_filter: enable_filter} = self, opts \\ []) do
    raise_or_nil init_corpus(String.to_charlist(path), String.length(path), enable_filter, is :verbose)
    self
  end

  @spec import_filter!(map, list) :: map
  def import_filter!(%Grapex.Meager.Corpus{drop_filter_duplicates: drop_duplicates} = self, opts \\ []) do
    raise_or_nil import_filter(drop_duplicates, is :verbose)
    self
  end

  @spec import_pattern!(map, list) :: map
  def import_pattern!(self, opts \\ []) do
    raise_or_nil import_pattern(is :verbose)
    self
  end

  @spec import_train!(map, list) :: map
  def import_train!(%Grapex.Meager.Corpus{drop_pattern_duplicates: drop_duplicates} = self, opts \\ []) do
    raise_or_nil import_train(drop_duplicates, is :verbose)
    self
  end

  @spec import_triples!(map, atom, list) :: map
  def import_triples!(self, subset, opts \\ []) when subset in @valid_subsets do
    raise_or_nil import_triples(subset, is :verbose)
    self
  end

  @spec import_types!(map, list) :: map
  def import_types!(self, opts \\ []) do
    raise_or_nil import_types(is :verbose)
    self
  end

  @spec count_entities!(map, list) :: number
  def count_entities!(_self, opts \\ []) do
    raise_or_value count_entities(is :verbose)
  end

  @spec count_relations!(map, list) :: number
  def count_relations!(_self, opts \\ []) do
    raise_or_value count_relations(is :verbose)
  end

  @spec count_triples!(map, list) :: number
  def count_triples!(self, opts \\ []) do
    if opts in @valid_subsets do
      count_triples!(self, opts, [])
    else
      raise_or_value count_triples(is :verbose)
    end
  end

  @spec count_triples!(map, atom, list) :: number
  def count_triples!(_self, subset, opts) when subset in @valid_subsets do
    raise_or_value count_triples(subset, is :verbose)
    # case subset do
    #   nil -> count_triples(is :verbose)
    #   value -> count_triples(value, is :verbose)
    # end
    # |> raise_or_value
  end

  def count_eval_triples(self, subset, opts \\ []) do
    max_n_eval_triples = opt :max_n_eval_triples

    case max_n_eval_triples do
      # nil -> Grapex.Meager.count_triples!(subset, verbose)
      nil -> Corpus.count_triples!(self, subset, opts)
      # _ -> min(max_n_test_triples, Grapex.Meager.count_triples!(subset, verbose))
      _ -> min(max_n_eval_triples, Corpus.count_triples!(self, subset, opts))
    end
  end

end
