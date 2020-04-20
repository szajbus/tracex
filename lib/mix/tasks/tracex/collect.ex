defmodule Mix.Tasks.Tracex.Collect do
  use Mix.Task

  @default_opts [
    path: "compiler_traces.log"
  ]

  @impl Mix.Task
  def run(argv) do
    {opts, _argv, _errors} = OptionParser.parse(argv, strict: @default_opts)

    {project, traces} = Tracex.compile_project()
    Tracex.dump_to_file(project, traces, opts[:path])

    :ok
  end
end
