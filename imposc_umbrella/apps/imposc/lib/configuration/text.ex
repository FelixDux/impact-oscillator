defmodule GreekLetters do
  @moduledoc """
  Unicode Greek letters
  """

  @doc """
  Unicode Greek letter sigma
  """

  @const_sigma List.to_string([<<207_131::utf8>>])

  def const_sigma, do: @const_sigma

  @doc """
  Unicode Greek letter omega
  """

  @const_omega List.to_string([<<207_137::utf8>>])

  def const_omega, do: @const_omega
end
