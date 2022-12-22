defmodule Grapex.Trainer do

  alias Grapex.Model
  alias Grapex.Config

  alias Grapex.Model.Trainers.MarginBasedTrainer

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

  def init(
    {
      model_instance,
      model_module,
    },
    %Config{
      model: %Model{
        model: model_type
      }
    } = config,
    opts \\ []
  ) do
    case model_type do
      :transe -> MarginBasedTrainer.train(model_instance, model_module, config, opts)
      _ -> raise "Unknown model type"
    end
  end

end
