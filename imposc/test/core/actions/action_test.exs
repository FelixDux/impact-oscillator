defmodule ActionTest do
  use ExUnit.Case

  alias Action

  @moduletag :capture_log

  doctest Action

  test "module exists" do
    assert is_list(Action.module_info())
  end

  test "validation succeeds on valid arguments and options" do
    args = %{
      "initial_point" => %{"phi" => 0.5, "v" => 0.15},
      "params" => %{"omega" => 2.8, "sigma" => 0, "r" => 0.8},
      "num_iterations" => 10000
    }

    options = %{"outfile" => "png"}

    assert {:ok, ""} == Action.validate(ScatterAction, args, options)
  end

  test "validation fails on missing arguments" do
    args = %{
      "initial_point" => %{"v" => 0.15},
      "params" => %{"omega" => 2.8, "sigma" => 0, "r" => 0.8},
      "num_iterationZ" => 10000
    }

    options = %{}

    assert {:error, "Missing arguments: num_iterations\ninitial_point: Missing arguments: phi"} =
             Action.validate(ScatterAction, args, options)
  end

  test "validation fails on unrecognised options" do
    args = %{
      "initial_point" => %{"phi" => 0.5, "v" => 0.15},
      "params" => %{"omega" => 2.8, "sigma" => 0, "r" => 0.8},
      "num_iterations" => 10000
    }

    options = %{"infile" => "png"}

    assert {:error, "Unrecognised options: infile"} ==
             Action.validate(ScatterAction, args, options)
  end

  test "validation fails on arguments and options" do
    args = %{
      "params" => %{"omega" => 2.8, "sigma" => 0, "r" => 0.8},
      "num_iterations" => 10000
    }

    options = %{"infile" => "png"}

    assert {:error, "Missing arguments: initial_point\nUnrecognised options: infile"} ==
             Action.validate(ScatterAction, args, options)
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
