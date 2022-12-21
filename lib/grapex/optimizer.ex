defmodule Grapex.Optimizer do

  defmacro __using__(_) do
    quote do

      @valid_optimizers [
        :sgd,
        :adam,
        :adamw,
        :adagrad
      ]

    end
  end

  @enforce_keys [
    :optimizer,
    :alpha
  ]

  defstruct @enforce_keys

end
