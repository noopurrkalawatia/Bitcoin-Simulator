#---
# Title        : Assignment - 4.2
# Subject      : Distributed And Operating Systems Principles
# Team Members : Noopur R K
# File name    : utility.ex
#---

defmodule Bitcoin.Utility do
  @moduledoc """
  This module is responsible for the utility functions, it provides the base58 encoding, and
  hash functions. The module is used by both miners and clients
  """
  def encode_data(data, hash \\ "")

  def encode_data(data, hash) when is_binary(data) do
    encode_zeros(data) <> encode_data(:binary.decode_unsigned(data), hash)
  end

  def encode_data(0, hash), do: hash

  def encode_data(data, hash) do
    character = <<Enum.at(@alphabet, rem(data, 58))>>
    encode_data(div(data, 58), character <> hash)
  end

  defp encode_zeros(data) do
    <<Enum.at(@alphabet, 0)>>
    |> String.duplicate(leading_zeros(data))
  end

  defp leading_zeros(data) do
    :binary.bin_to_list(data)
    |> Enum.find_index(&(&1 != 0))
  end

  def generateKeys() do
    :crypto.generate_key(:ecdh, :secp256k1)
  end

  def computeHashValue(key_list) do
    :crypto.hash(:sha256, key_list) |> Base.encode16
  end
end
