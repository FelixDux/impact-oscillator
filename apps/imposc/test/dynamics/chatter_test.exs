defmodule ChatterTest do
  use ExUnit.Case

  alias Chatter

  @moduletag :capture_log

  doctest Chatter

  test "module exists" do
    assert is_list(Chatter.module_info())
  end

  test "accumulation_state error conditions with r" do
    for r <- [1.2, 1, 0, -0.4],
        do:
          (fn ->
             parameters = %SystemParameters{omega: 2, sigma: 0, r: r}
             assert {:ok, period} = ForcingPhase.forcing_period(parameters.omega)
             state = %StateOfMotion{t: period / 2, x: parameters.sigma, v: 1}

             assert {:error, _} = Chatter.accumulation_state(state, parameters)
           end).()
  end

  test "accumulation_state error conditions with g" do
    parameters = %SystemParameters{omega: 2, sigma: 0, r: 0.5}
    assert {:ok, period} = ForcingPhase.forcing_period(parameters.omega)
    state = %StateOfMotion{t: period / 2, x: parameters.sigma, v: 1}

    assert {:error, _} = Chatter.accumulation_state(state, parameters)
  end

  test "accumulation_state valid" do
    parameters = %SystemParameters{omega: 2, sigma: 0, r: 0.5}
    state = %StateOfMotion{t: 0, x: parameters.sigma, v: -0.0001}

    assert {:ok, new_state} = Chatter.accumulation_state(state, parameters)

    assert new_state.t > state.t
    assert new_state.v == 0
    assert new_state.x == parameters.sigma
  end

  test "count_low_v below threshold low v" do
    counter = Chatter.const_low_v_count_threshold() - 1
    v = 0.0001

    f = Chatter.count_low_v(counter)

    assert {false, g} = f.(v)

    assert {true, _} = g.(v)
  end

  test "count_low_v high v" do
    counter = Chatter.const_low_v_count_threshold() - 1
    v = 100

    f = Chatter.count_low_v(counter)

    assert {false, _} = f.(v)
  end

  test "count_low_v zero v" do
    counter = Chatter.const_low_v_count_threshold() - 1
    v = 0

    f = Chatter.count_low_v(counter)

    assert {false, _} = f.(v)
  end
end
