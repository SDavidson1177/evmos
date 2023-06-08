package keeper

import (
	"encoding/binary"

	"github.com/cosmos/cosmos-sdk/store/prefix"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/sdavidson1177/lotery/x/chat/types"
)

// GetHistoryCount get the total number of history
func (k Keeper) GetHistoryCount(ctx sdk.Context) uint64 {
	store := prefix.NewStore(ctx.KVStore(k.storeKey), []byte{})
	byteKey := types.KeyPrefix(types.HistoryCountKey)
	bz := store.Get(byteKey)

	// Count doesn't exist: no element
	if bz == nil {
		return 0
	}

	// Parse bytes
	return binary.BigEndian.Uint64(bz)
}

// SetHistoryCount set the total number of history
func (k Keeper) SetHistoryCount(ctx sdk.Context, count uint64) {
	store := prefix.NewStore(ctx.KVStore(k.storeKey), []byte{})
	byteKey := types.KeyPrefix(types.HistoryCountKey)
	bz := make([]byte, 8)
	binary.BigEndian.PutUint64(bz, count)
	store.Set(byteKey, bz)
}

// AppendHistory appends a history in the store with a new id and update the count
func (k Keeper) AppendHistory(
	ctx sdk.Context,
	history types.History,
) uint64 {
	// Create the history
	count := k.GetHistoryCount(ctx)

	// Set the ID of the appended value
	history.Id = count

	store := prefix.NewStore(ctx.KVStore(k.storeKey), types.KeyPrefix(types.HistoryKey))
	appendedValue := k.cdc.MustMarshal(&history)
	store.Set(GetHistoryIDBytes(history.Id), appendedValue)

	// Update history count
	k.SetHistoryCount(ctx, count+1)

	return count
}

// SetHistory set a specific history in the store
func (k Keeper) SetHistory(ctx sdk.Context, history types.History) {
	store := prefix.NewStore(ctx.KVStore(k.storeKey), types.KeyPrefix(types.HistoryKey))
	b := k.cdc.MustMarshal(&history)
	store.Set(GetHistoryIDBytes(history.Id), b)
}

// GetHistory returns a history from its id
func (k Keeper) GetHistory(ctx sdk.Context, id uint64) (val types.History, found bool) {
	store := prefix.NewStore(ctx.KVStore(k.storeKey), types.KeyPrefix(types.HistoryKey))
	b := store.Get(GetHistoryIDBytes(id))
	if b == nil {
		return val, false
	}
	k.cdc.MustUnmarshal(b, &val)
	return val, true
}

// RemoveHistory removes a history from the store
func (k Keeper) RemoveHistory(ctx sdk.Context, id uint64) {
	store := prefix.NewStore(ctx.KVStore(k.storeKey), types.KeyPrefix(types.HistoryKey))
	store.Delete(GetHistoryIDBytes(id))
}

// GetAllHistory returns all history
func (k Keeper) GetAllHistory(ctx sdk.Context) (list []types.History) {
	store := prefix.NewStore(ctx.KVStore(k.storeKey), types.KeyPrefix(types.HistoryKey))
	iterator := sdk.KVStorePrefixIterator(store, []byte{})

	defer iterator.Close()

	for ; iterator.Valid(); iterator.Next() {
		var val types.History
		k.cdc.MustUnmarshal(iterator.Value(), &val)
		list = append(list, val)
	}

	return
}

// GetHistoryIDBytes returns the byte representation of the ID
func GetHistoryIDBytes(id uint64) []byte {
	bz := make([]byte, 8)
	binary.BigEndian.PutUint64(bz, id)
	return bz
}

// GetHistoryIDFromBytes returns ID in uint64 format from a byte array
func GetHistoryIDFromBytes(bz []byte) uint64 {
	return binary.BigEndian.Uint64(bz)
}
