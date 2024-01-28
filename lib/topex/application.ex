defmodule Topex.Application do
  use Application

  alias Topex.Config

  defmodule ConfigEntry do
    @enforce_keys [:name, :key]
    defstruct [:name, :key]

    @type t() :: %__MODULE__{
            key: String.t()
          }
  end

  # TODO: make this more intelligent, $XDG_CONFIG_HOME or some such
  @config_path "./topex.conf"

  @impl true
  @dialyzer {:no_return, start: 2}
  def start(_type, _args) do
    key_name = key_name_from_args()

    with {:ok, entries} <- read_config(),
         {:ok, entry} <- choose_entry(entries, key_name),
         {:ok, code} <- generate_code(entry.key) do
      IO.puts("#{entry.name} code: #{code}")
      System.halt(0)
    else
      {:error, message} ->
        error_puts(message)
        System.halt(1)
    end
  end

  @spec error_puts(String.t()) :: :ok
  defp error_puts(msg) do
    IO.puts(:stderr, "#{IO.ANSI.red()}error:#{IO.ANSI.reset()} #{msg}")
  end

  @spec key_name_from_args() :: String.t() | nil
  defp key_name_from_args() do
    case Burrito.Util.Args.get_arguments()  do
      [] -> nil
      [arg | _rest] -> arg
    end
  end

  @spec read_config() :: {:ok, list(Config.Entry.t())} | {:error, String.t()}
  defp read_config() do
    with {:ok, config_contents} <- read_config_file(@config_path),
         {:ok, parsed} <- parse_config(config_contents) do
      {:ok, parsed}
    end
  end

  @spec choose_entry(list(Config.Entry), String.t() | nil) :: {:ok, Config.Entry.t()}, {:error, String.t()}
  defp choose_entry([entry], nil) do
    {:ok, entry}
  end

  defp choose_entry([_head | _rest], nil) do
    {:error, "no key selected"}
  end

  defp choose_entry(entries, name) do
    Enum.find(entries, fn entry -> entry.name == name end)
    |> case do
      nil -> {:error, "no key with name #{name}"}
      entry -> {:ok, entry}
    end
  end

  @spec generate_code(key :: String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp generate_code(key) do
    case Topex.totp_code(key) do
      {:ok, code} -> {:ok, code}
      {:error, reason} -> {:error, generate_code_error_message(reason)}
    end
  end

  @spec read_config_file(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp read_config_file(path) do
    case File.read(path) do
      {:ok, contents} -> {:ok, contents}
      {:error, reason} -> {:error, file_error_message(path, reason)}
    end
  end

  @spec parse_config(String.t()) :: {:ok, list(Config.Entry.t())} | {:error, String.t()}
  defp parse_config(config_contents) do
    case Config.parse_config(config_contents) do
      {:ok, contents} ->
        {:ok, contents}

      {:error, reason} ->
        {:error, config_parse_error_message(reason)}

      {:error, {:missingfield, field_name}, entry_number} ->
        {:error, config_parse_error_message(field_name, entry_number)}
    end
  end

  @spec file_error_message(path :: String.t(), reason :: atom()) :: String.t()
  defp file_error_message(path, reason) do
    "could not open config file at #{path}: #{:file.format_error(reason)}"
  end

  @spec config_parse_error_message({:badconfig, binary()}) :: String.t()
  defp config_parse_error_message({:badconfig, message}) do
    "could not parse configuration file, invalid TOML: #{message}"
  end

  @spec config_parse_error_message(:nokeys) :: String.t()
  defp config_parse_error_message(:nokeys) do
    "invalid configuration file: no TOTP keys were present"
  end

  @spec config_parse_error_message(field_name :: String.t(), entry :: number()) ::
          String.t()
  defp config_parse_error_message(field_name, entry) do
    "key entry #{entry + 1} is missing the required field #{field_name}"
  end

  @spec generate_code_error_message(:badkey) :: String.t()
  defp generate_code_error_message(:badkey) do
    "invalid key; is it properly encoded as Base32?"
  end

  @spec generate_code_error_message({:encode, {any(), any(), binary()}}) :: String.t()
  defp generate_code_error_message({:encode, {_tag, _info, description}}) do
    "could not generate HMAC for key: #{description}"
  end
end
