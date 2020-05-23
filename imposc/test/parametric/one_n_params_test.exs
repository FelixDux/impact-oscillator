defmodule OneNParamsTest do
  use ExUnit.Case

  alias OneNParams

  @moduletag :capture_log

  doctest OneNParams

  test "module exists" do
    assert is_list(OneNParams.module_info())
  end

  test "derive error cases - omega" do
    for omega <- [-3.7, 0], do: assert(elem(OneNParams.derive(omega, 0.8, 1), 0) == :error)
  end

  test "derive error cases - n" do
    for n <- [-3, 0, 1.8], do: assert(elem(OneNParams.derive(5.2, 0.8, n), 0) == :error)
  end

  test "derive error cases - r" do
    for r <- [-3.7, 1, 3.2], do: assert(elem(OneNParams.derive(4.6, r, 1), 0) == :error)
  end

  test "velocities for valid parameters" do
    assert {:ok, params} = OneNParams.derive(3.7, 0.8, 2)

    assert {v0, nil} = OneNParams.velocities(0, params)

    assert v0 > 0

    assert {v_plus_u, v_plus_l} = OneNParams.velocities(0.2, params)

    assert v_plus_u > 0

    assert v_plus_l > 0

    assert {nil, nil} = OneNParams.velocities(-0.06, params)

    assert {nil, nil} = OneNParams.velocities(0.4, params)
  end

  test "Orbits for valid parameters" do
    for n <- 1..10,
        do:
          (fn ->
             sys_params = %SystemParameters{omega: 2 * n, r: 0.4, sigma: 0.001}

             assert {:ok, params} = OneNParams.derive(sys_params.omega, sys_params.r, n)

             assert [point, nil] = OneNParams.orbits(sys_params.sigma, params)

             assert !is_nil(point)

             assert {new_point, _, _} = MotionBetweenImpacts.next_impact(point, sys_params)

             assert abs(point.phi - new_point.phi) < 0.00001

             assert abs(point.v - new_point.v) < 0.00001

             assert abs(new_point.t - (point.t + 2 * :math.pi() * n / sys_params.omega)) < 0.00001
           end).()
  end
end
