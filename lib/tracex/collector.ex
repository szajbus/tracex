defmodule Tracex.Collector do
  use GenServer

  def start_link(project) do
    GenServer.start_link(__MODULE__, project, name: __MODULE__)
  end

  def init(project) do
    {:ok, {project, []}}
  end

  def log_trace(event, env) do
    GenServer.call(__MODULE__, {:log_trace, event, env})
  end

  def dump_to_file(path) do
    GenServer.call(__MODULE__, {:dump_to_file, path}, :infinity)
  end

  def handle_call(
        {:log_trace, event, env},
        _from,
        {project, traces}
      ) do
    traces =
      if project_file?(project, env.file) do
        env = build_env(env, project)
        [{event, env} | traces]
      else
        traces
      end

    {:reply, :ok, {project, traces}}
  end

  def handle_call({:dump_to_file, path}, _from, %{traces: traces} = state) do
    file = File.stream!(path)

    traces
    |> Stream.map(&encode/1)
    |> Stream.intersperse("\n")
    |> Stream.into(file)
    |> Stream.run()

    {:reply, :ok, state}
  end

  defp project_file?(%{root_path: root_path}, path),
    do: String.starts_with?(path, root_path <> "/")

  defp build_env(env, %{root_path: root_path}) do
    env
    |> Map.take(~w(aliases context context_modules file function line module)a)
    |> Map.update!(:file, &String.replace_leading(&1, root_path <> "/", ""))
  end

  defp encode(trace) do
    inspect(trace,
      limit: :infinity,
      printable_limit: :infinity,
      width: 1_000_000_000
    )
  end
end
