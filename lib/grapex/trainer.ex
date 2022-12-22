defmodule Grapex.Trainer do

  @enforce_keys [
    :n_epochs,
    :batch_size,

    :entity_negative_rate,
    :relation_negative_rate,

    :margin
  ]

  defstruct @enforce_keys

  def group_size(%Grapex.Trainer{batch_size: batch_size, entity_negative_rate: entity_negative_rate, relation_negative_rate: relation_negative_rate}) do
    batch_size * (1 + entity_negative_rate + relation_negative_rate)
  end

end

# defprotocol Grapex.TrainerProtocol do
# 
#   def train(model, params, corpus, trainer, opts)
# 
# end
