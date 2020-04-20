defmodule ImpactPointTest do
  use ExUnit.Case

  alias ImpactPoint

  @moduletag :capture_log

  doctest ImpactPoint

  test "module exists" do
    assert is_list(ImpactPoint.module_info())
  end

  test "impact point maps to list" do
    assert ImpactPoint.point_to_list(%ImpactPoint{phi: 1.6, v: 0.7}) == [1.6, 0.7]
  end
end
