defmodule Topex.TOTP do
  alias Topex.HOTP

  # TODO: Make these configurable
  @period_length 30
  @num_digits 6

  @spec code(key :: String.t()) :: {:ok, String.t()} | {:error, :badkey | {:encode, any()}}
  def code(key) do
    with {:ok, key} <- decode_key(key),
         {:ok, code} <- code_from_decoded_key(key) do
      {:ok, code}
    end
  end

  @spec code_from_decoded_key(key :: binary()) :: {:ok, String.t()} | {:error, {:encode, any()}}
  def code_from_decoded_key(key) do
    counter = counter_value()
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

  @spec counter_value() :: integer()
  defp counter_value() do
    t0 = 0
    tx = @period_length

    now = DateTime.utc_now() |> DateTime.to_unix()

    div(now - t0, tx)
  end

  @spec stringify_code(integer(), number()) :: String.t()
  defp stringify_code(code, length) do
    Integer.to_string(code)
    |> String.pad_leading(length, "0")
  end
end
