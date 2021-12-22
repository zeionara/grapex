defprotocol PatternOccurrence do
  @spec to_tensor(map) :: map
  def to_tensor(occurrence)
end

