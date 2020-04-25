defmodule Tracex.Collector do
  use GenServer

  alias Tracex.Classifier
  alias Tracex.Trace
  alias Tracex.Project

  @discarded_modules [
    Kernel,
    Kernel.LexicalTracker,
    Kernel.Typespec,
    Kernel.Utils,
    Module,
    Enum,
    Map,
    Keyword,
    List,
    String,
    String.Chars,
    Macro,
    Protocol,
    Logger,
    :elixir_bootstrap,
    :elixir_def,
    :elixir_module,
    :elixir_utils,
    :erlang,
    :maps
  ]

  def start_link(project, traces) do
    GenServer.start_link(__MODULE__, {project, traces}, name: __MODULE__)
  end

  def stop do
    if GenServer.whereis(__MODULE__), do: GenServer.stop(__MODULE__)
  end

  def init({project, traces}) do
    {:ok, {project, traces}}
  end

  def process(trace) do
    GenServer.cast(__MODULE__, {:process, trace})
  end

  def finalize do
    GenServer.call(__MODULE__, :finalize, :infinity)
  end

  def handle_cast({:process, {_, env} = trace}, {project, _traces} = state) do
    if project_file?(project, env.file) do
      state =
        state
        |> maybe_collect_module(trace)
        |> maybe_collect_trace(trace)

      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  def handle_call(:finalize, _from, {project, traces}) do
    traces =
      traces
      |> discard_non_project_modules(project)
      |> discard_local_traces(project)
      |> Enum.reverse()

    {:reply, {project, traces}, {project, traces}}
  end

  defp maybe_collect_module({project, traces}, trace) do
    project =
      project
      |> maybe_add_module(trace)
      |> maybe_classify_module(trace)

    {project, traces}
  end

  defp maybe_add_module(project, {_, env} = trace) do
    if Trace.module_definition?(trace) do
      Project.add_module(
        project,
        {Trace.outbound_module(trace), relative_path(env.file, project)}
      )
    else
      project
    end
  end

  defp maybe_classify_module(project, trace) do
    case Classifier.classify(trace) do
      nil -> project
      {:tag, tag} -> Project.tag_module(project, Trace.outbound_module(trace), tag)
    end
  end

  defp maybe_collect_trace({project, traces}, trace) do
    if Trace.module_definition?(trace) or Trace.inbound_module(trace) in @discarded_modules do
      {project, traces}
    else
      {project, [normalize_trace(trace, project) | traces]}
    end
  end

  defp project_file?(%{root_path: root_path}, path),
    do: String.starts_with?(path, root_path <> "/")

  defp normalize_trace({event, env}, project) do
    env =
      env
      |> Map.take(~w(aliases context context_modules file function line module)a)
      |> Map.update!(:file, &relative_path(&1, project))

    {event, env}
  end

  defp discard_non_project_modules(traces, project) do
    Enum.filter(traces, fn trace ->
      Trace.inbound_module(trace) in Map.keys(project.modules)
    end)
  end

  defp discard_local_traces(traces, project) do
    Enum.filter(traces, fn {_, env} = trace ->
      src =
        case Trace.outbound_module(trace) do
          nil -> env.file
          module -> Project.module_file(project, module)
        end

      dest = Project.module_file(project, Trace.inbound_module(trace))

      src != dest
    end)
  end

  defp relative_path(full_path, project) do
    Path.relative_to(full_path, project.root_path)
  end
end
