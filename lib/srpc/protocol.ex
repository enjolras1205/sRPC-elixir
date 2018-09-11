
defmodule SRPC.Protocol do
  @static_keys [:codec, :method, :session, :code, :error, :timestamp, :trace]
  @static_values [:json, :sproto, :protobuf, :raw, 0]

  def decode(<<header_length::size(16), header::binary-size(header_length), body::binary>>) do
    {:ok, decode_header(header, []), body}
  end

  def encode(header, body) do
  end

  def decode_header(<<>>, acc) do
    :lists.reverse(acc)
  end
  def decode_header(<<1::size(1), idx::size(7), rest::binary>>, acc) do
    key = decode_static_key(idx)
    {value, rest} = decode_value(rest)
    decode_header(rest, [{key, value}|acc])
  end
  def decode_header(<<0::size(1), len::size(7), key::binary-size(len), rest::binary>>, acc) do
    {value, rest} = decode_value(rest)
    decode_header(rest, [{key, value}|acc])
  end

  def decode_value(<<1::size(2), idx::size(6), rest::binary>>) do
    {decode_static_value(idx), rest}
  end
  def decode_value(<<0::size(2), len::size(6), value::binary-size(len), rest::binary>>) do
    {value, rest}
  end
  def decode_value(<<1::size(2), len::size(14), value::binary-size(len), rest::binary>>) when len >= 64 do
    {value, rest}
  end

  def encode_header([], acc) do
    size = :erlang.iolist_size(acc)
    [<<size::size(16)>>, acc]
  end
  def encode_header([{key, value}|tail]) do
    
  end

  for {v, idx} <- Enum.with_index(@static_keys, 1) do
    defp decode_static_key(unquote(idx)), do: unquote(v)
  end

  for {v, idx} <- Enum.with_index(@static_values, 1) do
    defp decode_static_value(unquote(idx)), do: unquote(v)
  end
  
  for {v, idx} <- Enum.with_index(@static_keys, 1) do
    defp encode_key(unquote(v)), do: unquote(idx)
  end
  defp encode_key(k) do
  end

  for {v, idx} <- Enum.with_index(@static_values, 1) do
    defp encode_value(unquote(v)), do: <<1::size(1), unquote(idx)::size(7)>>
  end
  defp encode_value(k) when is_atom(k) do
    k
    |> :erlang.atom_to_binary(:latin1)
    |> encode_value
  end
  defp encode_value(k)  do
    size = :erlang.size(k)
    cond do
      size < 64 ->
        <<0::size(2), size::size(6), k::binary>>
      true ->
        <<1::size(2), size::size(14), k::binary>>
    end
  end

end
