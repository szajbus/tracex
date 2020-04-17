defmodule Tracex.Tracer do
  def trace(event, env) do
    Tracex.Collector.log_trace(event, env)
    :ok
  end
end
