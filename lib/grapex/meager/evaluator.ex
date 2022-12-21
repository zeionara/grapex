defmodule Grapex.Meager.Evaluator do
  import Grapex.ExceptionHandling
  import Grapex.Patterns.MeagerDecoder
  import Grapex.Meager.Placeholder

  @enforce_keys [
    :task,
    :metrics
  ]
  defstruct @enforce_keys

  @spec init_evaluator!(map, atom, boolean) :: atom
  def init_evaluator!(%Grapex.Meager.Evaluator{task: task, metrics: metrics} = self, subset, verbose \\ false) do  # when task in @valid_tasks and subset in @valid_subsets do
    raise_or_nil init_evaluator(metrics, task, subset, verbose)
    self
  end

  @spec trial!(map, atom, boolean) :: atom
  def trial!(_self, component, verbose \\ false) do  # when component in @valid_triple_components do 
    raise_or_value trial(component, verbose), as: fn data -> decode(data) end
  end

  @spec evaluate!(map, atom, list, boolean, list) :: atom
  def evaluate!(_self, component, predictions, verbose \\ false, opts \\ []) do  # when component in @valid_triple_components do
    reverse = Keyword.get(opts, :reverse, false)  # reverse = higher values are better
    raise_or_nil evaluate(component, predictions, reverse, verbose)
  end

  @spec compute_metrics!(map, bool) :: atom
  def compute_metrics!(_self, verbose \\ false) do
    raise_or_value compute_metrics(verbose)
  end

end
