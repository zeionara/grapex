defmodule Grapex.Optimizer do
  require Grapex.PersistedStruct

  Grapex.PersistedStruct.init [
    required_keys: [
      optimizer: nil,
      alpha: nil,
    ],

    attributes: [
      valid_optimizers: [
        :sgd,
        :adam,
        :adamw,
        :adagrad
      ]
    ]
  ]

  defmacro __using__(_) do
    quote do
      @valid_optimizers unquote(@valid_optimizers)
    end
  end

end
