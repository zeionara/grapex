defmodule Grapex.IOutils do
  def inspect_shape(x, message \\ nil) do
    unless message == nil do
      IO.puts message
    end

    x
    |> Nx.shape
    |> IO.inspect

    x
  end
end

