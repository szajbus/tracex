defmodule Tracex.Event do
  def get_module({:import, _, module, _}), do: module
  def get_module({:imported_function, _, module, _, _}), do: module
  def get_module({:imported_macro, _, module, _, _}), do: module
  def get_module({:alias, _, module, _, _}), do: module
  def get_module({:alias_expansion, _, _, module}), do: module
  def get_module({:alias_reference, _, module}), do: module
  def get_module({:struct_expansion, _, module, _}), do: module
  def get_module({:remote_function, _, module, _, _}), do: module
  def get_module({:remote_macro, _, module, _, _}), do: module
  def get_module(_), do: nil

  def get_func_and_arity({:remote_function, _, _, name, arity}), do: "#{name}/#{arity}"
  def get_func_and_arity({:remote_macro, _, _, name, arity}), do: "#{name}/#{arity}"
  def get_func_and_arity(_), do: nil

  def module_definition?({:defmodule, _}), do: true
  def module_definition?(_), do: false

  def ecto_schema_definition?({:remote_macro, _, Ecto.Schema, :__using__, 1}), do: true
  def ecto_schema_definition?(_), do: false
end
