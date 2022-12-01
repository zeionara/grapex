defmodule Grapex.Models.Testers.EntityBased do
  require Axon
  # import Nx.Defn

  defp reshape_output(x) do
      x
      |> Nx.flatten
      |> Nx.slice([0], [Grapex.Meager.n_entities])
      |> Nx.to_flat_list
  end

  defp generate_predictions_for_testing(batches,  %Grapex.Init{model_impl: model_impl, compiler: compiler, compiler_impl: compiler_impl} = params, model, state) do
    # Axon.predict(model, state, Grapex.Models.Utils.to_model_input_for_testing(batches, input_size), compiler: compiler)
    # IO.puts "OK"
    # IO.puts '-'
    tensor = 
        batches
        # |> IO.inspect
        |> PatternOccurrence.to_tensor(params)
        |> (&({&1.entities, &1.relations})).()
    # IO.puts '*'
    prediction =
      model
      |> Axon.predict(
        state,
        tensor,
        compiler: compiler_impl
      )
    # IO.puts '+'
    score = 
      prediction
      |> model_impl.compute_score(compiler == :xla)  # compile scoring function to speed up execution
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

  def test_one_triple(_config, i, n_test_triples, _reverse, command) when command == :halt or i >= n_test_triples, do: nil

  def test_one_triple({%Grapex.Init{as_tsv: as_tsv, verbose: verbose} = params, model, model_state}, i, n_test_triples, reverse, _command) do
    location = if as_tsv, do: nil, else: "#{i} / #{n_test_triples} / #{Grapex.Meager.n_test_triples}" # unless verbose do nil else end 

    unless as_tsv do
      Grapex.IOutils.clear_lines(1)
      IO.write "\nHandling #{location} test triple..."
    end

    # IO.puts "Start sampling head"

    

    {command, predictions} = Grapex.Meager.trial!(:head, verbose)
    # {command, predictions} = Grapex.Meager.sample_head_batch
                             |> generate_predictions_for_testing(params, model, model_state)
    
    # IO.puts "Stop sampling head"

    # IO.puts "Start testing head"
    if command == :continue do 
      Grapex.Meager.test_head_batch(predictions, reverse: reverse)
    # IO.puts "Stop testing head"

    # IO.puts "Start sampling tail"
    {command, predictions} = Grapex.Meager.trial!(:tail, verbose)
    # {command, predictions} = Grapex.Meager.sample_tail_batch
                             |> generate_predictions_for_testing(params, model, model_state)
    # IO.puts "Stop sampling tail"

    # IO.puts "Start testing tail"
      if command == :continue do
        Grapex.Meager.test_tail_batch(predictions, reverse: reverse)
      end
    # IO.puts "Stop testing tail"
    end

    test_one_triple({params, model, model_state}, i + 1, n_test_triples, reverse, command)
  end

  def test({%Grapex.Init{as_tsv: as_tsv} = params, model, model_state}, opts \\ []) do # {%Grapex.Init{verbose: verbose} = 
    reverse = Keyword.get(opts, :reverse, false)

    Grapex.Meager.init_testing

    n_test_triples = Grapex.Init.n_test_triples(params)

    unless as_tsv do
      IO.write "\n"
    end

    test_one_triple({params, model, model_state}, 0, n_test_triples, reverse, :continue)
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

    Grapex.Meager.test_link_prediction(params.as_tsv)

    {params, model, model_state}
  end

  def validate({params, model, model_state}, opts \\ []) do
    reverse = Keyword.get(opts, :reverse, false)

    Grapex.Meager.init_testing

    n_triples = Grapex.Meager.n_valid_triples

    # case verbose do
    #   true -> IO.puts "Total number of validation triples: #{n_triples}"
    #   _ -> {:ok, nil}
    # end 

    for _ <- 1..n_triples do
      Grapex.Meager.sample_validation_head_batch
      |> generate_predictions_for_testing(params, model, model_state)
      |> Grapex.Meager.validate_head_batch(reverse: reverse)

      Grapex.Meager.sample_validation_tail_batch
      |> generate_predictions_for_testing(params, model, model_state)
      |> Grapex.Meager.validate_tail_batch(reverse: reverse)
    end

    Grapex.Meager.test_link_prediction(params.as_tsv)

    {params, model, model_state}
  end

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
