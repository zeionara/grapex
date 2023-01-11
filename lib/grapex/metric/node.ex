defmodule Grapex.Metric.Node do
  defstruct [:name, value: nil]
end

defimpl Serializer, for: Grapex.Metric.Node do
  import Grapex.Option, only: [opt: 2]

  @max_parameter 0xffff

  defp prepend(byte, bytes) when is_integer(byte) do
    [byte | bytes]
  end

  defp reverse([head | []], bytes) do # reverse and append bytes
    prepend(head, bytes)
  end

  defp reverse([head | tail], bytes) do # reverse and append bytes
    reverse(tail, prepend(head, bytes)) 
  end

  defp encode_string(string, bytes) do
    [
      0
      | string
      |> Atom.to_string
      |> to_charlist
      |> Enum.reverse
    ]
    |> reverse(bytes)
  end

  defp encode_parameter(value, bytes) do  # 2 bytes, little-endian
    if value > @max_parameter do
      raise ArgumentError, message: "Parameter cannot be greater than #{@max_parameter} but is equal to #{value}"
    end

    <<value::16>> 
    |> :binary.bin_to_list
    # |> Enum.reverse # convert from big-endian to little-endian
    |> reverse(bytes)
  end

  def serialize(%Grapex.Metric.Node{name: name, value: value}, opts \\ []) do
    case value do
      nil ->
        encode_string(name, (opt :bytes, else: []))
      _ ->
        value_bytes = opt :value_bytes, else: []
        name_bytes = opt :name_bytes, else: []

        case name do
          {name, parameter} -> 
            {
              <<value::float-64>>
              |> :binary.bin_to_list # in big-endian
              |> Enum.reverse
              |> reverse(value_bytes),
              [1 | encode_string(name, encode_parameter(parameter, name_bytes))]  # 1 parameter
            }
          name -> 
            {
              <<value::float-64>>
              |> :binary.bin_to_list
              |> Enum.reverse
              |> reverse(value_bytes), # in big-endian
              [0 | encode_string(name, name_bytes)]  # 0 parameters
            }
        end
    end
  end
end
