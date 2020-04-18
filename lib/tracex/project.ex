defmodule Tracex.Project do
  defstruct root_path: nil,
            source_files: [],
            modules: [],
            ecto_schemas: []

  def build() do
    mix_project = Mix.Project.config()

    srcs =
      mix_project
      |> Keyword.take([:elixirc_paths, :apps_path])
      |> Keyword.values()
      |> Enum.map(&List.wrap/1)
      |> Enum.concat()

    source_files = Mix.Utils.extract_files(srcs, [:ex])

    %__MODULE__{root_path: File.cwd!(), source_files: source_files}
  end

  def add_module(%__MODULE__{} = project, module) do
    Map.update!(project, :modules, &[module | &1])
  end

  def add_ecto_schema(%__MODULE__{} = project, module) do
    Map.update!(project, :ecto_schemas, &[module | &1])
  end
end
