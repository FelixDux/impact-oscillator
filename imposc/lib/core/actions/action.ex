defmodule Action do
  @callback execute(map(), map()) :: atom() | {atom(), iodata()}

  @callback requirements() :: map()

  @callback description() :: iodata()

  @doc """
  Validates `:args` against `:requirements`
  """
  @spec validate_args(module(), map()) :: {atom(), nil | iodata()}
  def validate_args(implementation, args) do
    implementation.requirements() |> validate_against_template(args)
  end

  @spec validate_against_template(map(), map()) :: {atom(), nil | iodata()}
  defp validate_against_template(template, args) do
    missing_keys = Map.keys(template) -- Map.keys(args)

    case missing_keys do
      # recurse for values which are maps
      [] -> {:ok, nil}
      _ -> missing_keys |> Enum.join(", ") |> (&{:error, "Missing arguments: #{&1}"}).()
    end
    |> (fn result ->
          Enum.filter(args, fn {_k, v} -> is_map(v) end)
          |> (&Enum.reduce(&1, result, fn {action, sub_args}, acc ->
                case validate_against_template(template[action], sub_args) do
                  {:error, new_message} ->
                    case acc do
                      {:ok, _} -> {:error, new_message}
                      {:error, message} -> {:error, ~s(#{message}\n#{action}: #{new_message})}
                    end

                  _ ->
                    acc
                end
              end)).()
        end).()
  end
end
