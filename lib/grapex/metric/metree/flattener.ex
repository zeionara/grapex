defmodule Grapex.Metric.Metree.Flattener do

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

end
