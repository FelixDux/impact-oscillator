defmodule CoreWrapperTest do
  use ExUnit.Case

  alias CoreWrapper

  @moduletag :capture_log

  doctest CoreWrapper

  test "module exists" do
    assert is_list(CoreWrapper.module_info())
  end

  test "JSON from input" do
    "[{\"a\": \"b\"}]"
    |> CoreWrapper.json_from_input()
    |> (&assert(&1 == {:ok, [%{"a" => "b"}]})).()
  end

  test "output to JSON" do
    [%{"a" => "b"}]
    |> CoreWrapper.json_to_output()
    |> (&assert(&1 == "[{\"a\":\"b\"}]")).()
  end
end
