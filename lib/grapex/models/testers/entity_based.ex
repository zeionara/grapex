defmodule Grapex.Models.Testers.EntityBased do
  require Axon
  # import Nx.Defn

  defp reshape_output(x) do
      # IO.puts 'reshaping output'
      reshaped = x
      |> Nx.flatten
      |> Nx.slice([0], [Grapex.Meager.n_entities])
      |> Nx.to_flat_list
      # IO.puts 'reshaped output'
      reshaped
  end

  defp generate_predictions_for_testing(batches,  %Grapex.Init{model_impl: model_impl, compiler: compiler, compiler_impl: compiler_impl} = params, model, state, predict_fn) do
    # Axon.predict(model, state, Grapex.Models.Utils.to_model_input_for_testing(batches, input_size), compiler: compiler)
    # IO.puts "OK"
    # IO.puts '-'
    tensor = 
        batches
        # |> IO.inspect
        |> PatternOccurrence.to_tensor(params)
        |> (&(%{"entities" => &1.entities, "relations" => &1.relations})).()
    # IO.puts '*'
    # IO.puts 'generating prediction'
    prediction = predict_fn.(state, tensor)

    # IO.inspect predict_fn
    # prediction =
    #   model
    #   |> Axon.predict(
    #     state,
    #     tensor,
    #     compiler: compiler_impl
    #   )
    # IO.inspect prediction
    # IO.puts '+'
    # IO.puts 'generating score'
    score = 
      prediction
      |> model_impl.compute_score(compiler == :xla)  # compile scoring function to speed up execution
    # IO.inspect score
    # IO.puts ')'
    # {
    #   :continue,
    #   case compiler do
    #     :xla -> EXLA.jit(&reshape_output/1, [score])
    #     _ -> reshape_output(score)
    #   end
    #   |> Nx.to_flat_list
    # }
    {
      :continue,
      reshape_output(score)
    }
  end

  def test_one_triple(_config, _predict_fn, i, n_test_triples, _reverse, command) when command == :halt or i >= n_test_triples, do: nil

  def test_one_triple({%Grapex.Init{as_tsv: as_tsv, verbose: verbose} = params, model, model_state}, predict_fn, i, n_test_triples, reverse, _command) do
    location = if as_tsv, do: nil, else: "#{i} / #{n_test_triples}" # unless verbose do nil else end 

    unless as_tsv do
      Grapex.IOutils.clear_lines(1)
      IO.write "\nHandling #{location} test triple..."
    end

    # {_, predict_fn} = Axon.build(model, mode: :inference)
    # IO.puts "Start sampling head"

    {command, predictions} = Grapex.Meager.trial!(:head, verbose)
    # {command, predictions} = Grapex.Meager.sample_head_batch
                             |> generate_predictions_for_testing(params, model, model_state, predict_fn)
    
    # IO.puts "Stop sampling head"

    # IO.puts "Start testing head"
    if command == :continue do 
      # Grapex.Meager.test_head_batch(predictions, reverse: reverse)
      Grapex.Meager.evaluate!(:head, predictions, verbose, reverse: reverse)
    # IO.puts "Stop testing head"

    # IO.puts "Start sampling tail"
    {command, predictions} = Grapex.Meager.trial!(:tail, verbose)
    # {command, predictions} = Grapex.Meager.sample_tail_batch
                             |> generate_predictions_for_testing(params, model, model_state, predict_fn)
    # IO.puts "Stop sampling tail"

    # IO.puts "Start testing tail"
      if command == :continue do
        # Grapex.Meager.test_tail_batch(predictions, reverse: reverse)
        Grapex.Meager.evaluate!(:tail, predictions, verbose, reverse: reverse)
      end
    # IO.puts "Stop testing tail"
    end

    :erlang.garbage_collect()

    test_one_triple({params, model, model_state}, predict_fn, i + 1, n_test_triples, reverse, command)
  end

  # def test({%Grapex.Init{as_tsv: as_tsv} = params, model, model_state}, opts \\ []) do # {%Grapex.Init{verbose: verbose} = 
  def evaluate({%Grapex.Init{as_tsv: as_tsv, verbose: verbose} = params, model, model_state}, subset \\ :test, opts \\ []) do # {%Grapex.Init{verbose: verbose} = 
    reverse = Keyword.get(opts, :reverse, false)

    # Grapex.Meager.init_testing

    # n_test_triples = Grapex.Init.n_test_triples(params)

    n_test_triples = Grapex.Init.n_evaluation_triples(params, subset)

    unless as_tsv do
      IO.write "\n"
    end

    {_, predict_fn} = Axon.build(model, mode: :inference)

    test_one_triple({params, model, model_state}, predict_fn, 0, n_test_triples, reverse, :continue)


    # for i <- 1..Grapex.Meager.n_test_triples do
    # for i <- 1..n_test_triples do
    #   location = if as_tsv, do: nil, else: "#{i} / #{n_test_triples} / #{Grapex.Meager.n_test_triples}" # unless verbose do nil else end 

    #   unless as_tsv do
    #     Grapex.IOutils.clear_lines(1)
    #     IO.write "\nHandling #{location} test triple..."
    #   end

    #   {command, predictions} = Grapex.Meager.sample_head_batch
    #                            |> generate_predictions_for_testing(params, model, model_state)
    #   
    #   if command == :continue do 
    #     Grapex.Meager.test_head_batch(predictions, reverse: reverse)

    #     {command, predictions} = Grapex.Meager.sample_tail_batch
    #                              |> generate_predictions_for_testing(params, model, model_state)

    #     if command == :continue do
    #       Grapex.Meager.test_tail_batch(predictions, reverse: reverse)
    #     else
    #       if command == :halt do
    #         i = n_test_triples
    #       end
    #     end
    #   else
    #     if command == :halt do
    #       i = n_test_triples
    #     end
    #   end

    #   # if verbose do
    #   #   IO.write "\nHandled #{location} test triple"
    #   # end
    # end

    unless as_tsv do
      IO.write "\n\n"
    end

    # Grapex.Meager.test_link_prediction(params.as_tsv)
    evaluation_results = Grapex.Meager.compute_metrics!(verbose)

    %Grapex.EvaluationResults{data: evaluation_results} |> Grapex.EvaluationResults.puts

    # metrics = get_metrics(evaluation_results)
    # metrics
    # |> Enum.map(
    #   fn x ->
    #     case x do
    #       {metric, parameter} -> "#{metric}@#{parameter}"
    #       res -> Atom.to_string(res)
    #     end
    #     |> String.pad_trailing(16)
    #   end
    # )
    # |> Enum.join
    # |> String.pad_leading(32 + 16 * length(metrics))
    # |> IO.puts
    # # |> Enum.join " "
    # metric_values = get_metric_value(evaluation_results)
    #                 |> List.flatten
    #                 |> Enum.join("\n")
    #                 |> IO.puts
    #   |> Enum.map(
    #     fn metric -> 
    #       evaluation_results
    #       x 
    #     end
    #   )
    #   |> IO.inspect

    {params, model, model_state}
  end

  # def get_metrics([]) do
  #   []
  # end

  # def get_metrics([head | tail]) do
  #   case head do
  #     {label, [nested_head | nested_tail] = items} -> get_metrics(items)
  #     {metric, value} -> [metric | get_metrics(tail)]
  #   end
  # end

  # def get_metric_value(items, labels \\ []) do
  #   Enum.map(
  #     items, fn item -> 
  #       case item do
  #         {label, [{nested_label, [nested_nested_head | nested_nested_tail]} | nested_tail] = items} -> get_metric_value(items, [label | labels])
  #         {label, [{nested_label, nested_value} | nested_tail] = items} ->
  #           values = items
  #           |> Enum.map(
  #             fn item -> 
  #               elem(item, 1)
  #             end
  #           )

  #           title =
  #             [label | labels]
  #             |> Enum.reverse
  #             |> Enum.join(" ")
  #             |> String.pad_trailing(32)

  #           values_ = 
  #             values
  #             |> Enum.map(
  #               fn x ->
  #                 Float.to_string(x, decimals: 5)
  #                 |> String.pad_trailing(16)
  #               end
  #             )
  #             |> Enum.join

  #           # {title, values_}
  #           "#{title}#{values_}"
  #           # |> IO.inspect
  #       end
  #     end
  #   )
  #   # IO.inspect joined
  #   # |> Enum.join("\n")
  #   # |> IO.puts
  # end

  # def validate({params, model, model_state}, opts \\ []) do
  #   reverse = Keyword.get(opts, :reverse, false)

  #   Grapex.Meager.init_testing

  #   n_triples = Grapex.Meager.n_valid_triples

  #   # case verbose do
  #   #   true -> IO.puts "Total number of validation triples: #{n_triples}"
  #   #   _ -> {:ok, nil}
  #   # end 

  #   for _ <- 1..n_triples do
  #     Grapex.Meager.sample_validation_head_batch
  #     |> generate_predictions_for_testing(params, model, model_state)
  #     |> Grapex.Meager.validate_head_batch(reverse: reverse)

  #     Grapex.Meager.sample_validation_tail_batch
  #     |> generate_predictions_for_testing(params, model, model_state)
  #     |> Grapex.Meager.validate_tail_batch(reverse: reverse)
  #   end

  #   Grapex.Meager.test_link_prediction(params.as_tsv)

  #   {params, model, model_state}
  # end

  defp generate_predictions_for_testing_(batches, model_impl, compiler, model, state) do  # deprecated (missing compiler checking for the case in which model is executed without xla)
    Axon.predict(model, state, batches, compiler: compiler)
    |> model_impl.compute_score(true)
    |> Nx.flatten
  end

  def test_({%Grapex.Init{model_impl: model_impl, compiler_impl: compiler} = params, model, model_state}, opts \\ []) do
    reverse = Keyword.get(opts, :reverse, false)

    Grapex.Meager.init_testing

    for _ <- 1..Grapex.Meager.n_test_triples do
      Grapex.Meager.sample_head_batch
      # |> IO.inspect
      |> Grapex.Models.Utils.to_model_input_for_testing(params.input_size)
      # |> IO.inspect
      |> generate_predictions_for_testing_(model_impl, compiler, model, model_state)
      |> Nx.slice([0], [Grapex.Meager.n_entities])
      |> Nx.to_flat_list
      # |> IO.inspect
      |> Grapex.Meager.test_head_batch(reverse: reverse)

      Grapex.Meager.sample_tail_batch
      |> Grapex.Models.Utils.to_model_input_for_testing(params.input_size)
      |> generate_predictions_for_testing_(model_impl, compiler, model, model_state)
      |> Nx.slice([0], [Grapex.Meager.n_entities])
      |> Nx.to_flat_list
      |> Grapex.Meager.test_tail_batch(reverse: reverse)
    end

    Grapex.Meager.test_link_prediction(params.as_tsv)

    {params, model, model_state}
  end
end
