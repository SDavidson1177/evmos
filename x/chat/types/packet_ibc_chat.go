package types

// ValidateBasic is used for validating the packet
func (p IbcChatPacketData) ValidateBasic() error {

	// TODO: Validate the packet data

	return nil
}

// GetBytes is a helper for serialising
func (p IbcChatPacketData) GetBytes() ([]byte, error) {
	var modulePacket ChatPacketData

	modulePacket.Packet = &ChatPacketData_IbcChatPacket{&p}

	return modulePacket.Marshal()
}
