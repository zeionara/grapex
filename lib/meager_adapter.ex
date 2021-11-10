defmodule Meager do
  @on_load :load_nifs
  # @dialyzer {:nowarn_function, rollback: 1}

  defp load_nifs do
    :erlang.load_nif('/usr/lib/libmeager', 0)
  end

  defp set_in_path(_a, _b, _c, _d) do
    raise "NIF set_in_path/4 not implemented"
  end

  defp decode_nif_result(encoded_result) do
    if encoded_result == 0, do: :ok, else: :error
  end

  # defp handle_errors(f) do
  #   try do
  #     f.()
  #   catch 
  #     :error, message -> IO.puts "Error #{message}"; {:error, message}
  #   end
  # end

  #
  #  Settings
  #

  @spec set_input_path(charlist, boolean) :: integer
  def set_input_path(path, as_tsv \\ false) do
    set_in_path(String.to_charlist(path), as_tsv, String.length(path), String.length(Atom.to_string(as_tsv)))
  end

  defp set_bern(_a) do
    raise "NIF set_bern/1 not implemented"
  end

  @spec set_bern_flag(boolean) :: integer
  def set_bern_flag(value \\ true) do
    set_bern(if value, do: 1, else: 0)
  end

  defp set_work_threads(_a) do
    raise "NIF set_work_threads/1 not implemented"
  end

  @spec set_n_workers(integer) :: integer
  def set_n_workers(n_workers \\ 8) do
    set_work_threads(n_workers)
  end


  defp get_relation_total() do
    raise "NIF get_relation_total/0 not implemented"
  end

  @spec n_relations() :: integer
  def n_relations() do
    get_relation_total()
  end

  defp get_entity_total() do
    raise "NIF get_entity_total/0 not implemented"
  end

  @spec n_entities() :: integer
  def n_entities() do
    get_entity_total()
  end

  defp get_train_total() do
    raise "NIF get_train_total/0 not implemented"
  end

  @spec n_train_triples() :: integer
  def n_train_triples() do
    get_train_total()
  end
  
  defp get_test_total() do
    raise "NIF get_test_total/0 not implemented"
  end

  @spec n_test_triples() :: integer
  def n_test_triples() do
    get_test_total()
  end

  defp get_valid_total() do
    raise "NIF get_valid_total/0 not implemented"
  end

  @spec n_valid_triples() :: integer
  def n_valid_triples() do
    get_valid_total()
  end

  #
  #  Randomization
  #

  defp rand_reset() do
    raise "NIF rand_reset/0 not implemented"
  end

  @spec reset_randomizer() :: atom
  def reset_randomizer() do
    rand_reset()
    |> decode_nif_result
  end

  # 
  #  Reading
  #

  defp import_train_files(_a, _b) do
    raise "NIF import_train_files/2 not implemented"
  end

  @spec import_train_files(boolean) :: atom
  def import_train_files(verbose \\ false) do
    import_train_files(verbose, String.length(Atom.to_string(verbose)))
    |> decode_nif_result
  end
  
  defp import_test_files(_a, _b) do
    raise "NIF import_test_files/2 not implemented"
  end

  @spec import_test_files(boolean) :: atom
  def import_test_files(verbose \\ false) do
    import_test_files(verbose, String.length(Atom.to_string(verbose)))
    |> decode_nif_result
  end

  defp import_type_files() do
    raise "NIF import_type_files/0 not implemented"
  end

  @spec read_type_files() :: atom
  def read_type_files() do
    import_type_files()
    |> decode_nif_result
  end
  
  #
  #  Sampling
  #
  
  defp sample(_a, _b, _c, _d, _e) do
    raise "NIF sample/5 not implemented"
  end

  @spec sample(integer, integer, integer, boolean) :: list
  def sample(batch_size \\ 16, entity_negative_rate \\ 1, relation_negative_rate \\ 0, head_batch_flag \\ false) do
    batch = sample(batch_size, entity_negative_rate, relation_negative_rate, head_batch_flag, String.length(Atom.to_string(head_batch_flag)))
    %{
      heads: Enum.at(batch, 0),
      tails: Enum.at(batch, 1),
      relations: Enum.at(batch, 2),
      labels: Enum.at(batch, 3)
    }
  end

  #
  #  Test
  #

  defp get_head_batch() do
    raise "NIF get_head_batch/0 not implemented"
  end

  @spec sample_head_batch() :: map
  def sample_head_batch() do
    batch = get_head_batch()
    %{
      heads: Enum.at(batch, 0),
      tails: Enum.at(batch, 1),
      relations: Enum.at(batch, 2),
    }
  end

  defp test_head(_a) do
    raise "NIF test_head/1 not implemented"
  end

  @spec test_head_batch(list) :: atom
  def test_head_batch(probabilities) do
    test_head(probabilities)
    |> decode_nif_result
  end
  
  defp get_tail_batch() do
    raise "NIF get_tail_batch/0 not implemented"
  end

  @spec sample_tail_batch() :: map
  def sample_tail_batch() do
    batch = get_tail_batch()
    %{
      heads: Enum.at(batch, 0),
      tails: Enum.at(batch, 1),
      relations: Enum.at(batch, 2),
    }
  end

  defp test_tail(_a) do
    raise "NIF test_tail/1 not implemented"
  end

  @spec test_tail_batch(list) :: atom
  def test_tail_batch(probabilities) do
    test_tail(probabilities)
    |> decode_nif_result
  end

  #
  #  Validate
  #

  defp get_valid_head_batch() do
    raise "NIF get_valid_head_batch/0 not implemented"
  end

  @spec sample_validation_head_batch() :: map
  def sample_validation_head_batch() do
    batch = get_valid_head_batch()
    %{
      heads: Enum.at(batch, 0),
      tails: Enum.at(batch, 1),
      relations: Enum.at(batch, 2),
    }
  end

  defp valid_head(_a) do
    raise "NIF valid_head/1 not implemented"
  end

  @spec validate_head_batch(list) :: atom
  def validate_head_batch(probabilities) do
    valid_head(probabilities)
    |> decode_nif_result
  end
  
  defp get_valid_tail_batch() do
    raise "NIF get_valid_tail_batch/0 not implemented"
  end

  @spec sample_validation_tail_batch() :: map
  def sample_validation_tail_batch() do
    batch = get_valid_tail_batch()
    %{
      heads: Enum.at(batch, 0),
      tails: Enum.at(batch, 1),
      relations: Enum.at(batch, 2),
    }
  end

  defp valid_tail(_a) do
    raise "NIF valid_tail/1 not implemented"
  end

  @spec validate_tail_batch(list) :: atom
  def validate_tail_batch(probabilities) do
    valid_tail(probabilities)
    |> decode_nif_result
  end

  defp test_link_prediction(_a, _b) do
    raise "NIF test_link_prediction/2 not implemented"
  end

  @spec test_link_prediction(boolean) :: atom
  def test_link_prediction(as_tsv \\ false) do
    test_link_prediction(as_tsv, String.length(Atom.to_string(as_tsv)))
    |> decode_nif_result
  end
end

