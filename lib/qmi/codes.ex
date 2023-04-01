defmodule QMI.Codes do
  @moduledoc false

  # QMI_ERR_NONE
  @error_codes %{
    0x0000 => :none,
    # QMI_ERR_MALFORMED_MSG
    0x0001 => :malformed_msg,
    # QMI_ERR_NO_MEMORY
    0x0002 => :no_memory,
    # QMI_ERR_INTERNAL
    0x0003 => :internal,
    # QMI_ERR_ABORTED
    0x0004 => :aborted,
    # QMI_ERR_CLIENT_IDS_EXHAUSTED
    0x0005 => :client_ids_exhausted,
    # QMI_ERR_UNABORTABLE_TRANSACTION
    0x0006 => :unabortable_transaction,
    # QMI_ERR_INVALID_CLIENT_ID
    0x0007 => :invalid_client_id,
    # QMI_ERR_NO_THRESHOLDS
    0x0008 => :no_thresholds,
    # QMI_ERR_INVALID_HANDLE
    0x0009 => :invalid_handle,
    # QMI_ERR_INVALID_PROFILE
    0x000A => :invalid_profile,
    # QMI_ERR_INVALID_PINID
    0x000B => :invalid_pinid,
    # QMI_ERR_INCORRECT_PIN
    0x000C => :incorrect_pin,
    # QMI_ERR_NO_NETWORK_FOUND
    0x000D => :no_network_found,
    # QMI_ERR_CALL_FAILED
    0x000E => :call_failed,
    # QMI_ERR_OUT_OF_CALL
    0x000F => :out_of_call,
    # QMI_ERR_NOT_PROVISIONED
    0x0010 => :not_provisioned,
    # QMI_ERR_MISSING_ARG
    0x0011 => :missing_arg,
    # QMI_ERR_ARG_TOO_LONG
    0x0013 => :arg_too_long,
    # QMI_ERR_INVALID_TX_ID
    0x0016 => :invalid_tx_id,
    # QMI_ERR_DEVICE_IN_USE
    0x0017 => :device_in_use,
    # QMI_ERR_OP_NETWORK_UNSUPPORTED
    0x0018 => :op_network_unsupported,
    # QMI_ERR_OP_DEVICE_UNSUPPORTED
    0x0019 => :op_device_unsupported,
    # QMI_ERR_NO_EFFECT
    0x001A => :no_effect,
    # QMI_ERR_NO_FREE_PROFILE
    0x001B => :no_free_profile,
    # QMI_ERR_INVALID_PDP_TYPE
    0x001C => :invalid_pdp_type,
    # QMI_ERR_INVALID_TECH_PREF
    0x001D => :invalid_tech_pref,
    # QMI_ERR_INVALID_PROFILE_TYPE
    0x001E => :invalid_profile_type,
    # QMI_ERR_INVALID_SERVICE_TYPE
    0x001F => :invalid_service_type,
    # QMI_ERR_INVALID_REGISTER_ACTION
    0x0020 => :invalid_register_action,
    # QMI_ERR_INVALID_PS_ATTACH_ACTION
    0x0021 => :invalid_ps_attach_action,
    # QMI_ERR_AUTHENTICATION_FAILED
    0x0022 => :authentication_failed,
    # QMI_ERR_PIN_BLOCKED
    0x0023 => :pin_blocked,
    # QMI_ERR_PIN_PERM_BLOCKED
    0x0024 => :pin_perm_blocked,
    # QMI_ERR_SIM_NOT_INITIALIZED
    0x0025 => :sim_not_initialized,
    # QMI_ERR_MAX_QOS_REQUESTS_IN_USE
    0x0026 => :max_qos_requests_in_use,
    # QMI_ERR_INCORRECT_FLOW_FILTER
    0x0027 => :incorrect_flow_filter,
    # QMI_ERR_NETWORK_QOS_UNAWARE
    0x0028 => :network_qos_unaware,
    # QMI_ERR_INVALID_QOS_ID/QMI_ERR_INVALID_ID
    0x0029 => :invalid_qos_id,
    # QMI_ERR_REQUESTED_NUM_UNSUPPORTED
    0x002A => :requested_num_unsupported,
    # QMI_ERR_INTERFACE_NOT_FOUND
    0x002B => :interface_not_found,
    # QMI_ERR_FLOW_SUSPENDED
    0x002C => :flow_suspended,
    # QMI_ERR_INVALID_DATA_FORMAT
    0x002D => :invalid_data_format,
    # QMI_ERR_GENERAL
    0x002E => :general,
    # QMI_ERR_UNKNOWN
    0x002F => :unknown,
    # QMI_ERR_INVALID_ARG
    0x0030 => :invalid_arg,
    # QMI_ERR_INVALID_INDEX
    0x0031 => :invalid_index,
    # QMI_ERR_NO_ENTRY
    0x0032 => :no_entry,
    # QMI_ERR_DEVICE_STORAGE_FULL
    0x0033 => :device_storage_full,
    # QMI_ERR_DEVICE_NOT_READY
    0x0034 => :device_not_ready,
    # QMI_ERR_NETWORK_NOT_READY
    0x0035 => :network_not_ready,
    # QMI_ERR_CAUSE_CODE
    0x0036 => :cause_code,
    # QMI_ERR_MESSAGE_NOT_SENT
    0x0037 => :message_not_sent,
    # QMI_ERR_MESSAGE_DELIVERY_FAILURE
    0x0038 => :message_delivery_failure,
    # QMI_ERR_INVALID_MESSAGE_ID
    0x0039 => :invalid_message_id,
    # QMI_ERR_ENCODING
    0x003A => :encoding,
    # QMI_ERR_AUTHENTICATION_LOCK
    0x003B => :authentication_lock,
    # QMI_ERR_INVALID_TRANSITION
    0x003C => :invalid_transition,
    # QMI_ERR_NOT_A_MCAST_IFACE
    0x003D => :not_a_mcast_iface,
    # QMI_ERR_MAX_MCAST_REQUESTS_IN_USE
    0x003E => :max_mcast_requests_in_use,
    # QMI_ERR_INVALID_MCAST_HANDLE
    0x003F => :invalid_mcast_handle,
    # QMI_ERR_INVALID_IP_FAMILY_PREF
    0x0040 => :invalid_ip_family_pref,
    # QMI_ERR_SESSION_INACTIVE
    0x0041 => :session_inactive,
    # QMI_ERR_SESSION_INVALID
    0x0042 => :session_invalid,
    # QMI_ERR_SESSION_OWNERSHIP
    0x0043 => :session_ownership,
    # QMI_ERR_INSUFFICIENT_RESOURCES
    0x0044 => :insufficient_resources,
    # QMI_ERR_DISABLED
    0x0045 => :disabled,
    # QMI_ERR_INVALID_OPERATION
    0x0046 => :invalid_operation,
    # QMI_ERR_INVALID_QMI_CMD
    0x0047 => :invalid_qmi_cmd,
    # QMI_ERR_TPDU_TYPE
    0x0048 => :tpdu_type,
    # QMI_ERR_SMSC_ADDR
    0x0049 => :smsc_addr,
    # QMI_ERR_INFO_UNAVAILABLE
    0x004A => :info_unavailable,
    # QMI_ERR_SEGMENT_TOO_LONG
    0x004B => :segment_too_long,
    # QMI_ERR_SEGMENT_ORDER
    0x004C => :segment_order,
    # QMI_ERR_BUNDLING_NOT_SUPPORTED
    0x004D => :bundling_not_supported,
    # QMI_ERR_OP_PARTIAL_FAILURE
    0x004E => :op_partial_failure,
    # QMI_ERR_POLICY_MISMATCH
    0x004F => :policy_mismatch,
    # QMI_ERR_SIM_FILE_NOT_FOUND
    0x0050 => :sim_file_not_found,
    # QMI_ERR_EXTENDED_INTERNAL
    0x0051 => :extended_internal,
    # QMI_ERR_ACCESS_DENIED
    0x0052 => :access_denied,
    # QMI_ERR_HARDWARE_RESTRICTED
    0x0053 => :hardware_restricted,
    # QMI_ERR_ACK_NOT_SENT
    0x0054 => :ack_not_sent,
    # QMI_ERR_INJECT_TIMEOUT
    0x0055 => :inject_timeout,
    # QMI_ERR_INCOMPATIBLE_STATE
    0x005A => :incompatible_state,
    # QMI_ERR_FDN_RESTRICT
    0x005B => :fdn_restrict,
    # QMI_ERR_SUPS_FAILURE_CAUSE
    0x005C => :sups_failure_cause,
    # QMI_ERR_NO_RADIO
    0x005D => :no_radio,
    # QMI_ERR_NOT_SUPPORTED
    0x005E => :not_supported,
    # QMI_ERR_NO_SUBSCRIPTION
    0x005F => :no_subscription,
    # QMI_ERR_CARD_CALL_CONTROL_FAILED
    0x0060 => :card_call_control_failed,
    # QMI_ERR_NETWORK_ABORTED
    0x0061 => :network_aborted,
    # QMI_ERR_MSG_BLOCKE
    0x0062 => :msg_blocke,
    # QMI_ERR_INVALID_SESSION_TYPE
    0x0064 => :invalid_session_type,
    # QMI_ERR_INVALID_PB_TYPE
    0x0065 => :invalid_pb_type,
    # QMI_ERR_NO_SIM
    0x0066 => :no_sim,
    # QMI_ERR_PB_NOT_READY
    0x0067 => :pb_not_ready,
    # QMI_ERR_PIN_RESTRICTION
    0x0068 => :pin_restriction,
    # QMI_ERR_PIN2_RESTRICTION
    0x0069 => :pin2_restriction,
    # QMI_ERR_PUK_RESTRICTION
    0x006A => :puk_restriction,
    # QMI_ERR_PUK2_RESTRICTION
    0x006B => :puk2_restriction,
    # QMI_ERR_PB_ACCESS_RESTRICTED
    0x006C => :pb_access_restricted,
    # QMI_ERR_PB_DELETE_IN_PROG
    0x006D => :pb_delete_in_prog,
    # QMI_ERR_PB_TEXT_TOO_LONG
    0x006E => :pb_text_too_long,
    # QMI_ERR_PB_NUMBER_TOO_LONG
    0x006F => :pb_number_too_long,
    # QMI_ERR_PB_HIDDEN_KEY_RESTRICTION
    0x0070 => :pb_hidden_key_restriction,
    # QMI_ERR_PB_NOT_AVAILABLE
    0x0071 => :pb_not_available,
    # QMI_ERR_DEVICE_MEMORY_ERROR
    0x0072 => :device_memory_error,
    # QMI_ERR_NO_PERMISSION
    0x0073 => :no_permission,
    # QMI_ERR_TOO_SOON
    0x0074 => :too_soon,
    # QMI_ERR_TIME_NOT_ACQUIRED
    0x0075 => :time_not_acquired,
    # QMI_ERR_OP_IN_PROGRESS
    0x0076 => :op_in_progress,
    # QMI_ERR_FW_WRITE_FAILED
    0x0184 => :fw_write_failed,
    # QMI_ERR_FW_INFO_READ_FAILED
    0x0185 => :fw_info_read_failed,
    # QMI_ERR_FW_FILE_NOT_FOUND
    0x0186 => :fw_file_not_found,
    # QMI_ERR_FW_DIR_NOT_FOUND
    0x0187 => :fw_dir_not_found,
    # QMI_ERR_FW_ALREADY_ACTIVATED
    0x0188 => :fw_already_activated,
    # QMI_ERR_FW_CANNOT_GENERIC_IMAGE
    0x0189 => :fw_cannot_generic_image,
    # QMI_ERR_FW_FILE_OPEN_FAILED
    0x0190 => :fw_file_open_failed,
    # QMI_ERR_FW_UPDATE_DISCONTINOUS_FRAME
    0x0191 => :fw_update_discontinous_frame,
    # QMI_ERR_FW_UPDATE_FAILED
    0x0192 => :fw_update_failed
  }

  @spec decode_error_code(non_neg_integer()) :: atom()
  def decode_error_code(code) when is_integer(code) do
    @error_codes[code] || :unknown
  end

  def decode_error_code(code) when is_atom(code), do: code

  @spec decode_result_code(non_neg_integer()) :: :success | :failure | :unknown
  def decode_result_code(code) when is_integer(code) do
    case code do
      0 -> :success
      1 -> :failure
      _ -> :unknown
    end
  end

  def decode_result_code(code) when is_atom(code), do: code
end
