defmodule Topex.Config do
  defmodule Entry do
    @enforce_keys [:name, :key]
    defstruct [:name, :key]

    @type t() :: %__MODULE__{
            key: String.t()
          }
  end

  @spec parse_config(String.t()) ::
          {:ok, list(Entry.t())}
          | {:error, {:badconfig, binary()}}
          | {:error, :nokeys}
          | {:error, {:missingfield, String.t()}, number()}
  def parse_config(raw_config) do
    case Toml.decode(raw_config) do
      {:ok, parsed_toml} -> extract_config(parsed_toml)
      {:error, {:invalid_toml, reason}} -> {:error, {:badconfig, reason}}
      {:error, reason} -> {:error, {:badconfig, reason}}
    end
  end

  @spec extract_config(%{String.t() => any()}) ::
          {:ok, list(Entry.t())}
          | {:error, :nokeys}
          | {:error, {:missingfield, String.t()}, number()}
  defp extract_config(config_map) do
    case config_map["keys"] do
      keys when is_list(keys) ->
        extract_key_entries(keys)

      _ ->
        {:error, :nokeys}
    end
  end

  @spec extract_key_entries(list(%{String.t() => any()})) ::
          {:ok, list(Entry.t())} | {:error, {:missingfield, String.t()}, number()}
  defp extract_key_entries(keys) do
    map_result(keys, &extract_key_entry/1)
  end

  @spec extract_key_entry(%{String.t() => any()}) ::
          {:ok, Entry.t()} | {:error, {:missingfield, String.t()}}
  defp extract_key_entry(entry) do
    with {:ok, key} <- pluck_key(entry, "key"),
         {:ok, name} <- pluck_key(entry, "name") do
      entry = %Entry{
        key: key,
        name: name
      }

      {:ok, entry}
    end
  end

  @spec pluck_key(map :: %{String.t() => t}, config_name :: String.t()) ::
          {:ok, t} | {:error, {:missingfield, String.t()}}
        when t: any()
  defp pluck_key(map, config_name) do
    case map[config_name] do
      nil -> {:error, {:missingfield, config_name}}
      val -> {:ok, val}
    end
  end

  @spec map_result(Enumerable.t(t), (t -> {:ok, u} | {:error, e})) ::
          {:ok, list(u)} | {:error, e, number()}
        when t: any(), u: any(), e: any()
  defp map_result(enum, mapper) do
    res =
      enum
      |> Enum.with_index()
      |> Enum.reduce_while({:ok, []}, fn {item, idx}, {:ok, acc} ->
        case mapper.(item) do
          {:ok, res} -> {:cont, {:ok, [res | acc]}}
          {:error, reason} -> {:halt, {:error, reason, idx}}
        end
      end)

    case res do
      {:ok, mapped} ->
        {:ok, Enum.reverse(mapped)}

      err = {:error, _reason, _n} ->
        err
    end
  end
end
