defmodule Tracex.Collector do
  use GenServer

  def start_link(project) do
    GenServer.start_link(__MODULE__, project, name: __MODULE__)
  end

  def init(project) do
    {:ok, {project, []}}
  end

  def process(event, env) do
    GenServer.call(__MODULE__, {:process, event, env})
  end

  def get_traces() do
    GenServer.call(__MODULE__, :get_traces)
  end

  def dump_to_file(path) do
    GenServer.call(__MODULE__, {:dump_to_file, path}, :infinity)
  end

  def handle_call(
        {:process, event, env},
        _from,
        {project, _traces} = state
      ) do
    if project_file?(project, env.file) do
      state = maybe_collect_trace(event, env, state)

      {:reply, :ok, state}
    else
      {:reply, :ok, state}
    end
  end

  def handle_call(:get_traces, _from, {project, traces}) do
    {:reply, traces, {project, traces}}
  end

  def handle_call({:dump_to_file, path}, _from, {project, traces}) do
    file = File.stream!(path)

    traces
    |> Enum.reverse()
    |> Stream.map(&encode/1)
    |> Stream.intersperse("\n")
    |> Stream.into(file)
    |> Stream.run()

    {:reply, :ok, {project, traces}}
  end

  defp maybe_collect_trace({:defmodule, _}, env, {project, traces}) do
    project = Map.update!(project, :modules, &[env.module | &1])
    {project, traces}
  end

  defp maybe_collect_trace(event, env, {project, traces}) do
    if Tracex.Event.get_module(event) in project.modules do
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

  defp encode(trace) do
    inspect(trace,
      limit: :infinity,
      printable_limit: :infinity,
      width: 1_000_000_000
    )
  end
end
