defmodule Tracex.Insights do
  alias Tracex.Env
  alias Tracex.Event

  def module(traces, modules) when is_list(modules) do
    traces
    |> Enum.reduce(%{}, fn trace, insights ->
      insights
      |> maybe_add_inbound_trace(trace, modules)
      |> maybe_add_outbound_trace(trace, modules)
    end)
  end

  def module(traces, module) do
    module(traces, [module]) |> Map.get(module)
  end

  def format_inbound(event, env) do
    case Event.get_func_and_arity(event) do
      nil -> {elem(event, 0), env.module, Env.get_location(env)}
      func -> {elem(event, 0), env.module, func, Env.get_location(env)}
    end
  end

  def format_outbound(event, env) do
    case Event.get_func_and_arity(event) do
      nil -> {elem(event, 0), Event.get_module(event), Env.get_location(env)}
      func -> {elem(event, 0), Event.get_module(event), func, Env.get_location(env)}
    end
  end

  defp maybe_add_inbound_trace(insights, {event, env}, modules) do
    module = Event.get_module(event)

    if module in modules do
      insights
      |> Map.put_new(module, %{inbound: [], outbound: []})
      |> update_in([module, :inbound], &[format_inbound(event, env) | &1])
    else
      insights
    end
  end

  defp maybe_add_outbound_trace(insights, {event, env}, modules) do
    module = env.module

    if module in modules do
      insights
      |> Map.put_new(module, %{inbound: [], outbound: []})
      |> update_in([module, :outbound], &[format_outbound(event, env) | &1])
    else
      insights
    end
  end
end
