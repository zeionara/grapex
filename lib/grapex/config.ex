defmodule Grapex.Config do

  @enforce_keys [
    :corpus,
    :sampler,
    :evaluator,

    :model,
    :trainer,
    :optimizer,
    :checkpoint,
  ]

  @keys @enforce_keys

  defstruct @keys

  def import(path) do
    config = YamlElixir.read_from_file!(path, atoms: true)

    for key <- @keys do
      case Map.get(config, key) do
        nil -> nil # raise "No key #{key} in file #{path}"
        values ->
          short_module_name =
            key
            |> Atom.to_string
            |> String.capitalize
          apply(String.to_existing_atom("Elixir.Grapex.#{short_module_name}"), :import, [values])
      end
    end

  end

end
