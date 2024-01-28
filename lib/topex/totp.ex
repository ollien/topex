defmodule Topex.TOTP do
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
      :error -> {:error, :badkey}
    end
  end

  @spec code_from_decoded_key(binary()) :: {:ok, binary()} | {:error, {:encode, any()}}
  defp code_from_decoded_key(key) do
    counter = counter_value()

    with {:ok, mac} <- hmac(key, counter) do
      res = hmac_to_hotp(mac)
        |> Integer.to_string()
        |> String.pad_leading(6, "0")

      {:ok, res}
    end
  end

  @spec hmac_to_hotp(binary()) :: integer()
  defp hmac_to_hotp(mac) do
    offset = least_significant_nibble(mac)
    <<_head :: binary-size(offset), _msb :: size(1), truncated :: unsigned-big-integer-size(31), _tail :: bits>> = mac

    truncated |> rem(Integer.pow(10, 6))
  end

  @spec counter_value() :: integer()
  defp counter_value() do
    t0 = 0
    tx = 30
    now = DateTime.utc_now() |> DateTime.to_unix()

    div(now - t0, tx)
  end

  @spec hmac(binary(), integer()) :: {:ok, binary()} | {:error, {:encode, any()}}
  defp hmac(key, counter) do
    try do
      mac = :crypto.mac(:hmac, :sha, key, <<counter::unsigned-big-integer-size(64)>>)
      {:ok, mac}
    rescue
      err in ErlangError ->
        %ErlangError{original: reason} = err
        {:error, {:encode, reason}}
    end
  end

  defp least_significant_nibble(bin) when is_binary(bin) and byte_size(bin) > 0 do
    head_size = byte_size(bin) * 8 - 4
    <<_head::size(head_size), least_significant::size(4)>> = bin

    least_significant
  end
end
