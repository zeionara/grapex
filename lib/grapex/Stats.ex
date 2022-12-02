defmodule Stats do
  import Enum, only: [map: 2, sum: 1]

  def mean(values) do
    case values do
      [] -> {:error, "Cannot compute mean of an empty list"}
      _ -> sum(values) / length(values)
    end
  end

end
