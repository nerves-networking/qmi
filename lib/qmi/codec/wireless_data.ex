defmodule QMI.Codec.WirelessData do
  @moduledoc """
  Codec for making wireless data service requests
  """

  @start_network_interface 0x0020

  @type start_network_interface_opt() :: {:apn, binary()}

  @doc """
  Send command to request the that the network interface starts to receive data
  """
  @spec start_network_interface(start_network_interface_opt()) :: QMI.request()
  def start_network_interface(opts \\ []) do
    {tlvs, size} = make_tlvs(opts, [], 0)

    payload = [<<@start_network_interface::little-16, size::little-16>>, tlvs]

    %{payload: payload, decode: &parse_start_network_interface_resp/1}
  end

  defp make_tlvs([], tlvs, size) do
    {tlvs, size}
  end

  defp make_tlvs([{:apn, apn} | rest], tlvs, size) do
    apn_size = byte_size(apn)
    size = size + 3 + apn_size
    tlvs = tlvs ++ [<<0x14, apn_size::little-16, apn::binary>>]
    make_tlvs(rest, tlvs, size)
  end

  @doc """
  Parse the response to requesting QMI to start receiving data on the network
  interface
  """
  @spec parse_start_network_interface_resp(binary()) :: map()
  def parse_start_network_interface_resp(
        <<@start_network_interface::little-16, _length::little-16, tlvs::binary>>
      ) do
    Map.new()
    |> parse_start_network_interface_tlvs(tlvs)
  end

  defp parse_start_network_interface_tlvs(parsed, <<>>) do
    parsed
  end

  defp parse_start_network_interface_tlvs(
         parsed,
         <<0x01, 0x04, 0x00, packet_data_handle::little-32, rest::binary>>
       ) do
    parsed
    |> Map.put(:packet_data_handle, packet_data_handle)
    |> parse_start_network_interface_tlvs(rest)
  end

  defp parse_start_network_interface_tlvs(
         parsed,
         <<_type, length::little-16, _values::size(length)-unit(8)-binary, rest::binary>>
       ) do
    parse_start_network_interface_tlvs(parsed, rest)
  end
end
