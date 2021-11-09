defmodule Meager do
  @on_load :load_nifs

  def load_nifs do
    :erlang.load_nif('/usr/lib/libmeager', 0)
  end

  def set_in_path(_a, _b, _c, _d) do
    raise "NIF set_in_path/4 not implemented"
  end

  def set_input_path(path, as_tsv) do
    set_in_path(String.to_charlist(path), as_tsv, String.length(path), String.length(Atom.to_string(as_tsv)))
  end

  def set_bern(_a) do
    raise "NIF set_bern/1 not implemented"
  end

  def set_bern_flag(value) do
    set_bern(if value, do: 1, else: 0)
  end
end

