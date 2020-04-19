defmodule Tracex do
  alias Tracex.Collector
  alias Tracex.Project
  alias Tracex.Tracer

  def compile_project do
    start_collector()

    Mix.Task.clear()
    Mix.Task.run("compile", ["--force", "--tracer", Tracer])

    Collector.finalize()

    :ok
  end

  def project do
    Collector.get_project()
  end

  def traces do
    Collector.get_traces()
  end

  def dump_to_file(path) do
    file = File.stream!(path)

    [project() | traces()]
    |> Stream.map(&encode/1)
    |> Stream.intersperse("\n")
    |> Stream.into(file)
    |> Stream.run()
  end

  def load_from_file(path) do
    [project | traces] =
      path
      |> stream_from_file()
      |> Enum.to_list()

    start_collector(project, traces)
    Collector.finalize()

    :ok
  end

  def stream_from_file(path) do
    path
    |> File.stream!()
    |> Stream.map(&decode/1)
  end

  defp encode(term) do
    inspect(term,
      limit: :infinity,
      printable_limit: :infinity,
      width: 1_000_000_000
    )
  end

  defp decode(line) do
    {term, _binding} = Code.eval_string(line)
    term
  end

  defp start_collector(project \\ Project.build(), traces \\ []) do
    Collector.stop()
    {:ok, _} = Collector.start_link(project, traces)
  end
end
