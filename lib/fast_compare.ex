defmodule FastCompare do
  @on_load :load_nifs

  def load_nifs do
    :erlang.load_nif('/usr/lib/libmeager', 0)
  end

  def fast_compare(_a, _b) do
    raise "NIF fast_compare/2 not implemented"
  end

  def set_in_path(_a, _b, _c, _d) do
    raise "NIF set_in_path/4 not implemented"
  end

  def set_in_path(path, as_tsv) do
    set_in_path(String.to_charlist(path), as_tsv, String.length(path), String.length(Atom.to_string(as_tsv)))
  end
end

