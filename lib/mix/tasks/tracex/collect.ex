defmodule Mix.Tasks.Tracex.Collect do
  use Mix.Task

  @opts [
    path: :string,
    classifier: [:string, :keep]
  ]

  @impl Mix.Task
  @spec run(list(binary)) :: :ok
  def run(argv) do
    {opts, _argv, _errors} = OptionParser.parse(argv, strict: @opts)

    classifiers = Keyword.get_values(opts, :classifier) |> Enum.map(&load_module/1)

    opts =
      opts
      |> Keyword.delete(:classifier)
      |> Keyword.put(:extra_classifiers, classifiers)

    Tracex.compile_project(opts)

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
