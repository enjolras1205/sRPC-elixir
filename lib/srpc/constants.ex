defmodule Srpc.Constants do
  def init_const() do
    init_status_code_const()
  end

  defp init_status_code_const() do
    status_code = %{
      ok: 0,
      unknown: 1,
      canceled: 2,
      packet_too_large: 3,
      bad_request: 40,
      method_not_found: 41,
      codec_not_supported: 42,
      internal_server_error: 50,
    }
    GlobalConst.new(SrpcStatusCode, status_code)
  end
end

defmodule SrpcStatusCode do
  @spec get(any()) :: any()
  def get(:dummy), do: {:error, :global_const_not_found}
  def get(a), do: a
  @spec get(any(), any()) :: any()
  def get(_, _), do: :ok

  def cmp(_), do: false
end