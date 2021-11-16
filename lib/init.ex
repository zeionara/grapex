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
  defstruct [:input_path, :model, :batch_size, n_epochs: 10, n_batches: 2, entity_negative_rate: 1, margin: 5.0, alpha: 0.5, relation_negative_rate: 0]

  import Map
  import Grapex.Init.Macros

  defparam :input_path, as: String.t
  defparam :n_epochs, as: integer
  defparam :n_batches, as: integer
  defparam :model, as: atom

  defparam :entity_negative_rate, as: integer
  defparam :relation_negative_rate, as: integer

  # computed fields
 
  defparam :batch_size, as: integer

  def from_cli_params({
    [:test],
    %Optimus.ParseResult{
      args: %{input_path: input_path},
      options: %{
        model: model,
        n_batches: n_batches,
        n_epochs: n_epochs,
        entity_negative_rate: entity_negative_rate,
        relation_negative_rate: relation_negative_rate
      }
    }
  }) do
    Grapex.Init.set_input_path(input_path)
    |> Grapex.Init.set_n_epochs(n_epochs)
    |> Grapex.Init.set_n_batches(n_batches)
    |> Grapex.Init.set_model(model)
    |> set_entity_negative_rate(entity_negative_rate)
    |> set_relation_negative_rate(relation_negative_rate)
  end

  def init_meager(%Grapex.Init{input_path: input_path} = params) do
    Meager.set_input_path(input_path, false)
    Meager.set_n_workers(8)
    Meager.reset_randomizer()

    Meager.import_train_files
    Meager.import_test_files
    Meager.read_type_files

    params
  end

  def init_computed_params(%Grapex.Init{n_batches: n_batches} = params) do
    params 
    |> set_batch_size(
      # Float.ceil(Meager.n_train_triples / n_batches) # The last batch may be incomplete - this situation is handled correctly in the meager library 
      Meager.n_train_triples
      |> div(n_batches)
      # |> trunc
    )
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

