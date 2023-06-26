#!/bin/bash

# Usage: ./earth.sh <number of nodes>
USAGE="Usage: ./earth.sh <number of nodes>"

MONIKER=earth
CHAINID="evmos_9000-4"
HOMEDIR_PREFIX="$HOME/.earth"
VALIDATOR_PREFIX="devearth"

# Check for correct arguments
if [$# -le 1]; then
    echo $USAGE
    exit 1
fi

# Create a validator for each of the nodes
VALIDATORS=()
HOMEDIRS=()
counter=1
while [ $counter -le ${1} ]
do
   VALIDATORS+=("${VALIDATOR_PREFIX}${counter}")
   HOMEDIRS+=("${HOMEDIR_PREFIX}${counter}")
   ((counter++))
done

echo "${VALIDATORS[*]}"
echo "${HOMEDIRS[*]}"

NODEADDR="tcp://localhost:26657"
GENESIS=$HOMEDIR/config/genesis.json
TMP_GENESIS=$HOMEDIR/config/tmp_genesis.json

# Create new info for each node
counter=1
while [ $counter -le ${1} ]
do
    # Remove old data
    rm -rf "${HOMEDIRS[${counter}]}"

    evmosd config chain-id $CHAINID --home "${HOMEDIRS[((${counter} - 1))]}"
    evmosd config node $NODEADDR --home "${HOMEDIRS[((${counter} - 1))]}"
    evmosd keys add "${HOMEDIRS[((${counter} - 1))]}" --output json --home "${HOMEDIRS[((${counter} - 1))]}"

    # The argument $MONIKER is the custom username of your node, it should be human-readable.
    evmosd init $MONIKER --chain-id=$CHAINID --home "${HOMEDIRS[((${counter} - 1))]}"
    ((counter++))
done

exit 1

# Change parameter token denominations to aevmos
jq '.app_state["staking"]["params"]["bond_denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["crisis"]["constant_fee"]["denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["evm"]["params"]["evm_denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["inflation"]["params"]["mint_denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

jq '.consensus_params["block"]["max_gas"]="10000000"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

evmosd add-genesis-account $VALIDATOR  100000000000000000000000000stake,100000000000000000000000000aevmos --home $HOMEDIR
evmosd add-genesis-account $TESTACCOUNT 100000000000000000000000000aevmos --home $HOMEDIR
evmosd gentx $VALIDATOR  1000000000000000000000aevmos --chain-id $CHAINID --home $HOMEDIR

evmosd collect-gentxs --home $HOMEDIR
evmosd validate-genesis --home $HOMEDIR

# Get a seed so that other nodes can establish p2p connection
evmosd tendermint show-node-id --home $HOMEDIR

# copy over config
# cp ./earth_config/app.toml "$HOMEDIR/config/app.toml"
# cp ./earth_config/config.toml "$HOMEDIR/config/config.toml"

# hermes add keys
# hermes --config config.toml keys delete --chain evmos_9000-4 --all
# hermes --config config.toml keys add --hd-path "m/44'/60'/0'/0/0" --chain evmos_9000-4 --key-file devearth-key-info

# evmosd start --json-rpc.enable --home $HOMEDIR