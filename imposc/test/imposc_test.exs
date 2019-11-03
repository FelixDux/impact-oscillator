defmodule ImposcTest do
  use ExUnit.Case
  doctest Imposc

  test "greets the world" do
    assert Imposc.hello() == :world
  end

  test "phi is modulo" do
    assert Imposc.phi(3, :math.pi) == 1
  end

  test "gamma(0) is 1" do
    assert Imposc.gamma(0) == 1
  end

  test "modulo(x, 0) is x" do
    for x <- [7.3, 4, -2.5], do: assert Imposc.modulo(x, 0) == x
  end

  test "gamma(1) is 1" do
    assert Imposc.gamma(1) == 1
  end
end
