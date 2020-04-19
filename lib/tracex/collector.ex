defmodule Tracex.Collector do
  use GenServer

  alias Tracex.Event
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

  def process(event, env) do
    GenServer.cast(__MODULE__, {:process, event, env})
  end

  def finalize do
    GenServer.call(__MODULE__, :finalize, :infinity)
  end

  def get_project do
    GenServer.call(__MODULE__, :get_project)
  end

  def get_traces do
    GenServer.call(__MODULE__, :get_traces)
  end

  def handle_cast({:process, event, env}, {project, _traces} = state) do
    if project_file?(project, env.file) do
      state =
        state
        |> maybe_collect_module(event, env)
        |> maybe_collect_trace(event, env)

      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  def handle_call(:finalize, _from, {project, traces}) do
    modules = Map.keys(project.modules)

    traces =
      traces
      |> Enum.filter(fn {event, _} -> Event.get_module(event) in modules end)
      |> Enum.reverse()

    {:reply, :ok, {project, traces}}
  end

  def handle_call(:get_traces, _from, {project, traces}) do
    {:reply, Enum.reverse(traces), {project, traces}}
  end

  def handle_call(:get_project, _from, {project, traces}) do
    {:reply, project, {project, traces}}
  end

  defp maybe_collect_module({project, traces}, event, env) do
    project =
      cond do
        Event.module_definition?(event) ->
          Project.add_module(project, {env.module, env.file})

        Event.ecto_schema_definition?(event) ->
          Project.add_ecto_schema(project, {env.module, env.file})

        true ->
          project
      end

    {project, traces}
  end

  defp maybe_collect_trace({project, traces}, event, env) do
    if Event.get_module(event) in @discarded_modules do
      {project, traces}
    else
      {project, [to_trace(event, env, project) | traces]}
    end
  end

  defp project_file?(%{root_path: root_path}, path),
    do: String.starts_with?(path, root_path <> "/")

  defp to_trace(event, env, %{root_path: root_path}) do
    env =
      env
      |> Map.take(~w(aliases context context_modules file function line module)a)
      |> Map.update!(:file, &String.replace_leading(&1, root_path <> "/", ""))

    {event, env}
  end
end
