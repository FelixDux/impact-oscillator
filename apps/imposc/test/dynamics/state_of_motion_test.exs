defmodule StateOfMotionTest do
  use ExUnit.Case

  alias StateOfMotion

  @moduletag :capture_log

  doctest StateOfMotion

  test "module exists" do
    assert is_list(StateOfMotion.module_info())
  end

  test "ImpactPoint from state" do
    omega = 2 * :math.pi()

    for state <- [
          %StateOfMotion{t: 37.5, v: 8.2},
          %StateOfMotion{t: 18.6, v: -0.42},
          %StateOfMotion{t: -37.5, v: 8.2}
        ],
        do:
          StateOfMotion.point_from_state(state, omega)
          |> (fn point ->
                assert(
                  state.t == point.t && state.v == point.v &&
                    abs(ForcingPhase.frac_part(abs(state.t)) - point.phi) < 0.000001
                )
              end).()
  end
end
