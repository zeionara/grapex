defmodule Grapex.Model.Config do

  defmacro __using__(opts) do
    enforced_keys = Keyword.get(opts, :enforced_keys)
    regular_keys = Keyword.get(opts, :regular_keys)
    attributes = Keyword.get(opts, :attributes)

    # quoted = quote do
    #   @foo [2, 3]
    # end

    # IO.inspect quoted

    # quoted = quote do
    #   def import(%{model: model, hidden_size: hidden_size, reverse: reverse} = config) do
    #     %Grapex.Model{model: model, hidden_size: hidden_size, reverse: reverse}
    #     # %Grapex.Model{unquote(for tag <- enforced_keys, do: {tag, {tag, [], Grapex.Model.Config}})}
    #     # |> Map.put(:entity_size, Map.get(config, :entity_size))
    #     # |> Map.put(:relation_size, Map.get(config, :relation_size))
    #   end
    # end

    # IO.inspect quoted

    quoted = quote do
      def import(unquote({:%{}, [], (for tag <- enforced_keys, do: {tag, {tag, [], Grapex.Model.Config}})}) = config) do
        # %Grapex.Model{model: model, hidden_size: hidden_size, reverse: reverse}
        unquote(
          {:%, [], [
            {:__aliases__, [alias: false], [:Grapex, :Model]},
            {:%{}, [], (for tag <- enforced_keys, do: {tag, {tag, [], Grapex.Model.Config}})}
          ]}
        )
        # %Grapex.Model{unquote(for tag <- enforced_keys, do: {tag, {tag, [], Grapex.Model.Config}})}
        |> Map.put(:entity_size, Map.get(config, :entity_size))
        # |> Map.put(:relation_size, Map.get(config, :relation_size))
      end
    end

    IO.inspect quoted

    {a, b} = 2

    # reversed_args = 
    #   for param <- Enum.reverse enforced_keys do
    #     # {:%{}, [], [{param, {param, [], Grapex.Model.Config}}]}
    #     {param, {param, [], Grapex.Model.Config}}
    #   end

    # args = 
    #   for param <- enforced_keys do
    #     # {:%{}, [], [{param, {param, [], Grapex.Model.Config}}]}
    #     {param, {param, [], Grapex.Model.Config}}
    #   end

    # IO.inspect args

    # quoted =  {:def, [context: Grapex.Model.Config, imports: [{1, Kernel}, {2, Kernel}]],
    #  [
    #    {:import, [context: Grapex.Model.Config],
    #     [
    #       {:=, [],
    #        [
    #          {:%{}, [], args},
    #          {:config, [], Grapex.Model.Config}
    #        ]}
    #     ]},
    #    [
    #      do: {:|, [],
    #       [
    #         {:%, [],
    #          [
    #            {:__aliases__, [alias: false], [:Grapex, :Model]},
    #            {:%{}, [], args}
    #          ]},
    #         {:config, [], Grapex.Model.Config}
    #       ]}
    #    ]
    #  ]}


    # updated_head = [
    #   {:config, [], Grapex.Model.Macros} | reversed_args
    # ]
    # |> Enum.reverse

    # updated_head_2 = [
    #   {:__aliases__, [alias: false], [:Grapex, :Model]} | (reversed_args |> Enum.reverse)
    # ]

    # quoted = {:def, [context: Grapex.Model.Config, imports: [{1, Kernel}, {2, Kernel}]],
    #  [
    #    {:import, [context: Grapex.Model.Config],
    #     [
    #       # {:=, [], updated_head}
    #       {:%, [], updated_head},
    #       {:config, [], Grapex.Model.Macros}
    #     ]},
    #    [
    #      do: {:|, [],
    #       [
    #         {:%, [], updated_head_2},
    #         {:config, [], Grapex.Model.Config}
    #       ]}
    #    ]
    #   ]
    # }

    # IO.inspect quoted

    # IO.inspect keys
    # IO.inspect quoted

    full_quote = {_block, _empty_list, items} = quote do

      # unquote do
      #   if attributes != nil do
      #     for {attribute, value} <- attributes do
      #       [{attribute, [context: Grapex.Model.Config], [value]}]
      #     end
      #   end
      # end

      @enforced_keys unquote(enforced_keys)
      # @enforced_keyss unquote(enforced_keys)
      defstruct unquote(regular_keys ++ enforced_keys)

      unquote(quoted)

    end

    full_quote = if attributes != nil do
      updated_items = for {{attribute, _, _}, value} <- attributes do
        {:@, [context: Grapex.Model.Config, imports: [{1, Kernel}]],
        [{attribute, [context: Grapex.Model.Config], [value]}]}
      end ++ items
      {:__block__, [], updated_items}
    else
      full_quote
    end

    IO.inspect full_quote

    # {a, b} = 2

    full_quote

    # quoted
  end

end


# defmodule Grapex.Model.Macros do
# 
#   use Grapex.Model.Config
#   alias Grapex.Model.Macros
# 
#   defmacro importt() do
#     quoted = quote do
#       # def import(%{:model => model, :hidden_size => hidden_size, :reverse => reverse} = config) do
#       def import(%{:foo => bar} = config) do
#         # IO.inspect unquote(params)
#         # %Grapex.Model{model: model, hidden_size: hidden_size, reverse: reverse} | config
#         %Grapex.Model{foo: bar} | config
#       end
#     end
# 
#     IO.inspect @enforced_keys
#     # IO.inspect Grapex.Model.init(1, 2)
#     # params = Macro.expand(params, __CALLER__)
# 
#     # IO.inspect params
# 
#     IO.inspect quoted
# 
#     [
#       {
#         _import,
#         _context,
#         [
#           {
#             _assignment,
#             _empty_list,
#             head
#           }
#         ]
#       } |
#       _tail
#     ] =
#       quoted
#       |> elem(2)
# 
#     updated_head = [
#       {:config, [], Grapex.Model.Macros} |
#       for param <- Enum.reverse @enforced_keys do
#         {:%{}, [], [{param, {param, [], Grapex.Model.Macros}}]}
#       end
#     ]
#     |> Enum.reverse
#     
#     # quoted_updated = {
#     #   :def, [context: Macros, imports: [{1, Kernel}, {2, Kernel}]],
#     #   [
#     #     {:import, [context: Grapex.Model.Macros],
# 
#     # }
# 
#     updated_head |> IO.inspect
# 
#     head
#     |> IO.inspect
# 
#     {a, b} = 2
#     quoted
#   end
# 
# 
#   defmacro defparam(clause, as: type) do
#     function_name = String.to_atom("set_#{clause}")
#     
#     quoted = quote do
# 
#       @spec unquote(function_name)(map, unquote(type)) :: map
#       def unquote(function_name)(config, value) do
#         put(config, unquote(clause), value)
#       end
# 
#       @spec unquote(function_name)(unquote(type)) :: map
#       def unquote(function_name)(value) do
#         unquote(function_name)(%Grapex.Init{}, value)
#       end
#     end
# 
#     quoted
#   end
# 
# end

defmodule Grapex.Model do
  
  alias Grapex.Model
  alias Grapex.Config

  alias Grapex.Model.Transe

  # import Grapex.Model.Macros

  use Grapex.Model.Config, 
    enforced_keys: [:model, :hidden_size, :reverse],
    regular_keys: [:entity_size, :relation_size],
    attributes: [
      {valid_models, [:transe]}
    ]

  defmacro __using__(_) do
    quote do
      @valid_models unquote(@valid_models)
    end
  end

  # @enforced_keys [
  #   :model,

  #   :hidden_size,
  #   :reverse
  # ]

  # @enforce_keys @enforced_keys

  # defstruct [
  #   # :n_entities
  #   # :n_relations,
  #   :entity_size,
  #   :relation_size | @enforced_keys
  # ]

  def init(
    %Config{
      model: %Model{
        model: model_type
      } = model,
      corpus: corpus,
      trainer: trainer
    },
    _opts \\ []
  ) when model_type in @valid_models do
    case model_type do
      :transe -> {Transe.init(model, corpus, trainer, verbose: true), Transe}
      _ -> raise "Unknown model type"
    end
  end

  def model | config do
    model
    |> Map.put(:entity_size, Map.get(config, :entity_size))
    |> Map.put(:relation_size, Map.get(config, :relation_size))
  end

  # importt

  # def import(%{:model => model, :hidden_size => hidden_size, :reverse => reverse} = config) do
  #   %Model{model: model, hidden_size: hidden_size, reverse: reverse} | config
  # end

end
