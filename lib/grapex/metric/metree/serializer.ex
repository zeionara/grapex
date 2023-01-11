defmodule Grapex.Metric.Metree.Serializer do

  defp serialize_metric_name([%Grapex.Metric.Node{} = head | tail], length) when length == 1 do
    Serializer.serialize(head, [name_only: true, name_bytes: serialize(tail)])
  end

  defp serialize_metric_name([%Grapex.Metric.Node{} = head | tail], length) do
    Serializer.serialize(head, [name_only: true, name_bytes: serialize_metric_name(tail, length - 1)])
  end

  defp serialize_metric_value([%Grapex.Metric.Node{} = head | _tail], length, bytes) when length == 1 do
    Serializer.serialize(head, [value_only: true, value_bytes: bytes])
  end

  defp serialize_metric_value([%Grapex.Metric.Node{} = head | tail], length, bytes) do
    Serializer.serialize(head, [value_only: true, value_bytes: serialize_metric_value(tail, length - 1, bytes)])
  end

  def serialize(value, _opts \\ [])

  def serialize([] = value, _opts) do
    value
  end

  def serialize([%Grapex.Metric.Tree{length: length, is_leaf: is_leaf} = head | tail], _opts) when is_leaf == true do
    name = serialize_metric_name(tail, length)
    value = serialize_metric_value(tail, length, name)

    Serializer.serialize(head, [bytes: value])
  end

  def serialize([head | tail], _opts) do
    Serializer.serialize(head, [bytes: serialize(tail)])
  end

end
