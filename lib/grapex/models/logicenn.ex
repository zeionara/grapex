defmodule Grapex.Model.Logicenn do
  require Axon

  defp new_axes_(x, axes) when axes == [] do
    x
  end

  defp new_axes_(x, axes) do
    [axis | tail] = axes

    Nx.new_axis(x, 0)
    |> Nx.tile([axis | (for _ <- 1..tuple_size(Nx.shape(x)), do: 1)])
    |> new_axes_(tail)
  end

  defp new_axes(x, axes) do
    new_axes_(x, axes |> Enum.reverse)
  end

  defp relation_embeddings(%Axon{output_shape: parent_shape} = x, n_relations, opts \\ []) do
    n_hidden_units = elem(parent_shape, tuple_size(parent_shape) - 1)

    output_shape = parent_shape
                   |> Tuple.delete_at(tuple_size(parent_shape) - 1)
                   |> Tuple.append(n_relations)

    kernel_shape = {n_hidden_units, n_relations}

    kernel_initializer = opts[:kernel_initializer]
    kernel_regularizer = opts[:kernel_regularizer]

    kernel = Axon.param("kernel", kernel_shape, initializer: kernel_initializer, regularizer: kernel_regularizer)

    Axon.layer(
      x,
      fn input, params ->
        IO.puts "input shape"

        input_shape = Nx.shape(input)

        tiled_input = input
        |> Nx.new_axis(-1, :relationship_dimension)
        |> Nx.tile(
          (for _ <- 1..tuple_size(Nx.shape(input)), do: 1) ++ [n_relations]
        )
        # |> Nx.shape
        # |> IO.inspect

        target_shape = input_shape 
        |> Tuple.delete_at(tuple_size(input_shape) - 1)
        |> Tuple.to_list

        IO.inspect target_shape

        IO.puts "relation embeddings shape"

        params["kernel"]
        |> new_axes(target_shape)
        |> Nx.multiply(tiled_input)
        |> Nx.sum(axes: [-2])
        # |> Nx.shape
        # |> IO.inspect
        
        # {1, 2}
      end,
      output_shape, 
      %{"kernel" => kernel}
    )

  end

  defp inner_product(%Axon{output_shape: parent_shape} = x, units, opts \\ []) do
    activation = opts[:activation]

    # parent_shape_size = tuple_size(parent_shape)
    
    parent_shape_without_first_element = Tuple.delete_at(parent_shape, 0) 

    bias_shape = Tuple.append(parent_shape_without_first_element, units) # Axon.Shape.dense_kernel(parent_shape, units)
                 |> Tuple.delete_at(0)
    kernel_shape = bias_shape # parent_shape # Axon.Shape.dense_bias(parent_shape, units)
    output_shape = # Axon.Shape.dense(parent_shape, units)
      parent_shape
      |> Tuple.delete_at(tuple_size(parent_shape) - 1)
      |> Tuple.append(units)

    # kernel_shape =  Axon.Shape.dense_kernel(parent_shape, units)
    # bias_shape = Axon.Shape.dense_bias(parent_shape, units)
    # output_shape = Axon.Shape.dense(parent_shape, units)

    IO.inspect %{kernel_shape: kernel_shape, bias_shape: bias_shape, output_shape: output_shape}

    # {_ , _} = nil

    kernel_initializer = opts[:kernel_initializer]
    kernel_regularizer = opts[:kernel_regularizer]

    bias_initializer = opts[:bias_initializer]
    bias_regularizer = opts[:bias_regularizer]

    kernel = Axon.param("kernel", kernel_shape, initializer: kernel_initializer, regularizer: kernel_regularizer)
    bias = Axon.param("bias", bias_shape, initializer: bias_initializer, regularizer: bias_regularizer)

    node = Axon.layer(
      x,
      fn input, params ->
        bias = params["bias"]
        kernel = params["kernel"]

        bias_shape = Nx.shape(bias)
        # kernel_shape = Nx.shape(kernel)
        # IO.inspect input
        # (input + params["bias"]) * params["kernel"]
        IO.puts "input shape"
        tiled_input =
          input
          |> Nx.new_axis(-1)
          |> Nx.tile(
            (for _ <- 1..tuple_size(Nx.shape(input)), do: 1) ++ [elem(bias_shape, tuple_size(bias_shape) - 1)]
          )
        IO.puts "bias shape"
        tiled_bias =
          bias
          |> Nx.new_axis(0)
          |> Nx.tile(
            [
              elem(Nx.shape(input), 1) |
              (for _ <- 1..tuple_size(bias_shape), do: 1)
            ]
          )
          |> Nx.new_axis(0)
          |> Nx.tile(
            [
              elem(Nx.shape(input), 0) |
              (for _ <- 0..tuple_size(bias_shape), do: 1)
            ]
          )
        IO.inspect "kernel shape"
        tiled_kernel =
          kernel
          |> Nx.new_axis(0)
          |> Nx.tile(
            [
              elem(Nx.shape(input), 1) |
              (for _ <- 1..tuple_size(kernel_shape), do: 1)
            ]
          )
          |> Nx.new_axis(0)
          |> Nx.tile(
            [
              elem(Nx.shape(input), 0) |
              (for _ <- 0..tuple_size(kernel_shape), do: 1)
            ]
          )
        IO.inspect Nx.shape(tiled_kernel)
        IO.inspect "result shape"


        tiled_input
        |> Nx.add(tiled_bias)
        |> Nx.multiply(tiled_kernel)
        |> Nx.sum(axes: [-2])
        # |> Nx.shape
        # |> IO.inspect

        
        # Nx.shape(Nx.multiply(Nx.add(tiled_input, tiled_bias), tiled_kernel))

        # _ = {1, 2}
        # (input + params["bias"]) * params["kernel"]
      end,
      output_shape,
      %{"kernel" => kernel, "bias" => bias}
    )
    # |> Axon.nx(
    #   fn input ->
    #     Nx.sum(input)
    #   end
    # )

    if activation do
      Axon.activation(node, activation)
    else
      node
    end
  end
   
  # def model(n_entities, n_relations, entity_embedding_size, relation_embedding_size, batch_size \\ 16) do
  def model(%Grapex.Init{entity_dimension: entity_embedding_size, relation_dimension: relation_embedding_size, input_size: batch_size}) do

    entity_embeddings = Axon.input({nil, batch_size, 2})
                        |> Axon.embedding(Grapex.Meager.n_entities, entity_embedding_size)
                        |> Axon.reshape({batch_size, entity_embedding_size * 2})
                        # |> Axon.dense(2)
                        |> inner_product(3, activation: :relu)
                        |> relation_embeddings(Grapex.Meager.n_relations)

    IO.inspect entity_embeddings

    # {_, _} = nil
    
    entity_embeddings

  end

  defp fix_shape(x, first_dimension) do
    case {x, first_dimension} do
      {%{shape: {_, _, _}}, 1} -> 
        # IO.puts "first statement" 
        Nx.new_axis(x, 0)
      {%{shape: {_, _, _}}, _} -> 
        # IO.puts "second statement"
        Nx.new_axis(x, 0)
        |> Nx.tile([first_dimension, 1, 1, 1])
      _ -> x
    end
  end

  def compute_score(x) do
    Nx.add(Nx.slice_axis(x, 0, 1, 2), Nx.slice_axis(x, 1, 1, 2))
    |> Nx.subtract(Nx.slice_axis(x, 2, 1, 2))
    |> Nx.abs
    |> Nx.sum(axes: [-1])
    |> Nx.squeeze(axes: [-1])
  end 

  def compute_loss(x) do
    # fixed_x = fix_shape(x, 2)

    # IO.inspect x
    # IO.inspect fixed_x

    # {_, _} = 2
    #
    Nx.sum(x)

    # Nx.slice_axis(fixed_x, 0, 1, 0)
    # |> compute_score
    # |> Nx.flatten
    # |> Nx.subtract(
    #    Nx.slice_axis(fixed_x, 1, 1, 0)
    #    |> compute_score
    #    |> Nx.flatten
    # )
  end 
end

