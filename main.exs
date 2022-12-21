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

alias Grapex.Model.Operations, as: ModelOps
alias Grapex.Meager.Corpus, as: Corpus

# EXLA.set_preferred_defn_options([:tpu, :cuda, :rocm])
# IO.inspect EXLA.NIF.get_supported_platforms()
# IO.inspect EXLA.NIF.get_gpu_client(1.0, 0)

n_epochs = 70
# n_epochs = 2

_model_filename = "transe-#{n_epochs}-epochs.onnx"
input_path = "#{Application.get_env(:grapex, :relentness_root)}/Assets/Corpora/Demo/0000/"

# {params, _, _}
# params = Grapex.Init.set_input_path("#{Application.get_env(:grapex, :relentness_root)}/Assets/Corpora/DemoTmp/0000/")
# params = Grapex.Init.set_input_path("#{Application.get_env(:grapex, :relentness_root)}/Assets/Corpora/DemoTmp/0000/")
# params = Grapex.Init.set_input_path("#{Application.get_env(:grapex, :relentness_root)}/Assets/Corpora/Demo/0000/")
# params = Grapex.Init.set_input_path("#{Application.get_env(:grapex, :relentness_root)}/Assets/Corpora/wordnet-11/")
# params = Grapex.Init.set_input_path("#{Application.get_env(:grapex, :relentness_root)}/Assets/Corpora/fb-13/")
# _params = Grapex.Init.set_input_path("#{Application.get_env(:grapex, :relentness_root)}/Assets/Corpora/wordnet-11/")
_params = Grapex.Init.set_input_path(input_path)
|> Grapex.Init.set_corpus(%Corpus{path: input_path, enable_filter: false, drop_pattern_duplicates: false, drop_filter_duplicates: true})
|> Grapex.Init.set_n_observed_triples_per_pattern_instance(1)
|> Grapex.Init.set_pattern(nil)
|> Grapex.Init.set_n_workers(1)
|> Grapex.Init.set_entity_negative_rate(1)
# |> Grapex.Init.from_file('assets/configs/default.yml')
|> Grapex.Init.set_n_epochs(n_epochs)
# |> Grapex.Init.set_n_epochs(8)
# |> Grapex.Init.set_n_epochs(20)
# |> Grapex.Init.set_max_n_test_triples(100)
# |> Grapex.Init.set_n_epochs(500)
# |> Grapex.Init.set_max_n_test_triples(200)
# |> Grapex.Init.set_n_epochs(17)
# |> Grapex.Init.set_n_batches(2000)
# |> Grapex.Init.set_batch_size(1024)
|> Grapex.Init.set_batch_size(40)
# |> Grapex.Init.set_n_batches(10)
# |> Grapex.Init.set_model(:logicenn)
# |> Grapex.Init.set_model_impl(Grapex.Model.Logicenn)
# |> Grapex.Init.set_model(:se)
# |> Grapex.Init.set_model_impl(Grapex.Model.Se)
|> Grapex.Init.set_model(:transe)
|> Grapex.Init.set_model_impl(Grapex.Model.Transe)
# |> Grapex.Init.set_model_impl(Grapex.Model.TranseHeterogenous)
# |> Grapex.Init.set_hidden_size(5)
|> Grapex.Init.set_hidden_size(10)
# |> Grapex.Init.set_entity_dimension(6)
# |> Grapex.Init.set_entity_dimension(6)
# |> Grapex.Init.set_relation_dimension(4)
|> Grapex.Init.set_alpha(0.001)
# |> Grapex.Init.set_alpha(0.3)
# |> Grapex.Init.set_alpha(0.8)
# |> Grapex.Init.set_lambda(0.02)
# |> Grapex.Init.set_alpha(0.05)
# |> Grapex.Init.set_alpha(0.3)
# |> Grapex.Init.set_lambda(0.2)
# |> Grapex.Init.set_lambda(0)
|> Grapex.Init.set_margin(5.0)
# |> Grapex.Init.set_margin(2)
# |> Grapex.Init.set_validate(true)
# |> Grapex.Init.set_n_export_steps(5)
# |> Grapex.Init.set_remove(true)
|> Grapex.Init.set_verbose(true)
# |> Grapex.Init.set_verbose(true)
|> Grapex.Init.set_compiler(:xla)
|> Grapex.Init.set_compiler_impl(EXLA)
# |> Grapex.Init.set_compiler_impl(Nx.Defn.Evaluator)
# |> Grapex.Init.set_enable_bias(true)
# |> Grapex.Init.set_enable_filters(true)
# |> Grapex.Init.set_min_delta(0.01)
# |> Grapex.Init.set_patience(50)
# |> (fn params -> Grapex.Init.set_output_path(params, Path.join([Application.get_env(:grapex, :project_root), "assets/models", "se.onnx"])) end).()
# |> (fn params -> Grapex.Init.set_input_path(params, Path.join([Application.get_env(:grapex, :project_root), "assets/models", "se.onnx"])) end).()
# |> (fn params -> Grapex.Init.set_output_path(params, Path.join([Application.get_env(:grapex, :project_root), "assets/models", "transe.onnx"])) end).()
# |> (fn params -> Grapex.Init.set_output_path(params, Path.join([Application.get_env(:grapex, :project_root), "assets/models", model_filename])) end).()
# |> (fn params -> Grapex.Init.set_import_path(params, Path.join([Application.get_env(:grapex, :project_root), "assets/models", model_filename])) end).()
# |> Grapex.Init.set_foo(22)
# |> IO.inspect
|> Grapex.Init.init_corpus
|> Grapex.Init.init_computed_params
|> ModelOps.train_or_import(seed: 19)
# # # |> IO.inspect structs: false
|> ModelOps.evaluate(:link_prediction, :test)
# |> ModelOps.save

# IO.write "\nfoo"
# IO.write "\nbar"
# IO.write "\nbaz"
# IO.write "\r\x1b[K"
# IO.write "\r\x1b[K"
# IO.write "\r\x1b[K\r\x1b[K"
# IO.write "\x1b[F"
# IO.write "\x1b[F"
# IO.write "\nqux"
# 
# IO.write "\n"
# Grapex.Meager.init_testing

# for _ <- 1..Grapex.Meager.n_test_triples do
#   # Grapex.Meager.sample_head_batch
#   # # |> IO.inspect
#   # |> Grapex.Models.Utils.to_model_input_for_testing(params.input_size)
#   # # |> IO.inspect
#   # |> generate_predictions_for_testing(model_impl, compiler, model, model_state)
#   # |> Nx.slice([0], [Grapex.Meager.n_entities])
#   # |> Nx.to_flat_list
#   # |> IO.inspect
#   # |> IO.inspect
#   for _ <- 1..Grapex.Meager.n_entities do 0.0 end
#   |> Grapex.Meager.test_head_batch(reverse: true)
# 
#   # Grapex.Meager.sample_tail_batch
#   # |> Grapex.Models.Utils.to_model_input_for_testing(params.input_size)
#   # |> generate_predictions_for_testing(model_impl, compiler, model, model_state)
#   # |> Nx.slice([0], [Grapex.Meager.n_entities])
#   # |> Nx.to_flat_list
#   for _ <- 1..Grapex.Meager.n_entities do 0.0 end
#   |> Grapex.Meager.test_tail_batch(reverse: true)
# end
# 
# Grapex.Meager.test_link_prediction(params.as_tsv)

# samples = params
#           # |> Grapex.Meager.sample_symmetric
#           |> Grapex.Meager.sample?(:symmetric, 1)
#           # |> SymmetricPatternOccurrence.get_positive_and_negative_triples
#           # |> IO.inspect(structs: false)
#           # |> IO.inspect(charlists: :as_lists)
#           # |> PatternOccurrence.to_tensor
#           |> IO.inspect

# samples.forward
# |> IO.inspect(structs: false)
# |> TripleOccurrence.as_tensor
# |> IO.inspect
# |> Grapex.Models.Utils.get_positive_and_negative_triples
# |> IO.inspect(charlists: :as_lists)
# |> Grapex.Models.Utils.to_model_input(params.margin, params.entity_negative_rate, params.relation_negative_rate) 
# |> IO.inspect

# IO.puts "Original model >>>"
# IO.inspect model, structs: false

# {model, state} = AxonOnnx.Deserialize.__import__(params.output_path)
# IO.puts state
# IO.puts "Deserialized model >>>"
# IO.inspect model, structs: false#
# Grapex.Init.init_meager(params)
# |> Grapex.Init.init_computed_params
# Meager.sample_head_batch |> IO.inspect



#
# Uncomment for testing model deserialization
#


# params
# |> Grapex.Init.set_import_path(Path.join([Application.get_env(:grapex, :project_root), "assets/models", "se.onnx"]))
# |> ModelOps.train_or_import
# # |> IO.inspect
# |> ModelOps.test



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

