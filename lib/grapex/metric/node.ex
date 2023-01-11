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
        # name_bytes = opt :name_bytes, else: []

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
        # case name do
        #   {name, parameter} -> 
        #     {
        #       <<value::float-64>>
        #       |> :binary.bin_to_list # in big-endian
        #       |> Enum.reverse
        #       |> reverse(value_bytes),
        #       [1 | encode_string(name, encode_parameter(parameter, name_bytes))]  # 1 parameter
        #     }
        #   name -> 
        #     {
        #       <<value::float-64>>
        #       |> :binary.bin_to_list
        #       |> Enum.reverse
        #       |> reverse(value_bytes), # in big-endian
        #       [0 | encode_string(name, name_bytes)]  # 0 parameters
        #     }
        # end
    end
  end
end
