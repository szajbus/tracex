defmodule Tracex.Trace do
  @moduledoc """
  Collection of helpers to extract data from compiler traces

  Compiler traces encapsulate events happening in certain environment.

  The module originating an event is considered an *outbound* module,
  the module on the receiving end is considered an *inbound* module.

  For example, consider a trace emitted when module `A` imports a function
  from module `B`. `A` is denoted as outbound and `B` as inbound.

  Traces of local function or marco calls naturally have the same module as
  both inbound and outbound.

  Note that inbound/outbound notions translate directly to direction of
  the edge between the two modules involved in project's module dependency graph.
  """

  @type t :: {tuple, Macro.Env.t()}

  @doc """
  Returns trace's inbound module
  """
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

  @doc """
  Returns trace's outbound module
  """
  @spec outbound_module(t) :: atom
  def outbound_module({_, env}), do: env.module

  @doc """
  Returns true if trace describes a remote function or macro call
  """
  @spec remote_call?(t) :: boolean
  def remote_call?({event, _env}) do
    elem(event, 0) in [:remote_function, :remote_macro]
  end

  @doc """
  Returns function name and arity formatted as `function/arity` for remote call traces
  """
  @spec event_func_and_arity(t) :: binary
  def event_func_and_arity({event, _env}) do
    case event do
      {:remote_function, _, _, name, arity} -> "#{name}/#{arity}"
      {:remote_macro, _, _, name, arity} -> "#{name}/#{arity}"
      _ -> "cannot extract func and arity from event #{inspect(event)}"
    end
  end

  @doc """
  Returns location in code where a trace originates formatted as `path:line`

  Elixir compiler does not always provide a precise line number of the code in question,
  but rather the line of where its execution environment is defined.

  For example if an event originates in function's body, a line in which the function
  is defined is returned.
  """
  @spec call_location(t) :: binary
  def call_location({event, env}) do
    meta = elem(event, 1)
    line = Keyword.get(meta, :line, env.line)

    "#{env.file}:#{line}"
  end

  @doc """
  Returns true if trace describes a module definition
  """
  @spec module_definition?(t) :: boolean
  def module_definition?({event, _env}) do
    case event do
      {:defmodule, _} -> true
      _ -> false
    end
  end

  @doc """
  Returns true if trace describes using given module via `use GivenModule`
  """
  @spec macro_usage?(t, atom) :: boolean
  def macro_usage?({event, _env}, module) do
    case event do
      {:remote_macro, _, ^module, :__using__, 1} -> true
      _ -> false
    end
  end

  @doc """
  Returns true if given `module` is on the receiving end of the traced event
  """
  @spec inbound?(t, atom) :: boolean
  def inbound?({event, _} = trace, module) do
    case event do
      {:local_function, _, _, _} -> false
      {:local_macro, _, _, _} -> false
      _ -> inbound_module(trace) == module
    end
  end

  @doc """
  Returns true if given `module` is originating the traced event
  """
  @spec outbound?(t, atom) :: boolean
  def outbound?({event, _} = trace, module) do
    case event do
      {:local_function, _, _, _} -> false
      {:local_macro, _, _, _} -> false
      _ -> outbound_module(trace) == module
    end
  end
end
