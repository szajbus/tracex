defmodule Tracex.Project do
  @moduledoc """
  Wrapper for project metadata

  Keeps information about project's source files and defined modules.

  Project modules can be tagged or have extra attributes assigned.
  """

  @type t :: %__MODULE__{}
  @type project_module :: __MODULE__.Module.t()

  defstruct root_path: nil,
            source_files: [],
            modules: %{}

  defmodule Module do
    defstruct name: nil, file: nil, tags: [], extra: %{}

    @type t :: %__MODULE__{}
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
  Returns the list of modules tracked for project, optionally filtered

  ## Options:

    * `tags` - list of tags to filter modules by (at least one tag must match)
  """
  @spec get_modules(t, list(atom)) :: list(project_module)
  def get_modules(project, filters \\ []) when is_list(filters) do
    modules = Map.values(project.modules)

    case Keyword.get(filters, :tags, []) do
      [] ->
        modules

      tags ->
        Enum.filter(modules, fn module ->
          Enum.any?(tags, &(&1 in module.tags))
        end)
    end
  end

  @doc """
  Returns project module
  """
  @spec get_module(t, atom) :: project_module
  def get_module(project, module), do: Map.get(project.modules, module)

  @doc """
  Returns a path to a file in which a module is defined
  """
  @spec get_module_file(t, atom) :: binary
  def get_module_file(project, module) do
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
