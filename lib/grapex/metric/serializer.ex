defprotocol Serializer do
  @fallback_to_any true

  @spec serialize(t, list) :: list
  def serialize(value, opts \\ [])
end

defimpl Serializer, for: Any do
  import Grapex.Option, only: [opt: 2]

  def serialize(value, opts \\ []) do # by default there is no serialization - the object is taken as-is and added to the beginning of byte sequence
    bytes = opt :bytes, else: []

    [value | bytes]
  end
end
