defmodule Grapex.Config do

  @enforce_keys [
    :corpus,
    :sampler,
    :evaluator,

    :model,
    :trainer,
    :optimizer,
    :checkpoint,
  ]

  defstruct @enforce_keys

end
