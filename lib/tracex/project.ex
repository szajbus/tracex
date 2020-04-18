defmodule Tracex.Project do
  defstruct root_path: nil,
            source_files: [],
            modules: [],
            ecto_schemas: []

  def add_module(%__MODULE__{} = project, module) do
    Map.update!(project, :modules, &[module | &1])
  end

  def add_ecto_schema(%__MODULE__{} = project, module) do
    Map.update!(project, :ecto_schemas, &[module | &1])
  end
end
