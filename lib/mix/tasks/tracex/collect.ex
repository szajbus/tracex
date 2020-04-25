defmodule Mix.Tasks.Tracex.Collect do
  use Mix.Task

  @opts [
    path: :string,
    classifier: [:string, :keep]
  ]

  @impl Mix.Task
  def run(argv) do
    {opts, _argv, _errors} = OptionParser.parse(argv, strict: @opts)

    path = Keyword.get(opts, :path, "compiler_traces.log")
    classifiers = Keyword.get_values(opts, :classifier) |> Enum.map(&load_module/1)

    {project, traces} = Tracex.compile_project(extra_classifiers: classifiers)
    Tracex.dump_to_file(project, traces, path)

    :ok
  end

  defp load_module(path) do
    with {:ok, data} <- File.read(path),
         {:ok, quoted} <- Code.string_to_quoted(data, file: path),
         {{:module, module, _, _}, _} <- Code.eval_quoted(quoted) do
      module
    else
      _ ->
        raise "Cannot load classifier module from `#{path}`."
    end
  end
end
