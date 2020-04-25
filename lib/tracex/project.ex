defmodule Tracex.Project do
  defstruct root_path: nil,
            source_files: [],
            modules: %{}

  defmodule Module do
    defstruct name: nil, file: nil, tags: []
  end

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

  def module_file(project, module) do
    project
    |> get_in([Access.key(:modules), module, Access.key(:file)])
  end

  def add_module(%__MODULE__{} = project, {module, file}) do
    project
    |> put_in([Access.key(:modules), module], %Module{name: module, file: file})
  end

  def tag_module(%__MODULE__{} = project, module, tag) do
    project
    |> update_in([Access.key(:modules), module, Access.key(:tags)], &[tag | &1])
  end
end
