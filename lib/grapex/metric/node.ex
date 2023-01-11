defmodule Grapex.Metric.Node do
  defstruct [:name, value: nil]
end

defimpl Serializer, for: Grapex.Metric.Node do
  # import Bitwise

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

    # IO.puts value
    # IO.inspect <<value::16>> |> :binary.bin_to_list |> Enum.reverse
    # IO.inspect [value &&& 0x00ff | [value >>> 8 | bytes]]

    # [value &&& 0x00ff | [value >>> 8 | bytes]]

    <<value::16>> 
    |> :binary.bin_to_list
    |> Enum.reverse
    |> reverse(bytes)
  end

  def serialize(%Grapex.Metric.Node{name: name, value: value}, bytes) do
    case value do
      nil ->
        encode_string(name, bytes)
      _ ->
        case name do
          {name, parameter} -> 
            {
              <<value::float-64>> |> :binary.bin_to_list,
              [1 | encode_string(name, encode_parameter(parameter, bytes))]  # 1 parameter
            }
          name -> 
            {
              <<value::float-64>> |> :binary.bin_to_list,
              [0 | encode_string(name, bytes)]  # 0 parameters
            }
        end
    end
  end
end
