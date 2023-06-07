package keeper

import (
	"encoding/binary"

	"github.com/cosmos/cosmos-sdk/store/prefix"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/sdavidson1177/lotery/x/chat/types"
)

// GetSenderCount get the total number of sender
func (k Keeper) GetSenderCount(ctx sdk.Context) uint64 {
	store := prefix.NewStore(ctx.KVStore(k.storeKey), []byte{})
	byteKey := types.KeyPrefix(types.SenderCountKey)
	bz := store.Get(byteKey)

	// Count doesn't exist: no element
	if bz == nil {
		return 0
	}

	// Parse bytes
	return binary.BigEndian.Uint64(bz)
}

// SetSenderCount set the total number of sender
func (k Keeper) SetSenderCount(ctx sdk.Context, count uint64) {
	store := prefix.NewStore(ctx.KVStore(k.storeKey), []byte{})
	byteKey := types.KeyPrefix(types.SenderCountKey)
	bz := make([]byte, 8)
	binary.BigEndian.PutUint64(bz, count)
	store.Set(byteKey, bz)
}

// AppendSender appends a sender in the store with a new id and update the count
func (k Keeper) AppendSender(
	ctx sdk.Context,
	sender types.Sender,
) uint64 {
	// Create the sender
	count := k.GetSenderCount(ctx)

	// Set the ID of the appended value
	sender.Id = count

	store := prefix.NewStore(ctx.KVStore(k.storeKey), types.KeyPrefix(types.SenderKey))
	appendedValue := k.cdc.MustMarshal(&sender)
	store.Set(GetSenderIDBytes(sender.Id), appendedValue)

	// Update sender count
	k.SetSenderCount(ctx, count+1)

	return count
}

// SetSender set a specific sender in the store
func (k Keeper) SetSender(ctx sdk.Context, sender types.Sender) {
	store := prefix.NewStore(ctx.KVStore(k.storeKey), types.KeyPrefix(types.SenderKey))
	b := k.cdc.MustMarshal(&sender)
	store.Set(GetSenderIDBytes(sender.Id), b)
}

// GetSender returns a sender from its id
func (k Keeper) GetSender(ctx sdk.Context, id uint64) (val types.Sender, found bool) {
	store := prefix.NewStore(ctx.KVStore(k.storeKey), types.KeyPrefix(types.SenderKey))
	b := store.Get(GetSenderIDBytes(id))
	if b == nil {
		return val, false
	}
	k.cdc.MustUnmarshal(b, &val)
	return val, true
}

// RemoveSender removes a sender from the store
func (k Keeper) RemoveSender(ctx sdk.Context, id uint64) {
	store := prefix.NewStore(ctx.KVStore(k.storeKey), types.KeyPrefix(types.SenderKey))
	store.Delete(GetSenderIDBytes(id))
}

// GetAllSender returns all sender
func (k Keeper) GetAllSender(ctx sdk.Context) (list []types.Sender) {
	store := prefix.NewStore(ctx.KVStore(k.storeKey), types.KeyPrefix(types.SenderKey))
	iterator := sdk.KVStorePrefixIterator(store, []byte{})

	defer iterator.Close()

	for ; iterator.Valid(); iterator.Next() {
		var val types.Sender
		k.cdc.MustUnmarshal(iterator.Value(), &val)
		list = append(list, val)
	}

	return
}

// GetSenderIDBytes returns the byte representation of the ID
func GetSenderIDBytes(id uint64) []byte {
	bz := make([]byte, 8)
	binary.BigEndian.PutUint64(bz, id)
	return bz
}

// GetSenderIDFromBytes returns ID in uint64 format from a byte array
func GetSenderIDFromBytes(bz []byte) uint64 {
	return binary.BigEndian.Uint64(bz)
}
