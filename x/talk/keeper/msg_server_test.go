package keeper_test

import (
	"context"
	"testing"

	sdk "github.com/cosmos/cosmos-sdk/types"
	keepertest "github.com/evmos/evmos/v12/testutil/keeper"
	"github.com/evmos/evmos/v12/x/talk/keeper"
	"github.com/evmos/evmos/v12/x/talk/types"
)

func setupMsgServer(t testing.TB) (types.MsgServer, context.Context) {
	k, ctx := keepertest.TalkKeeper(t)
	return keeper.NewMsgServerImpl(*k), sdk.WrapSDKContext(ctx)
}
