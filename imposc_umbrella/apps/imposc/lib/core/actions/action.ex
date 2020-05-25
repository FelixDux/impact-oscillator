defmodule Action do
  @callback execute(map() | [map()], map()) :: atom() | {atom(), iodata()}

  @callback expects_list?() :: boolean()

  @callback requirements() :: map() | [map()]

  @callback expected_options() :: map()

  @callback description() :: iodata()

  @doc """
  Validates `:args` and `:options` for the action
  """
  @spec validate(module(), map(), map()) :: {atom(), nil | iodata()}
  def validate(implementation, args, options) do
    {args_outcome, args_message} = validate_args(implementation, args)
    {options_outcome, options_message} = validate_options(implementation, options)

    {[args_outcome, options_outcome]
     |> Enum.all?(fn a -> a == :ok end)
     |> (&if(&1, do: :ok, else: :error)).(),
     [args_message, options_message] |> Enum.filter(fn s -> s != nil end) |> Enum.join("\n")}
  end

  @doc """
  Validates `:args` against `:requirements`
  """
  @spec validate_args(module(), map() | [map()]) :: {atom(), nil | iodata()}
  def validate_args(implementation, args) do
    implementation.requirements() |> validate_against_template(args)
  end

  @doc """
  Validates `:options` against `:expected_options`
  """
  @spec validate_options(module(), map()) :: {atom(), nil | iodata()}
  def validate_options(implementation, options) do
    options
    |> validate_against_template(
      implementation.expected_options(),
      "Unrecognised options"
    )
  end

  @spec validate_against_template(map() | [map()], map() | [map()], iodata()) ::
          {atom(), nil | iodata()}
  defp validate_against_template(template, args, error_prompt \\ "Missing arguments")

  defp validate_against_template(template, args, error_prompt) when is_list(template) do
    template
    |> Enum.reduce({:error, nil}, fn template_map, result ->
      validate_against_template(template_map, args, error_prompt)
      |> (&(with {:error, _} <- &1, {:error, _} <- result do
              &1
            end)).()
    end)
  end

  defp validate_against_template(template, args, error_prompt) when is_list(args) do
    args
    |> Enum.reduce({:error, nil}, fn args_map, result ->
      validate_against_template(template, args_map, error_prompt)
      |> (&(with {:error, _} <- &1, {:error, _} <- result do
              &1
            end)).()
    end)
  end

  defp validate_against_template(template, args, error_prompt) do
    missing_keys = Map.keys(template) -- Map.keys(args)

    case missing_keys do
      # recurse for values which are maps
      [] -> {:ok, nil}
      _ -> missing_keys |> Enum.join(", ") |> (&{:error, "#{error_prompt}: #{&1}"}).()
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
