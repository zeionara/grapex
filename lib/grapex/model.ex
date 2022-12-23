defmodule Grapex.Model do
  
  alias Grapex.Model
  alias Grapex.Config

  alias Grapex.Model.Transe

  require Grapex.PersistedStruct

  Grapex.PersistedStruct.init [
    required_keys: [
      model: nil,

      hidden_size: nil,
      reverse: nil
    ],

    optional_keys: [
      entity_size: nil,
      relation_size: nil
    ],

    attributes: [
      valid_models: [
        :transe,
        :complex
      ]
    ],

    validate: &Grapex.Model.validate/1
  ]

  defmacro __using__(_) do
    quote do
      @valid_models unquote(@valid_models)
    end
  end

  def init(
    %Config{
      model: %Model{
        model: model_type
      } = model,
      corpus: corpus,
      trainer: trainer
    },
    _opts \\ []
  ) when model_type in @valid_models do
    case model_type do
      :transe -> {Transe.init(model, corpus, trainer, verbose: true), Transe}
      _ -> raise "Unknown model type"
    end
  end

  def validate(%Grapex.Model{hidden_size: hidden_size, entity_size: entity_size, relation_size: relation_size} = model) do
    if not is_nil(hidden_size) and (not is_nil(entity_size) or not is_nil(relation_size)) do
      raise "Either hidden size, either entity size and relation size must be passed, but not both"
    end
    if not is_nil(entity_size) and is_nil(relation_size) or is_nil(entity_size) and not is_nil(relation_size) do
      raise "If hidden size is not specified then both - entity size and relation size must be set"
    end
    model
  end

end
