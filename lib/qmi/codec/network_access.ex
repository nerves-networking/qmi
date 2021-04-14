defmodule QMI.Codec.NetworkAccess do
  @moduledoc """
  Codec for making network access service requests
  """
  @network_access_service_id 0x03

  @get_signal_strength 0x0020
  @get_home_network 0x0025

  @typedoc """
  The radio interface that is being reported
  """
  @type radio_interface() :: :no_service | :cdma_1x | :cdma_1x_evdo | :amps | :gsm | :umts | :lte

  @typedoc """
  Report from requesting the signal strength
  """
  @type signal_strength_report() :: %{
          rssis: [%{radio: radio_interface(), rssi: integer()}]
        }

  @typedoc """
  Report from requesting the home network
  """
  @type home_network_report() :: %{mmc: char(), mnc: char()}

  @doc """
  Make the `QMI.request()` for getting signal strength
  """
  @spec get_signal_strength() :: QMI.request()
  def get_signal_strength() do
    %{
      service_id: @network_access_service_id,
      payload:
        <<@get_signal_strength::16-little, 0x05::little-16, 0x10, 0x02::little-16,
          0xEF::little-16>>,
      decode: &parse_get_signal_strength_resp/1
    }
  end

  @doc """
  Parse the get signal strength response
  """
  @spec parse_get_signal_strength_resp(binary()) :: signal_strength_report()
  def parse_get_signal_strength_resp(
        <<@get_signal_strength::little-16, _length::little-16, tlvs::binary>>
      ) do
    parse_get_signal_strength_tlvs(%{rssis: []}, tlvs)
  end

  defp parse_get_signal_strength_tlvs(parsed, <<>>) do
    parsed
  end

  defp parse_get_signal_strength_tlvs(
         parsed,
         <<0x11, _length::little-16, num_sets::little-16,
           rssi_list::size(num_sets)-unit(16)-binary, rest::binary>>
       ) do
    rssis =
      for <<rssi, radio_if <- rssi_list>>, do: %{rssi: -rssi, radio: radio_interface(radio_if)}

    parsed
    |> Map.put(:rssis, rssis)
    |> parse_get_signal_strength_tlvs(rest)
  end

  defp parse_get_signal_strength_tlvs(
         parsed,
         <<_type, length::little-16, _values::size(length)-unit(8)-binary, rest::binary>>
       ) do
    parse_get_signal_strength_tlvs(parsed, rest)
  end

  defp radio_interface(0x00), do: :no_service
  defp radio_interface(0x01), do: :cdma_1x
  defp radio_interface(0x02), do: :cdma_1x_evdo
  defp radio_interface(0x03), do: :amps
  defp radio_interface(0x04), do: :gsm
  defp radio_interface(0x05), do: :umts
  defp radio_interface(0x08), do: :lte

  @doc """
  Make the request for getting the home network
  """
  @spec get_home_network() :: QMI.request()
  def get_home_network() do
    %{
      service_id: @network_access_service_id,
      payload: <<@get_home_network::little-16, 0x00, 0x00>>,
      decode: &parse_get_home_network_resp/1
    }
  end

  defp parse_get_home_network_resp(
         <<@get_home_network::little-16, size::little-16, tlvs::size(size)-binary>>
       ) do
    {:ok, parse_get_home_network_tlvs(%{}, tlvs)}
  end

  defp parse_get_home_network_resp(_other) do
    {:error, :unexpected_response}
  end

  defp parse_get_home_network_tlvs(parsed, <<>>) do
    parsed
  end

  defp parse_get_home_network_tlvs(
         parsed,
         <<0x01, 0x04::little-16, mcc::little-16, mnc::little-16, rest::binary>>
       ) do
    parsed
    |> Map.put(:mcc, mcc)
    |> Map.put(:mnc, mnc)
    |> parse_get_home_network_tlvs(rest)
  end

  defp parse_get_home_network_tlvs(
         parsed,
         <<_type, length::little-16, _values::size(length)-binary, rest::binary>>
       ) do
    parse_get_home_network_tlvs(parsed, rest)
  end
end
