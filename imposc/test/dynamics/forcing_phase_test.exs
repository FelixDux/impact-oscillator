defmodule ForcingPhaseTest do
  use ExUnit.Case
  doctest ForcingPhase

  test "phi is modulo" do
    assert ForcingPhase.phi(3, :math.pi(), false) == 1

    for t <- 0..100, do: assert(ForcingPhase.phi(t, 2.8) >= 0)
  end

  test "gamma(0) is 1" do
    assert ForcingPhase.gamma(0) == 1
  end

  test "frac_part(n + z) is z (n integer, 0<z<1)" do
    for x <- [{3, 0.123}],
        do: assert(abs(ForcingPhase.frac_part(elem(x, 0) + elem(x, 1)) - elem(x, 1)) < 0.000001)
  end

  test "modulo(x, 0) is x" do
    for x <- [7.3, 4, -2.5], do: assert(ForcingPhase.modulo(x, 0) == x)
  end

  test "modulo(n*x+k, x) is k" do
    for y <- [{3, -4.2, 2}, {3, 3.141, 2}],
        do:
          assert(
            abs(
              ForcingPhase.modulo(elem(y, 0) * elem(y, 1) + elem(y, 2), elem(y, 1)) - elem(y, 2)
            ) < 0.0000001
          )
  end

  test "gamma(1) is 1" do
    assert ForcingPhase.gamma(1) == 1
  end

  test "forcing_period error cases" do
    for omega <- [-3.7, 0], do: assert(elem(ForcingPhase.forcing_period(omega), 0) == :error)
  end

  test "forcing_period valid cases" do
    for omega <- [:math.pi(), 2],
        do:
          assert(elem(ForcingPhase.forcing_period(omega), 0) == :ok) &&
            assert(
              abs(elem(ForcingPhase.forcing_period(omega), 1) - 2 * :math.pi() / omega) < 0.0001
            )
  end

  test "forward_to_phase" do
    omega = 2.7

    {_, period} = ForcingPhase.forcing_period(omega)

    for {n, phi, diff} <- [{21, 0.25, 0.001}, {-2,  1 / 4.0, 0.15}],
        do:
          assert(
            abs(
              ForcingPhase.forward_to_phase((n + phi) * period - diff, phi, period) -
                (n + phi) * period
            ) < 0.000001
          )
  end
end
