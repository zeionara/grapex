defmodule Grapex.Checkpoint do

  alias Grapex.Checkpoint

  @filename "weights"

  @enforce_keys [
    :root,
    :frequency
  ]

  @valid_formats [
    :binary
  ]

  defstruct @enforce_keys

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
