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

Meager.sample_head_batch
|> IO.inspect

# Meager.test_head_batch([0.2, 0.17, 0.19])
Meager.test_head_batch(for _ <- 1..Meager.n_entities, do: :rand.uniform())
|> (&(IO.puts("Head testing result: #{&1}"))).()

Meager.test_tail_batch(for _ <- 1..Meager.n_entities, do: :rand.uniform())
|> (&(IO.puts("Tail testing result: #{&1}"))).()
# IO.puts(batch)

