defmodule Topex.TOTP do
  alias Topex.HOTP

  # TODO: handle decoded keys
  @spec generate_code(String.t()) :: {:ok, String.t()} | {:error, any}
  def generate_code(key) do
    with {:ok, key} <- decode_key(key),
         {:ok, code} <- code_from_decoded_key(key) do
      {:ok, code}
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

  @spec code_from_decoded_key(binary()) :: {:ok, binary()} | {:error, {:encode, any()}}
  defp code_from_decoded_key(key) do
    counter = counter_value()
    num_digits = 6

    case HOTP.hotp(key, counter, num_digits: num_digits) do
      {:ok, hotp_val} ->
        {:ok, stringify_code(hotp_val, num_digits)}

      err = {:error, _reason} ->
        err
    end
  end

  @spec counter_value() :: integer()
  defp counter_value() do
    t0 = 0
    tx = 30
    now = DateTime.utc_now() |> DateTime.to_unix()

    div(now - t0, tx)
  end

  @spec stringify_code(integer(), number()) :: String.t()
  defp stringify_code(code, length) do
    Integer.to_string(code)
    |> String.pad_leading(length, "0")
  end
end
