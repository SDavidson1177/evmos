package keeper

import (
	"context"

	sdk "github.com/cosmos/cosmos-sdk/types"
	clienttypes "github.com/cosmos/ibc-go/v6/modules/core/02-client/types"
	"github.com/sdavidson1177/lotery/x/chat/types"
)

func (k msgServer) SendIbcChat(goCtx context.Context, msg *types.MsgSendIbcChat) (*types.MsgSendIbcChatResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)

	// TODO: logic before transmitting the packet

	// Construct the packet
	var packet types.IbcChatPacketData

	packet.Author = msg.Author
	packet.Message = msg.Message

	// Transmit the packet
	_, err := k.TransmitIbcChatPacket(
		ctx,
		packet,
		msg.Port,
		msg.ChannelID,
		clienttypes.ZeroHeight(),
		msg.TimeoutTimestamp,
	)
	if err != nil {
		return nil, err
	}

	return &types.MsgSendIbcChatResponse{}, nil
}
