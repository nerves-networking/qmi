defprotocol QMI.Response do
  def parse_tlvs(response, binary)
end
