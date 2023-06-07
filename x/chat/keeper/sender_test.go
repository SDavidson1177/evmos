package keeper_test

import (
	"testing"

	sdk "github.com/cosmos/cosmos-sdk/types"
	keepertest "github.com/sdavidson1177/lotery/testutil/keeper"
	"github.com/sdavidson1177/lotery/testutil/nullify"
	"github.com/sdavidson1177/lotery/x/chat/keeper"
	"github.com/sdavidson1177/lotery/x/chat/types"
	"github.com/stretchr/testify/require"
)

func createNSender(keeper *keeper.Keeper, ctx sdk.Context, n int) []types.Sender {
	items := make([]types.Sender, n)
	for i := range items {
		items[i].Id = keeper.AppendSender(ctx, items[i])
	}
	return items
}

func TestSenderGet(t *testing.T) {
	keeper, ctx := keepertest.ChatKeeper(t)
	items := createNSender(keeper, ctx, 10)
	for _, item := range items {
		got, found := keeper.GetSender(ctx, item.Id)
		require.True(t, found)
		require.Equal(t,
			nullify.Fill(&item),
			nullify.Fill(&got),
		)
	}
}

func TestSenderRemove(t *testing.T) {
	keeper, ctx := keepertest.ChatKeeper(t)
	items := createNSender(keeper, ctx, 10)
	for _, item := range items {
		keeper.RemoveSender(ctx, item.Id)
		_, found := keeper.GetSender(ctx, item.Id)
		require.False(t, found)
	}
}

func TestSenderGetAll(t *testing.T) {
	keeper, ctx := keepertest.ChatKeeper(t)
	items := createNSender(keeper, ctx, 10)
	require.ElementsMatch(t,
		nullify.Fill(items),
		nullify.Fill(keeper.GetAllSender(ctx)),
	)
}

func TestSenderCount(t *testing.T) {
	keeper, ctx := keepertest.ChatKeeper(t)
	items := createNSender(keeper, ctx, 10)
	count := uint64(len(items))
	require.Equal(t, count, keeper.GetSenderCount(ctx))
}
