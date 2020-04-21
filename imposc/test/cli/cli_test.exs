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

    assert {[window: true], [], []} = CLI.parse_args(["--window"])

    assert {[json: true, file: true], [], []} = CLI.parse_args(["--json", "--file"])

    assert {[help: true], [], []} = CLI.parse_args(["-h"])

    assert {[window: true], [], []} = CLI.parse_args(["-w"])

    assert {[json: true, file: true], [], []} = CLI.parse_args(["-j", "-f"])
  end
end
