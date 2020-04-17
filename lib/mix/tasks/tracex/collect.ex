require Logger

defmodule Mix.Tasks.Tracex.Collect do
  use Mix.Task

  @tracer_module Tracex.Tracer

  @impl Mix.Task
  def run(_) do
    project = Mix.Project.config()

    srcs =
      project
      |> Keyword.take([:elixirc_paths, :apps_path])
      |> Keyword.values()
      |> Enum.map(&List.wrap/1)
      |> Enum.concat()

    source_files = Mix.Utils.extract_files(srcs, [:ex])

    {:ok, _} = Tracex.Collector.start_link(cwd: File.cwd!(), source_files: source_files)

    Mix.Task.clear()
    Mix.Task.run("compile", ["--force", "--tracer", @tracer_module])

    Logger.debug("Dumping compiler traces to file.")
    Tracex.Collector.dump_to_file("compiler_traces.log")

    :ok
  end
end
