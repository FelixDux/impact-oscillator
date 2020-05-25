defmodule StickingTest do
  use ExUnit.Case

  alias StickingRegion

  @moduletag :capture_log

  doctest StickingRegion

  test "module exists" do
    assert is_list(StickingRegion.module_info())
  end

  test "derive with bad omega" do
    for omega <- [0, -1.2],
        do:
          assert(
            {:error, reason} =
              StickingRegion.derive(%SystemParameters{omega: omega, sigma: 0, r: 0.5})
          )
  end

  test "derive no sticking region" do
    assert {:ok, region} = StickingRegion.derive(%SystemParameters{omega: 2.5, sigma: 2, r: 0.5})

    assert is_nil(region.phi_in)
    assert is_nil(region.phi_out)
  end

  test "derive sticking region is single point" do
    assert {:ok, region} = StickingRegion.derive(%SystemParameters{omega: 2.5, sigma: 1, r: 0.5})

    assert region.phi_in == region.phi_out
  end

  test "derive sticking region is sub-interval" do
    assert {:ok, region} =
             StickingRegion.derive(%SystemParameters{omega: 2.5, sigma: 0.4, r: 0.5})

    assert region.phi_in != region.phi_out
    assert region.phi_out != 0
    assert region.phi_in != region.period
  end

  test "derive sticking region is whole interval" do
    assert {:ok, region} =
             StickingRegion.derive(%SystemParameters{omega: 2.5, sigma: -1.4, r: 0.5})

    assert region.phi_out == 0
    assert region.phi_in == region.period
  end

  test "is_sticking?" do
    assert {:ok, region} = StickingRegion.derive(%SystemParameters{omega: 2, sigma: 0, r: 0.5})

    for phi <- [0, region.period], do: assert(StickingRegion.is_sticking?(phi, region))

    assert !StickingRegion.is_sticking?(0.5 * region.period, region)
  end

  test "is_sticking_impact?" do
    assert {:ok, region} = StickingRegion.derive(%SystemParameters{omega: 2, sigma: 0, r: 0.5})

    for phi <- [0, region.period],
        do:
          assert(StickingRegion.is_sticking_impact?(%ImpactPoint{phi: phi, t: phi, v: 0}, region))

    for phi <- [0, region.period],
        do:
          assert(
            !StickingRegion.is_sticking_impact?(%ImpactPoint{phi: phi, t: phi, v: 1}, region)
          )

    assert(
      false ==
        (0.5 * region.period)
        |> (&StickingRegion.is_sticking_impact?(%ImpactPoint{phi: &1, t: &1, v: 0}, region)).()
    )
  end

  test "next_impact_state" do
    sigma = 0
    omega = 2

    assert {:ok, region} =
             StickingRegion.derive(%SystemParameters{omega: omega, sigma: sigma, r: 0.5})

    for t <- [0, -10, 23],
        do:
          StickingRegion.next_impact_state(t, sigma, region)
          |> (fn state ->
                assert(state.v == 0) &&
                  assert(abs(ForcingPhase.phi(state.t, omega) - region.phi_out) < 0.00001)
              end).()
  end

  test "state_if_sticking" do
    sigma = 0.1
    omega = 4.2

    assert {:ok, region} =
             StickingRegion.derive(%SystemParameters{omega: omega, sigma: sigma, r: 0.5})

    assert is_nil(StickingRegion.state_if_sticking(nil, region))

    assert is_nil(
             StickingRegion.state_if_sticking(
               %StateOfMotion{t: 0.5 * region.period, x: sigma, v: 0},
               region
             )
           )

    StickingRegion.state_if_sticking(%StateOfMotion{t: 0, x: sigma, v: 0}, region)
    |> (fn state -> assert(state.v == 0) && assert(state.t == 0) && assert(state.x == sigma) end).()
  end
end
