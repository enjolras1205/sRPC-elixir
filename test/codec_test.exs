defmodule SrpcCodecTest do
  use ExUnit.Case

  @test_case [
    {[], ""},
    {[{:codec, :json}, {:method, "/hello"}, {"x-real-ip", "0.0.0.0"}], "hello world"},
    {%{code: 0, session: "12312", method: "/world"}, "hello world"},
    {%{"zzz" => :json, code: 123, session: "12312", method: "/world"}, "hello world"}
  ]
  test "encode/decode" do
    @test_case
    |> Enum.each(fn {header, body} ->
      opt =
        case is_map(header) do
          true -> [:map_headers]
          false -> []
        end

      assert pkg = test_encode(header, body)
      assert {:ok, header, body} == SRPC.Protocol.decode(pkg, opt)
    end)
  end

  defp test_encode(header, body) do
    assert {:ok, iodata} = SRPC.Protocol.encode(header, body)
    :erlang.iolist_to_binary(iodata)
  end
end
