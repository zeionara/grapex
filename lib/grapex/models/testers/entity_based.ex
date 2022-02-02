defmodule Grapex.Models.Testers.EntityBased do
  require Axon
  # import Nx.Defn

  # defn post_process(x, n_entities) do
  #   x
  #   |> Nx.flatten
  #   |> Nx.slice([0], [Nx.scalar(n_entities)])
  # end

  defp generate_predictions_for_testing(batches,  %Grapex.Init{model_impl: model_impl, compiler_impl: compiler} = params, model, state) do
    # IO.inspect compiler
    # bt = batches |> PatternOccurrence.to_tensor(params)
    # IO.inspect bt
    # Axon.predict(model, state, Grapex.Models.Utils.to_model_input_for_testing(batches, input_size), compiler: compiler)
    # try do
    # IO.puts "Generating prediction"
    # prediction = model
    #              |> Axon.nx(&model_impl.compute_score/1) 
    #              |> Axon.predict(
    #                state,
    #                batches
    #                # |> IO.inspect
    #                |> PatternOccurrence.to_tensor(params)
    #                |> (&({&1.entities, &1.relations})).(),
    #                compiler: compiler
    #              )
    # IO.puts "Generated prediction"
    # sliced = prediction
    #          # |> model_impl.compute_score
    #          # |> post_process(Grapex.Meager.n_entities)
    #          # |> Nx.flatten
    # IO.puts "Post-processed prediction"
    # sliced = sliced
    #          |> Nx.slice([0], [Grapex.Meager.n_entities])
    # IO.puts "Generated slice"
    # result =
    {
      :continue,
      model
      |> Axon.nx(&model_impl.fix_shape/1)
      |> Axon.nx(&model_impl.compute_score/1) 
      |> Axon.predict(
        state,
        batches
        # |> IO.inspect
        |> PatternOccurrence.to_tensor(params)
        |> (&({&1.entities, &1.relations})).(),
        compiler: compiler
      )
      |> Nx.slice([0], [Grapex.Meager.n_entities])
      |> Nx.to_flat_list
    }
    # IO.puts "Generated result"
    # result
    # rescue
    #   _ ->
    #     IO.puts "Cannot evaluate test triple"
    #     IO.inspect batches
    #     for _ <- 1..Grapex.Meager.n_entities do 0 end
    #     {:halt, nil}
    # end
  end

  def test_one_triple(_config, i, n_test_triples, _reverse, command) when command == :halt or i >= n_test_triples, do: nil

  def test_one_triple({%Grapex.Init{as_tsv: as_tsv, validate: validate} = params, model, model_state}, i, n_test_triples, reverse, _command) do
    location = if as_tsv, do: nil, else: "#{i} / #{n_test_triples} / #{if validate, do: Grapex.Meager.n_valid_triples, else: Grapex.Meager.n_test_triples}" # unless verbose do nil else end 

    unless as_tsv do
      Grapex.IOutils.clear_lines(1)
      IO.write "\nHandling #{location} test triple..."
    end

    {command, predictions} = (if validate, do: Grapex.Meager.sample_validation_head_batch, else: Grapex.Meager.sample_head_batch)
                             |> generate_predictions_for_testing(params, model, model_state)

    if command == :continue do
      if validate, do: Grapex.Meager.validate_head_batch(predictions, reverse: reverse), else: Grapex.Meager.test_head_batch(predictions, reverse: reverse)

      {command, predictions} = (if validate, do: Grapex.Meager.sample_validation_tail_batch, else: Grapex.Meager.sample_tail_batch)
                               |> generate_predictions_for_testing(params, model, model_state)

      if command == :continue do
        if validate, do: Grapex.Meager.validate_tail_batch(predictions: predictions, reverse: reverse), else: Grapex.Meager.test_tail_batch(predictions, reverse: reverse)
      end
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

  # def validate({params, model, model_state}, opts \\ []) do
  #   reverse = Keyword.get(opts, :reverse, false)

  #   Grapex.Meager.init_testing

  #   n_triples = Grapex.Meager.n_valid_triples

  #   # case verbose do
  #   #   true -> IO.puts "Total number of validation triples: #{n_triples}"
  #   #   _ -> {:ok, nil}
  #   # end 

  #   for _ <- 1..n_triples do
  #     preds = Grapex.Meager.sample_validation_head_batch
  #     |> generate_predictions_for_testing(params, model, model_state)

  #     IO.inspect preds
  #     
  #     Grapex.Meager.validate_head_batch(preds, reverse: reverse)

  #     IO.puts "after"

  #     Grapex.Meager.sample_validation_tail_batch
  #     |> generate_predictions_for_testing(params, model, model_state)
  #     |> Grapex.Meager.validate_tail_batch(reverse: reverse)
  #   end

  #   Grapex.Meager.test_link_prediction(params.as_tsv)

  #   {params, model, model_state}
  # end

  defp generate_predictions_for_testing_(batches, model_impl, compiler, model, state) do
    Axon.predict(model, state, batches, compiler: compiler)
    |> model_impl.compute_score
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
