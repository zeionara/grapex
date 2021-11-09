defmodule FastCompare do
  # @on_load :load_nifs

  # def load_nifs do
  #   :erlang.load_nif('/usr/lib/libmeager', 0)
  # end

  def fast_compare(_a, _b) do
    raise "NIF fast_compare/2 not implemented"
  end

end

