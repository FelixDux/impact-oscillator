defmodule CLITest do
  use ExUnit.Case

  alias CLI

  @moduletag :capture_log

  doctest CLI

  test "module exists" do
    assert is_list(CLI.module_info())
  end

  test "Parse switches" do
    assert {[help: true], [], []} = CLI.parse_args(["--help"])

    assert {[one_shot: true, console: true], [], []} = CLI.parse_args(["--one-shot", "--console"])

    assert {[help: true], [], []} = CLI.parse_args(["-h"])

    assert {[one_shot: true, console: true], [], []} = CLI.parse_args(["-o", "-c"])
  end

  test "help" do
    CLI.process({[help: true], nil, nil})
  end
end
