defmodule Tracex.Project do
  defstruct root_path: nil,
            source_files: [],
            module_files: %{},
            modules: [],
            ecto_schemas: [],
            phoenix_controllers: [],
            phoenix_channels: [],
            phoenix_views: [],
            phoenix_routers: []

  @module_lists [
    :ecto_schemas,
    :phoenix_controllers,
    :phoenix_channels,
    :phoenix_views,
    :phoenix_routers
  ]

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
    project
    |> Map.update!(:module_files, &Map.put(&1, module, file))
    |> Map.update!(:modules, &[module | &1])
  end

  def add_module_in(%__MODULE__{} = project, key, module) when key in @module_lists do
    project
    |> Map.update!(key, &[module | &1])
  end
end
