defmodule Grapex.EvaluationResults do
  import Grapex.Option, only: [opt: 2]
  import Grapex.Metric.Metree.Transposer

  defstruct [:data]

  @default_accuracy 5

  @default_value_column_width 16
  @default_label_column_width 32

  # Puts

  def puts(%Grapex.EvaluationResults{data: data}, opts \\ []) do
    accuracy = opt :accuracy, else: @default_accuracy  # Keyword.get(opts, :accuracy, 5)
    value_column_width = opt :value_column_width, else: @default_value_column_width  # Keyword.get(opts, :value_column_width, 16)
    label_column_width = opt :label_column_width, else: @default_label_column_width  # Keyword.get(opts, :label_column_width, 32)

    metric_names = get_metric_names(data, "", opts)

    metric_names
    |> String.pad_leading(label_column_width + String.length(metric_names))
    |> IO.puts

    get_metric_values(data, "", [], opts)
    |> IO.puts

    transpose(data)
    |> Enum.map(fn x -> Stats.mean(x) end)
    |> stringify_metrics("mean", accuracy, value_column_width, label_column_width)
    |> IO.puts

    transpose(data)
    |> Enum.map(fn x -> Stats.std(x) end)
    |> stringify_metrics("standard deviation", accuracy, value_column_width, label_column_width)
    |> IO.puts
  end

  defp stringify_metrics(values, title, accuracy, value_column_width, label_column_width) do
    stringified_values = 
      values
      |> Enum.map(
        fn x ->
          :erlang.float_to_binary(x, decimals: accuracy)
          |> String.pad_trailing(value_column_width)
        end
      )
      |> Enum.join

    (title |> String.pad_trailing(label_column_width)) <> stringified_values
  end

  defp get_metric_names(items, line, opts)

  defp get_metric_names([] = _items, line, _opts) do
    line
  end

  defp get_metric_names([head | tail], line, opts) do
    case head do
      {_label, [_nested_head | _nested_tail] = items} -> get_metric_names(items, line, opts)  # if current node is not a leaf
      {metric, _value} ->  # if current node is a leaf
        value_column_width = opt :value_column_width, else: @default_value_column_width

        stringified_metric = case metric do
          {metric, parameter} -> "#{metric}@#{parameter}"
          res -> Atom.to_string(res)
        end
        |> String.pad_trailing(value_column_width)

        get_metric_names(tail, line <> stringified_metric, opts) # after handling the first leaf the algorithm completes
    end
  end

  defp get_metric_values(items, line, labels, opts)

  defp get_metric_values([], line, _labels, _opts) do
    line
  end

  defp get_metric_values([head | tail] = _items, line, labels, opts) do
    accuracy = opt :accuracy, else: @default_accuracy
    value_column_width = opt :value_column_width, else: @default_value_column_width
    label_column_width = opt :label_column_width, else: @default_label_column_width

    line = case head do
      {label, [{_nested_label, [_nested_nested_head | _nested_nested_tail]} | _nested_tail] = items} -> get_metric_values(items, line, [label | labels], opts) # Current and next label contain lists
      {label, [{_nested_label, _nested_value} | _nested_tail] = items} ->  # Current label contains list, but next label does not
        stringified_values = 
          items
          |> Enum.map(
            fn item -> 
              item
              |> elem(1)  # Get metric value
              |> :erlang.float_to_binary(decimals: accuracy)
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
    get_metric_values(tail, line, labels, opts)
  end
end
