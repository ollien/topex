defmodule TopexTest.HOTP do
  alias Topex.HOTP

  use ExUnit.Case
  doctest Topex

  test "Generates correct HOTP value from MAC" do
    # Taken from https://datatracker.ietf.org/doc/html/rfc4226#section-5.4
    mac =
      <<0x1F, 0x86, 0x98, 0x69, 0x0E, 0x02, 0xCA, 0x16, 0x61, 0x85, 0x50, 0xEF, 0x7F, 0x19, 0xDA,
        0x8E, 0x94, 0x5B, 0x55, 0x5A>>

    hotp_value = HOTP.from_sha_hmac(mac)

    assert hotp_value == 872_921
  end

  test "Generates correct HOTP value from key and counter" do
    # Sample key from google authenticator
    key = Base.decode32!("JBSWY3DPEHPK3PXP")
    # Some counter value I could observe
    counter = 56_880_150

    {:ok, hotp_value} = HOTP.hotp(key, counter)

    assert hotp_value == 205_718
  end
end
