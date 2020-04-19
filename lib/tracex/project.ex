defmodule Tracex.Project do
  defstruct root_path: nil,
            source_files: [],
            modules: %{},
            ecto_schemas: %{}

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

  def add_module(%__MODULE__{} = project, {module, file}) do
    Map.update!(project, :modules, &Map.put(&1, module, file))
  end

  def add_ecto_schema(%__MODULE__{} = project, {module, file}) do
    Map.update!(project, :ecto_schemas, &Map.put(&1, module, file))
  end
end
