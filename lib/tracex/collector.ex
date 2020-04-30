defmodule Tracex.Collector do
  @moduledoc false

  use GenServer

  alias Tracex.Trace
  alias Tracex.Project

  @opaque state :: {Project.t(), list(Trace.t()), list(classifier)}
  @type classifier :: atom

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

  @spec start_link(Project.t(), list(Trace.t()), list(classifier)) ::
          :ignore | {:error, any} | {:ok, pid}
  def start_link(project, traces, classifiers) do
    GenServer.start_link(__MODULE__, {project, traces, classifiers}, name: __MODULE__)
  end

  @spec stop :: nil | :ok
  def stop do
    if GenServer.whereis(__MODULE__), do: GenServer.stop(__MODULE__)
  end

  @spec init(state) :: {:ok, state}
  def init({project, traces, classifiers}) do
    {:ok, {project, traces, classifiers}}
  end

  @spec process({tuple, Macro.Env.t()}) :: :ok
  def process(trace) do
    GenServer.cast(__MODULE__, {:process, trace})
  end

  @spec finalize :: {Project.t(), list(Trace.t())}
  def finalize do
    GenServer.call(__MODULE__, :finalize, :infinity)
  end

  def handle_cast({:process, {_, env} = trace}, {project, _, _} = state) do
    if project_file?(project, env.file) do
      trace = normalize_trace(trace, project)

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
      annotations = classifier.classify(trace) |> List.wrap()

      Enum.reduce(annotations, project, fn annotation, project ->
        case annotation do
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
      {project, [trace | traces], classifiers}
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
          module -> Project.get_module(project, module) |> Map.get(:file)
        end

      dest = Project.get_module(project, Trace.inbound_module(trace)) |> Map.get(:file)

      src != dest
    end)
  end

  defp relative_path(full_path, project) do
    Path.relative_to(full_path, project.root_path)
  end
end
