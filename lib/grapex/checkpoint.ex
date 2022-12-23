defmodule Grapex.Checkpoint do

  alias Grapex.Checkpoint
  alias Grapex.Model
  alias Grapex.Meager.Corpus

  require Grapex.PersistedStruct

  import Grapex.Option, only: [opt: 1]

  Grapex.PersistedStruct.init [
    optional_keys: [
      root: nil,
      frequency: nil,
    ],
    attributes: [
      valid_formats: [
        :binary
      ]
    ]
  ]

  defmacro __using__(_) do
    quote do
      @valid_formats unquote(@valid_formats)
    end
  end

  @filename "weights"

  def path(%Checkpoint{root: root}, format) when root != nil and format in @valid_formats do
    Path.join(
      root,
      "#{@filename}" <>
        case format do
          :binary -> ".bin"
          _ -> raise "Unsupported format {format}"
        end
    )
  end

  def make_root(%Corpus{path: corpus_path}, %Model{model: model}, opts \\ []) do
    [_, cv_split, corpus_name, _, remainder] =
      String.reverse(corpus_path)
      |> String.split("/", parts: 5)

    Path.join(
      [
        String.reverse(remainder),
        'Models',
        String.reverse(corpus_name),
        String.reverse(cv_split),
        Atom.to_string(model),
        case opt :seed do
          nil -> UUID.uuid1()
          seed -> Integer.to_string(seed)
        end
      ]
    )
  end

end
