#!/usr/bin/make -f

ifndef $(GOPATH)
  GOPATH=$(shell go env GOPATH)
  export GOPATH
endif

LEDGER_ENABLED ?= true
BINDIR ?= $(GOPATH)/bin
BUILDDIR ?= $(CURDIR)/build
DOCKER := $(shell which docker)
COMMIT := $(shell git log -1 --format='%H')
VERSION := $(shell echo $(shell git describe --tags) | sed 's/^v//')
SDK_PACK := $(shell go list -m github.com/cosmos/cosmos-sdk | sed  's/ /\@/g')
GO_VERSION := $(shell cat go.mod | grep -E 'go [0-9].[0-9]+' | cut -d ' ' -f 2)
JQ := $(shell which jq)

export GO111MODULE = on

# ensure jq is installed

ifeq ($(JQ),)
  $(error "jq" is not installed. Please install it with your package manager.)
endif

# read feather config

FEATH_CONFIG := $(CURDIR)/config/mainnet/config.json

# these keys must match config/mainnet/config.json
KEY_APP_NAME=app_name
KEY_BOND_DENOM=bond_denom
KEY_APP_BINARY_NAME=app_binary_name
KEY_ACC_ADDR_PREFIX=account_address_prefix
KEY_ACC_PUBKEY_PREFIX=account_pubkey_prefix
KEY_VALIDATOR_ADDRESS_PREFIX=validator_address_prefix
KEY_VALIDATOR_PUBKEY_PREFIX=validator_pubkey_prefix
KEY_CONS_NODE_ADDR_PREFIX=consensus_node_address_prefix
KEY_CONS_NODE_PUBKEY_PREFIX=consensus_node_pubkey_prefix

# check that required keys are defined in config.json
HAS_APP_NAME := $(shell jq 'has("$(KEY_APP_NAME)")' $(FEATH_CONFIG))
HAS_BOND_DENOM := $(shell jq 'has("$(KEY_BOND_DENOM)")' $(FEATH_CONFIG))
HAS_APP_BINARY_NAME := $(shell jq 'has("$(KEY_APP_BINARY_NAME)")' $(FEATH_CONFIG))
HAS_ACC_ADDR_PREFIX := $(shell jq 'has("$(KEY_ACC_ADDR_PREFIX)")' $(FEATH_CONFIG))
HAS_ACC_PUBKEY_PREFIX := $(shell jq 'has("$(KEY_ACC_PUBKEY_PREFIX)")' $(FEATH_CONFIG))
HAS_VALIDATOR_ADDRESS_PREFIX := $(shell jq 'has("$(KEY_VALIDATOR_ADDRESS_PREFIX)")' $(FEATH_CONFIG))
HAS_VALIDATOR_PUBKEY_PREFIX := $(shell jq 'has("$(KEY_VALIDATOR_PUBKEY_PREFIX)")' $(FEATH_CONFIG))
HAS_CONS_NODE_ADDR_PREFIX := $(shell jq 'has("$(KEY_CONS_NODE_ADDR_PREFIX)")' $(FEATH_CONFIG))
HAS_CONS_NODE_PUBKEY_PREFIX := $(shell jq 'has("$(KEY_CONS_NODE_PUBKEY_PREFIX)")' $(FEATH_CONFIG))

ifeq ($(HAS_APP_NAME),false)
  $(error "$(FEATH_CONFIG) does not have key $(KEY_APP_NAME)")
endif
ifeq ($(HAS_BOND_DENOM),false)
  $(error "$(FEATH_CONFIG) does not have key $(KEY_BOND_DENOM)")
endif
ifeq ($(HAS_APP_BINARY_NAME),false)
  $(error "$(FEATH_CONFIG) does not have key $(KEY_APP_BINARY_NAME)")
endif
ifeq ($(HAS_ACC_ADDR_PREFIX),false)
  $(error "$(FEATH_CONFIG) does not have key $(KEY_ACC_ADDR_PREFIX)")
endif
ifeq ($(HAS_ACC_PUBKEY_PREFIX),false)
  $(error "$(FEATH_CONFIG) does not have key $(KEY_ACC_PUBKEY_PREFIX)")
endif
ifeq ($(HAS_VALIDATOR_ADDRESS_PREFIX),false)
  $(error "$(FEATH_CONFIG) does not have key $(KEY_VALIDATOR_ADDRESS_PREFIX)")
endif
ifeq ($(HAS_VALIDATOR_PUBKEY_PREFIX),false)
  $(error "$(FEATH_CONFIG) does not have key $(KEY_VALIDATOR_PUBKEY_PREFIX)")
endif
ifeq ($(HAS_CONS_NODE_ADDR_PREFIX),false)
  $(error "$(FEATH_CONFIG) does not have key $(KEY_CONS_NODE_ADDR_PREFIX)")
endif
ifeq ($(HAS_CONS_NODE_PUBKEY_PREFIX),false)
  $(error "$(FEATH_CONFIG) does not have key $(KEY_CONS_NODE_PUBKEY_PREFIX)")
endif

# retrieve key values, strip double quotes
FEATH_CONFIG_APP_NAME := $(patsubst "%",%,$(shell jq '.$(KEY_APP_NAME)' $(FEATH_CONFIG)))
FEATH_CONFIG_BOND_DENOM := $(patsubst "%",%,$(shell jq '.$(KEY_BOND_DENOM)' $(FEATH_CONFIG)))
FEATH_CONFIG_APP_BINARY_NAME := $(patsubst "%",%,$(shell jq '.$(KEY_APP_BINARY_NAME)' $(FEATH_CONFIG)))
FEATH_CONFIG_ACC_ADDR_PREFIX := $(patsubst "%",%,$(shell jq '.$(KEY_ACC_ADDR_PREFIX)' $(FEATH_CONFIG)))
FEATH_CONFIG_ACC_PUBKEY_PREFIX := $(patsubst "%",%,$(shell jq '.$(KEY_ACC_PUBKEY_PREFIX)' $(FEATH_CONFIG)))
FEATH_CONFIG_VALIDATOR_ADDRESS_PREFIX := $(patsubst "%",%,$(shell jq '.$(KEY_VALIDATOR_ADDRESS_PREFIX)' $(FEATH_CONFIG)))
FEATH_CONFIG_VALIDATOR_PUBKEY_PREFIX := $(patsubst "%",%,$(shell jq '.$(KEY_VALIDATOR_PUBKEY_PREFIX)' $(FEATH_CONFIG)))
FEATH_CONFIG_CONS_NODE_ADDR_PREFIX := $(patsubst "%",%,$(shell jq '.$(KEY_CONS_NODE_ADDR_PREFIX)' $(FEATH_CONFIG)))
FEATH_CONFIG_CONS_NODE_PUBKEY_PREFIX := $(patsubst "%",%,$(shell jq '.$(KEY_CONS_NODE_PUBKEY_PREFIX)' $(FEATH_CONFIG)))

# process build tags

build_tags = netgo

ifeq ($(WITH_CLEVELDB),yes)
  build_tags += gcc
endif
build_tags += $(BUILD_TAGS)
build_tags := $(strip $(build_tags))

whitespace :=
empty = $(whitespace) $(whitespace)
comma := ,
build_tags_comma_sep := $(subst $(empty),$(comma),$(build_tags))

# process linker flags

ldflags = -X github.com/cosmos/cosmos-sdk/version.Name=$(FEATH_CONFIG_APP_NAME) \
		  -X github.com/cosmos/cosmos-sdk/version.AppName=$(FEATH_CONFIG_APP_BINARY_NAME) \
		  -X github.com/cosmos/cosmos-sdk/version.Version=$(VERSION) \
		  -X github.com/cosmos/cosmos-sdk/version.Commit=$(COMMIT) \
		  -X "github.com/cosmos/cosmos-sdk/version.BuildTags=$(build_tags_comma_sep)" \
		  -X github.com/KendrickAng/feather-core-ignite/app.AppName=$(FEATH_CONFIG_APP_NAME) \
		  -X github.com/KendrickAng/feather-core-ignite/app.AccountAddressPrefix=$(FEATH_CONFIG_ACC_ADDR_PREFIX) \
		  -X github.com/KendrickAng/feather-core-ignite/app.AccountPubKeyPrefix=$(FEATH_CONFIG_ACC_PUBKEY_PREFIX) \
		  -X github.com/KendrickAng/feather-core-ignite/app.ValidatorAddressPrefix=$(FEATH_CONFIG_VALIDATOR_ADDRESS_PREFIX) \
		  -X github.com/KendrickAng/feather-core-ignite/app.ValidatorPubKeyPrefix=$(FEATH_CONFIG_VALIDATOR_PUBKEY_PREFIX) \
		  -X github.com/KendrickAng/feather-core-ignite/app.ConsensusNodeAddressPrefix=$(FEATH_CONFIG_CONS_NODE_ADDR_PREFIX) \
		  -X github.com/KendrickAng/feather-core-ignite/app.ConsensusNodePubKeyPrefix=$(FEATH_CONFIG_ACC_PUBKEY_PREFIX) \
		  -X github.com/KendrickAng/feather-core-ignite/app.BondDenom=$(FEATH_CONFIG_BOND_DENOM)

ifeq ($(WITH_CLEVELDB),yes)
  ldflags += -X github.com/cosmos/cosmos-sdk/types.DBBackend=cleveldb
endif
ifeq ($(LINK_STATICALLY),true)
	ldflags += -linkmode=external -extldflags "-Wl,-z,muldefs -static"
endif
ldflags += $(LDFLAGS)
ldflags := $(strip $(ldflags))

BUILD_FLAGS := -tags "$(build_tags_comma_sep)" -ldflags '$(ldflags)' -trimpath

install: go.sum
	echo $(BINDIR)
	go build -o $(BINDIR)/$(FEATH_CONFIG_APP_BINARY_NAME) -mod=readonly $(BUILD_FLAGS) ./cmd/feather-core-ignited

build: go.sum
ifeq ($(OS),Windows_NT)
	exit 1
else
	go build -mod=readonly $(BUILD_FLAGS) -o $(BUILDDIR)/feather-core-ignited ./cmd/feather-core-ignited
endif
