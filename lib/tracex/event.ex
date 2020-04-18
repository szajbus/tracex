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
end
