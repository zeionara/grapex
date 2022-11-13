defmodule Grapex.IOutils do
  def inspect(x, message \\ nil) do
    unless message == nil do
      IO.puts message
    end

    x
    |> IO.inspect

    x
  end

  def inspect_shape(x, message \\ nil) do
    unless message == nil do
      IO.puts message
    end

    x
    |> Nx.shape
    |> IO.inspect

    x
  end

  def clear_lines(n_lines \\ 1) do
    for _ <- 1..n_lines do
      IO.write "\x1b[F"
      # IO.write "\033[F\033[F\033[F"
      IO.write "\r\x1b[K"
    end
  end
end

