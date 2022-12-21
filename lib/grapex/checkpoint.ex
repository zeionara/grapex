defmodule Grapex.Checkpoint do

  @enforce_keys [
    :root,
    :frequency
  ]

  defstruct @enforce_keys

end
