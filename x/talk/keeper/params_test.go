package keeper_test

import (
	"testing"

	testkeeper "github.com/evmos/evmos/v12/testutil/keeper"
	"github.com/evmos/evmos/v12/x/talk/types"
	"github.com/stretchr/testify/require"
)

func TestGetParams(t *testing.T) {
	k, ctx := testkeeper.TalkKeeper(t)
	params := types.DefaultParams()

	k.SetParams(ctx, params)

	require.EqualValues(t, params, k.GetParams(ctx))
}
