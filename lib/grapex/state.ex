defmodule Grapex.State do

  @enforce_keys [
    :config,
    :instance,
    :weights,
    :module,
  ]

  defstruct @enforce_keys

end
