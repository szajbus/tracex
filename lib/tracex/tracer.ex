defmodule Tracex.Tracer do
  def trace(event, env) do
    Tracex.Collector.process({event, env})
    :ok
  end
end
