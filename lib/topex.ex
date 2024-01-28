defmodule Topex do
  defdelegate totp_code(key), to: Topex.TOTP, as: :code
end
