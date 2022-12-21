defmodule Grapex.Meager.CorpusConfig do
  @enforce_keys [
    :path,
    :enable_filter,
    :drop_pattern_duplicates,
    :drop_filter_duplicates
  ]
  defstruct @enforce_keys
end
