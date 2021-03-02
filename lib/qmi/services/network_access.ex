defmodule QMI.Service.NetworkAccess do
  use QMI.Service, id: 0x03
  require Logger

  @get_signal_strength 0x0020

  @spec get_signal_strength(QMI.device(), QMI.control_point()) :: QMI.Driver.response()
  def get_signal_strength(device, cp) do
    # TODO: Maybe ensure cp is for NetworkAccess serivce?
    bin = <<@get_signal_strength::16-little, 5, 0, 16, 2, 0, 239, 0>>

    QMI.Driver.request(device, bin, cp)
  end

  @doc false
  @impl QMI.Service
  def decode_response_tlvs(%{code: code} = resp) when code not in [0, :success] do
    # Response almost never has more TLV's if the command
    # was not successful. Just assume skip all for now
    resp
  end

  def decode_response_tlvs(%{id: @get_signal_strength, tlvs: raw_tlvs} = resp) do
    decoded_tlvs = decode_signal_strength(raw_tlvs, [])
    %{resp | tlvs: decoded_tlvs}
  end

  def decode_response_tlvs(resp), do: resp

  defp decode_signal_strength(<<1, 2, 0, sig_strength::signed, radio_if, rem::binary>>, acc) do
    radio = decode_radio_if(radio_if)
    acc = [%{signal_strength: sig_strength, radio: radio} | acc]

    decode_signal_strength(rem, acc)
  end

  defp decode_signal_strength(
         <<0x10, _len::little-16, num::16-little, sig_list::size(num)-unit(16)-binary,
           rest::binary>>,
         acc
       ) do
    sigs =
      for <<sig::signed, radio_if <- sig_list>>,
        do: %{signal_strength: sig, radio: decode_radio_if(radio_if)}

    decode_signal_strength(rest, acc ++ sigs)
  end

  defp decode_signal_strength(
         <<0x11, _len::little-16, num::16-little, rssi_list::size(num)-unit(16)-binary,
           rest::binary>>,
         acc
       ) do
    rssis =
      for <<rssi, radio_if <- rssi_list>>, do: %{rssi: -rssi, radio: decode_radio_if(radio_if)}

    decode_signal_strength(rest, acc ++ rssis)
  end

  defp decode_signal_strength(
         <<0x12, _len::little-16, num::16-little, ecio_list::size(num)-unit(16)-binary,
           rest::binary>>,
         acc
       ) do
    ecios =
      for <<ecio, radio_if <- ecio_list>>,
        do: %{ecio: ecio * -0.5, radio: decode_radio_if(radio_if)}

    decode_signal_strength(rest, acc ++ ecios)
  end

  defp decode_signal_strength(<<0x13, 4, 0, io::32-signed-little, rest::binary>>, acc) do
    decode_signal_strength(rest, [%{io: io} | acc])
  end

  defp decode_signal_strength(<<0x14, 1, 0, sinr, rest::binary>>, acc) do
    sinr =
      case sinr do
        # SINR_LEVEL_0 is -9 dB
        0x00 -> -9
        # SINR_LEVEL_1 is -6 dB
        0x01 -> -6
        # SINR_LEVEL_2 is -4.5 dB
        0x02 -> -4.5
        # SINR_LEVEL_3 is -3 dB
        0x03 -> -3
        # SINR_LEVEL_4 is -2 dB
        0x04 -> -2
        # SINR_LEVEL_5 is +1 dB
        0x05 -> 1
        # SINR_LEVEL_6 is +3 dB
        0x06 -> 3
        # SINR_LEVEL_7 is +6 dB
        0x07 -> 6
        # SINR_LEVEL_8 is +9 dB
        0x08 -> 9
      end

    decode_signal_strength(rest, [%{sinr: sinr} | acc])
  end

  defp decode_signal_strength(
         <<0x15, _len::little-16, num::16-little, error_rate_list::size(num)-unit(16)-binary,
           rest::binary>>,
         acc
       ) do
    error_rates =
      for <<error_rate, radio_if <- error_rate_list>>,
        do: %{error_rate: error_rate, radio: decode_radio_if(radio_if)}

    decode_signal_strength(rest, acc ++ error_rates)
  end

  defp decode_signal_strength(<<0x16, 2, 0, rsrq::signed, radio_if, rest::binary>>, acc) do
    decode_signal_strength(rest, [%{rsrq: rsrq, radio: decode_radio_if(radio_if)} | acc])
  end

  defp decode_signal_strength(<<0x17, 2, 0, snr::16-little-signed, rest::binary>>, acc) do
    decode_signal_strength(rest, [%{snr: snr * 0.1} | acc])
  end

  defp decode_signal_strength(<<0x18, 2, 0, rsrp::16-little-signed, rest::binary>>, acc) do
    decode_signal_strength(rest, [%{rsrp: rsrp} | acc])
  end

  defp decode_signal_strength(rem, acc) do
    if byte_size(rem) > 0 do
      Logger.warn("[NAS] signal strength has unmatched bytes remaining- #{inspect(rem)}")
    end

    Enum.reverse(acc)
  end

  defp decode_radio_if(radio_if) do
    case radio_if do
      # RADIO_IF_NO_SVC – None (no service)
      0x00 -> :none
      # RADIO_IF_CDMA_1X – cdma2000® 1X
      0x01 -> :CDMA_1X
      # RADIO_IF_CDMA_1XEVDO – cdma2000® HRPD (1xEV-DO)
      0x02 -> :CDMA_1XEVDO
      # RADIO_IF_AMPS – AMPS
      0x03 -> :AMPS
      # RADIO_IF_GSM – GSM
      0x04 -> :GSM
      # RADIO_IF_UMTS – UMTS
      0x05 -> :UMTS
      # RADIO_IF_LTE – LTE
      0x08 -> :LTE
    end
  end
end
