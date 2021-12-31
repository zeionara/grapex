defmodule Grapex.TupleUtils do
  def delete_first(tuple, n_elements \\ 1)

  def delete_first(tuple, n_elements) when n_elements <= 0 do
    tuple
  end

  def delete_first(tuple, n_elements) do
    Tuple.delete_at(tuple, 0)
    |> delete_first(n_elements - 1) 
  end

  def delete_last(tuple, n_elements \\ 1)

  def delete_last(tuple, n_elements) when n_elements <= 0 do
    tuple
  end

  def delete_last(tuple, n_elements) do
    Tuple.delete_at(tuple, tuple_size(tuple) - 1)
    |> delete_last(n_elements - 1) 
  end

  def last(tuple) do
    elem(tuple, tuple_size(tuple) - 1)
  end

  def elems(tuple, indices) do 
    for index <- indices do
      elem(tuple, index)
    end
  end
end

