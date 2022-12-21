defmodule Grapex.Model do

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
  ]

  defstruct [
    :n_entities,
    :n_relations,
    :entity_size,
    :relation_size | @enforce_keys
  ]

end
