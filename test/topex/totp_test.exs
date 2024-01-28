defmodule TopexTest.TOTP do
  alias Topex.TOTP

  use ExUnit.Case
  doctest Topex.TOTP

  test "can generate a code from a base-32 encoded key" do
    {:ok, code} =
      TOTP.code(
        # Sample key from google authenticator
        "JBSWY3DPEHPK3PXP",
        # Some time when I was writing this
        time: ~U[2024-01-28 01:15:00Z]
      )

    assert code == "205718"
  end

  test "can generate a code from a rawe key" do
    {:ok, code} =
      TOTP.code_from_decoded_key(
        # Sample key from google authenticator
        Base.decode32!("JBSWY3DPEHPK3PXP"),
        # Some time when I was writing this
        time: ~U[2024-01-28 01:15:00Z]
      )

    assert code == "205718"
  end
end
