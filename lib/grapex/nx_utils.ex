defmodule Grapex.NxUtils do

  defp new_axes_(x, axes) when axes == [] do
    x
  end

  defp new_axes_(x, axes) do
    [axis | tail] = axes

    # Nx.new_axis(x, 0)
    # |> Nx.tile([axis | (for _ <- 1..tuple_size(Nx.shape(x)), do: 1)])
    reshaped_x = x # Nx.reshape(x, Tuple.insert_at(Nx.shape(x), 0, 1))

    for _ <- 1..axis do reshaped_x end
    |> Nx.stack
    |> new_axes_(tail)
  end

  def new_axes(x, axes) do
    new_axes_(x, axes |> Enum.reverse)
  end

  def flatten_leading_dimensions(tensor, n_dimensions) do
    Nx.reshape(
      tensor,
      tensor
      |> Nx.shape
      |> Grapex.TupleUtils.delete_first(n_dimensions)
      |> Tuple.insert_at(0, :auto)
    )
  end
end

