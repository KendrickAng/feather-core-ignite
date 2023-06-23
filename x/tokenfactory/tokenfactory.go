package tokenfactory

import (
	wasmvmtypes "github.com/CosmWasm/wasmvm/types"
)

// Dummy struct just to have a use for the wasmvm dependency
type ReflectMsgs struct {
	Msgs []wasmvmtypes.CosmosMsg `json:"msgs"`
}
