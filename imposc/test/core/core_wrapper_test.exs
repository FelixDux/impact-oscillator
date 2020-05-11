defmodule CoreWrapperTest do
  use ExUnit.Case

  alias CoreWrapper

  @moduletag :capture_log

  doctest CoreWrapper

  test "module exists" do
    assert is_list(CoreWrapper.module_info())
  end

  test "Extract integer from args" do
    key = "key"
    value = 12
    args = %{key => value}
    assert value == CoreWrapper.from_args(Integer, args, key)
  end

  test "Extract struct from args" do
    key = "key"
    args = %{key => %{"phi" => 1, "v" => 2, "t" => 1}}
    assert %ImpactPoint{phi: 1, v: 2, t: 1} == CoreWrapper.from_args(ImpactPoint, args, key)
  end
end
