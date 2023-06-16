package keeper

import (
	"errors"
	"fmt"

	sdk "github.com/cosmos/cosmos-sdk/types"
	sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"
	clienttypes "github.com/cosmos/ibc-go/v6/modules/core/02-client/types"
	channeltypes "github.com/cosmos/ibc-go/v6/modules/core/04-channel/types"
	host "github.com/cosmos/ibc-go/v6/modules/core/24-host"
	"github.com/sdavidson1177/lotery/x/chat/types"
)

// TransmitIbcChatPacket transmits the packet over IBC with the specified source port and source channel
func (k Keeper) TransmitIbcChatPacket(
	ctx sdk.Context,
	packetData types.IbcChatPacketData,
	sourcePort,
	sourceChannel string,
	timeoutHeight clienttypes.Height,
	timeoutTimestamp uint64,
) (uint64, error) {
	channelCap, ok := k.scopedKeeper.GetCapability(ctx, host.ChannelCapabilityPath(sourcePort, sourceChannel))
	if !ok {
		return 0, sdkerrors.Wrap(channeltypes.ErrChannelCapabilityNotFound, "module does not own channel capability")
	}

	packetBytes, err := packetData.GetBytes()
	if err != nil {
		return 0, sdkerrors.Wrapf(sdkerrors.ErrJSONMarshal, "cannot marshal the packet: %w", err)
	}

	test_headers := []channeltypes.MultiHopHeader{}
	test_headers = append(test_headers, channeltypes.MultiHopHeader{
		SourcePort:         "chat",
		SourceChannel:      "channel-3",
		DestinationPort:    "chat",
		DestinationChannel: "channel-3",
	})

	fmt.Println("HERE custom send")

	return k.channelKeeper.SendPacketMultiHop(ctx, channelCap, sourcePort, sourceChannel, timeoutHeight, timeoutTimestamp, packetBytes, 0, test_headers)
}

// OnRecvIbcChatPacket processes packet reception
func (k Keeper) OnRecvIbcChatPacket(ctx sdk.Context, packet channeltypes.Packet, data types.IbcChatPacketData) (packetAck types.IbcChatPacketAck, err error) {
	// validate packet data upon receiving
	if err := data.ValidateBasic(); err != nil {
		return packetAck, err
	}

	// Store the message in a list
	hist_obj := types.History{
		From:    data.Author,
		Message: data.Message,
	}
	k.AppendHistory(ctx, hist_obj)

	return packetAck, nil
}

// OnAcknowledgementIbcChatPacket responds to the the success or failure of a packet
// acknowledgement written on the receiving chain.
func (k Keeper) OnAcknowledgementIbcChatPacket(ctx sdk.Context, packet channeltypes.Packet, data types.IbcChatPacketData, ack channeltypes.Acknowledgement) error {
	switch dispatchedAck := ack.Response.(type) {
	case *channeltypes.Acknowledgement_Error:

		// TODO: failed acknowledgement logic
		_ = dispatchedAck.Error

		return nil
	case *channeltypes.Acknowledgement_Result:
		// Decode the packet acknowledgment
		var packetAck types.IbcChatPacketAck

		if err := types.ModuleCdc.UnmarshalJSON(dispatchedAck.Result, &packetAck); err != nil {
			// The counter-party module doesn't implement the correct acknowledgment format
			return errors.New("cannot unmarshal acknowledgment")
		}

		// TODO: successful acknowledgement logic

		return nil
	default:
		// The counter-party module doesn't implement the correct acknowledgment format
		return errors.New("invalid acknowledgment format")
	}
}

// OnTimeoutIbcChatPacket responds to the case where a packet has not been transmitted because of a timeout
func (k Keeper) OnTimeoutIbcChatPacket(ctx sdk.Context, packet channeltypes.Packet, data types.IbcChatPacketData) error {

	// TODO: packet timeout logic

	return nil
}
