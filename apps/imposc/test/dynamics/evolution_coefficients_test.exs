defmodule EvolutionCoefficientsTest do
  use ExUnit.Case

  alias EvolutionCoefficients

  @moduletag :capture_log

  doctest EvolutionCoefficients

  test "module exists" do
    assert is_list(EvolutionCoefficients.module_info())
  end

  test "Derive from valid inputs" do
    parameters = %SystemParameters{omega: 3, r: 0.5, sigma: 0}

    elem(ForcingPhase.forcing_period(parameters.omega), 1)
    |> (fn period ->
          for params <- [
                [phi: 0, v: 1, gamma: -0.125, cos_coeff: 0.125, sin_coeff: -0.5],
                [phi: period / 4, v: 1, gamma: -0.125, cos_coeff: 0, sin_coeff: -0.875]
              ],
              do:
                %ImpactPoint{phi: params[:phi], t: params[:phi], v: params[:v]}
                |> (fn point ->
                      EvolutionCoefficients.derive(parameters, point)
                      |> (fn result ->
                            assert elem(result, 0) == :ok
                            assert abs(elem(result, 1).gamma - params[:gamma]) < 0.00001
                            assert abs(elem(result, 1).cos_coeff - params[:cos_coeff]) < 0.00001
                            assert abs(elem(result, 1).sin_coeff - params[:sin_coeff]) < 0.00001
                            assert abs(elem(result, 1).sticking_region.period - period) < 0.00001
                          end).()
                    end).()
        end).()
  end
end
