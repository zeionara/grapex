defmodule Grapex.Meager.Evaluator do
  use Grapex.Meager

  import Grapex.ExceptionHandling
  import Grapex.Patterns.MeagerDecoder
  import Grapex.Meager.Placeholder

  require Grapex.PersistedStruct

  Grapex.PersistedStruct.init [
    required_keys: [
      task: nil,
      metrics: &Grapex.Meager.Evaluator.parse_metrics/1,
    ],

    attributes: [
      valid_metrics: [
        :top_n,
        :rank,
        :reciprocal_rank
      ]
    ]
  ]

  def parse_metrics(metrics) do
    for metric <- metrics do
      case metric do
        [:top_n | [n]] -> {:top_n, n}
        [metric_id | _tail] -> {metric_id}
      end
    end
  end

  @spec init!(map, atom, boolean) :: map
  def init!(%Grapex.Meager.Evaluator{task: task, metrics: metrics} = self, subset, verbose \\ false) do  # when task in @valid_tasks and subset in @valid_subsets do
    raise_or_nil init_evaluator(metrics, task, subset, verbose)
    self
  end

  @spec trial!(map, atom, boolean) :: list
  def trial!(_self, component, verbose \\ false) when component in @valid_triple_components do 
    raise_or_value trial(component, verbose), as: fn data -> decode(data) end
  end

  @spec evaluate!(map, atom, list, boolean, list) :: map
  def evaluate!(self, component, predictions, verbose \\ false, opts \\ []) when component in @valid_triple_components do
    reverse = Keyword.get(opts, :reverse, false)  # reverse = higher values are better
    raise_or_nil evaluate(component, predictions, reverse, verbose)
    self
  end

  @spec compute_metrics!(map, bool) :: list
  def compute_metrics!(_self, verbose \\ false) do
    raise_or_value compute_metrics(verbose)
  end

end
