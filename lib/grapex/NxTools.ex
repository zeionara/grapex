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

  # defp delete_leading_dimensions(shape, n_dimensions) when n_dimensions <= 0 do
  #   shape
  # end

  # defp delete_leading_dimensions(shape, n_dimensions) do
  #   Tuple.delete_at(shape, 0)
  #   |> delete_leading_dimensions(n_dimensions - 1) 
  # end

  def flatten_leading_dimensions(tensor, n_dimensions) do
    Nx.reshape(
      tensor,
      tensor
      |> Nx.shape
      |> Grapex.TupleUtils.delete_first(n_dimensions)
      # |> delete_leading_dimensions(n_dimensions)
      |> Tuple.insert_at(0, :auto)
    )
  end
end

