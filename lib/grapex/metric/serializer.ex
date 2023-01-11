defprotocol Serializer do
  @fallback_to_any true

  @spec serialize(t, list) :: list
  def serialize(value, bytes)
end

defimpl Serializer, for: Any do
  def serialize(value, bytes) do # by default there is no serialization - the object is taken as-is and added to the beginning of byte sequence
    [value | bytes]
  end
end
