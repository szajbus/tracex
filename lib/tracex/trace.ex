defmodule Tracex.Trace do
  alias Tracex.Event

  def inbound?({event, _env}, module) do
    case event do
      {:local_function, _, _, _} -> false
      {:local_macro, _, _, _} -> false
      _ -> Event.get_module(event) == module
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
