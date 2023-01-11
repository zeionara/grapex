defmodule Grapex.Metric.Node do
  defstruct [:name, value: nil]
end

defimpl Serializer, for: Grapex.Metric.Node do
  import Grapex.Option, only: [opt: 2]

  @max_parameter 0xffff

  defp prepend(byte, bytes) when is_integer(byte) do
    [byte | bytes]
  end

  defp reverse([head | []], bytes) do
    prepend(head, bytes)
  end

  defp reverse([head | tail], bytes) do
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
    |> reverse(bytes)
  end

  defp encode_value(value, bytes) do
    <<value::float-64>>
    |> :binary.bin_to_list # in big-endian
    |> Enum.reverse
    |> reverse(bytes)
  end

  defp encode_name({name, parameter}, bytes) do
    [1 | encode_string(name, encode_parameter(parameter, bytes))]  # 1 parameter
  end

  defp encode_name(name, bytes) do
    [0 | encode_string(name, bytes)]  # 0 parameters
  end

  def serialize(%Grapex.Metric.Node{name: name, value: value}, opts \\ []) do
    case value do
      nil ->
        encode_string(name, (opt :bytes, else: []))
      _ ->
        if opt :value_only, else: false do
          encode_value(value, (opt :value_bytes, else: []))
        else 
          if opt :name_only, else: false do
            encode_name(name, (opt :name_bytes, else: []))
          else
            {
              encode_value(value, (opt :value_bytes, else: [])),
              encode_name(name, (opt :name_bytes, else: []))
            }
          end
        end
    end
  end
end
