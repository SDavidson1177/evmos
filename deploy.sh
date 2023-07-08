#!/bin/bash

# Help
HELP="Usage: ./deploy.sh [COMMAND]\n
\tCommands:\n
\t\tstart \t Start a blockchain\n
\t\tstop \t Stop a blockchain"

# Make sure a command is given
if [ $# -lt 1 ]; then
    echo "Missing commands"
    echo -e $HELP
    exit 0
fi

CMD=${1}

if [ $CMD = "start" ]; then
    # Usage
    USAGE="Usage: ./deploy.sh start <chain name> <number of nodes> <chain id integer> [OPTIONS]\n
    \tOptions:\n
    \t\t--build \t Build the baton docker image\n
    \t\t--help  \t\t Print help"

    NUM_ARGS=4

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

    MONIKER=${2}
    CHAINID_NUM="${4}"
    CHAINID="evmos_9000-${CHAINID_NUM}"
    HOMEDIR_PREFIX="$HOME/.${MONIKER}"
    VALIDATOR_PREFIX="dev${MONIKER}"
    MEMORY="./.memory-${MONIKER}"
    NUM_NODES=${3}

    # Create a validator for each of the nodes
    VALIDATORS=()
    HOMEDIRS=()
    counter=0
    while [ $counter -lt $NUM_NODES ];
    do
        VALIDATORS+=("${VALIDATOR_PREFIX}${counter}")
        HOMEDIRS+=("${HOMEDIR_PREFIX}${counter}")
        ((counter++))
    done

    echo "Validators: ${VALIDATORS[*]}"
    echo "Home Directories: ${HOMEDIRS[*]}"

    PEERING_PORT="26656"
    NODEADDR="tcp://localhost:26657"
    GENESIS=${HOMEDIRS[0]}/config/genesis.json
    TMP_GENESIS=${HOMEDIRS[0]}/config/tmp_genesis.json

    # Create new info for each node
    counter=0
    while [ $counter -lt $NUM_NODES ]
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

    # Initialize genesis accounts and validators
    counter=0
    while [ $counter -lt $NUM_NODES ]
    do
        evmosd add-genesis-account "${VALIDATORS[((${counter}))]}"  100000000000000000000000000stake,100000000000000000000000000aevmos --home "${HOMEDIRS[((${counter}))]}"
        evmosd gentx "${VALIDATORS[((${counter}))]}"   1000000000000000000000aevmos --chain-id $CHAINID --home "${HOMEDIRS[((${counter}))]}"

        evmosd collect-gentxs --home "${HOMEDIRS[((${counter}))]}"
        evmosd validate-genesis --home "${HOMEDIRS[((${counter}))]}"
        ((counter++))
    done

    # Copy the gensis file to all of the nodes other
    counter=0
    while [ $counter -lt $NUM_NODES ]
    do
        cp "$GENESIS" "${HOMEDIRS[((${counter}))]}/config/genesis.json"
        ((counter++))
    done

    # Get a seed so that other nodes can establish p2p connection
    SEED=$(evmosd tendermint show-node-id --home "${HOMEDIRS[0]}")"@192.255.${CHAINID_NUM}.2:"${PEERING_PORT}

    # Replace seed in all of the node config files
    counter=0
    while [ $counter -lt $NUM_NODES ]
    do
        sed -i "s/seeds = .*/seeds = \"$SEED\"/g" "${HOMEDIRS[((${counter}))]}/config/config.toml"
        ((counter++))
    done

    # Perform option actions
    counter=$(( $NUM_ARGS + 1 ))
    while [ $counter -le $# ]
    do  
        if [ "${!counter}" = "--build" ]; then
            # Build a new docker image
            docker build -t baton:latest .
        elif [ "${!counter}" = "--network" ]; then
            # Create bridge network
            docker network create --subnet "192.255.0.0/16" "baton-net"
        fi
        ((counter++))
    done

    # Start the containers
    echo "" > "${MEMORY}.txt"
    counter=0
    while [ $counter -lt $NUM_NODES ]
    do  
        docker container create --name "${VALIDATORS[((${counter}))]}" --volume "${HOMEDIRS[((${counter}))]}:/evmos" --network "baton-net" --ip "192.255.${CHAINID_NUM}.$(( $counter + 2 ))" baton:latest ./evmosd start --home /evmos
        docker container start "${VALIDATORS[((${counter}))]}" && echo "${VALIDATORS[((${counter}))]}" >> "${MEMORY}.txt"
        ((counter++))
    done
elif [ $CMD = "stop" ]; then
    # Usage
    USAGE="Usage: ./deploy.sh stop <chain name>"
    NUM_ARGS=2

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

    if [ -f "./.memory-${2}.txt" ]; then
        docker container stop $(cat "./.memory-${2}.txt")
        docker container remove $(cat "./.memory-${2}.txt")
    fi

    # Perform option actions
    counter=$(( $NUM_ARGS + 1 ))
    while [ $counter -le $# ]
    do  
        if [ "${!counter}" = "--network" ]; then
            # Create bridge network
            docker network remove "baton-net"
        fi
        ((counter++))
    done

    if [ -f "./.memory-${2}.txt" ]; then
        rm "./.memory-${2}.txt"
    fi
else
    echo "Invalid command: ${1}"
    echo -e $HELP
    exit 0
fi

# copy over config
# cp ./earth_config/app.toml "$HOMEDIR/config/app.toml"
# cp ./earth_config/config.toml "$HOMEDIR/config/config.toml"

# hermes add keys
# hermes --config config.toml keys delete --chain evmos_9000-4 --all
# hermes --config config.toml keys add --hd-path "m/44'/60'/0'/0/0" --chain evmos_9000-4 --key-file devearth-key-info

# evmosd start --json-rpc.enable --home $HOMEDIR