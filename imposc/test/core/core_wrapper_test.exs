defmodule CoreWrapperTest do
  use ExUnit.Case

  alias CoreWrapper

  @moduletag :capture_log

  doctest CoreWrapper

  test "module exists" do
    assert is_list(CoreWrapper.module_info())
  end
end
