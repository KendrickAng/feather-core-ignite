package keeper_test

import (
	"testing"

	testkeeper "github.com/KendrickAng/feather-core-ignite/testutil/keeper"
	"github.com/KendrickAng/feather-core-ignite/x/feathercoreignite/types"
	"github.com/stretchr/testify/require"
)

func TestGetParams(t *testing.T) {
	k, ctx := testkeeper.FeathercoreigniteKeeper(t)
	params := types.DefaultParams()

	k.SetParams(ctx, params)

	require.EqualValues(t, params, k.GetParams(ctx))
}
