defmodule QMI.WirelessData.StartNetworkInterfaceReq do
  @moduledoc """
  Request to packet data service

  When issuing this request the control point binds itself to the WWAN data
  connection. This data connection remains connect while at least one control
  point is bound to the WWAN data connection.
  """

  @typedoc """
  Which authentication algorithms should be tried

  If more than one algorithm is specified the device decides which to use while
  setting up the data session.
  """
  @type authentication() :: :pap | :chap

  @type ip_family() :: :ipv4 | :ipv6

  @type t() :: %__MODULE__{
          apn_name: String.t() | nil,
          username: String.t() | nil,
          password: String.t() | nil,
          ip_family: ip_family(),
          authentication_preferences: [authentication()]
        }

  defstruct apn_name: nil,
            username: nil,
            password: nil,
            authentication_preferences: [],
            ip_family: :ipv4

  defimpl QMI.Request do
    def encode(request) do
      tlvs = encode_tlvs(request)
      tlvs_size = byte_size(tlvs)

      <<0x0020::16-little, tlvs_size::16-little>> <> tlvs
    end

    defp encode_tlvs(request) do
      fields =
        request
        |> Map.from_struct()
        |> Map.keys()

      for field <- fields, into: <<>>, do: encode_tlv(request, field)
    end

    defp encode_tlv(%{apn_name: apn}, :apn_name) when not is_nil(apn) do
      apn_size = byte_size(apn)
      <<0x14, apn_size::little-16, apn::binary>>
    end

    defp encode_tlv(%{username: username}, :username) when not is_nil(username) do
      username_size = byte_size(username)
      <<0x17, username_size::little-16, username::binary>>
    end

    defp encode_tlv(%{password: password}, :password) when not is_nil(password) do
      password_size = byte_size(password)
      <<0x18, password_size::little-16, password::binary>>
    end

    defp encode_tlv(%{authentication_preferences: []}, :authentication_preferences) do
      <<>>
    end

    defp encode_tlv(%{authentication_preferences: prefs}, :authentication_preferences) do
      pap = if :pap in prefs, do: 1, else: 0
      chap = if :chap in prefs, do: 1, else: 0

      tlvs_tl = <<0x16, 0x01::little-16>>

      case {pap, chap} do
        {1, 1} ->
          tlvs_tl <> <<0x03>>

        {0, 1} ->
          tlvs_tl <> <<0x02>>

        {1, 0} ->
          tlvs_tl <> <<0x01>>

        _ ->
          # default is 0, and makes this an optional TLV
          <<>>
      end
    end

    defp encode_tlv(%{ip_family: ip_family}, :ip_family) when not is_nil(ip_family) do
      tlvs_tl = <<0x19, 0x01::little-16>>

      case ip_family do
        :ipv4 ->
          tlvs_tl <> <<0x04>>

        :ipv6 ->
          tlvs_tl <> <<0x08>>
      end
    end

    defp encode_tlv(_req, _field), do: <<>>
  end
end
