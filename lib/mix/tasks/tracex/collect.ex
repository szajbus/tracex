defmodule Mix.Tasks.Tracex.Collect do
  @moduledoc """
  Command-line interface to Tracex collector
  """

  use Mix.Task

  @opts [
    path: :string,
    classifier: [:string, :keep]
  ]

  @doc """
  Compiles project, collects compiler traces, builds project's metadata and dumps
  to disk in form of manifest file.

  ## Command line options

    * `manifest_path` - path to manifest file,
      defaults to `_build/{Mix.env}/lib/tracex/.mix/tracex.collect`
    * `classifier` - path to a file defining custom classifier module

  Multiple classifiers can be specified as:
    `mix tracex.collect --classifier one.ex --classifier two.ex`

  See `Tracex.Classifier` for information about writing custom classifiers.
  """
  @impl Mix.Task
  @spec run(list(binary)) :: :ok
  def run(argv) do
    {opts, _argv, _errors} = OptionParser.parse(argv, strict: @opts)

    classifiers = Keyword.get_values(opts, :classifier) |> Enum.map(&load_module/1)

    opts =
      opts
      |> Keyword.delete(:classifier)
      |> Keyword.put(:custom_classifiers, classifiers)

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
