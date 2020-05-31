defmodule ActionChangeset do
  @behaviour Phoenix.HTML.FormData

  defstruct action: "", description: "", requirements: %{}, model: %{}

  @type t :: %ActionChangeset{
          action: String.t(),
          description: String.t(),
          requirements: %{binary => term},
          model: %{binary => term}
        }

  @expected_fields [
    :n,
    :num_points,
    :omega,
    :r,
    :initial_point__phi,
    :initial_point__v,
    :num_iterations,
    :params__omega,
    :params__r,
    :params__sigma,
    :start_impact__phi,
    :start_impact__v
  ]

  @integer_fields [:n, :num_points, :num_iterations]

  @symbol_map %{
      "omega" => "ω",
      "sigma" => "σ",
      "phi" => "φ#{List.to_string([8320])}",
      "v" => "v#{List.to_string([8320])}",
      "r" => "r"
  }

  def replace_symbols(text) do
    Enum.reduce(@symbol_map, text, fn {k, v}, acc ->
      acc |> String.replace(k, v)
    end)
  end

  def field_label(field) when field == :n or field == :r do
    Atom.to_string(field) |> String.downcase()
  end

  def field_label(field) do
    f = Atom.to_string(field)
    tokens = f |> String.split("__")
    [t | _h] = Enum.reverse(tokens)

    case Map.fetch(@symbol_map, t) do
      {:ok, value} -> value
      _ -> f |> String.split("_") |> Enum.join(" ")
    end
  end

  def from_map(%{action: action, description: description, requirements: requirements}) do
    %ActionChangeset{
      action: action,
      description: description,
      requirements: requirements,
      model: requirements_to_model(requirements)
    }
  end

  def form_fields(data) do
    Map.keys(data.model)
  end

  @impl Phoenix.HTML.FormData
  def to_form(data, options) do
    %Phoenix.HTML.Form{
      source: data,
      options: options,
      params: data.model,
      impl: ActionChangeset,
      id: data.action,
      name: data.action,
      action: data.action,
      errors: [],
      hidden: [action: data.action],
      data: []
    }
  end

  @impl Phoenix.HTML.FormData
  def to_form(data, _form, _field, options) do
    to_form(data, options)
  end

  @impl Phoenix.HTML.FormData
  def input_value(data, _form, field) do
    case Map.fetch(data.model, field) do
      {:ok, value} -> value
      _ -> nil
    end
  end

  @impl Phoenix.HTML.FormData
  def input_validations(_data, _form, field) do
    cond do
      field in @integer_fields -> [min: 1, step: 1]
      field in @expected_fields -> [min: 0]
      true -> []
    end
  end

  @impl Phoenix.HTML.FormData
  def input_type(_data, _form, field) do
    if(field in @integer_fields, do: :number_input, else: :text_input)
  end

  def input_field(form, field) do
    if field in @integer_fields do
      Phoenix.HTML.Form.number_input(form, field)
    else
      Phoenix.HTML.Form.text_input(form, field)
    end
  end

  def to_model(data) do
    data.requirements |> requirements_to_model
  end

  def requirements_to_model_list(requirements) do
    requirements
    |> Map.to_list()
    |> Enum.reduce([], fn {key, value}, acc ->
      if is_map(value) do
        requirements_to_model_list(value)
        |> Enum.map(fn {k, v} ->
          {"#{key}__#{k}", v}
        end)
        |> (&(acc ++ &1)).()
      else
        acc ++ [{key, value}]
      end
    end)
  end

  def requirements_to_model(requirements) do
    requirements
    |> requirements_to_model_list
    |> Enum.map(fn {key, value} -> {String.to_existing_atom(key), value} end)
    |> Map.new()
  end

  def model_to_requirements(model) do
    model
    |> Map.to_list()
    |> Enum.map(fn {k, v} ->
      {if(is_atom(k), do: Atom.to_string(k), else: k)
       |> String.split("__"), v |> numberfy_if_poss}
    end)
    |> Enum.map(fn x -> nest_keys(x) end)
    |> merge_nested
  end

  def numberfy_if_poss(value) when is_binary(value) do
    if(String.starts_with?(value, "."), do: "0#{value}", else: value)
    |> (fn value ->
          case Integer.parse(value) do
            {v, ""} ->
              v

            _ ->
              case Float.parse(value) do
                {f, ""} -> f
                _ -> value
              end
          end
        end).()
  end

  def numberfy_if_poss(value) do
    value
  end

  def model_to_response(action, model) do
    %{
      "action" => action,
      "options" => %{"outfile" => "png"},
      "args" => model_to_requirements(model)
    }
  end

  def nest_keys({[first | other], value}) do
    case other do
      [] -> %{first => value}
      _ -> %{first => nest_keys({other, value})}
    end
  end

  defp merge_nested(maps) do
    maps
    |> Enum.group_by(fn m -> Map.keys(m) |> Enum.at(0) end, fn m -> Map.values(m) end)
    |> Map.to_list()
    |> Enum.map(fn {k, v} ->
      cond do
        is_list(v) ->
          {k,
           List.flatten(v)
           |> Enum.reduce(nil, fn x, acc ->
             if is_map(x) do
               if is_map(acc),
                 do: Map.merge(acc, x),
                 else: x
             else
               x
             end
           end)}

        true ->
          {k, v}
      end
    end)
    |> Enum.into(%{})
  end
end

defimpl Phoenix.HTML.FormData, for: ActionChangeset do
  def to_form(data, options), do: ActionChangeset.to_form(data, options)
  def to_form(data, form, field, options), do: ActionChangeset.to_form(data, form, field, options)
  def input_value(data, form, field), do: ActionChangeset.input_value(data, form, field)

  def input_validations(data, form, field),
    do: ActionChangeset.input_validations(data, form, field)

  def input_type(data, form, field), do: ActionChangeset.input_type(data, form, field)
end
