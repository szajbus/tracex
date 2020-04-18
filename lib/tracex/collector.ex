defmodule Tracex.Collector do
  use GenServer

  alias Tracex.Event
  alias Tracex.Project

  def start_link(project) do
    GenServer.start_link(__MODULE__, project, name: __MODULE__)
  end

  def init(project) do
    {:ok, {project, []}}
  end

  def process(event, env) do
    GenServer.call(__MODULE__, {:process, event, env})
  end

  def get_project() do
    GenServer.call(__MODULE__, :get_project)
  end

  def get_traces() do
    GenServer.call(__MODULE__, :get_traces)
  end

  def handle_call(
        {:process, event, env},
        _from,
        {project, _traces} = state
      ) do
    if project_file?(project, env.file) do
      state =
        state
        |> maybe_collect_module(event, env)
        |> maybe_collect_trace(event, env)

      {:reply, :ok, state}
    else
      {:reply, :ok, state}
    end
  end

  def handle_call(:get_traces, _from, {project, traces}) do
    {:reply, Enum.reverse(traces), {project, traces}}
  end

  def handle_call(:get_project, _from, {project, traces}) do
    {:reply, project, {project, traces}}
  end

  defp maybe_collect_module({project, traces}, event, env) do
    cond do
      Event.module_definition?(event) ->
        {Project.add_module(project, env.module), traces}

      Event.ecto_schema_definition?(event) ->
        {Project.add_ecto_schema(project, env.module), traces}

      true ->
        {project, traces}
    end
  end

  defp maybe_collect_trace({project, traces}, event, env) do
    if Event.get_module(event) in project.modules do
      {project, [to_trace(event, env, project) | traces]}
    else
      {project, traces}
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
