defmodule Grapex.Model.Logicenn do
  require Axon

  @n_entities_per_triple 2

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
                   |> Tuple.delete_at(tuple_size(parent_shape) - 2)
                   |> Tuple.insert_at(tuple_size(parent_shape) - 2, elem(parent_shape, tuple_size(parent_shape) - 2) - 1)
                   |> Tuple.append(n_relations + 1)

    IO.puts "output shape from relation embeddings"
    IO.inspect output_shape

    # {_, _} = nil

    kernel_shape = {n_hidden_units, n_relations}

    kernel_initializer = opts[:kernel_initializer]
    kernel_regularizer = opts[:kernel_regularizer]

    kernel = Axon.param("kernel", kernel_shape, initializer: kernel_initializer, regularizer: kernel_regularizer)

    Axon.layer(
      x,
      fn input, params ->
        IO.puts "input shape"

        input_shape = Nx.shape(input) |> IO.inspect

        observed_relation_indices = input
                                    |> Nx.slice_axis(elem(Nx.shape(input), 2) - 1, 1, 2)
                                    |> Nx.slice_axis(0, 1, -1)
                                    |> Nx.new_axis(-1, :relationship_dimension)
                                    |> Nx.tile([1, 1, (Nx.shape(input) |> elem(2)) - 1, (Nx.shape(input) |> elem(3)), 1])
                           # |> Nx.tile([1, 1, (Nx.shape(input) |> elem(2)) - 1, 1])
                           # |> Nx.squeeze
                           # |> Nx.shape |> IO.inspect


        tiled_input = input
                      |> Nx.slice_axis(0, (Nx.shape(input) |> elem(2)) - 1, 2)
                      |> Nx.new_axis(-1, :relationship_dimension)
                      |> Nx.tile(
                        (for _ <- 1..tuple_size(Nx.shape(input)), do: 1) ++ [n_relations]
                      )
        # |> Nx.shape
        # |> IO.inspect

        target_shape = input_shape 
        |> Tuple.delete_at(tuple_size(input_shape) - 1)
        |> Tuple.delete_at(tuple_size(input_shape) - 2)
        |> Tuple.insert_at(tuple_size(input_shape) - 2, elem(input_shape, tuple_size(input_shape) - 2) - 1)
        |> Tuple.to_list

        # {_, _} = nil

        IO.inspect target_shape

        IO.puts "relation embeddings shape"

        result = params["kernel"]
        |> new_axes(target_shape)
        |> Nx.multiply(tiled_input)
        # |> Nx.sum(axes: [-2])
        # |> Nx.shape
        # |> Nx.shape |> IO.inspect
        # result |> Nx.shape |> IO.inspect

        observed_relations = Nx.take_along_axis(result, Nx.as_type(observed_relation_indices, {:s, 64}), axis: 4)
        # observed_relations |> Nx.shape |> IO.inspect

        # stacked_scores =
        Nx.concatenate([result, observed_relations], axis: 4) # |> Nx.shape |> IO.inspect
 
        # {_, _} = nil

        
        # {1, 2}
      end,
      output_shape, 
      %{"kernel" => kernel},
      "logicenn_scoring"
    )

  end

  defp inner_product(%Axon{output_shape: parent_shape} = x, units, opts) do
    activation = opts[:activation]

    # parent_shape_size = tuple_size(parent_shape)

    IO.inspect parent_shape
    
    parent_shape_without_first_element = Tuple.delete_at(parent_shape, 0) # delete variable batch size 

    bias_shape = Tuple.append(parent_shape_without_first_element, units) # number of units in layer # Axon.Shape.dense_kernel(parent_shape, units)
                 |> Tuple.delete_at(0) # delete constant batch size
                 # |> Tuple.delete_at(0) # delete number of entities per triple
    kernel_shape = bias_shape # parent_shape # Axon.Shape.dense_bias(parent_shape, units)
    output_shape = # Axon.Shape.dense(parent_shape, units)
      parent_shape
      |> Tuple.delete_at(tuple_size(parent_shape) - 1)
      |> Tuple.delete_at(tuple_size(parent_shape) - 2)
      |> Tuple.append(2) # two variants of entity composition (t -> r -> h and h -> r -> t)
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
          |> Nx.take(Nx.tensor([[0, 1], [1, 0]]), axis: 2)
          # |> Nx.shape |> IO.inspect

        # {_, _} = nil
        
        IO.puts "bias shape"
        tiled_bias =
          bias
          |> Nx.new_axis(0) # order of entities in a triple
          |> Nx.tile(
            [
              elem(Nx.shape(input), 2) |
              (for _ <- 1..tuple_size(bias_shape), do: 1)
            ]
          )
          |> Nx.new_axis(0) # batch size
          |> Nx.tile(
            [
              elem(Nx.shape(input), 1) |
              (for _ <- 0..tuple_size(bias_shape), do: 1)
            ]
          )
          |> Nx.new_axis(0) # number of units in layer (L parameter)
          |> Nx.tile(
            [
              elem(Nx.shape(input), 0) |
              (for _ <- -1..tuple_size(bias_shape), do: 1)
            ]
          )
          # |> Nx.shape |> IO.inspect

        # {_, _} = nil

        IO.inspect "kernel shape"
        tiled_kernel =
          kernel
          |> Nx.new_axis(0)
          |> Nx.tile(
            [
              elem(Nx.shape(input), 2) |
              (for _ <- 1..tuple_size(kernel_shape), do: 1)
            ]
          )
          |> Nx.new_axis(0)
          |> Nx.tile(
            [
              elem(Nx.shape(input), 1) |
              (for _ <- 0..tuple_size(kernel_shape), do: 1)
            ]
          )
          |> Nx.new_axis(0)
          |> Nx.tile(
            [
              elem(Nx.shape(input), 0) |
              (for _ <- -1..tuple_size(kernel_shape), do: 1)
            ]
          )

        # {_, _} = nil

        IO.inspect Nx.shape(tiled_kernel)
        IO.inspect "result shape"


        tiled_input
        |> Nx.add(tiled_bias)
        |> Nx.multiply(tiled_kernel)
        |> Nx.sum(axes: [-2, -3])
        # |> Nx.shape
        # |> IO.inspect

        
        # Nx.shape(Nx.multiply(Nx.add(tiled_input, tiled_bias), tiled_kernel))

        # _ = {1, 2}
        # (input + params["bias"]) * params["kernel"]
      end,
      output_shape,
      %{"kernel" => kernel, "bias" => bias},
      "logicenn_inner_product"
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
  def model(%Grapex.Init{entity_dimension: entity_embedding_size, relation_dimension: relation_embedding_size, input_size: batch_size, hidden_size: hidden_size}) do

    product = Axon.input({nil, batch_size, 2})
              |> Axon.embedding(Grapex.Meager.n_entities, entity_embedding_size)
              # |> Axon.concatenate(
              #   Axon.input({nil, batch_size, 1})
              #   |> Axon.reshape({batch_size, 1, 1})
              #   |> Axon.pad([{0, 0}, {0, entity_embedding_size - 1})
              # )
              # |> Axon.reshape({batch_size, entity_embedding_size * 2})
              # |> Axon.dense(2)
              |> inner_product(hidden_size, activation: :relu)
              

    score = product
            |> Axon.concatenate(
              Axon.input({nil, batch_size, 1})
              |> Axon.reshape({batch_size, 1, 1})
              |> Axon.pad([{0, 0}, {0, hidden_size - 1}]),
              axis: 2
            )
            |> relation_embeddings(Grapex.Meager.n_relations)

    IO.puts "calling inspect..."
    IO.inspect product # , structs: false
    IO.puts "called inspect..."
 
    # {_, _} = nil
    
    Axon.concatenate(
      product
      |> Axon.reshape({1, batch_size, @n_entities_per_triple, hidden_size, 1})
      |> Axon.pad([{0, 0}, {0, 0}, {0, 0}, {0, Grapex.Meager.n_relations}]),
      score
      |> Axon.reshape({1, batch_size, @n_entities_per_triple, hidden_size, Grapex.Meager.n_relations + 1}),
      axis: 1
    )
    |> IO.inspect

    # {_, _} = nil

  end

  defp fix_shape(x, first_dimension) do
    case {x, first_dimension} do
      {%{shape: {_, _, _, _, _}}, 1} -> 
        # IO.puts "first statement" 
        Nx.new_axis(x, 0)
      {%{shape: {_, _, _, _, _}}, _} -> 
        # IO.puts "second statement"
        Nx.new_axis(x, 0)
        |> Nx.tile([first_dimension, 1, 1, 1, 1, 1])
      _ -> x
    end
  end

  def compute_score(x) do
    x
    |> Nx.slice_axis(1, 1, 1) # Drop intermediate results of inner products calculation
    |> Nx.slice_axis(0, 1, 3) # Drop results of reverse triples processing
    |> Nx.slice_axis(elem(Nx.shape(x), tuple_size(Nx.shape(x)) - 1) - 1, 1, -1) # Drop padding values in the last dimension which represents number of relations, last values correspond to the observed relations
    |> Nx.squeeze(axes: [1, 3, -1])
    |> Nx.sum(axes: [-1])
  end 

  def compute_loss_component(x, opts \\ []) do
    multiplier = Keyword.get(opts, :multiplier)

    x
    |> compute_score
    |> Nx.multiply(if multiplier == nil, do: 1, else: multiplier)
    |> Nx.multiply(-1)
    |> Nx.exp
    |> Nx.add(1)
    |> Nx.log
    # |> IO.inspect

    # {_, _} = 2

    # Nx.sum(x)
    # Nx.add(Nx.slice_axis(x, 0, 1, 2), Nx.slice_axis(x, 1, 1, 2))
    # |> Nx.subtract(Nx.slice_axis(x, 2, 1, 2))
    # |> Nx.abs
    # |> Nx.sum(axes: [-1])
    # |> Nx.squeeze(axes: [-1])
  end 

  def compute_loss(x) do
    fixed_x = fix_shape(x, 2)

    # IO.inspect x
    # IO.inspect fixed_x

    # {_, _} = 2
    #
    # Nx.sum(x)

    Nx.slice_axis(fixed_x, 0, 1, 0)
    # |> Nx.squeeze(axes: [0])
    |> compute_loss_component
    |> Nx.add(
      Nx.slice_axis(fixed_x, 1, 1, 0)
      # |> Nx.squeeze(axes: [0])
      |> compute_loss_component(multiplier: -1) # negative triples
    )
    |> Nx.flatten
    # |> Nx.flatten
    # |> Nx.subtract(
    #    Nx.slice_axis(fixed_x, 1, 1, 0)
    #    |> compute_score
    #    |> Nx.flatten
    # )
  end 
end

