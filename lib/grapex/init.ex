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
    :input_path, :model, :batch_size, :output_path, :import_path, :seed, :min_delta, :patience, :n_export_steps, :model_impl,  # :input_size, 
    :relation_dimension, :entity_dimension, 
    :tester, :max_n_test_triples, # :n_batches, :n_test_triples, :trainer, :reverse, 
    :corpus, :sampler, :evaluator,
    :model_, :optimizer_, :checkpoint, :early_stop, :trainer_,
    n_epochs: 10, entity_negative_rate: 25, relation_negative_rate: 0, as_tsv: false, remove: false, verbose: false, is_imported: false, validate: false, bern: false, cross_sampling: false,
    hidden_size: 10, n_workers: 8, optimizer: :sgd, task: :link_prediction,
    margin: 5.0, alpha: 0.1, lambda: 0.1, compiler: :default, compiler_impl: Nx.Defn.Evaluator, enable_bias: true, enable_filters: false, drop_duplicates_during_filtration: true,
    pattern: nil, n_observed_triples_per_pattern_instance: 1
  ]

  import Map
  import Grapex.Init.Macros

  alias Grapex.Meager.Corpus, as: Corpus

  defparam :input_path, as: String.t
  defparam :p_input_path, as: String.t
  defparam :n_epochs, as: integer
  # defparam :n_batches, as: integer
  defparam :model, as: atom
  defparam :model_impl, as: atom

  defparam :entity_negative_rate, as: integer
  defparam :relation_negative_rate, as: integer

  defparam :as_tsv, as: boolean
  defparam :remove, as: boolean
  defparam :verbose, as: boolean
  defparam :validate, as: boolean

  defparam :hidden_size, as: integer
  defparam :entity_dimension, as: integer
  defparam :relation_dimension, as: integer
  defparam :n_workers, as: integer

  defparam :output_path, as: String.t
  defparam :import_path, as: String.t

  defparam :seed, as: integer

  # computed fields
 
  defparam :batch_size, as: integer
  # defparam :input_size, as: integer

  defparam :is_imported, as: boolean
  defparam :optimizer, as: atom
  defparam :task, as: atom
  defparam :bern, as: boolean
  defparam :cross_sampling, as: boolean

  defparam :margin, as: float
  defparam :alpha, as: float
  defparam :lambda, as: float

  defparam :min_delta, as: float
  defparam :patience, as: integer
  defparam :n_export_steps, as: integer

  defparam :compiler, as: atom
  defparam :compiler_impl, as: atom

  # defparam :trainer, as: atom
  defparam :tester, as: atom
  # defparam :reverse, as: atom

  defparam :max_n_test_triples, as: integer
  # defparam :n_test_triples, as: integer

  defparam :enable_bias, as: boolean
  defparam :enable_filters, as: boolean
  defparam :drop_duplicates_during_filtration, as: boolean

  defparam :pattern, as: atom
  defparam :n_observed_triples_per_pattern_instance, as: integer

  defparam :corpus, as: map
  defparam :sampler, as: map
  defparam :evaluator, as: map

  defparam :model_, as: map
  defparam :optimizer_, as: map
  defparam :checkpoint, as: map
  defparam :early_stop, as: map
  defparam :trainer_, as: map

  def get_relative_path(params, filename) do
    case params.p_input_path do # TODO: implemented random number insertion into the path for making it possible to run multiple evaluations on the same model
      nil -> 
        [cv_split, corpus_name, _, remainder] =
          String.reverse(params.input_path) 
          |> String.split("/", parts: 4)
        Path.join([String.reverse(remainder), 'models', String.reverse(corpus_name), String.reverse(cv_split), filename])
      input_path -> Path.join([Application.get_env(:grapex, :project_root), "assets/models", String.downcase(input_path), filename]) # |> IO.inspect
    end
  end

  def from_file(params, path) do
    %{
      entity_negative_rate: entity_negative_rate
    } = YamlElixir.read_from_file!(path, atoms: true)

    params = case entity_negative_rate do
      nil -> params
      _ -> set_entity_negative_rate(params, entity_negative_rate)
    end

    params
  end

  def from_cli_params({
    [:test],
    %Optimus.ParseResult{
      args: %{
        input_path: %{
          absolute: input_path,
          relative: path
        }
      },
      options: %{
        model: model,
        batch_size: batch_size,
        # n_batches: n_batches,
        n_epochs: n_epochs,
        entity_negative_rate: entity_negative_rate,
        relation_negative_rate: relation_negative_rate,
        hidden_size: hidden_size,
        entity_dimension: entity_dimension,
        relation_dimension: relation_dimension,
        n_workers: n_workers,
        output_path: output_path,
        import_path: import_path,
        export_path: export_path,
        seed: seed,
        margin: margin,
        alpha: alpha,
        lambda: lambda,
        optimizer: optimizer,
        task: task,
        min_delta: min_delta,
        patience: patience,
        n_export_steps: n_export_steps,
        compiler: compiler,
        max_n_test_triples: max_n_test_triples
      },
      flags: %{
        as_tsv: as_tsv,
        remove: remove,
        verbose: verbose,
        validate: validate,
        bern: bern,
        disable_bias: disable_bias,
        enable_filters: enable_filters,
        disable_duplicates_dropping: disable_duplicates_dropping
      }
    }
  }) do
    params = 
      Grapex.Init.set_input_path(input_path)
      |> set_p_input_path(path)     
      |> Grapex.Init.set_n_epochs(n_epochs)
      |> Grapex.Init.set_batch_size(batch_size)
      # |> Grapex.Init.set_n_batches(n_batches)
      |> Grapex.Init.set_model(model)
      |> set_entity_negative_rate(entity_negative_rate)
      |> set_relation_negative_rate(relation_negative_rate)
      |> set_as_tsv(as_tsv)
      |> set_hidden_size(hidden_size)
      |> set_n_workers(n_workers)
      |> set_remove(remove)
      |> set_verbose(verbose)
      |> set_is_imported(false)
      |> set_seed(seed)
      |> set_validate(validate)
      |> set_margin(margin)
      |> set_alpha(alpha)
      |> set_lambda(lambda)
      |> set_optimizer(optimizer)
      |> set_task(task)
      |> set_bern(bern)
      |> set_n_export_steps(n_export_steps)
      |> set_model_impl(
        case model do
          :transe -> Grapex.Model.Transe
          :transe_heterogenous -> Grapex.Model.TranseHeterogenous
          :se -> Grapex.Model.Se
          :logicenn -> Grapex.Model.Logicenn
          model_name -> raise "Unknown model architecture #{model_name}"
        end
      ) 
      |> set_compiler(compiler)
      |> set_compiler_impl(
        case compiler do
          :default -> Nx.Defn.Evaluator
          :xla -> EXLA
          compiler_name -> raise "Unknown compiler #{compiler_name}"
        end
      )
      |> set_max_n_test_triples(max_n_test_triples)
      |> set_enable_bias(!disable_bias)
      |> set_enable_filters(enable_filters)
      |> set_drop_duplicates_during_filtration(!disable_duplicates_dropping)

    params = case entity_dimension do
      nil -> Grapex.Init.set_entity_dimension(params, hidden_size)
      _ when entity_dimension > 0 -> Grapex.Init.set_entity_dimension(params, entity_dimension)
    end

    params = case relation_dimension do
      nil -> Grapex.Init.set_relation_dimension(params, hidden_size)
      _ when relation_dimension > 0 -> Grapex.Init.set_relation_dimension(params, relation_dimension)
    end

    output_path = case {output_path, export_path} do
      {nil, nil} -> nil
      {nil, path} -> path
      {path, nil} -> path
      _ -> case output_path == export_path do
        true -> path
        _ -> raise "Two different output paths cannot be provided at the same time"
      end
    end

    params = case output_path do
      nil ->
        set_output_path(params,
          get_relative_path(
            params,
            Path.join(
              [
                case seed do
                  nil -> UUID.uuid1()
                  _ -> Integer.to_string(seed)
                end,
                "#{params.model}.onnx"
              ]
            )
          )
        )
      _ -> set_output_path(params, output_path)
    end

    params = case import_path do
      nil -> params
      _ -> set_import_path(params,
          get_relative_path(
            params,
            import_path
          )
      )
    end

    params = cond do
      min_delta == nil and patience == nil -> params
      min_delta != nil and patience != nil ->
        params
        |> set_min_delta(min_delta)
        |> set_patience(patience)
      true -> raise "Train parameters min_delta and patience must either both be provided either both be omitted"
    end
    
    params # |> IO.inspect
  end

  def from_cli_params(params) do
    IO.puts("Got following params:")
    IO.inspect(params)
    raise "Invalid command call. Required parameters weren't provided. See documentation for instructions on how to call the package."
  end

  def n_evaluation_triples(%Grapex.Init{max_n_test_triples: max_n_test_triples, verbose: verbose, corpus: corpus}, subset) do
    case max_n_test_triples do
      # nil -> Grapex.Meager.count_triples!(subset, verbose)
      nil -> Corpus.count_triples!(corpus, subset, verbose)
      # _ -> min(max_n_test_triples, Grapex.Meager.count_triples!(subset, verbose))
      _ -> min(max_n_test_triples, Corpus.count_triples!(corpus, subset, verbose))
    end
  end

  @spec get_model_by_name(String.t) :: atom
  def get_model_by_name(model) do
    case model do
      "transe" -> :transe
      "transe-heterogenous" -> :transe_heterogenous
      "se" -> :se
      "logicenn" -> :logicenn
      _ -> raise "Unknown model #{model}"
    end
  end

  @spec get_compiler_by_name(String.t) :: atom
  def get_compiler_by_name(compiler) do
    case compiler do
      "default" -> :default
      "xla" -> :xla
      _ -> raise "Unknown compiler #{compiler}"
    end
  end
end
