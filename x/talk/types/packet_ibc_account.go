package types

// ValidateBasic is used for validating the packet
func (p IbcAccountPacketData) ValidateBasic() error {

	// TODO: Validate the packet data

	return nil
}

// GetBytes is a helper for serialising
func (p IbcAccountPacketData) GetBytes() ([]byte, error) {
	var modulePacket TalkPacketData

	modulePacket.Packet = &TalkPacketData_IbcAccountPacket{&p}

	return modulePacket.Marshal()
}
