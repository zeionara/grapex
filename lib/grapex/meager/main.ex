defmodule Grapex.Meager do

  @valid_subsets [
    :train,
    :test,
    :valid
  ]

  @valid_patterns [
    nil,
    :none,
    :symmetric,
    :inverse
  ]

  @valid_tasks [
    :link_prediction,
    :triple_classification
  ]

  @valid_triple_components [
    :head,
    :tail
  ]

end
