defmodule CoreWrapper do
  @moduledoc """
  Core wrapper: accepts (JSON-compatible) nested collections as input and interprets them into core function calls. 

  """

  @doc """
  Initialises a struct of type `:kind` from a `:Map` whose keys are strings.

  Taken from https://groups.google.com/forum/#!msg/elixir-lang-talk/6geXOLUeIpI/L9einu4EEAAJ
  """
  @spec to_struct(module(), map()) :: struct()
  defp to_struct(kind, attrs) do
    kind
    |> struct
    |> (fn struct ->
          Enum.reduce(Map.to_list(struct), struct, fn {k, _}, acc ->
            case Map.fetch(attrs, Atom.to_string(k)) do
              {:ok, v} -> %{acc | k => v}
              :error -> acc
            end
          end)
        end).()
  end

  # Extracts an input parameter of type `:kind` from `:attrs`. If `:attrs`
  # is a number we just return it, if it is a `:Map` we convert it to a 
  # struct type specified by `:kind`.
  @spec from_attrs(module(), map()) :: struct()
  defp from_attrs(kind, attrs) when Integer == kind and is_integer(attrs) do
    attrs
  end

  defp from_attrs(kind, attrs) when Float == kind and is_float(attrs) do
    attrs
  end

  defp from_attrs(kind, attrs) when String == kind and is_binary(attrs) do
    attrs
  end

  defp from_attrs(kind, attrs) do
    # Work out which struct type is needed and initialise it appropriately.
    case kind.module_info() |> Keyword.fetch(:module) do
      {:ok, module_type} ->
        case module_type do
          ImpactPoint ->
            attrs
            |> (&to_struct(ImpactPoint, &1)).()
            # We just expect the phase and velocity from the input and 
            # initialise the time to the phase
            |> (&%ImpactPoint{phi: &1.phi, v: &1.v, t: &1.phi}).()

          SystemParameters ->
            attrs |> (&to_struct(SystemParameters, &1)).()

          _ ->
            nil
        end

      _ ->
        nil
    end
  end

  @doc """
  Extracts an input parameter of type `:kind` from `:args` using key `:key`.
  """
  @spec from_args(module(), map(), iodata()) :: nil | number() | {atom(), iodata()} | struct()
  def from_args(kind, args, key) do
    case Map.fetch(args, key) do
      {:ok, attrs} ->
        attrs |> (&from_attrs(kind, &1)).()

      :error ->
        {:error, "Missing arguments for \"#{key}\""}
    end
  end

  # Determines which kind of action is required by a JSON-derived `:Map`
  # of `:input` and returns an async-ed `:Task` to execute it.
  @spec execute_action(map() | {atom(), iodata()}) :: {atom(), iodata()} | Task.t()
  defp execute_action(input) do
    Task.async(fn ->
      case input do
        {:error, _} ->
          input

        %{"action" => action, "args" => args, "options" => options} ->
          ActionMap.execute(action, args, options)
          |> (&%{"action" => action, "args" => args, "result" => &1}).()

        %{"action" => action, "args" => args} ->
          ActionMap.execute(action, args, %{})
          |> (&%{"action" => action, "args" => args, "result" => &1}).()

        _ ->
          {:error, "Could not retrieve action from JSON input"}
      end
    end)
  end

  @spec process(map() | {atom(), iodata()}) :: {atom(), iodata()} | atom()
  def process(input) do
    case input do
      {:ok, _} -> input |> elem(1) |> process
      [_ | _] -> input |> Enum.map(&process(&1))
      _ -> input |> execute_action |> Task.await()
    end
  end

  @spec process_decoded(map() | {atom(), iodata()}) :: iodata()
  def process_decoded(input) do
    input |> process |> JSON.encode!()
  end

  @spec process_input_string(iodata()) :: iodata()
  def process_input_string(input) do
    input |> JSON.decode() |> process_decoded
  end

  @spec process_input() :: :ok
  def process_input() do
    IO.read(:all) |> process_input_string |> IO.puts()
  end
end
