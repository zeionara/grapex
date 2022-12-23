defmodule Grapex.Checkpoint do

  alias Grapex.Checkpoint

  require Grapex.PersistedStruct

  Grapex.PersistedStruct.init [
    required_keys: [
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

end
