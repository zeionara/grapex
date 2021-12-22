defmodule NxTools do

  defp new_axes_(x, axes) when axes == [] do
    x
  end

  defp new_axes_(x, axes) do
    [axis | tail] = axes

    Nx.new_axis(x, 0)
    |> Nx.tile([axis | (for _ <- 1..tuple_size(Nx.shape(x)), do: 1)])
    |> new_axes_(tail)
  end

  def new_axes(x, axes) do
    new_axes_(x, axes |> Enum.reverse)
  end

end

