#
#  Demonstrate some features of the meager library adapter
#

# Meager.set_input_path("/home/zeio/relentness/Assets/Corpora/Demo/0000/", false)
# Meager.set_bern_flag # Meager.set_bern_flag(true)
# Meager.set_n_workers(8)
# Meager.reset_randomizer()
# |> (&(IO.puts("Randomizer reset result: #{&1}"))).()
# Meager.import_train_files
# |> (&(IO.puts("Train files import result: #{&1}"))).()
# 
# Meager.import_test_files
# |> (&(IO.puts("Test files import result: #{&1}"))).()
# 
# Meager.read_type_files
# |> (&(IO.puts("Type files import result: #{&1}"))).()
# 
# IO.puts("n-relations = #{Meager.n_relations}; n-entities = #{Meager.n_entities}; n-train-triples = #{Meager.n_train_triples}; n-test-triples = #{Meager.n_test_triples}; n-valid-triples = #{Meager.n_valid_triples}")
# 
# Meager.sample
# |> IO.inspect
# 
# Meager.sample
# |> IO.inspect
# 
# Meager.sample_head_batch
# |> IO.inspect
# 
# # Meager.test_head_batch([0.2, 0.17, 0.19])
# Meager.test_head_batch(for _ <- 1..Meager.n_entities, do: :rand.uniform())
# |> (&(IO.puts("Head testing result: #{&1}"))).()
# 
# Meager.test_tail_batch(for _ <- 1..Meager.n_entities, do: :rand.uniform())
# |> (&(IO.puts("Tail testing result: #{&1}"))).()
# # IO.puts(batch)
# 
# Meager.test_link_prediction

#
#  Initialize knowledge graph embeddings model
#

# local_path = "/Demo/0000"
# 
# path = case local_path do
#   "/" <> _ = absolute_path -> absolute_path
#   _ -> Path.join([Application.get_env(:grapex, :relentness_root),"Assets/Corpora", local_path])
# end
# 
# IO.puts(path)

params = Grapex.Init.set_input_path("#{Application.get_env(:grapex, :relentness_root)}/Assets/Corpora/Demo/0000/")
|> Grapex.Init.set_n_epochs(20)
# |> Grapex.Init.set_n_epochs(17)
|> Grapex.Init.set_n_batches(10)
|> Grapex.Init.set_model(:transe)
# |> Grapex.Init.set_foo(22)
# |> IO.inspect
|> Grapex.Init.init_meager
|> Grapex.Init.init_computed_params

{model, model_state} = TransE.run(params)

for _ <- 1..Meager.n_test_triples do
  Meager.sample_head_batch
  |> Models.Utils.to_model_input_for_testing(params.input_size)
  |> TransE.test(model, model_state)
  |> Nx.slice([0], [Meager.n_entities])
  |> Nx.to_flat_list
  |> Meager.test_head_batch
  # |> IO.inspect

  Meager.sample_tail_batch
  |> Models.Utils.to_model_input_for_testing(params.input_size)
  |> TransE.test(model, model_state)
  |> Nx.slice([0], [Meager.n_entities])
  |> Nx.to_flat_list
  |> Meager.test_tail_batch
  # |> IO.inspect
end

Meager.test_link_prediction

# Meager.set_input_path(params.input_path, false)
# Meager.set_n_workers(8)
# Meager.reset_randomizer()
# 
# Meager.import_train_files
# Meager.import_test_files
# Meager.read_type_files
# 
# IO.puts("n-relations = #{Meager.n_relations}; n-entities = #{Meager.n_entities}; n-train-triples = #{Meager.n_train_triples}; n-test-triples = #{Meager.n_test_triples}; n-valid-triples = #{Meager.n_valid_triples}")

# samples = Meager.sample
# |> Models.Utils.get_positive_and_negative_triples
# |> Models.Utils.to_model_input
# |> IO.inspect

# TransE.run(params)

