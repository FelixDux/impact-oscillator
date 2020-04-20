defmodule MotionBetweenImpactsTest do
  use ExUnit.Case

  alias MotionBetweenImpacts

  @moduletag :capture_log

  doctest MotionBetweenImpacts

  test "module exists" do
    assert is_list(MotionBetweenImpacts.module_info())
  end

  test "motion_at_time is periodic in time (for rational omega)" do
    system_parameters = %SystemParameters{omega: 2, r: 0.8, sigma: 0}

    period = 2 * :math.pi()

    for n <- 1..5,
        do:
          for(
            point <- [
              %ImpactPoint{phi: 0, t: 0, v: 0},
              %ImpactPoint{phi: period / 5, t: period / 5 + 6 * period, v: 10},
              %ImpactPoint{phi: period / 4, t: period / 4 - 3 * period, v: -3}
            ],
            do:
              elem(EvolutionCoefficients.derive(system_parameters, point), 1)
              |> (fn coeffs ->
                    (period * n + point.t)
                    |> (fn t ->
                          MotionBetweenImpacts.motion_at_time(t, point, coeffs)
                          |> (fn state ->
                                assert state.t == t &&
                                         assert(
                                           abs(state.v + system_parameters.r * point.v) < 0.000001 &&
                                             assert(
                                               abs(state.x - system_parameters.sigma) < 0.000001
                                             )
                                         )
                              end).()
                        end).()
                  end).()
          )
  end

  # next_impact

  test "new_step_size" do
    step_size = 0.01

    sigma = 1

    assert MotionBetweenImpacts.new_step_size(step_size, 1.75 * step_size, sigma - 0.1, sigma) ==
             step_size

    assert MotionBetweenImpacts.new_step_size(step_size, 1.75 * step_size, sigma + 0.1, sigma) ==
             -0.5 * step_size
  end

  # iterate_impacts
end
