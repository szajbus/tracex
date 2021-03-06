defmodule Tracex.Insights do
  @moduledoc """
  Module providing insights on project's modules by analyzing traces collected
  during its compilation
  """

  alias Tracex.Trace

  @doc """
  Returns insights on given module or modules

  If you need insights on multiple modules it's faster to pass them as a list
  to this function instead of calling it for each module separately.
  """
  @spec module(list(), atom | list(atom)) :: map
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

  defp format_inbound({event, _} = trace) do
    if Trace.remote_call?(trace) do
      {elem(event, 0), Trace.outbound_module(trace), Trace.event_func_and_arity(trace),
       Trace.event_location(trace)}
    else
      {elem(event, 0), Trace.outbound_module(trace), Trace.event_location(trace)}
    end
  end

  defp format_outbound({event, _} = trace) do
    if Trace.remote_call?(trace) do
      {elem(event, 0), Trace.inbound_module(trace), Trace.event_func_and_arity(trace),
       Trace.event_location(trace)}
    else
      {elem(event, 0), Trace.inbound_module(trace), Trace.event_location(trace)}
    end
  end

  defp maybe_add_inbound_trace(insights, trace, modules) do
    module = Trace.inbound_module(trace)

    if module in modules do
      insights
      |> Map.put_new(module, %{inbound: [], outbound: []})
      |> update_in([module, :inbound], &[format_inbound(trace) | &1])
    else
      insights
    end
  end

  defp maybe_add_outbound_trace(insights, {_, env} = trace, modules) do
    module = env.module

    if module in modules do
      insights
      |> Map.put_new(module, %{inbound: [], outbound: []})
      |> update_in([module, :outbound], &[format_outbound(trace) | &1])
    else
      insights
    end
  end
end
