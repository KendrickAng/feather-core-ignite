package feathercoreignite_test

import (
	"testing"

	keepertest "github.com/KendrickAng/feather-core-ignite/testutil/keeper"
	"github.com/KendrickAng/feather-core-ignite/testutil/nullify"
	"github.com/KendrickAng/feather-core-ignite/x/feathercoreignite"
	"github.com/KendrickAng/feather-core-ignite/x/feathercoreignite/types"
	"github.com/stretchr/testify/require"
)

func TestGenesis(t *testing.T) {
	genesisState := types.GenesisState{
		Params: types.DefaultParams(),

		// this line is used by starport scaffolding # genesis/test/state
	}

	k, ctx := keepertest.FeathercoreigniteKeeper(t)
	feathercoreignite.InitGenesis(ctx, *k, genesisState)
	got := feathercoreignite.ExportGenesis(ctx, *k)
	require.NotNil(t, got)

	nullify.Fill(&genesisState)
	nullify.Fill(got)

	// this line is used by starport scaffolding # genesis/test/assert
}
