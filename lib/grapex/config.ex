defmodule Grapex.Config do
  require Grapex.PersistedStruct

  Grapex.PersistedStruct.init [
    required_keys: [
      corpus: &Grapex.Meager.Corpus.import/1,
      sampler: &Grapex.Meager.Sampler.import/1,
      evaluator: &Grapex.Meager.Evaluator.import/1,

      model: &Grapex.Model.import/1,
      trainer: &Grapex.Trainer.import/1,
      optimizer: &Grapex.Optimizer.import/1,
      checkpoint: &Grapex.Checkpoint.import/1
    ]
  ]

  def import(path, opts \\ []) when not is_map(path) do
    config = 
      %Grapex.Config{checkpoint: checkpoint, corpus: corpus, model: model} = 
        path
        |> YamlElixir.read_from_file!(atoms: true)
        |> Grapex.Config.import

    IO.inspect checkpoint

    config # Set up default model checkpoint path
    |> struct(
      checkpoint: case checkpoint do
        %Grapex.Checkpoint{root: nil} -> 
          checkpoint
          |> struct(
            root: Grapex.Checkpoint.make_root(corpus, model, opts)
          )
        _ -> checkpoint
      end
    )
  end

end
