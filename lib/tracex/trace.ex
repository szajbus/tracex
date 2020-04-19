defmodule Tracex.Trace do
  def event_module({event, _env}) do
    case event do
      {:import, _, module, _} -> module
      {:imported_function, _, module, _, _} -> module
      {:imported_macro, _, module, _, _} -> module
      {:alias, _, module, _, _} -> module
      {:alias_expansion, _, _, module} -> module
      {:alias_reference, _, module} -> module
      {:struct_expansion, _, module, _} -> module
      {:remote_function, _, module, _, _} -> module
      {:remote_macro, _, module, _, _} -> module
      _ -> nil
    end
  end

  def event_func_and_arity({event, _env}) do
    case event do
      {:remote_function, _, _, name, arity} -> "#{name}/#{arity}"
      {:remote_macro, _, _, name, arity} -> "#{name}/#{arity}"
      _ -> nil
    end
  end

  def call_location({_event, env}) do
    "#{env.file}:#{env.line}"
  end

  def module_definition?({event, _env}) do
    case event do
      {:defmodule, _} -> true
      _ -> false
    end
  end

  def macro_usage?({event, _env}, module) do
    case event do
      {:remote_macro, _, ^module, :__using__, 1} -> true
      _ -> false
    end
  end

  def inbound?({event, env}, module) do
    case event do
      {:local_function, _, _, _} -> false
      {:local_macro, _, _, _} -> false
      _ -> event_module({event, env}) == module
    end
  end

  def outbound?({event, env}, module) do
    case event do
      {:local_function, _, _, _} -> false
      {:local_macro, _, _, _} -> false
      _ -> env.module == module
    end
  end
end
