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
  defstruct [
    :input_path, :model, :batch_size, :input_size,
    :relation_dimension, :entity_dimension, 
    n_epochs: 10, n_batches: 2, entity_negative_rate: 1, margin: 5.0, alpha: 0.5, relation_negative_rate: 0, as_tsv: false,
    hidden_size: 10, n_workers: 8 
  ]

  import Map
  import Grapex.Init.Macros

  defparam :input_path, as: String.t
  defparam :n_epochs, as: integer
  defparam :n_batches, as: integer
  defparam :model, as: atom

  defparam :entity_negative_rate, as: integer
  defparam :relation_negative_rate, as: integer

  defparam :as_tsv, as: boolean

  defparam :hidden_size, as: integer
  defparam :entity_dimension, as: integer
  defparam :relation_dimension, as: integer
  defparam :n_workers, as: integer

  # computed fields
 
  defparam :batch_size, as: integer
  defparam :input_size, as: integer

  def from_cli_params({
    [:test],
    %Optimus.ParseResult{
      args: %{
        input_path: input_path
      },
      options: %{
        model: model,
        n_batches: n_batches,
        n_epochs: n_epochs,
        entity_negative_rate: entity_negative_rate,
        relation_negative_rate: relation_negative_rate,
        hidden_size: hidden_size,
        entity_dimension: entity_dimension,
        relation_dimension: relation_dimension,
        n_workers: n_workers
      },
      flags: %{
        as_tsv: as_tsv
      }
    }
  }) do
    params = Grapex.Init.set_input_path(input_path)
    |> Grapex.Init.set_n_epochs(n_epochs)
    |> Grapex.Init.set_n_batches(n_batches)
    |> Grapex.Init.set_model(model)
    |> set_entity_negative_rate(entity_negative_rate)
    |> set_relation_negative_rate(relation_negative_rate)
    |> set_as_tsv(as_tsv)
    |> set_hidden_size(hidden_size)
    |> set_n_workers(n_workers)

    params = case entity_dimension do
      nil -> Grapex.Init.set_entity_dimension(params, hidden_size)
      _ when entity_dimension > 0 -> Grapex.Init.set_entity_dimension(params, entity_dimension)
    end

    params = case relation_dimension do
      nil -> Grapex.Init.set_relation_dimension(params, hidden_size)
      _ when relation_dimension > 0 -> Grapex.Init.set_relation_dimension(params, relation_dimension)
    end

    params
  end

  def init_meager(%Grapex.Init{input_path: input_path, as_tsv: as_tsv, n_workers: n_workers} = params) do
    Meager.set_input_path(input_path, as_tsv)
    Meager.set_n_workers(n_workers)
    Meager.reset_randomizer()

    Meager.import_train_files
    Meager.import_test_files
    Meager.read_type_files

    params
  end

  def init_computed_params(%Grapex.Init{n_batches: n_batches} = params) do
    params = params 
    |> set_batch_size(
      # Float.ceil(Meager.n_train_triples / n_batches) # The last batch may be incomplete - this situation is handled correctly in the meager library 
      Meager.n_train_triples
      |> div(n_batches)
      # |> trunc
    )
    
    params
    |> set_input_size(
      params.batch_size * (params.entity_negative_rate + params.relation_negative_rate)
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

