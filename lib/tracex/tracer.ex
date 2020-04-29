defmodule Tracex.Tracer do
  @moduledoc false

  @spec trace(tuple, Macro.Env.t()) :: :ok
  def trace(event, env) do
    Tracex.Collector.process({event, env})
    :ok
  end
end
