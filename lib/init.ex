defmodule Grapex.Init.Macros do

  defmacro defparam(clause, as: type) do
    function_name = String.to_atom("set_#{clause}")
    
    quoted = quote do

      @spec unquote(function_name)(map, unquote(type)) :: map
      def unquote(function_name)(config, value) do
        put(config, unquote(clause), value)
      end

      @spec unquote(function_name)(unquote(type)) :: map
      def unquote(function_name)(value) do
        unquote(function_name)(%Grapex.Init{}, value)
      end
    end

    quoted
  end

end

defmodule Grapex.Init do
  defstruct [:input_path, :model, n_epochs: 10, n_batches: 2, entity_negative_rate: 25, margin: 5.0, alpha: 0.5]

  import Map
  import Grapex.Init.Macros

  defparam :input_path, as: String.t
  defparam :n_epochs, as: integer
  defparam :n_batches, as: integer
  defparam :model, as: atom

  def from_cli_params({[:test], %Optimus.ParseResult{args: %{input_path: input_path}, options: %{model: model, n_batches: n_batches, n_epochs: n_epochs}}}) do
    Grapex.Init.set_input_path(input_path)
    |> Grapex.Init.set_n_epochs(n_epochs)
    |> Grapex.Init.set_n_batches(n_batches)
    |> Grapex.Init.set_model(model)
  end

  @spec get_model_by_name(String.t) :: atom
  def get_model_by_name(model) do
    case model do
      "transe" -> :transe
      _ -> raise "Unknown model #{model}"
    end
  end

  def from_cli_params(params) do
    IO.puts("Got following params:")
    IO.inspect(params)
    raise "Invalid command call. Required parameters weren't provided. See documentation for instructions on how to call the package."
  end

end

