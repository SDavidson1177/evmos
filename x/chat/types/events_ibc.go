package types

// IBC events
const (
	EventTypeTimeout       = "timeout"
	EventTypeIbcChatPacket = "ibcChat_packet"
	// this line is used by starport scaffolding # ibc/packet/event

	AttributeKeyAckSuccess = "success"
	AttributeKeyAck        = "acknowledgement"
	AttributeKeyAckError   = "error"
)
