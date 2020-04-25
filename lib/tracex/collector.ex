defmodule Tracex.Collector do
  use GenServer

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

  def start_link(project, traces, classifiers) do
    GenServer.start_link(__MODULE__, {project, traces, classifiers}, name: __MODULE__)
  end

  def stop do
    if GenServer.whereis(__MODULE__), do: GenServer.stop(__MODULE__)
  end

  def init({project, traces, classifiers}) do
    {:ok, {project, traces, classifiers}}
  end

  def process(trace) do
    GenServer.cast(__MODULE__, {:process, trace})
  end

  def finalize do
    GenServer.call(__MODULE__, :finalize, :infinity)
  end

  def handle_cast({:process, {_, env} = trace}, {project, _, _} = state) do
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

  def handle_call(:finalize, _from, {project, traces, classifiers}) do
    traces =
      traces
      |> discard_non_project_modules(project)
      |> discard_local_traces(project)
      |> Enum.reverse()

    {:reply, {project, traces}, {project, traces, classifiers}}
  end

  defp maybe_collect_module({project, traces, classifiers}, trace) do
    project =
      project
      |> maybe_classify_module(trace, classifiers)

    {project, traces, classifiers}
  end

  defp maybe_classify_module(project, trace, classifiers) do
    Enum.reduce(classifiers, project, fn classifier, project ->
      actions = classifier.classify(trace) |> List.wrap()

      Enum.reduce(actions, project, fn action, project ->
        case action do
          {:track, module, file} ->
            Project.add_module(project, {module, relative_path(file, project)})

          {:tag, module, tag} ->
            Project.tag_module(project, module, tag)

          {:extra, module, key, val} ->
            Project.add_extra(project, module, key, val)
        end
      end)
    end)
  end

  defp maybe_collect_trace({project, traces, classifiers}, trace) do
    if Trace.module_definition?(trace) or Trace.inbound_module(trace) in @discarded_modules do
      {project, traces, classifiers}
    else
      {project, [normalize_trace(trace, project) | traces], classifiers}
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
