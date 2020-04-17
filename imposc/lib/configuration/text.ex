defmodule GreekLetters do
  @moduledoc """
  Unicode Greek letters
  """

  @doc """
  Unicode Greek letter sigma
  """

  defmacro const_sigma do
    quote do: List.to_string([<<207_131::utf8>>])
  end

  @doc """
  Unicode Greek letter omega
  """

  defmacro const_omega do
    quote do: List.to_string([<<207_137::utf8>>])
  end
end
