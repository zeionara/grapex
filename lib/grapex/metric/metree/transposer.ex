defmodule Grapex.Metric.Metree.Transposer do

  def transpose(items, transposed \\ [])

  def transpose([], transposed) do
    transposed
  end

  def transpose([head | tail], transposed) do
    transposed = case head do
      {_label, [{_nested_label, [_nested_nested_head | _nested_nested_tail]} | _nested_tail] = nested_items} -> transpose(nested_items, transposed)  # if current node is not a leaf
      {_label, [{_nested_label, _nested_value} | _nested_tail] = items} ->  # if current node is a leaf
        case transposed do
          [] -> 
            items 
            |> Enum.map(
              fn x -> [
                x
                |> elem(1)
                | []
              ] end
            ) # Create N nested arrays, each of which contains one element (N - number of metrics)
          _ -> 
            items
            |> Enum.with_index
            |> Enum.map(
              fn {x, i} -> [
                x
                |> elem(1)
                | transposed
                |> Enum.at(i)
              ] end  # Take value of each metric from #items and prepend it to the #ith nested array
            )
        end
    end
    transpose(tail, transposed) 
  end

end
