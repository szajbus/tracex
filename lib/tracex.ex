defmodule Tracex do
  @moduledoc """
  Tracex is a tool for static analysis of mix projects

  It builds upon compiler tracing introduced in Elixir 1.10, simplifying collection of traces and turning them into valuable insights.

  Tracex collects traces emitted by Elixir compiler and performs some basic data extraction and classification. The result, together with project's metadata built along the way, is available to the developer for further analysis.

  Tracex automatically recognizes some common types of modules present in mix projects, like Ecto schemas or Phoenix controllers and views. Additionally it supports attaching custom classifiers that are specific to your project in order to collect extra information that may prove helpful in actual analysis.

  Elixir compiler emits a lot of traces. For practical reasons tracex collets only ones that are local to your project. It means that any traces of interactions of your project's code with Elixir's core modules or external libraries are discarded.
  """

  alias Tracex.Collector
  alias Tracex.Insights
  alias Tracex.Project
  alias Tracex.Trace
  alias Tracex.Tracer

  @app :tracex
  @manifest_vsn 0.1

  @doc """
  Compile a project and collect compiler traces for later analysis

  Project's metadata is built along the way and written to disk together with
  collected traces in manifest file. This enables the developer to load it into iex
  console and play with it.

  ## Options

    * `manifest_path` - path to manifest file,
      defaults to `_build/{Mix.env}/lib/tracex/.mix/tracex`
    * `custom_classifiers` - list of project-specific classifier modules
  """
  @spec compile_project(list) :: {Project.t(), list(Trace.t())}
  def compile_project(opts \\ []) do
    project = Project.build_from_mix_project()

    path = Keyword.get(opts, :manifest_path) || manifest_path()
    classifiers = [Tracex.Classifier | Keyword.get(opts, :custom_classifiers, [])]

    start_collector(project, [], classifiers)

    Mix.Task.clear()
    Mix.Task.run("compile", ["--force", "--tracer", Tracer])

    {project, traces} = Collector.finalize()
    Collector.stop()

    write_manifest({project, traces}, path)

    {project, traces}
  end

  @doc """
  Returns module insights
  """
  @spec insights(list(Trace.t()), atom | list(atom)) :: map
  def insights(traces, module) do
    Insights.module(traces, module)
  end

  @doc """
  Loads tracex manifest file from disk

  Useful for analysis done in iex console.
  """
  @spec load_from_manifest(binary) :: {Project.t(), list(Trace.t())}
  def load_from_manifest(path \\ manifest_path()) do
    read_manifest(path)
  end

  defp start_collector(project, traces, classifiers) do
    Collector.stop()
    {:ok, _} = Collector.start_link(project, traces, classifiers)
  end

  defp manifest_path do
    path = Mix.Project.manifest_path(app: @app, build_per_environment: true)
    Path.join(path, "tracex")
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
