defmodule T do
  def external_trace?(project, t, ctx) do
    module = elem(t, 1)
    context = Tracex.Project.get_extra(project, module, :context)
    context && context not in [ctx, "Web", "Lib"]
  end

  def internal_trace?(project, t, ctx) do
    module = elem(t, 1)
    context = Tracex.Project.get_extra(project, module, :context)
    context && context == ctx
  end

  def stats(project, traces) do
    external_insights = external_insights(project, traces)
    # internal_insights = internal_insights(project, traces)

    counts =
      external_insights
      |> Enum.reduce({0, 0}, fn {_, %{inbound: ins, outbound: outs}}, {acc_ins, acc_outs} ->
        {acc_ins + Enum.count(ins), acc_outs + Enum.count(outs)}
      end)

    counts
  end

  def contexts(project) do
    project
    |> Tracex.Project.get_modules()
    |> Enum.map(&(Map.get(&1, :extra) |> Map.get(:context)))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  def modules(project) do
    project
    |> Tracex.Project.get_modules()
    |> Enum.filter(&(Map.get(&1, :extra) |> Map.get(:context) == "Rt.Tracking"))
    |> Enum.map(& &1.name)
  end

  def external_insights(project, traces) do
    filter_insights(project, traces, &external_trace?/3)
  end

  def internal_insights(project, traces) do
    filter_insights(project, traces, &internal_trace?/3)
  end

  def filter_insights(project, traces, fun) do
    modules = modules(project)
    insights = traces |> Tracex.insights(modules)

    insights
    |> Enum.map(fn {module, %{inbound: ins, outbound: outs} = insight} ->
      context = Tracex.Project.get_extra(project, module, :context)

      insight =
        insight
        |> Map.put(:inbound, Enum.filter(ins, &fun.(project, &1, context)))
        |> Map.put(:outbound, Enum.filter(outs, &fun.(project, &1, context)))

      {module, insight}
    end)
  end

  def get_traces(insights, type) do
    insights
    |> Enum.flat_map(fn {_, insight} -> Map.get(insight, type) end)
  end

  def normalize_traces(traces) do
    traces
    |> Enum.map(&normalize_trace/1)
  end

  def normalize_trace(trace) do
    loc_index = loc_index(trace)
    trace |> put_elem(loc_index, elem(trace, loc_index) |> strip_line)
  end

  def strip_line(loc) do
    String.split(loc, ":") |> hd
  end

  def loc_index(t) do
    tuple_size(t) - 1
  end
end
