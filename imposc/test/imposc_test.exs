defmodule ImposcTest do
  use ExUnit.Case
  doctest ImposcUtils

  test "phi is modulo" do
    assert ImposcUtils.phi(3, :math.pi) == 1

    for t <- 0..100, do: assert ImposcUtils.phi(t, 2.8) >= 0
  end

  test "gamma(0) is 1" do
    assert ImposcUtils.gamma(0) == 1
  end

  test "modulo(x, 0) is x" do
    for x <- [7.3, 4, -2.5], do: assert ImposcUtils.modulo(x, 0) == x
  end

  test "gamma(1) is 1" do
    assert ImposcUtils.gamma(1) == 1
  end
end

defmodule ImpactPointTest do
  use ExUnit.Case
  doctest ImpactPoint

  test "impact point maps to list" do
    assert ImpactPoint.point_to_list(%ImpactPoint{phi: 1.6, v: 0.7}) == [1.6, 0.7]
  end
end
