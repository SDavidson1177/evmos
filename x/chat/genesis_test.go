package chat_test

import (
	"testing"

	keepertest "github.com/sdavidson1177/lotery/testutil/keeper"
	"github.com/sdavidson1177/lotery/testutil/nullify"
	"github.com/sdavidson1177/lotery/x/chat"
	"github.com/sdavidson1177/lotery/x/chat/types"
	"github.com/stretchr/testify/require"
)

func TestGenesis(t *testing.T) {
	genesisState := types.GenesisState{
		Params: types.DefaultParams(),
		PortId: types.PortID,
		SenderList: []types.Sender{
			{
				Id: 0,
			},
			{
				Id: 1,
			},
		},
		SenderCount: 2,
		// this line is used by starport scaffolding # genesis/test/state
	}

	k, ctx := keepertest.ChatKeeper(t)
	chat.InitGenesis(ctx, *k, genesisState)
	got := chat.ExportGenesis(ctx, *k)
	require.NotNil(t, got)

	nullify.Fill(&genesisState)
	nullify.Fill(got)

	require.Equal(t, genesisState.PortId, got.PortId)

	require.ElementsMatch(t, genesisState.SenderList, got.SenderList)
	require.Equal(t, genesisState.SenderCount, got.SenderCount)
	// this line is used by starport scaffolding # genesis/test/assert
}
