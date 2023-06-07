package keeper

import (
	"context"

	"github.com/cosmos/cosmos-sdk/store/prefix"
	sdk "github.com/cosmos/cosmos-sdk/types"
	sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"
	"github.com/cosmos/cosmos-sdk/types/query"
	"github.com/sdavidson1177/lotery/x/chat/types"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func (k Keeper) SenderAll(goCtx context.Context, req *types.QueryAllSenderRequest) (*types.QueryAllSenderResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}

	var senders []types.Sender
	ctx := sdk.UnwrapSDKContext(goCtx)

	store := ctx.KVStore(k.storeKey)
	senderStore := prefix.NewStore(store, types.KeyPrefix(types.SenderKey))

	pageRes, err := query.Paginate(senderStore, req.Pagination, func(key []byte, value []byte) error {
		var sender types.Sender
		if err := k.cdc.Unmarshal(value, &sender); err != nil {
			return err
		}

		senders = append(senders, sender)
		return nil
	})

	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}

	return &types.QueryAllSenderResponse{Sender: senders, Pagination: pageRes}, nil
}

func (k Keeper) Sender(goCtx context.Context, req *types.QueryGetSenderRequest) (*types.QueryGetSenderResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}

	ctx := sdk.UnwrapSDKContext(goCtx)
	sender, found := k.GetSender(ctx, req.Id)
	if !found {
		return nil, sdkerrors.ErrKeyNotFound
	}

	return &types.QueryGetSenderResponse{Sender: sender}, nil
}
