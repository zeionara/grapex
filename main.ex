Meager.set_input_path("/home/zeio/relentness/Assets/Corpora/Demo/0000/", false)
Meager.set_bern_flag # Meager.set_bern_flag(true)
Meager.set_n_workers(8)
Meager.reset_randomizer()
|> (&(IO.puts("Randomizer reset result: #{&1}"))).()
Meager.import_train_files
|> (&(IO.puts("Train files import result: #{&1}"))).()

Meager.import_test_files
|> (&(IO.puts("Test files import result: #{&1}"))).()

Meager.read_type_files
|> (&(IO.puts("Type files import result: #{&1}"))).()

IO.puts("n-relations = #{Meager.n_relations}; n-entities = #{Meager.n_entities}; n-train-triples = #{Meager.n_train_triples}; n-test-triples = #{Meager.n_test_triples}; n-valid-triples = #{Meager.n_valid_triples}")

Meager.sample
|> IO.inspect

Meager.sample
|> IO.inspect

# IO.puts(batch)

