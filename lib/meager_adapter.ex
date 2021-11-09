defmodule Meager do
  @on_load :load_nifs
  # @dialyzer {:nowarn_function, rollback: 1}

  def load_nifs do
    :erlang.load_nif('/usr/lib/libmeager', 0)
  end

  def set_in_path(_a, _b, _c, _d) do
    raise "NIF set_in_path/4 not implemented"
  end

  def handle_errors(f) do
    try do
      f.()
    catch 
      :error, message -> IO.puts "Error #{message}"; {:error, message}
    end
  end

  def set_input_path(path, as_tsv) do
    # case set_in_path(String.to_charlist(path), as_tsv, String.length(path), String.length(Atom.to_string(as_tsv))) do
    #   {:ok, body} -> IO.puts("Success: #{body}"); body
    #   {:error, reason} -> IO.puts("Error: #{reason}"); reason
    # end
    # try do
    #   set_in_path(String.to_charlist(path), as_tsv, String.length(path), String.length(Atom.to_string(as_tsv)))
    # catch 
    #   :error, message -> IO.puts "Error #{message}"; {:error, message}
    #   #  e in RumtimeError -> IO.puts("Unexpected error: " <> e.message)
    # end
    # |> IO.puts
    fn() -> set_in_path(String.to_charlist(path), as_tsv, String.length(path), String.length(Atom.to_string(as_tsv))) end
    |> handle_errors
  end

  def set_bern(_a) do
    raise "NIF set_bern/1 not implemented"
  end

  def set_bern_flag(value) do
    try do
      set_bern(if value, do: 1, else: 0)
    catch
      :error, message -> IO.puts "Error #{message}"; {:error, message}
    end
  end
end

