defmodule Tracex.Insights do
  alias Tracex.Trace

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
    case Trace.event_func_and_arity(event) do
      nil -> {elem(event, 0), env.module, Trace.call_location({event, env})}
      func -> {elem(event, 0), env.module, func, Trace.call_location({event, env})}
    end
  end

  def format_outbound(event, env) do
    case Trace.event_func_and_arity(event) do
      nil ->
        {elem(event, 0), Trace.event_module({event, env}), Trace.call_location({event, env})}

      func ->
        {elem(event, 0), Trace.event_module({event, env}), func,
         Trace.call_location({event, env})}
    end
  end

  defp maybe_add_inbound_trace(insights, {event, env}, modules) do
    module = Trace.event_module({event, env})

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
