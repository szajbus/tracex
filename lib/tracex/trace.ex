defmodule Tracex.Trace do
  @type t :: {tuple, Macro.Env.t()}

  @spec inbound_module(t) :: atom
  def inbound_module({event, env}) do
    case event do
      {:import, _, module, _} -> module
      {:imported_function, _, module, _, _} -> module
      {:imported_macro, _, module, _, _} -> module
      {:alias, _, module, _, _} -> module
      {:alias_expansion, _, _, module} -> module
      {:alias_reference, _, module} -> module
      {:require, _, module, _} -> module
      {:struct_expansion, _, module, _} -> module
      {:remote_function, _, module, _, _} -> module
      {:remote_macro, _, module, _, _} -> module
      {:local_function, _, _, _} -> env.module
      {:local_macro, _, _, _} -> env.module
      _ -> raise "cannot extract module from event: #{inspect(event)}"
    end
  end

  @spec outbound_module(t) :: atom
  def outbound_module({_, env}), do: env.module

  @spec remote_call?(t) :: boolean
  def remote_call?({event, _env}) do
    elem(event, 0) in [:remote_function, :remote_macro]
  end

  @spec event_func_and_arity(t) :: binary
  def event_func_and_arity({event, _env}) do
    case event do
      {:remote_function, _, _, name, arity} -> "#{name}/#{arity}"
      {:remote_macro, _, _, name, arity} -> "#{name}/#{arity}"
      _ -> "cannot extract func and arity from event #{inspect(event)}"
    end
  end

  @spec call_location(t) :: binary
  def call_location({event, env}) do
    meta = elem(event, 1)
    line = Keyword.get(meta, :line, env.line)

    "#{env.file}:#{line}"
  end

  @spec module_definition?(t) :: boolean
  def module_definition?({event, _env}) do
    case event do
      {:defmodule, _} -> true
      _ -> false
    end
  end

  @spec macro_usage?(t, atom) :: boolean
  def macro_usage?({event, _env}, module) do
    case event do
      {:remote_macro, _, ^module, :__using__, 1} -> true
      _ -> false
    end
  end

  @spec inbound?(t, atom) :: boolean
  def inbound?({event, _} = trace, module) do
    case event do
      {:local_function, _, _, _} -> false
      {:local_macro, _, _, _} -> false
      _ -> inbound_module(trace) == module
    end
  end

  @spec outbound?(t, atom) :: boolean
  def outbound?({event, _} = trace, module) do
    case event do
      {:local_function, _, _, _} -> false
      {:local_macro, _, _, _} -> false
      _ -> outbound_module(trace) == module
    end
  end
end
