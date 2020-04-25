defmodule Tracex.Classifier do
  alias Tracex.Trace

  def classify(trace) do
    cond do
      Trace.macro_usage?(trace, Ecto.Schema) ->
        {:tag, :ecto_schema}

      Trace.macro_usage?(trace, Phoenix.Controller) ->
        {:tag, :phoenix_controller}

      Trace.macro_usage?(trace, Phoenix.Channel) ->
        {:tag, :phoenix_channel}

      Trace.macro_usage?(trace, Phoenix.View) ->
        {:tag, :phoenix_view}

      Trace.macro_usage?(trace, Phoenix.Router) ->
        {:tag, :phoenix_router}

      true ->
        nil
    end
  end
end
