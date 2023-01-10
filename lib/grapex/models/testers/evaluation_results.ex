defmodule Grapex.EvaluationResults.Tree do
  import Bitwise

  @max_length 127

  defstruct [:length, is_leaf: false]

  def bytes(%Grapex.EvaluationResults.Tree{length: length, is_leaf: is_leaf}) do
    if length > @max_length do
      raise ArgumentError, message: "Branching factor cannot be greater than #{@max_length}"
    end

    if is_leaf do
      [length ||| 0xf0]
    else
      [length]
    end
  end
end

defprotocol Serializer do
  @fallback_to_any true

  @spec serialize(t, list) :: list
  def serialize(value, bytes)
end

defimpl Serializer, for: Grapex.EvaluationResults.Tree do
  import Bitwise

  @max_length 127

  def serialize(%Grapex.EvaluationResults.Tree{length: length, is_leaf: is_leaf}, bytes) do
    if length > @max_length do
      raise ArgumentError, message: "Branching factor cannot be greater than #{@max_length}"
    end

    if is_leaf do
      [length ||| 0xf0 | bytes]
    else
      [length | bytes]
    end
  end
end

defimpl Serializer, for: Any do
  def serialize(value, bytes) do
    [value | bytes]
  end
end

defmodule Grapex.EvaluationResults.Node do
  defstruct [:name, value: nil]
end

defimpl Serializer, for: Grapex.EvaluationResults.Node do
  import Bitwise

  @max_parameter 65535

  def encode_string_([head | []], bytes) do # reverse and append bytes
    encode_string_(head, bytes)
  end

  def encode_string_([head | tail], bytes) do # reverse and append bytes
    encode_string_(tail, encode_string_(head, bytes)) 
  end

  def encode_string_(head, bytes) do
    [head | bytes]
  end

  def encode_string(string, bytes) do
    # [
    #   0
    #   | string
    #   |> Atom.to_string
    #   |> to_charlist
    #   |> Enum.reverse
    # ]
    # |> Enum.reverse
    [
      0
      | string
      |> Atom.to_string
      |> to_charlist
      |> Enum.reverse
    ]
    |> encode_string_(bytes)
  end

  def encode_parameter(value, bytes) do  # 2 bytes, little-endian
    if value > @max_parameter do
      raise ArgumentError, message: "Parameter cannot be greater than #{@max_parameter}"
    end

    [value &&& 0x00ff | [value >>> 8 | bytes]]
  end

  def serialize(%Grapex.EvaluationResults.Node{name: name, value: value}, bytes) do
    case value do
      nil -> encode_string(value, bytes)
      _ ->
        case name do
          {name, parameter} -> [1 | encode_string(name, encode_parameter(parameter, bytes))]  # 1 parameter
          value -> [0 | encode_string(value, bytes)]  # 0 parameters
        end
    end
  end
end

defmodule Grapex.EvaluationResults do
  import Bitwise

  defstruct [:data]

  defp _flatten({label, [_head | _tail] = items}, flat) do
    [%Grapex.EvaluationResults.Node{:name => label} | _flatten(items, true, flat)]
    # [%Grapex.EvaluationResults.Node{:name => label} | [:foo, :bar]]
  end

  defp _flatten({label, value}, flat) do
    [%Grapex.EvaluationResults.Node{:name => label, :value => value} | flat]
    # [%Grapex.EvaluationResults.Node{:name => label} | [:foo, :bar]]
  end

  defp _flatten([], _first, flat) do
    flat
  end

  defp _flatten([head | tail] = items, first, flat) do
    if first do
      is_leaf = case head do
        {_label, [_head | _tail]} -> false
        _ -> true
      end
      # IO.inspect _flatten(items, false, flat)
      [%Grapex.EvaluationResults.Tree{:length => length(items), is_leaf: is_leaf} | _flatten(items, false, flat)]
    else
      # [_flatten(head, tail) | _flatten(tail, false, flat)]
      _flatten(head, _flatten(tail, false, flat))
      # IO.inspect _flatten(head, tail)
      # [_flatten(head, tail) | [:qux, :quux]]
    end
  end

  def flatten(%Grapex.EvaluationResults{data: data}, _opts \\ []) do
    _flatten(data, true, [])
  end

  def serialize(value, _opts \\ [])

  def serialize([] = value, _opts) do
    value = 1000
    IO.inspect [value &&& 0x00ff, value >>> 8]
    %Grapex.EvaluationResults.Node{name: {:top_n, 1000}, value: 1.0} |> Serializer.serialize([]) |> IO.inspect
    value
  end

  def serialize([head | tail], _opts) do
    Serializer.serialize(head, serialize(tail))
  end

  def puts(%Grapex.EvaluationResults{data: data}, opts \\ []) do
    accuracy = Keyword.get(opts, :accuracy, 5)
    value_column_width = Keyword.get(opts, :value_column_width, 16)
    label_column_width = Keyword.get(opts, :label_column_width, 32)

    metrics = get_metric_names(data, value_column_width)

    metrics |> String.pad_leading(label_column_width + String.length(metrics)) |> IO.puts

    get_metric_values(data, accuracy, value_column_width, label_column_width) |> IO.puts

    transpose(data) |> Enum.map(fn x -> Stats.mean(x) end) |> stringify_metrics("mean", accuracy, value_column_width, label_column_width) |> IO.puts
    transpose(data) |> Enum.map(fn x -> Stats.std(x) end) |> stringify_metrics("standard deviation", accuracy, value_column_width, label_column_width) |> IO.puts
  end

  defp transpose(items, transposed \\ [])

  defp transpose([], transposed) do
    transposed
  end

  defp transpose([head | tail], transposed) do
    transposed = case head do
      {_label, [{_nested_label, [_nested_nested_head | _nested_nested_tail]} | _nested_tail] = nested_items} -> transpose(nested_items, transposed)  # if current node is not a leaf
      {_label, [{_nested_label, _nested_value} | _nested_tail] = items} ->  # if current node is a leaf
        case transposed do
          [] -> items |> Enum.map(fn x -> [x |> elem(1) | []] end)
          _ -> items |> Enum.with_index |> Enum.map(fn {x, i} -> [x |> elem(1) | transposed |> Enum.at(i)] end)
        end
    end
    transpose(tail, transposed) 
  end

  defp get_metric_names(items, value_column_width, line \\ "")

  defp get_metric_names([], value_column_width, line) do
    line
  end

  defp get_metric_names([head | tail], value_column_width, line) do
    case head do
      {label, [nested_head | nested_tail] = items} -> get_metric_names(items, value_column_width, line)
      {metric, value} ->
        stringified_metric = case metric do
          {metric, parameter} -> "#{metric}@#{parameter}"
          res -> Atom.to_string(res)
        end
        |> String.pad_trailing(value_column_width)

        get_metric_names(tail, value_column_width, line <> stringified_metric)
    end
  end

  defp stringify_metrics(values, title, accuracy, value_column_width, label_column_width) do
    stringified_values = 
      values
      |> Enum.map(
        fn x ->
          Float.to_string(x, decimals: accuracy)
          |> String.pad_trailing(value_column_width)
        end
      )
      |> Enum.join

    (title |> String.pad_trailing(label_column_width)) <> stringified_values
  end

  defp get_metric_values(items, accuracy, value_column_width, label_column_width, line \\ "", labels \\ [])

  defp get_metric_values([], accuracy, value_column_width, label_column_width, line, labels) do
    line
  end

  defp get_metric_values([head | tail] = items, accuracy, value_column_width, label_column_width, line, labels) do
    line = case head do
      # Current and next label contain lists
      {label, [{nested_label, [nested_nested_head | nested_nested_tail]} | nested_tail] = items} -> get_metric_values(items, accuracy, value_column_width, label_column_width, line, [label | labels])
      {label, [{nested_label, nested_value} | nested_tail] = items} ->  # Current label contains list, but next label does not
        stringified_values = items
        |> Enum.map(
          fn item -> 
            elem(item, 1)  # Get metric value
            |> Float.to_string(decimals: accuracy)
            |> String.pad_trailing(value_column_width)
          end
        )
        |> Enum.join

        title =
          [label | labels]
          |> Enum.reverse
          |> Enum.join(" ")
          |> String.pad_trailing(label_column_width)

        case line do
          "" -> title <> stringified_values
          _ -> line <> "\n" <> title <> stringified_values
        end
    end
    get_metric_values(tail, accuracy, value_column_width, label_column_width, line, labels)
  end
end
