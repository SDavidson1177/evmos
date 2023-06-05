package types

// IBC events
const (
	EventTypeTimeout          = "timeout"
	EventTypeIbcAccountPacket = "ibcAccount_packet"
	// this line is used by starport scaffolding # ibc/packet/event

	AttributeKeyAckSuccess = "success"
	AttributeKeyAck        = "acknowledgement"
	AttributeKeyAckError   = "error"
)
