defmodule Grapex.Model.Config do

  defp call(function, parameters) do
    {
      {
        :., [], [function]
      }, [], (
        for parameter <- parameters do
          IO.inspect(parameter)
          case parameter do
            {{_, _, _}, _, _} -> parameter
            _ -> {parameter, [], Grapex.Model.Config}
          end
        end
      )
    }
  end

  # defp calll(function, parameters) do
  #   {
  #     {
  #       :., [], [function]
  #     }, [], (
  #       for parameter <- parameters, do: parameter
  #     )
  #   }
  # end

  defp get(object, key) do
    {
      {
        :., [], [{:__aliases__, [alias: false], [:Map]}, :get]
      }, [], [{object, [], Grapex.Model.Config}, key]
    }
  end

  defp put_optional_keys(object, []), do: object

  defp put_optional_keys(object, [{key, handler} | remaining_keys]) do
    {
      :|>, [context: Grapex.Model.Config, imports: [{2, Kernel}]],
      [
        object,
        {
          {
            :., [], [
              {:__aliases__, [alias: false], [:Map]}, :put]
          }, [], [
            key,
            case handler do
              nil -> get(:config, key)
              handle -> call(handle, [get(:config, key)])
            end
          ]
        }
      ]
    }
    |> put_optional_keys(remaining_keys)
  end

  defmacro __using__(opts) do
    required_keys = Keyword.get(opts, :required_keys)
    optional_keys = Keyword.get(opts, :optional_keys)
    attributes = Keyword.get(opts, :attributes)

    # quoted = quote do
    #   def import(%{model: model, hidden_size: hidden_size, reverse: reverse} = config) do
    #     %Grapex.Model{model: model, hidden_size: (&Ops.double/1).(hidden_size), reverse: reverse}
    #     # %Grapex.Model{unquote(for tag <- enforced_keys, do: {tag, {tag, [], Grapex.Model.Config}})}
    #     # |> Map.put(:entity_size, Map.get(config, :entity_size))
    #     # |> Map.put(:relation_size, Map.get(config, :relation_size))
    #   end
    # end

    # IO.inspect quoted

    # {a, b} = 2

    quoted = quote do
      def import(
        unquote(
          {
            :%{}, [], (
              for {key, _handler} <- required_keys, do: {
                key, {key, [], Grapex.Model.Config}
              }
            )
          }
        ) = config
      ) do
        unquote(
          {
            :%, [], [
              {:__aliases__, [alias: false], [:Grapex, :Model]},
              {
                :%{}, [], (
                  for {key, handler} <- required_keys, do: {
                    key, 
                    case handler do
                        nil -> {key, [], Grapex.Model.Config}
                        handle -> call(handle, [key])
                    end
                  }
                )
              }
            ]
          }
          |> put_optional_keys(optional_keys)
        )
      end
    end

    IO.inspect quoted

    # {a, b} = 2

    # quoted_ = quote do
    #   call(&Ops.double/1, bar)
    #   # Map.get(foo, :bar)
    # end
    func = &Ops.double/1
    quoted_ = call(func, [2])

    quoted__ = quote do
      (&Ops.double/1).(bar)
    end

    # quoted___ = quote do
    #   apply(:foo, bar)
    # end

    # IO.inspect quoted_
    # IO.inspect quoted__
    # IO.inspect call(:foo, [:bar, :baz])


    full_quote = {_block, _empty_list, items} = quote do

      @required_keys unquote(required_keys)

      defstruct unquote(optional_keys ++ required_keys)

      unquote(quoted)

    end

    if attributes != nil do
      # updated_items = for {{attribute, _, _}, value} <- attributes do
      updated_items = for {attribute, value} <- attributes do
        {:@, [context: Grapex.Model.Config, imports: [{1, Kernel}]],
        [{attribute, [context: Grapex.Model.Config], [value]}]}
      end ++ items
      {:__block__, [], updated_items}
    else
      full_quote
    end

  end

end

defmodule Ops do

  def double(x) do
    x * 3
  end

end

defmodule Grapex.Model do
  
  alias Grapex.Model
  alias Grapex.Config

  alias Grapex.Model.Transe

  use Grapex.Model.Config, 
    required_keys: [
      model: nil,

      # hidden_size: nil,
      hidden_size: &Ops.double/1,
      reverse: nil
    ],

    optional_keys: [
      entity_size: &Ops.double/1,  # nil,
      relation_size: nil
    ],

    attributes: [
      valid_models: [
        :transe
      ]
    ]

  defmacro __using__(_) do
    quote do
      @valid_models unquote(@valid_models)
    end
  end

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

end
