defmodule Grapex.Model do
  
  alias Grapex.Model
  alias Grapex.Config

  alias Grapex.Model.Transe

  defmacro __using__(_) do
    quote do

      @valid_models [
        :transe
      ]

    end
  end

  @enforce_keys [
    :model,

    :hidden_size,
    :reverse
  ]

  defstruct [
    :n_entities,
    :n_relations,
    :entity_size,
    :relation_size | @enforce_keys
  ]


  def init(
    %Config{
      model: %Model{
        model: model_type
      } = model,
      corpus: corpus,
      trainer: trainer
    },
    _opts \\ []
  ) do
    case model_type do
      :transe -> {Transe.init(model, corpus, trainer, verbose: true), Transe}
      _ -> raise "Unknown model type"
    end
  end

end
