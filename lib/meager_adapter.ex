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

  # def print_smth(verbose \\ false) do
  #   IO.puts("ddd")
  #   encoded = import_train_files(verbose, String.length(Atom.to_string(verbose)))
  # end
end

