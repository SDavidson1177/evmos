package keeper_test

import (
	"testing"

	sdk "github.com/cosmos/cosmos-sdk/types"
	sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"
	"github.com/cosmos/cosmos-sdk/types/query"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	keepertest "github.com/sdavidson1177/lotery/testutil/keeper"
	"github.com/sdavidson1177/lotery/testutil/nullify"
	"github.com/sdavidson1177/lotery/x/chat/types"
)

func TestSenderQuerySingle(t *testing.T) {
	keeper, ctx := keepertest.ChatKeeper(t)
	wctx := sdk.WrapSDKContext(ctx)
	msgs := createNSender(keeper, ctx, 2)
	for _, tc := range []struct {
		desc     string
		request  *types.QueryGetSenderRequest
		response *types.QueryGetSenderResponse
		err      error
	}{
		{
			desc:     "First",
			request:  &types.QueryGetSenderRequest{Id: msgs[0].Id},
			response: &types.QueryGetSenderResponse{Sender: msgs[0]},
		},
		{
			desc:     "Second",
			request:  &types.QueryGetSenderRequest{Id: msgs[1].Id},
			response: &types.QueryGetSenderResponse{Sender: msgs[1]},
		},
		{
			desc:    "KeyNotFound",
			request: &types.QueryGetSenderRequest{Id: uint64(len(msgs))},
			err:     sdkerrors.ErrKeyNotFound,
		},
		{
			desc: "InvalidRequest",
			err:  status.Error(codes.InvalidArgument, "invalid request"),
		},
	} {
		t.Run(tc.desc, func(t *testing.T) {
			response, err := keeper.Sender(wctx, tc.request)
			if tc.err != nil {
				require.ErrorIs(t, err, tc.err)
			} else {
				require.NoError(t, err)
				require.Equal(t,
					nullify.Fill(tc.response),
					nullify.Fill(response),
				)
			}
		})
	}
}

func TestSenderQueryPaginated(t *testing.T) {
	keeper, ctx := keepertest.ChatKeeper(t)
	wctx := sdk.WrapSDKContext(ctx)
	msgs := createNSender(keeper, ctx, 5)

	request := func(next []byte, offset, limit uint64, total bool) *types.QueryAllSenderRequest {
		return &types.QueryAllSenderRequest{
			Pagination: &query.PageRequest{
				Key:        next,
				Offset:     offset,
				Limit:      limit,
				CountTotal: total,
			},
		}
	}
	t.Run("ByOffset", func(t *testing.T) {
		step := 2
		for i := 0; i < len(msgs); i += step {
			resp, err := keeper.SenderAll(wctx, request(nil, uint64(i), uint64(step), false))
			require.NoError(t, err)
			require.LessOrEqual(t, len(resp.Sender), step)
			require.Subset(t,
				nullify.Fill(msgs),
				nullify.Fill(resp.Sender),
			)
		}
	})
	t.Run("ByKey", func(t *testing.T) {
		step := 2
		var next []byte
		for i := 0; i < len(msgs); i += step {
			resp, err := keeper.SenderAll(wctx, request(next, 0, uint64(step), false))
			require.NoError(t, err)
			require.LessOrEqual(t, len(resp.Sender), step)
			require.Subset(t,
				nullify.Fill(msgs),
				nullify.Fill(resp.Sender),
			)
			next = resp.Pagination.NextKey
		}
	})
	t.Run("Total", func(t *testing.T) {
		resp, err := keeper.SenderAll(wctx, request(nil, 0, 0, true))
		require.NoError(t, err)
		require.Equal(t, len(msgs), int(resp.Pagination.Total))
		require.ElementsMatch(t,
			nullify.Fill(msgs),
			nullify.Fill(resp.Sender),
		)
	})
	t.Run("InvalidRequest", func(t *testing.T) {
		_, err := keeper.SenderAll(wctx, nil)
		require.ErrorIs(t, err, status.Error(codes.InvalidArgument, "invalid request"))
	})
}
