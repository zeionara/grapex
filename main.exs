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

# :rand.seed(:exsss, 1700)

{params, _, _} = Grapex.Init.set_input_path("#{Application.get_env(:grapex, :relentness_root)}/Assets/Corpora/Demo/0000/")
|> Grapex.Init.set_n_epochs(10)
# |> Grapex.Init.set_n_epochs(17)
|> Grapex.Init.set_n_batches(10)
|> Grapex.Init.set_model(:transe)
|> Grapex.Init.set_hidden_size(10)
|> Grapex.Init.set_entity_dimension(10)
|> Grapex.Init.set_relation_dimension(5)
|> (fn params -> Grapex.Init.set_output_path(params, Path.join([Application.get_env(:grapex, :project_root), "assets/models", "transe.onnx"])) end).()
# |> Grapex.Init.set_foo(22)
# |> IO.inspect
|> Grapex.Init.init_meager
|> Grapex.Init.init_computed_params
|> TranseHeterogenous.train_or_import
# |> IO.inspect structs: false
|> TranseHeterogenous.test
|> TranseHeterogenous.save

# IO.puts "Original model >>>"
# IO.inspect model, structs: false

# {model, state} = AxonOnnx.Deserialize.__import__(params.output_path)
# IO.puts state
# IO.puts "Deserialized model >>>"
# IO.inspect model, structs: false#
# Grapex.Init.init_meager(params)
# |> Grapex.Init.init_computed_params
# Meager.sample_head_batch |> IO.inspect
params
|> Grapex.Init.set_import_path(Path.join([Application.get_env(:grapex, :project_root), "assets/models", "transe.onnx"]))
|> TranseHeterogenous.train_or_import
|> TranseHeterogenous.test
#

# IO.inspect model, structs: false
# IO.inspect state

# Axon.input({nil, 2})
# |> Axon.embedding(10, 3)
# |> Axon.dense(3)
# model
# |> AxonOnnx.Serialize.__export__(state)
# |> AxonOnnx.Serialize.to_onnx([], [], [])
# |> IO.inspect structs: false

# IO.puts "\n\n--\n\n"

# AxonOnnx.Serialize.__export__(model, state)

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

