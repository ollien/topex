defmodule Topex.TOTP do
  alias Topex.HOTP

  # TODO: Make these configurable
  @period_length 30
  @num_digits 6

  @type code_opt :: {:time, DateTime.t()}

  @spec code(key :: String.t(), opts :: list(code_opt)) ::
          {:ok, String.t()} | {:error, :badkey | {:encode, any()}}
  def code(key, opts \\ []) do
    with {:ok, key} <- decode_key(key),
         {:ok, code} <- code_from_decoded_key(key, opts) do
      {:ok, code}
    end
  end

  @spec code_from_decoded_key(key :: binary(), opts :: list(code_opt)) ::
          {:ok, String.t()} | {:error, {:encode, any()}}
  def code_from_decoded_key(key, opts \\ []) do
    time = Keyword.get_lazy(opts, :time, &DateTime.utc_now/0)
    counter = counter_value(time)

    case HOTP.hotp(key, counter, num_digits: @num_digits) do
      {:ok, hotp_val} ->
        {:ok, stringify_code(hotp_val, @num_digits)}

      err = {:error, _reason} ->
        err
    end
  end

  @spec decode_key(String.t()) :: {:ok, binary()} | {:error, :badkey}
  defp decode_key(key) do
    case Base.decode32(key) do
      {:ok, decoded} ->
        {:ok, decoded}

      :error ->
        {:error, :badkey}
    end
  end

  @spec counter_value(DateTime.t()) :: integer()
  defp counter_value(time) do
    t0 = 0
    tx = @period_length

    unix_time = DateTime.to_unix(time)

    div(unix_time - t0, tx)
  end

  @spec stringify_code(integer(), number()) :: String.t()
  defp stringify_code(code, length) do
    Integer.to_string(code)
    |> String.pad_leading(length, "0")
  end
end
