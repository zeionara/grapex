defmodule Grapex.Model.Logicenn do
  import Grapex.TupleUtils
  alias Grapex.IOutils, as: IO_
  alias Grapex.Trainer
  require Axon

  # defp relation_embeddings(%Axon{output_shape: parent_shape} = x, n_relations, opts \\ []) do
  defp relation_embeddings(x, n_relations, opts \\ []) do
    parent_shape = Axon.get_output_shape(x)
    n_hidden_units = last(parent_shape) - 1

    output_shape = parent_shape
                   |> delete_last
                   |> Tuple.append(last(parent_shape) - 1)
                   |> Tuple.append(n_relations + 1) # there will be a coefficient for every relation + coefficient for the observer relation

    kernel_shape = {n_hidden_units, n_relations}

    kernel_initializer = opts[:kernel_initializer]
    kernel_regularizer = opts[:kernel_regularizer]

    kernel = Axon.param("kernel", kernel_shape, initializer: kernel_initializer, regularizer: kernel_regularizer)

    Axon.layer(
      x,
      fn input, params ->
        input_shape = Nx.shape(input)
        n_hidden_units = (Nx.shape(input) |> elem(2)) - 1

        observed_relation_indices = input
                                    |> Nx.slice_axis(n_hidden_units, 1, 2) # take indices of the observed relations from the join input tensor
                                    |> Nx.new_axis(-1, :relationship_dimension)
                                    |> Nx.tile([1, 1, n_hidden_units, 1]) # align to the shape of input, last dimension has just one value since there is one observer relation per triple

        tiled_input = input
                      |> Nx.slice_axis(0, n_hidden_units, 2) # discard the last vectors from the 2nd axis which contain indices of observed relations
                      |> Nx.new_axis(-1, :relationship_dimension)
                      |> Nx.tile(
                        (for _ <- 1..tuple_size(Nx.shape(input)), do: 1) ++ [n_relations]
                      )

        batch_size = input_shape 
                     |> delete_last
                     |> Tuple.to_list

        result = params["kernel"]
                 |> Grapex.NxUtils.new_axes(batch_size)
                 |> Nx.multiply(tiled_input)

        observed_relations = Nx.take_along_axis(result, Nx.as_type(observed_relation_indices, {:s, 64}), axis: 3)

        Nx.concatenate([result, observed_relations], axis: 3)
      end,
      output_shape, 
      %{"kernel" => kernel},
      "logicenn_scoring"
    )
  end

  # defp inner_product(%Axon{output_shape: parent_shape} = x, units, opts) do
  defp inner_product(x, units, opts) do
    activation = opts[:activation]
    enable_bias = Keyword.get(opts, :enable_bias, true)

    parent_shape = Axon.get_output_shape(x)
    
    parent_shape_without_first_element = delete_first(parent_shape) # delete variable batch size 

    param_shape = parent_shape_without_first_element
                 |> delete_first # delete constant batch size
                 |> Tuple.append(units) # add number of units in layer

    output_shape =
      parent_shape
      |> delete_last(2) # delete entity embedding size and number of entities per triple from the parent node output shape
      |> Tuple.append(units)

    # IO.inspect parent_shape_without_first_element
    # IO.inspect param_shape
    # IO.inspect output_shape

    kernel_initializer = opts[:kernel_initializer]
    kernel_regularizer = opts[:kernel_regularizer]

    bias_initializer = unless enable_bias, do: nil, else: opts[:bias_initializer]
    bias_regularizer = unless enable_bias, do: nil, else: opts[:bias_regularizer]

    kernel = Axon.param("kernel", param_shape, initializer: kernel_initializer, regularizer: kernel_regularizer)
    bias = unless enable_bias, do: nil, else: Axon.param("bias", param_shape, initializer: bias_initializer, regularizer: bias_regularizer)

    node = Axon.layer(
      x,
      fn input, params ->
        bias = unless enable_bias, do: nil, else: params["bias"]
        kernel = params["kernel"]

        kernel_shape = Nx.shape(kernel)

        # align input to number of units in the hidden layer
        tiled_input =
          input
          |> Nx.new_axis(-1)
          |> Nx.tile(
            (for _ <- 1..tuple_size(Nx.shape(input)), do: 1) ++ [last(kernel_shape)] 
          )
          |> IO_.inspect('input size after adding new axis')

        # align bias to batch size
        tiled_bias = unless enable_bias, do: nil, else: Grapex.NxUtils.new_axes(
          bias,
          elems(
            Nx.shape(input),
            [
              0, # variable batch size
              1 # constant batch size
            ]
          )
        )

        # align kernel to batch size
        tiled_kernel = Grapex.NxUtils.new_axes(
          kernel,
          elems(
            Nx.shape(input),
            [
              0, # n elements per triple ( = 2 )
              1 # constant batch size
            ]
          )
        )

        tiled_input
        |> Nx.multiply(tiled_kernel)
        |> (
          fn(x) ->
            unless enable_bias do
              x
            else
              x
              |> Nx.add(tiled_bias)
            end
          end
        ).()
        # |> Nx.add(tiled_bias)
        # |> Nx.max(0) # relu
        # |> Nx.multiply(tiled_bias)
        |> Nx.sum(axes: [-2, -3]) # eliminate dimensions which correspond to the entity embedding size and number of entities per triple
      end,
      output_shape,
      (unless enable_bias, do: %{"kernel" => kernel}, else: %{"kernel" => kernel, "bias" => bias}),
      "logicenn_inner_product"
    )

    if activation do
      Axon.activation(node, activation)
    else
      node
    end
  end
   
  def model(%Grapex.Init{entity_dimension: entity_embedding_size, hidden_size: hidden_size, enable_bias: enable_bias}, trainer) do
    batch_size = Trainer.group_size(trainer)

    product = Axon.input({nil, batch_size, 2})
              |> Axon.embedding(Grapex.Meager.n_entities, entity_embedding_size)
              # |> IO_.inspect
              # |> Axon.layer_norm
              |> inner_product(hidden_size, activation: :relu, enable_bias: enable_bias)

    score = product
            |> Axon.concatenate(
              Axon.input({nil, batch_size, 1}),
              axis: 2
            )
            |> relation_embeddings(Grapex.Meager.n_relations)


    Axon.concatenate(
      product
      |> Axon.reshape({1, batch_size, hidden_size, 1})
      |> Axon.pad([{0, 0}, {0, 0}, {0, Grapex.Meager.n_relations}]),
      score
      |> Axon.reshape({1, batch_size, hidden_size, Grapex.Meager.n_relations + 1}),
      axis: 1
    ) # |> IO.inspect

    # Resulting dimensions:
    # - variable batch size
    # - generated value kinds ( = 2, the first contains values of f_ht functions which are independent of relations and the other one contains the same values multiplied by relations)
    # - constant batch size
    # - hidden size (number of units per hidden layer)
    # - relations + 1 (one is reserved for tracking the observed relation)
  end

  defp fix_shape(x, first_dimension) do
    case {x, first_dimension} do
      {%{shape: {_, _, _, _}}, 1} -> 
        Nx.new_axis(x, 0)
      {%{shape: {_, _, _, _}}, _} -> 
        Nx.new_axis(x, 0)
        |> Nx.tile([first_dimension, 1, 1, 1, 1])
      _ -> x
    end
  end

  def compute_score(x) do
    x
    # |> Grapex.IOutils.inspect_shape("original x")
    |> Nx.slice_axis(1, 1, 1) # Drop intermediate results of inner products calculation
    # |> Nx.slice_axis(0, 1, 1) # Drop intermediate results of inner products calculation
    # |> Nx.slice_axis(elem(Nx.shape(x), tuple_size(Nx.shape(x)) - 1) - 1, 1, -1) # Drop padding values in the last dimension which represents number of relations, last values correspond to the observed relations
    |> Nx.slice_axis(last(Nx.shape(x)) - 1, 1, -1) # Drop padding values in the last dimension which represents number of relations, last values correspond to the observed relations
    # |> Nx.slice_axis(last(Nx.shape(x)) - 1, 1, tuple_size(Nx.shape(x)) - 1) # Drop padding values in the last dimension which represents number of relations, last values correspond to the observed relations
    # |> Nx.slice_axis(0, 1, tuple_size(Nx.shape(x)) - 1) # Drop padding values in the last dimension which represents number of relations, last values correspond to the observed relations
    |> Nx.slice_axis(0, 1, -1) # Drop padding values in the last dimension which represents number of relations, last values correspond to the observed relations
    # |> Grapex.IOutils.inspect_shape("reshaped x")
    |> Nx.squeeze(axes: [1, -1])
    |> Nx.sum(axes: [-1]) # Sum up values corresponding to different values of L for the same (observed) relation
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
  end 

  def take_triples(x, index, inserted_dimension \\ 2) do
    fixed_x = 
      fix_shape(x, inserted_dimension)
    
    Nx.reshape(
      fixed_x,
      Nx.shape(fixed_x)
      |> delete_first
      |> Tuple.insert_at(0, 2)
      |> Tuple.insert_at(0, :auto)
    )
    |> (
      fn(y) ->
        if index >= 0 do
          Nx.slice_axis(y, index, 1, 0) # last dimension corresponds to the observed triples
        else
          Nx.slice_axis(y, (Nx.shape(y) |> elem(0)) + index, 1, 0)
        end
      end
    ).()
    |> Nx.squeeze(axes: [0])
  end

  def compute_loss(x, opts \\ []) do # when pattern == :symmetric do
    pattern = Keyword.get(opts, :pattern, nil)
    lambda = Keyword.get(opts, :lambda, nil)
    # enable_regularization = Keyword.get(opts, :enable_regularization, true)
    # fixed_x = 
    #   fix_shape(x, 2)
    # 
    # fixed_x =
    #   Nx.reshape(
    #     fixed_x,
    #     Nx.shape(fixed_x)
    #     |> delete_first
    #     |> Tuple.insert_at(0, 2)
    #     |> Tuple.insert_at(0, :auto)
    #   )
    #   |> Nx.slice_axis(-1, 1, 0) # last dimension corresponds to the observed triples
    #   |> Nx.squeeze(axes: [0])
    fixed_x = 
      x
      |> take_triples(-1)

     concat = Nx.concatenate(
      [
        Nx.slice_axis(fixed_x, 0, 1, 0) # positive_triples
        |> compute_loss_component
        |> (
          fn(positive_loss_component) ->
            unless lambda == nil do
              compute_regularization(x, pattern, opts)
              |> Nx.multiply(lambda)
              |> Nx.add(positive_loss_component)
            else
              positive_loss_component
            end
          end
        ).(),
        # |> IO_.inspect_shape("Positive triples shape")
        Nx.slice_axis(fixed_x, 1, 1, 0) # negative triples
        |> compute_loss_component(multiplier: -1)
        # |> IO_.inspect_shape("Negative triples shape")
      ]
    )
    |> Nx.flatten

    concat
  end 

  def compute_regularization(x, pattern, opts \\ []) do
    case pattern do
      binary_pattern when binary_pattern == :symmetric or binary_pattern == :inverse ->
        margin = Keyword.get(opts, :margin, 0)

        x
        |> take_triples(0, 4) # forward triples 
        |> Nx.slice_axis(0, 1, 0) # positive_triples
        |> Nx.slice_axis(1, 1, 1) # Drop intermediate results of inner products calculation
        |> Nx.slice_axis(last(Nx.shape(x)) - 1, 1, -1) # Drop padding values in the last dimension which represents number of relations, last values correspond to the observed relations
        |> Nx.squeeze(axes: [1, -1])
        |> Nx.subtract(
          x
          |> take_triples(1, 4) # backward triples
          |> Nx.slice_axis(0, 1, 0) # positive_triples
          |> Nx.slice_axis(1, 1, 1) # Drop intermediate results of inner products calculation
          |> Nx.slice_axis(last(Nx.shape(x)) - 1, 1, -1) # Drop padding values in the last dimension which represents number of relations, last values correspond to the observed relations
          |> Nx.squeeze(axes: [1, -1])
        )
        |> Nx.abs
        |> Nx.subtract(margin)
        |> Nx.max(0)
        |> Nx.sum(axes: [-1]) # Sum up values corresponding to different values of L for the same (observed) relation
        |> Nx.flatten
        # |> IO_.inspect_shape("Shape of symmetric regularization")
      _ -> 
        IO.puts "No regularization-specific loss components are defined for pattern #{pattern}"
        0
    end
  end
end

