Meager.set_input_path("/home/zeio/relentness/Assets/Corpora/Demo/0000/", false)
Meager.set_bern_flag # Meager.set_bern_flag(true)
Meager.set_n_workers(8)
Meager.reset_randomizer()
|> (&(IO.puts("Randomizer reset result: #{&1}"))).()
Meager.import_train_files(true)
|> (&(IO.puts("Train files import result: #{&1}"))).()

