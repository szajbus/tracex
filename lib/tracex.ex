defmodule Tracex do
  alias Tracex.Collector
  alias Tracex.Project
  alias Tracex.Tracer

  def compile_project do
    start_collector()

    Mix.Task.clear()
    Mix.Task.run("compile", ["--force", "--tracer", Tracer])

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

    traces()
    |> Stream.map(&encode/1)
    |> Stream.intersperse("\n")
    |> Stream.into(file)
    |> Stream.run()
  end

  def load_from_file(path) do
    start_collector()

    path
    |> stream_from_file()
    |> Stream.each(fn {event, env} -> Collector.process(event, env) end)
    |> Stream.run()
  end

  def stream_from_file(path) do
    path
    |> File.stream!()
    |> Stream.map(&decode/1)
  end

  defp encode(trace) do
    inspect(trace,
      limit: :infinity,
      printable_limit: :infinity,
      width: 1_000_000_000
    )
  end

  defp decode(line) do
    {trace, _binding} = Code.eval_string(line)
    trace
  end

  defp start_collector do
    project = Project.build()
    {:ok, _} = Collector.start_link(project)
  end
end
