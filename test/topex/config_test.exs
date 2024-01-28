defmodule TopexTest.Config do
  use ExUnit.Case
  doctest Topex.Config

  alias Topex.Config

  test "a config with multiple entries will be parsed" do
    config = """
      [[keys]]
      name = "account1"
      key = "JBSWY3DPEHPK3PXP"

      [[keys]]
      name = "account2"
      key = "PXP3KPHEPD3YWSBJ"
    """

    {:ok, parsed} = Config.parse_config(config)

    expected = [
      %Config.Entry{
        name: "account1",
        key: "JBSWY3DPEHPK3PXP"
      },
      %Config.Entry{
        name: "account2",
        key: "PXP3KPHEPD3YWSBJ"
      }
    ]

    assert parsed == expected
  end

  test "a config with a missing key indicates which entry is missing the key" do
    config = """
      [[keys]]
      name = "account1"
      key = "JBSWY3DPEHPK3PXP"

      [[keys]]
      name = "account2"
    """

    assert {:error, {:missingfield, "key"}, 1} == Config.parse_config(config)
  end

  test "an empty config gives a nokeys error" do
    assert {:error, :nokeys} == Config.parse_config("")
  end

  test "invalid TOML gives an badconfig error" do
    {:error, {:badconfig, _reason}} = Config.parse_config("[")
  end
end
