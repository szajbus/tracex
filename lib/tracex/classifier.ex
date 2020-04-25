defmodule Tracex.Classifier do
  alias Tracex.Trace

  def classify({_, env} = trace) do
    cond do
      Trace.module_definition?(trace) ->
        {:track, Trace.outbound_module(trace), env.file}

      Trace.macro_usage?(trace, Ecto.Schema) ->
        {:tag, Trace.outbound_module(trace), :ecto_schema}

      Trace.macro_usage?(trace, Phoenix.Controller) ->
        {:tag, Trace.outbound_module(trace), :phoenix_controller}

      Trace.macro_usage?(trace, Phoenix.Channel) ->
        {:tag, Trace.outbound_module(trace), :phoenix_channel}

      Trace.macro_usage?(trace, Phoenix.View) ->
        {:tag, Trace.outbound_module(trace), :phoenix_view}

      Trace.macro_usage?(trace, Phoenix.Router) ->
        {:tag, Trace.outbound_module(trace), :phoenix_router}

      true ->
        nil
    end
  end
end
