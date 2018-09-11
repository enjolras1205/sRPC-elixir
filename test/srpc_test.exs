defmodule SrpcTest do
  use ExUnit.Case
  doctest Srpc

  test "greets the world" do
    assert Srpc.hello() == :world
  end
end
