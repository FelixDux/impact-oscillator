defmodule ActionTest do
  use ExUnit.Case

  alias Action

  @moduletag :capture_log

  doctest Action

  test "module exists" do
    assert is_list(Action.module_info())
  end

  test "validation succeeds on valid arguments" do
    args = %{
      "initial_point" => %{"phi" => 0.5, "v" => 0.15},
      "params" => %{"omega" => 2.8, "sigma" => 0, "r" => 0.8},
      "num_iterations" => 10000
    }

    assert {:ok, nil} == Action.validate_args(ScatterAction, args)
  end

  test "validation fails on missing arguments" do
    args = %{
      "initial_point" => %{"v" => 0.15},
      "params" => %{"omega" => 2.8, "sigma" => 0, "r" => 0.8},
      "num_iterationZ" => 10000
    }

    assert {:error, "Missing arguments: num_iterations\ninitial_point: Missing arguments: phi"} =
             Action.validate_args(ScatterAction, args)
  end

  test "Action requirements correctly retrieved" do
    assert %{} = "ellipse" |> ActionMap.requirements()
  end

  test "Action description correctly retrieved" do
    assert Regex.match?(
             ~r/.*sigma.*$/i,
             "ellipse" |> ActionMap.description()
           )
  end

  test "Bad requirements request correctly handled" do
    action = "sdfh"

    assert {:error, "Unrecognised action" <> _a} = action |> ActionMap.requirements()
  end

  test "Bad description request correctly handled" do
    action = "sdfh"

    assert {:error, "Unrecognised action" <> _a} = action |> ActionMap.description()
  end
end
