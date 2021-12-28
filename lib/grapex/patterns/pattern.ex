defprotocol PatternOccurrence do
  @spec to_tensor(map, map, list) :: map
  def to_tensor(occurrence, patterns, opts \\ [])
end

