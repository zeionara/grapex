defmodule Grapex.Config do
  require Grapex.PersistedStruct
  # use Grapex.PersistedStruct, 
  Grapex.PersistedStruct.init [
    required_keys: [
      corpus: nil,
      sampler: nil,
      evaluator: nil,

      model: &Grapex.Model.import/1,
      trainer: nil,
      optimizer: &Grapex.Optimizer.import/1,
      checkpoint: nil
    ]
  ]

  # @enforce_keys [
  #   :corpus,
  #   :sampler,
  #   :evaluator,

  #   :model,
  #   :trainer,
  #   :optimizer,
  #   :checkpoint,
  # ]

  # @key_handlers %{
  #   :model => &Grapex.Model.import/1
  # }

  # @keys @enforce_keys

  # defstruct @keys
  # # defstruct [:foo, :bar]

  def import(path) when not is_map(path) do
    config = YamlElixir.read_from_file!(path, atoms: true)
    Grapex.Config.import(config)
  end
  # def import(path) do
  #   config = YamlElixir.read_from_file!(path, atoms: true)

  #   for key <- @keys do
  #     case Map.get(config, key) do
  #       nil -> nil # raise "No key #{key} in file #{path}"
  #       values ->
  #         case @key_handlers[key] do
  #           nil -> values
  #           handler -> handler.(values)
  #         end
  #         # short_module_name =
  #         #   key
  #         #   |> Atom.to_string
  #         #   |> String.capitalize
  #         # apply(String.to_existing_atom("Elixir.Grapex.#{short_module_name}"), :import, [values])
  #     end
  #   end

  # end

end
