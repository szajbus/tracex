defmodule Tracex.Classifier do
  @moduledoc """
  Default classifier that generates annotations for common modules,
  that are being picked up by the collector.

  The following annotations are currently supported:

    * `{:track, module, file}` - tracks module definition in given source file
      and enables trace collection for that module (collector does not collect
      traces for untracked modules)
    * `{:tag, module, tag}` - adds `tag` to module's tags
    * `{:extra, module, key, value}` - adds key/value pair to module's extra
      attributes

  Consult README for information about providing custom classifiers for
  your project.
  """

  alias Tracex.Trace

  @doc """
  Sets up tracking and generates module annotations for module types
  common among mix projects, (e.g. ecto schemas, phoenix controllers, views
  routers and channels).
  """
  @spec classify(Trace.t()) ::
          nil
          | {:tag, atom, atom}
          | {:track, atom, binary}
  def classify({_, env} = trace) do
    cond do
      Trace.module_definition?(trace) ->
        {:track, Trace.outbound_module(trace), env.file}

      Trace.macro_usage?(trace, Ecto.Repo) ->
        {:tag, Trace.outbound_module(trace), :ecto_repo}

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
