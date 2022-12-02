defmodule Grapex.EvaluationResults do
  defstruct [:data]

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

  defp transpose([head | tail] = items, transposed) do
    transposed = case head do
      {label, [{nested_label, [nested_nested_head | nested_nested_tail]} | nested_tail] = nested_items} -> transpose(nested_items, transposed)
      {label, [{nested_label, nested_value} | nested_tail] = items} ->  # Current label contains list, but next label does not
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
