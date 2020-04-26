defmodule Tracex do
  alias Tracex.Collector
  alias Tracex.Insights
  alias Tracex.Project
  alias Tracex.Tracer

  @app :tracex
  @manifest_vsn 1

  def compile_project(opts \\ []) do
    project = Project.build_from_mix_project()

    path = opts[:path] || manifest_path()
    classifiers = [Tracex.Classifier | opts[:extra_classifiers]]

    start_collector(project, [], classifiers)

    Mix.Task.clear()
    Mix.Task.run("compile", ["--force", "--tracer", Tracer])

    {project, traces} = Collector.finalize()
    Collector.stop()

    write_manifest({project, traces}, path)

    {project, traces}
  end

  def insights(traces, module) do
    Insights.module(traces, module)
  end

  def load_from_manifest(path \\ manifest_path()) do
    read_manifest(path)
  end

  defp start_collector(project, traces, classifiers) do
    Collector.stop()
    {:ok, _} = Collector.start_link(project, traces, classifiers)
  end

  defp manifest_path do
    path = Mix.Project.manifest_path(app: @app, build_per_environment: true)
    Path.join(path, "tracex.collect")
  end

  defp write_manifest({project, traces}, path) do
    data =
      {@manifest_vsn, project, traces}
      |> :erlang.term_to_binary()

    File.write!(path, data)
  end

  defp read_manifest(path) do
    manifest = path |> File.read!() |> :erlang.binary_to_term()

    case manifest do
      {@manifest_vsn, project, traces} ->
        {project, traces}

      {vsn, project, traces} ->
        raise "Loaded manifest is in version #{vsn}, " <>
                "current version is #{@manifest_vsn}. Please recompile."

        {project, traces}

      _ ->
        raise "Cannot parse manifest file, please recompile."
    end
  end
end
