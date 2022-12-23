defmodule Grapex.PersistedStruct do
  import Grapex.Option, only: [opt: 1]

  defp call(function, parameters, caller) do
    {
      {
        :., [], [function]
      }, [], (
        for parameter <- parameters do
          case parameter do
            {{_, _, _}, _, _} -> parameter
            _ -> {parameter, [], caller}
          end
        end
      )
    }
  end

  defp get(object, key, caller) do
    {
      {
        :., [], [{:__aliases__, [alias: false], [:Map]}, :get]
      }, [], [{object, [], caller}, key]
    }
  end

  defp put_optional_keys(object, [], _caller), do: object
  defp put_optional_keys(object, nil, _caller), do: object

  defp put_optional_keys(object, [{key, handler} | remaining_keys], caller) do
    {
      :|>, [context: caller, imports: [{2, Kernel}]],
      [
        object,
        {
          {
            :., [], [
              {:__aliases__, [alias: false], [:Map]}, :put]
          }, [], [
            key,
            case handler do
              nil -> get(:config, key, caller)
              handle -> call(handle, [get(:config, key, caller)], caller)
            end
          ]
        }
      ]
    }
    |> put_optional_keys(remaining_keys, caller)
  end

  defp put_attributes({block, empty_list, items}, attributes, caller) do
    {
      block,
      empty_list,
      for {attribute, value} <- attributes do
        {
          :@, [
            context: caller,
            imports: [{1, Kernel}]
          ], [
            {
              attribute,
              [context: caller],
              [value]
            }
          ]
        }
      end ++ items
    }
  end

  defmacro init(opts) do
    required_keys = Keyword.get(opts, :required_keys)
    optional_keys = Keyword.get(opts, :optional_keys)
    attributes = Keyword.get(opts, :attributes)
    validate = opt :validate

    [caller | _tail ] = __CALLER__.context_modules

    aliases = Module.split(caller) |> Enum.map(&String.to_atom/1)

    qq = quote do
      def foo(bar) do
        qux = Map.get(bar, :baz)
        if validate != nil do
          unquote(call(validate, [17], caller))
        end
      end
    end

    IO.inspect qq

    # {a, b} = 2

    quoted = {
      :def, [
        context: caller,
        imports: [{1, Kernel}, {2, Kernel}]
      ],
      [
        {
          :import, [context: caller], [
            {
              :=, [], [
                {
                  :%{}, [], (
                    for {key, _handler} <- required_keys, do: {
                      key, {key, [], caller}
                    }
                  )
                },
                {:config, [], caller}
              ]
            }
          ]
        },
        [
          do: {
            :__block__, [], [
              {
                :=, [], [
                  {:object, [], caller},
                  {
                    :%, [], [
                      {:__aliases__, [alias: false], aliases},
                      {
                        :%{}, [], (
                          for {key, handler} <- required_keys, do: {
                            key, 
                            case handler do
                                nil -> {key, [], caller}
                                handle -> call(handle, [key], caller)
                            end
                          }
                        )
                      }
                    ]
                  }
                  |> put_optional_keys(optional_keys, caller)
                ]
              }
            #   {
            #     :if, [context: caller, imports: [{2, Kernel}]],
            #     [
            #       {
            #         :!=, [context: caller, imports: [{2, Kernel}]],
            #         [{validate, [], caller}, nil],
            #         [do: call(validate, [:config], caller)]
            #       }
            #     ]
            #   }
            ] ++ case validate do
              nil -> []
              _ -> [call(validate, [:object], caller)]
            end
          }
        ]
      ]
    }

    required_keys_value = for {key, _handler} <- required_keys, do: key

    full_quote = quote do
      unquote(
        {
          :defstruct, [
            context: caller,
            imports: [{1, Kernel}]
          ],
          [
            (for {key, _handler} <- (if optional_keys == nil, do: required_keys, else: optional_keys ++ required_keys), do: key)
          ]
        }
      )

      unquote(quoted)
    end

    result = case attributes do
      nil -> put_attributes(full_quote, [required_keys: required_keys_value], caller)
      _ -> put_attributes(full_quote, [required_keys: required_keys_value] ++ attributes, caller)
    end

    # IO.inspect result

    # {a, b} = 2

    result

  end

end
