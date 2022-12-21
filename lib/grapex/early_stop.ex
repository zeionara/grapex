defmodule Grapex.EarlyStop do

  @enforce_keys [
    :patience,
    :min_delta
  ]

  defstruct @enforce_keys

end
