package keeper_test

import (
	"context"
	"testing"

	sdk "github.com/cosmos/cosmos-sdk/types"
	keepertest "github.com/sdavidson1177/lotery/testutil/keeper"
	"github.com/sdavidson1177/lotery/x/chat/keeper"
	"github.com/sdavidson1177/lotery/x/chat/types"
)

func setupMsgServer(t testing.TB) (types.MsgServer, context.Context) {
	k, ctx := keepertest.ChatKeeper(t)
	return keeper.NewMsgServerImpl(*k), sdk.WrapSDKContext(ctx)
}
