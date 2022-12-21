defmodule Grapex.Meager do
  @on_load :load_nifs

  defp load_nifs do
    :erlang.load_nif(Application.get_env(:grapex, :meager_path), 0)
  end

  #
  # Corpus
  #

  defp _init_corpus(_a, _b, _c, _d) do
    raise "NIF init_corpus/4 not implemented"
  end

  @spec init_corpus!(charlist, boolean, boolean) :: atom
  def init_corpus!(path, enable_filters \\ false, verbose \\ false) do
    case _init_corpus(String.to_charlist(path), String.length(path), enable_filters, verbose) do
      {:error, message} -> raise List.to_string(message)
      _ -> nil
    end
  end

  defp _import_filter(_a, _b) do
    raise "NIF import_filter/2 not implemented"
  end

  @spec import_filter!(boolean, boolean) :: atom
  def import_filter!(drop_duplicates \\ true, verbose \\ false) do
    case _import_filter(drop_duplicates, verbose) do
      {:error, message} -> raise List.to_string(message)
      _ -> nil
    end
  end

  defp _import_pattern(_a) do
    raise "NIF _import_pattern/1 not implemented"
  end

  @spec import_pattern!(boolean) :: atom
  def import_pattern!(verbose \\ false) do
    case _import_pattern(verbose) do
      {:error, message} -> raise List.to_string(message)
      _ -> nil
    end
  end

  defp _import_train(_a, _b) do
    raise "NIF _import_train/2 not implemented"
  end

  @spec import_train!(boolean, boolean) :: atom
  def import_train!(drop_pattern_duplicates \\ true, verbose \\ false) do
    case _import_train(drop_pattern_duplicates, verbose) do
      {:error, message} -> raise List.to_string(message)
      _ -> nil
    end
  end

  defp _import_triples(_a, _b) do
    raise "NIF _import_triples/2 not implemented"
  end

  @spec import_triples!(atom, boolean) :: atom
  def import_triples!(subset, verbose \\ false) do
    case _import_triples(subset, verbose) do
      {:error, message} -> raise List.to_string(message)
      _ -> nil
    end
  end

  defp _import_types(_a) do
    raise "NIF _import_types/1 not implemented"
  end

  @spec import_types!(boolean) :: atom
  def import_types!(verbose \\ false) do
    case _import_types(verbose) do
      {:error, message} -> raise List.to_string(message)
      _ -> nil
    end
  end

  defp _count_entities(_a) do
    raise "NIF _count_entities/1 not implemented"
  end

  @spec count_entities!(boolean) :: atom
  def count_entities!(verbose \\ false) do
    case _count_entities(verbose) do
      {:error, message} -> raise List.to_string(message)
      {:ok, quantity} -> quantity
    end
  end

  defp _count_relations(_a) do
    raise "NIF _count_relations/1 not implemented"
  end

  @spec count_relations!(boolean) :: atom
  def count_relations!(verbose \\ false) do
    case _count_relations(verbose) do
      {:error, message} -> raise List.to_string(message)
      {:ok, quantity} -> quantity
    end
  end

  defp _count_triples(_a) do
    raise "NIF _count_triples/1 not implemented"
  end

  @spec count_triples!(boolean) :: atom
  def count_triples!(verbose \\ false) do
    case _count_triples(verbose) do
      {:error, message} -> raise List.to_string(message)
      {:ok, quantity} -> quantity
    end
  end

  defp _count_triples(_a, _b) do
    raise "NIF _count_triples/2 not implemented"
  end

  @spec count_triples!(atom, boolean) :: atom
  def count_triples!(subset, verbose) do
    case subset do
      nil -> _count_triples(verbose)
      value -> _count_triples(value, verbose)
    end
    |> case do
      {:error, message} -> raise List.to_string(message)
      {:ok, quantity} -> quantity
    end
  end

  #
  # Sampler
  #

  defp _init_sampler(_a, _b, _c, _d, _e, _f) do
    raise "NIF _init_sampler/6 not implemented"
  end

  @spec init_sampler!(atom, integer, boolean, boolean, integer, boolean) :: atom
  def init_sampler!(pattern, n_observed_triples_per_pattern_instance, bern \\ false, crossSampling \\ false, nWorkers \\ 8, verbose \\ false) do
    case _init_sampler(pattern, n_observed_triples_per_pattern_instance, bern, crossSampling, nWorkers, verbose) do
      {:error, message} -> raise List.to_string(message)
      {:ok, _} -> nil
    end
  end

  defp _sample(_a, _b, _c, _d, _e) do
    raise "NIF _sample/5 not implemented"
  end

  @spec sample_!(integer, integer, integer, boolean, boolean, integer, atom) :: list
  defp sample_!(batch_size, entity_negative_rate, relation_negative_rate, head_batch_flag, verbose, n_observed_triples_per_pattern_instance, pattern) do
    _sample(
      batch_size,
      entity_negative_rate,
      relation_negative_rate,
      head_batch_flag,
      verbose
    )
    |> case do
      {:error, message} -> raise List.to_string(message)
      {:ok, data} -> Grapex.Patterns.MeagerDecoder.decode(data, batch_size, entity_negative_rate, relation_negative_rate, n_observed_triples_per_pattern_instance, pattern)
    end
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
    _sample(
      batch_size,
      entity_negative_rate,
      relation_negative_rate,
      head_batch_flag,
      verbose
    )
    |> case do
      {:error, _} -> nil
      {:ok, data} -> Grapex.Patterns.MeagerDecoder.decode(data, batch_size, entity_negative_rate, relation_negative_rate, n_observed_triples_per_pattern_instance, pattern)
    end
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

  defp _init_evaluator(_a, _b, _c, _d) do
    raise "NIF _init_evaluator/4 not implemented"
  end

  @spec init_evaluator!(list, atom, atom, boolean) :: atom
  def init_evaluator!(metrics, task, subset, verbose \\ false) do
    case _init_evaluator(metrics, task, subset, verbose) do
      {:error, message} -> raise List.to_string(message)
      {:ok, _} -> nil
    end
  end

  defp _trial(_a, _b) do
    raise "NIF _trial/2 not implemented"
  end

  @spec trial!(atom, boolean) :: atom
  def trial!(element, verbose \\ false) do
    case _trial(element, verbose) do
      {:error, message} -> raise List.to_string(message)
      {:ok, data} -> data |> Grapex.Patterns.MeagerDecoder.decode
    end
  end

  defp _evaluate(_a, _b, _c, _d) do
    raise "NIF _evaluate/4 not implemented"
  end

  @spec evaluate!(atom, list, boolean, list) :: atom
  def evaluate!(element, predictions, verbose \\ false, opts \\ []) do
    reverse = Keyword.get(opts, :reverse, false)  # reverse = higher values are better
    case _evaluate(element, predictions, reverse, verbose) do
      {:error, message} -> raise List.to_string(message)
      {:ok, _} -> nil
    end
  end

  defp _compute_metrics(_a) do
    raise "NIF _compute_metrics/1 not implemented"
  end

  @spec compute_metrics!(bool) :: atom
  def compute_metrics!(verbose \\ false) do
    case _compute_metrics(verbose) do
      {:error, message} -> raise List.to_string(message)
      {:ok, metrics} -> metrics
    end
  end

end
