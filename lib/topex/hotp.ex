defmodule Topex.HOTP do
  @type hotp_option :: {:num_digits, integer()}

  @spec hotp(key :: binary(), counter :: integer(), opts :: [hotp_option]) ::
          {:ok, integer()} | {:error, {:encode, any()}}
  def hotp(key, counter, opts \\ []) do
    with {:ok, mac} <- hmac(key, counter),
         mac <- from_sha_hmac(mac, opts) do
      {:ok, mac}
    end
  end

  @spec from_sha_hmac(mac :: binary(), opts :: [hotp_option]) :: integer()
  def from_sha_hmac(mac, opts \\ []) do
    num_digits = Keyword.get(opts, :num_digits, 6)
    offset = least_significant_nibble(mac)

    <<_head::binary-size(offset), _msb::size(1), truncated::unsigned-big-integer-size(31),
      _tail::bits>> = mac

    truncated |> rem(Integer.pow(10, num_digits))
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
