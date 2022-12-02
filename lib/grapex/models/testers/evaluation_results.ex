defmodule Grapex.EvaluationResults do
  defstruct [:data]

  def puts(%Grapex.EvaluationResults{data: data}, opts \\ []) do
    accuracy = Keyword.get(opts, :accuracy, 5)
    value_column_width = Keyword.get(opts, :value_column_width, 16)
    label_column_width = Keyword.get(opts, :label_column_width, 32)

    metrics = get_metric_names(data)
    metrics
    |> Enum.map(
      fn x ->
        case x do
          {metric, parameter} -> "#{metric}@#{parameter}"
          res -> Atom.to_string(res)
        end
        |> String.pad_trailing(value_column_width)
      end
    )
    |> Enum.join
    |> String.pad_leading(label_column_width + value_column_width * length(metrics))
    |> IO.puts

    get_metric_values(data, accuracy, value_column_width, label_column_width)
    |> List.flatten
    |> Enum.join("\n")
    |> IO.puts

    transpose(data) |> Enum.map(fn x -> Stats.mean(x) end) |> stringify_metrics("average", accuracy, value_column_width, label_column_width) |> IO.puts
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

  defp get_metric_names([]) do
    []
  end

  defp get_metric_names([head | tail]) do
    case head do
      {label, [nested_head | nested_tail] = items} -> get_metric_names(items)
      {metric, value} -> [metric | get_metric_names(tail)]
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

    "#{title |> String.pad_trailing(label_column_width)}#{stringified_values}"
  end

  defp get_metric_values(items, accuracy, value_column_width, label_column_width, labels \\ []) do
    Enum.map(
      items, fn item -> 
        case item do
          # Current and next label contain lists
          {label, [{nested_label, [nested_nested_head | nested_nested_tail]} | nested_tail] = items} -> get_metric_values(items, accuracy, value_column_width, label_column_width, [label | labels])
          {label, [{nested_label, nested_value} | nested_tail] = items} ->  # Current label contains list, but next label does not
            values = items
            |> Enum.map(
              fn item -> 
                elem(item, 1)  # Get metric value
              end
            )

            title =
              [label | labels]
              |> Enum.reverse
              |> Enum.join(" ")
              |> String.pad_trailing(label_column_width)

            stringified_values = 
              values
              |> Enum.map(
                fn x ->
                  Float.to_string(x, decimals: accuracy)
                  |> String.pad_trailing(value_column_width)
                end
              )
              |> Enum.join

            "#{title}#{stringified_values}"
        end
      end
    )
  end
end
