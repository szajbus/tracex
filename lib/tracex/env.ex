defmodule Tracex.Env do
  def get_location(%{file: file, line: line}) do
    "#{file}:#{line}"
  end
end
