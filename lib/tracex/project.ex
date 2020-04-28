defmodule Tracex.Project do
  @moduledoc """
  Wrapper for project metadata

  Keeps information about project's source files and defined modules.

  Project modules can be tagged or have extra attributes assigned.
  """

  @type t :: %__MODULE__{}

  defstruct root_path: nil,
            source_files: [],
            modules: %{}

  defmodule Module do
    defstruct name: nil, file: nil, tags: [], extra: %{}
  end

  @doc """
  Builds project struct from mix config
  """
  @spec build_from_mix_project(keyword) :: t
  def build_from_mix_project(config \\ Mix.Project.config()) do
    srcs =
      config
      |> Keyword.take([:elixirc_paths, :apps_path])
      |> Keyword.values()
      |> Enum.map(&List.wrap/1)
      |> Enum.concat()

    source_files = Mix.Utils.extract_files(srcs, [:ex])

    %__MODULE__{root_path: File.cwd!(), source_files: source_files}
  end

  @doc """
  Returns a path to a file in which a module is defined
  """
  @spec module_file(t, atom) :: binary
  def module_file(project, module) do
    project
    |> get_in([Access.key(:modules), module, Access.key(:file)])
  end

  @doc """
  Add module to the project
  """
  @spec add_module(t, {atom, binary}) :: t
  def add_module(%__MODULE__{} = project, {module, file}) do
    project
    |> put_in([Access.key(:modules), module], %Module{name: module, file: file})
  end

  @doc """
  Tag a module
  """
  @spec tag_module(t, atom, atom) :: t
  def tag_module(%__MODULE__{} = project, module, tag) do
    project
    |> update_in([Access.key(:modules), module, Access.key(:tags)], &([tag | &1] |> Enum.uniq()))
  end

  @doc """
  Add an extra attribute to a module
  """
  @spec add_extra(t, atom, atom, any) :: t
  def add_extra(%__MODULE__{} = project, module, key, val) do
    project
    |> put_in([Access.key(:modules), module, Access.key(:extra), key], val)
  end
end
