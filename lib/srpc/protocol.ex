defmodule SRPC.Protocol do
  @static_keys [
    :codec,
    :method,
    :session,
    :code,
    :error,
    :timestamp,
    :trace,
    :destination,
    :source
  ]
  @static_values [:json, :sproto, :protobuf, :raw, 0]

  def decode(pkg) do
    decode(pkg, [:map_headers])
  end

  def decode(
        <<header_length::size(16), header_bin::binary-size(header_length), body::binary>>,
        opt
      ) do
    header_list =
      header_bin
      |> decode_header([])
      |> convert_well_known()

    header =
      case opt do
        [] -> header_list
        [:map_headers] -> :maps.from_list(header_list)
      end

    {:ok, header, body}
  end

  def encode(header, body) do
    encoded_header = encode_header(header)
    {:ok, [encoded_header, body]}
  end

  def decode_header(<<>>, acc) do
    :lists.reverse(acc)
  end

  def decode_header(<<1::size(1), idx::size(7), rest::binary>>, acc) do
    key = decode_static_key(idx)
    {value, rest} = decode_value(rest)
    decode_header(rest, [{key, value} | acc])
  end

  def decode_header(<<0::size(1), len::size(7), key::binary-size(len), rest::binary>>, acc) do
    {value, rest} = decode_value(rest)
    decode_header(rest, [{key, value} | acc])
  end

  def decode_value(<<1::size(1), idx::size(7), rest::binary>>) do
    {decode_static_value(idx), rest}
  end

  def decode_value(<<0::size(2), len::size(6), value::binary-size(len), rest::binary>>) do
    {value, rest}
  end

  def decode_value(<<1::size(2), len::size(14), value::binary-size(len), rest::binary>>)
      when len >= 64 do
    {value, rest}
  end

  @spec encode_header([{atom() | binary(), atom() | binary() | integer()}]) :: [iolist()]
  def encode_header(m) when is_map(m) do
    m
    |> :maps.to_list()
    |> encode_header([])
  end

  def encode_header(l) do
    encode_header(l, [])
  end

  defp encode_header([], acc) do
    size = :erlang.iolist_size(acc)
    acc = :lists.reverse(acc)
    [<<size::size(16)>>, acc]
  end

  defp encode_header([{key, value} | tail], acc) do
    encode_header(tail, [[encode_key(key), encode_value(value)] | acc])
  end

  for {v, idx} <- Enum.with_index(@static_keys, 1) do
    defp decode_static_key(unquote(idx)), do: unquote(v)
  end

  for {v, idx} <- Enum.with_index(@static_values, 1) do
    defp decode_static_value(unquote(idx)), do: unquote(v)
  end

  for {v, idx} <- Enum.with_index(@static_keys, 1) do
    defp encode_key(unquote(v)), do: <<1::size(1), unquote(idx)::size(7)>>
  end

  defp encode_key(k) when is_atom(k) do
    k
    |> :erlang.atom_to_binary(:utf8)
    |> encode_key
  end

  defp encode_key(k) do
    size = :erlang.size(k)
    <<0::size(1), size::size(7), k::binary>>
  end

  for {v, idx} <- Enum.with_index(@static_values, 1) do
    defp encode_value(unquote(v)), do: <<1::size(1), unquote(idx)::size(7)>>
  end

  defp encode_value(k) when is_atom(k) do
    k
    |> :erlang.atom_to_binary(:utf8)
    |> encode_value
  end

  defp encode_value(k) when is_integer(k) do
    k
    |> :erlang.integer_to_binary()
    |> encode_value
  end

  defp encode_value(k) do
    size = :erlang.size(k)

    cond do
      size < 64 ->
        <<0::size(2), size::size(6), k::binary>>

      size < 16383 ->
        <<1::size(2), size::size(14), k::binary>>
    end
  end

  defp convert_well_known(headers) do
    :lists.map(
      fn
        {:code, v} when is_binary(v) -> {:code, :erlang.binary_to_integer(v)}
        other -> other
      end,
      headers
    )
  end
end
