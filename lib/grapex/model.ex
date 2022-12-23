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
    ]
  ],
  [:Grapex, :Model]

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

end
