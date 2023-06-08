package types

import (
	"fmt"

	host "github.com/cosmos/ibc-go/v6/modules/core/24-host"
)

// DefaultIndex is the default global index
const DefaultIndex uint64 = 1

// DefaultGenesis returns the default genesis state
func DefaultGenesis() *GenesisState {
	return &GenesisState{
		PortId:     PortID,
		SenderList: []Sender{},
		// this line is used by starport scaffolding # genesis/types/default
		Params: DefaultParams(),
	}
}

// Validate performs basic genesis state validation returning an error upon any
// failure.
func (gs GenesisState) Validate() error {
	if err := host.PortIdentifierValidator(gs.PortId); err != nil {
		return err
	}
	// Check for duplicated ID in sender
	senderIdMap := make(map[uint64]bool)
	senderCount := gs.GetSenderCount()
	for _, elem := range gs.SenderList {
		if _, ok := senderIdMap[elem.Id]; ok {
			return fmt.Errorf("duplicated id for sender")
		}
		if elem.Id >= senderCount {
			return fmt.Errorf("sender id should be lower or equal than the last id")
		}
		senderIdMap[elem.Id] = true
	}

	// Check for duplicated ID in history
	historyIdMap := make(map[uint64]bool)
	historyCount := gs.GetHistoryCount()
	for _, elem := range gs.HistoryList {
		if _, ok := historyIdMap[elem.Id]; ok {
			return fmt.Errorf("duplicated id for history")
		}
		if elem.Id >= historyCount {
			return fmt.Errorf("history id should be lower or equal than the last id")
		}
		historyIdMap[elem.Id] = true
	}
	// this line is used by starport scaffolding # genesis/types/validate

	return gs.Params.Validate()
}
