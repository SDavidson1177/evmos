#!/bin/bash

# Usage
USAGE="Usage: ./earth.sh <number of nodes> <ip address of node 0> [OPTIONS]\n
\tOptions:\n
\t\t--build \t Build the baton docker image\n
\t\t--help  \t\t Print help"

MONIKER=earth
CHAINID="evmos_9000-4"
HOMEDIR_PREFIX="$HOME/.earth"
VALIDATOR_PREFIX="devearth"
NUM_ARGS=1

# Check for help
# Perform option actions
counter=0
while [ $counter -le $# ]
do  
    if [ "${!counter}" = "--help" ]; then
        # Echo the help
        echo -e $USAGE
        exit 1
    fi
    ((counter++))
done

# Check for correct arguments
if [ $# -lt $NUM_ARGS ]; then
    echo "Invalid arguments"
    echo -e $USAGE
    exit 1
fi

# Create a validator for each of the nodes
VALIDATORS=()
HOMEDIRS=()
counter=0
while [ $counter -lt ${1} ];
do
   VALIDATORS+=("${VALIDATOR_PREFIX}${counter}")
   HOMEDIRS+=("${HOMEDIR_PREFIX}${counter}")
   ((counter++))
done

echo "${VALIDATORS[*]}"
echo "${HOMEDIRS[*]}"

PEERING_PORT="26656"
NODEADDR="tcp://localhost:26657"
GENESIS=${HOMEDIRS[0]}/config/genesis.json
TMP_GENESIS=${HOMEDIRS[0]}/config/tmp_genesis.json

# Create new info for each node
counter=0
while [ $counter -lt ${1} ]
do
    # Remove old data
    rm -rf "${HOMEDIRS[((${counter}))]}"

    evmosd config chain-id $CHAINID --home "${HOMEDIRS[((${counter}))]}"
    evmosd config node $NODEADDR --home "${HOMEDIRS[((${counter}))]}"
    evmosd keys add "${VALIDATORS[((${counter}))]}" --output json --home "${HOMEDIRS[((${counter}))]}"

    # The argument $MONIKER is the custom username of your node, it should be human-readable.
    evmosd init $MONIKER --chain-id=$CHAINID --home "${HOMEDIRS[((${counter}))]}"
    ((counter++))
done

# Choose only one of the genesis files to modify
# Change parameter token denominations to aevmos
jq '.app_state["staking"]["params"]["bond_denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["crisis"]["constant_fee"]["denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["evm"]["params"]["evm_denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["inflation"]["params"]["mint_denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

jq '.consensus_params["block"]["max_gas"]="10000000"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

# Copy the gensis file to all of the nodes other
counter=1
while [ $counter -lt ${1} ]
do
    cp "$GENESIS" "${HOMEDIRS[((${counter}))]}/config/genesis.json"
    ((counter++))
done

# Initialize genesis accounts and validators
counter=0
while [ $counter -lt ${1} ]
do
    evmosd add-genesis-account "${VALIDATORS[((${counter}))]}"  100000000000000000000000000stake,100000000000000000000000000aevmos --home "${HOMEDIRS[((${counter}))]}"
    evmosd gentx "${VALIDATORS[((${counter}))]}"   1000000000000000000000aevmos --chain-id $CHAINID --home "${HOMEDIRS[((${counter}))]}"

    evmosd collect-gentxs --home "${HOMEDIRS[((${counter}))]}"
    evmosd validate-genesis --home "${HOMEDIRS[((${counter}))]}"
    ((counter++))
done

# Get a seed so that other nodes can establish p2p connection
SEED=$(evmosd tendermint show-node-id --home "${HOMEDIRS[0]}")"@192.167.10.2:"${PEERING_PORT}

# Replace seed in all of the node config files
counter=0
while [ $counter -lt ${1} ]
do
    sed -i "s/seeds = .*/seeds = \"$SEED\"/g" "${HOMEDIRS[((${counter}))]}/config/config.toml"
    ((counter++))
done

# Perform option actions
counter=$(( $NUM_ARGS + 1 ))
echo $counter
while [ $counter -le $# ]
do  
    if [ "${!counter}" = "--build" ]; then
        # Build a new docker image
        docker build -t baton:latest .
    elif [ "${!counter}" = "--network" ]; then
        # Create bridge network
        docker network create --subnet 192.167.10.0/16 baton-net
    fi
    ((counter++))
done

# Start the containers
counter=0
while [ $counter -lt ${1} ]
do  
    docker container create --name "${VALIDATORS[((${counter}))]}" --volume "${HOMEDIRS[((${counter}))]}:/evmos" --network baton-net --ip "192.167.10.$(( $counter + 2 ))" baton:latest ./evmosd start --home /evmos
    docker container start "${VALIDATORS[((${counter}))]}"
    ((counter++))
done


# copy over config
# cp ./earth_config/app.toml "$HOMEDIR/config/app.toml"
# cp ./earth_config/config.toml "$HOMEDIR/config/config.toml"

# hermes add keys
# hermes --config config.toml keys delete --chain evmos_9000-4 --all
# hermes --config config.toml keys add --hd-path "m/44'/60'/0'/0/0" --chain evmos_9000-4 --key-file devearth-key-info

# evmosd start --json-rpc.enable --home $HOMEDIR