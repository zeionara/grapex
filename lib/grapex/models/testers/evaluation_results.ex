defmodule Grapex.EvaluationResults do
  defstruct [:data]

  # Flatten

  defp _flatten({label, [_head | _tail] = items}, flat) do
    [%Grapex.Metric.Node{:name => label} | _flatten(items, true, flat)]
  end

  defp _flatten({label, value}, flat) do
    [%Grapex.Metric.Node{:name => label, :value => value} | flat]
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
      [%Grapex.Metric.Tree{:length => length(items), is_leaf: is_leaf} | _flatten(items, false, flat)]
    else
      _flatten(head, _flatten(tail, false, flat))
    end
  end

  def flatten(%Grapex.EvaluationResults{data: data}, _opts \\ []) do
    _flatten(data, true, [])
  end

  # Serialize

  def serialize_metric_name([%Grapex.Metric.Node{} = head | tail], length) when length == 1 do
    Serializer.serialize(head, [name_only: true, name_bytes: serialize(tail)])
  end

  def serialize_metric_name([%Grapex.Metric.Node{} = head | tail], length) do
    Serializer.serialize(head, [name_only: true, name_bytes: serialize_metric_name(tail, length - 1)])
  end

  def serialize_metric_value([%Grapex.Metric.Node{} = head | _tail], length, bytes) when length == 1 do
    Serializer.serialize(head, [value_only: true, value_bytes: bytes])
  end

  def serialize_metric_value([%Grapex.Metric.Node{} = head | tail], length, bytes) do
    Serializer.serialize(head, [value_only: true, value_bytes: serialize_metric_value(tail, length - 1, bytes)])
  end

  def serialize_([%Grapex.Metric.Node{} = head | tail], length) when length == 1 do
    # IO.puts "following"
    # IO.inspect serialize(tail)
    Serializer.serialize(head, [name_bytes: serialize(tail)])
  end

  def serialize_([%Grapex.Metric.Node{} = head | tail], length) do
    {next_value, next_name} = serialize_(tail, length - 1)
    # IO.puts "next"
    # IO.inspect {next_value, next_name}
    # IO.puts "current"
    Serializer.serialize(head, [value_bytes: next_value, name_bytes: next_name])
    # |> IO.inspect
  end

  def serialize(value, _opts \\ [])

  def serialize([] = value, _opts) do
    value
  end

  def serialize([%Grapex.Metric.Tree{length: length, is_leaf: is_leaf} = head | tail], _opts) when is_leaf == true do

    name = serialize_metric_name(tail, length)
    value = serialize_metric_value(tail, length, name)

    Serializer.serialize(head, [bytes: value])

    # {value, name} = serialize_(tail, length)
    # Serializer.serialize(head, [bytes: value ++ name])
  end

  #

  # def serialize_([], items_left, values, names) when items_left == 0 do
  #   values ++ names
  # end

  # def serialize_([head | tail] = items, items_left, values, names) do
  #   if items_left > 0 do
  #     {value, name} = Serializer.serialize(head, [])
  #     serialize_(tail, items_left - 1, values ++ value, names ++ name)
  #   else
  #     values ++ names ++ serialize(items)  # TODO: optimize this
  #   end
  # end

  # def serialize(value, _opts \\ [])

  # def serialize([] = value, _opts) do
  #   value
  # end

  # def serialize([%Grapex.Metric.Tree{length: length, is_leaf: is_leaf} = head | tail], _opts) when is_leaf == true do
  #   Serializer.serialize(head, [bytes: serialize_(tail, length, [], [])])
  # end

  def serialize([head | tail], _opts) do
    Serializer.serialize(head, [bytes: serialize(tail)])
  end

  # Puts

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
