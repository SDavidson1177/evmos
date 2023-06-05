package keeper

import (
	"github.com/evmos/evmos/v12/x/talk/types"
)

var _ types.QueryServer = Keeper{}
