defmodule Grapex.Metric.Tree do
  defstruct [:length, is_leaf: false]
end

defimpl Serializer, for: Grapex.Metric.Tree do
  import Bitwise

  @max_length 127
  @is_leaf_bit_mask 0x80

  def serialize(%Grapex.Metric.Tree{length: length, is_leaf: is_leaf}, bytes) do
    if length > @max_length do
      raise ArgumentError, message: "Branching factor in tree of metrics cannot be greater than #{@max_length} but it is equal to #{length}"
    end

    if is_leaf do
      [length ||| @is_leaf_bit_mask | bytes]
    else
      [length | bytes]
    end
  end
end
