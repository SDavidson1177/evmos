package keeper

import (
	"context"

	sdk "github.com/cosmos/cosmos-sdk/types"
	clienttypes "github.com/cosmos/ibc-go/v6/modules/core/02-client/types"
	"github.com/evmos/evmos/v12/x/talk/types"
)

func (k msgServer) SendIbcAccount(goCtx context.Context, msg *types.MsgSendIbcAccount) (*types.MsgSendIbcAccountResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)

	// TODO: logic before transmitting the packet

	// Construct the packet
	var packet types.IbcAccountPacketData

	packet.Account = msg.Account

	// Transmit the packet
	_, err := k.TransmitIbcAccountPacket(
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

	return &types.MsgSendIbcAccountResponse{}, nil
}
