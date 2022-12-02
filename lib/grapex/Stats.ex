defmodule Stats do
  import Enum, only: [map: 2, sum: 1]
  import :math, only: [sqrt: 1, pow: 2]

  def mean(values) do
    case values do
      [] -> {:error, "Cannot compute mean of an empty list"}
      _ -> sum(values) / length(values)
    end
  end

  def variance(values) do
    mean_ = mean(values)

    case values do
      [] -> {:error, "Cannot compute variance of an empty list"}
      _ -> for x <- values do pow(x - mean_, 2) end |> mean
    end
  end

  def std(values) do
    case values do
      [] -> {:error, "Cannot compute standard deviation of an empty list"}
      _ -> values |> variance |> sqrt
    end

  end

end
