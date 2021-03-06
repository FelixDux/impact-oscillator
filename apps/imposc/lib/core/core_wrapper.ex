defmodule CoreWrapper do
  @moduledoc """
  Core wrapper: accepts (JSON-compatible) nested collections as input and interprets them into core function calls. 

  """

  @doc """
  Initialises a struct of type `:kind` from a `:Map` whose keys are strings.

  Taken from https://groups.google.com/forum/#!msg/elixir-lang-talk/6geXOLUeIpI/L9einu4EEAAJ
  """
  @spec to_struct(module(), map()) :: struct()
  def to_struct(kind, attrs) do
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
    |> InputValidator.validate()
  end

  # Extracts an input parameter of type `:kind` from `:attrs`. If `:attrs`
  # is a number we just return it, if it is a `:Map` we convert it to a 
  # struct type specified by `:kind`.
  @spec from_attrs(module(), map()) :: struct() | {atom(), binary()}
  defp from_attrs(kind, attrs) when Integer == kind and is_binary(attrs) do
    Integer.parse(attrs)
  end

  defp from_attrs(kind, attrs) when Float == kind and is_binary(attrs) do
    if(String.starts_with?(attrs, "."), do: "0#{attrs}", else: attrs)
    |> Float.parse()
  end

  defp from_attrs(kind, attrs) when Integer == kind and is_integer(attrs) do
    attrs
  end

  defp from_attrs(kind, attrs) when (Float == kind and is_float(attrs)) or is_integer(attrs) do
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
            |> (fn point ->
                  case point do
                    {:error, message} ->
                      {:error, message}

                    _ ->
                      point
                      # We just expect the phase and velocity from the input and 
                      # initialise the time to the phase
                      |> (&%ImpactPoint{phi: &1.phi, v: &1.v, t: &1.phi}).()
                  end
                end).()

          SystemParameters ->
            attrs |> (&to_struct(SystemParameters, &1)).()

          _ ->
            {:error, "Unrecognised module type: #{module_type}"}
        end

      _ ->
        {:error, "No module type specified"}
    end
  end

  @doc """
  Extracts an input parameter of type `:kind` from `:args` using key `:key`.
  """
  @spec from_args(module(), map(), binary()) :: {atom(), binary()} | struct()
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
  @spec execute_action(map() | {atom(), String.t()}) :: {atom(), String.t()} | Task.t()
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
      _ -> input |> execute_action |> Task.await(:infinity)
    end
  end

  @spec process_decoded(map() | {atom(), String.t()}) :: String.t()
  def process_decoded(input) do
    input |> process |> JSON.encode!()
  end

  @spec process_input_string(String.t()) :: String.t()
  def process_input_string(input) do
    input |> JSON.decode() |> process_decoded
  end

  @spec process_input() :: :ok
  def process_input() do
    IO.read(:all) |> process_input_string |> IO.puts()
  end

  @doc """
  Returns a `:Map` with only the values which are shared identically by
  two maps.

  ## Example
      iex> x=%{"cars" => %{"Ford"=>"Cortina", "Renault"=>"Clio"}}
      %{"cars" => %{"Ford" => "Cortina", "Renault" => "Clio"}}
      iex> y=%{"cars" => %{"Ford"=>"Cortina", "Renault"=>"Laguna"}}
      %{"cars" => %{"Ford" => "Cortina", "Renault" => "Laguna"}}
      iex> CoreWrapper.intersect_args(x,y)
      %{"cars" => %{"Ford" => "Cortina"}}

  """
  def intersect_args(args1, args2, complement \\ false, exclude \\ []) do
    keys_in_common =
      if complement do
        args2 |> Map.keys()
      else
        MapSet.intersection(
          MapSet.new(args1 |> Map.keys()),
          MapSet.new(args2 |> Map.keys())
        )
      end
      |> MapSet.new()
      |> MapSet.difference(MapSet.new(exclude))

    keys_in_common
    |> Enum.reduce(
      [],
      fn key, collection ->
        value1 =
          if Map.has_key?(args1, key) do
            Map.fetch!(args1, key)
          else
            nil
          end

        value2 = Map.fetch!(args2, key)

        cond do
          is_map(value2) ->
            if(value1 == nil, do: %{}, else: value1)
            |> intersect_args(value2, complement, exclude)
            |> (fn sub_collection ->
                  cond do
                    map_size(sub_collection) == 0 -> collection
                    true -> collection ++ [{key, sub_collection}]
                  end
                end).()

          complement == false and value1 == value2 ->
            collection ++ [{key, value2}]

          complement == true and value1 != value2 ->
            collection ++ [{key, value2}]

          true ->
            collection
        end
      end
    )
    |> Map.new()
  end

  @doc """
  Returns a `:Map` with only the values which are shared identically by
  two maps.

  ## Example
      iex> x=%{"cars" => %{"Ford"=>"Cortina", "Renault"=>"Clio"}}
      %{"cars" => %{"Ford" => "Cortina", "Renault" => "Clio"}}
      iex> y=%{"cars" => %{"Ford"=>"Cortina", "Renault"=>"Laguna"}}
      %{"cars" => %{"Ford" => "Cortina", "Renault" => "Laguna"}}
      iex> z=%{"cars" => %{"Ford"=>"Cortina", "Renault"=>"Megane"}}
      %{"cars" => %{"Ford" => "Cortina", "Renault" => "Megane"}}
      iex> CoreWrapper.intersect_arglist([x, y, z])
      %{"cars" => %{"Ford" => "Cortina"}}

  """
  def intersect_arglist(arglist, exclude \\ []) do
    [head | tail] = arglist

    Enum.reduce(tail, head, fn args1, args2 -> intersect_args(args1, args2, false, exclude) end)
  end

  def arglist_complements(template, arg_list, exclude \\ []) do
    arg_list |> Enum.map(&intersect_args(template, &1, true, exclude))
  end
end

defprotocol InputValidator do
  @spec validate(t) :: t | {atom(), binary()}
  def validate(instance)
end
