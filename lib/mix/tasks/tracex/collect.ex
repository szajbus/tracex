require Logger

defmodule Mix.Tasks.Tracex.Collect do
  use Mix.Task

  @tracer_module Tracex.Tracer

  @impl Mix.Task
  def run(_) do
    project = build_project()
    {:ok, _} = Tracex.Collector.start_link(project)

    Mix.Task.clear()
    Mix.Task.run("compile", ["--force", "--tracer", @tracer_module])

    IO.puts("Dumping compiler traces to file.")
    Tracex.Collector.dump_to_file("compiler_traces.log")

    :ok
  end

  defp build_project do
    mix_project = Mix.Project.config()

    srcs =
      mix_project
      |> Keyword.take([:elixirc_paths, :apps_path])
      |> Keyword.values()
      |> Enum.map(&List.wrap/1)
      |> Enum.concat()

    source_files = Mix.Utils.extract_files(srcs, [:ex])

    %Tracex.Project{root_path: File.cwd!(), source_files: source_files}
  end
end
