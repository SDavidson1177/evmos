#!/bin/bash

# Help
HELP="Usage: ./deploy.sh [COMMAND]\n
\tCommands:\n
\t\tstart \t Start a blockchain\n
\t\tstop \t Stop a blockchain\n
\t\trelayer \t Start a relayer"

# Make sure a command is given
if [ $# -lt 1 ]; then
    echo "Missing commands"
    echo -e $HELP
    exit 0
fi

CMD=${1}

DERIVATION_PATH="m/44'/60'/0'/0/0"

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
    HOMEDIR_PREFIX="./build/.${MONIKER}"
    VALIDATOR_PREFIX="dev${MONIKER}"
    MEMORY="./.memory-${MONIKER}"
    NUM_NODES=${3}

    # Create hermes directory
    if [ ! -d "./build/hermes" ]; then
        mkdir ./build/hermes
    fi

    # Template configuration for hermes
    HERMES_CHAIN_CONFIG="[[chains]]\n
        id = 'evmos_9000-6'\n
        grpc_addr = 'http://127.0.0.1:9190'\n
        rpc_addr = 'http://localhost:26757'\n
        websocket_addr = 'ws://127.0.0.1:26757/websocket'\n
        rpc_timeout = '15s'\n
        account_prefix = 'evmos'\n
        key_name = 'devmoon'\n
        address_type = { derivation = 'ethermint', proto_type = { pk_type = '/ethermint.crypto.v1.ethsecp256k1.PubKey' } }\n
        store_prefix = 'ibc'\n
        gas_price = { price = 1767812500, denom = 'aevmos' }\n
        gas_multiplier = 1.1\n
        max_gas = 3000000\n
        max_msg_num = 30\n
        max_tx_size = 2097152\n
        clock_drift = '5s'\n
        max_block_time = '30s'\n
        trusting_period = '14days'\n
        trust_threshold = { numerator = '2', denominator = '3' }\n"

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
    counter=$(( $NUM_NODES - 1 ))
    rm -rf "./build/hermes/hermes-${CHAINID_NUM}"
    mkdir "./build/hermes/hermes-${CHAINID_NUM}" # Directory that will store key files for this chain (for hermes relayer)
    while [ $counter -ge 0 ]
    do
        # Remove old data
        rm -rf "${HOMEDIRS[((${counter}))]}"

        ./build/evmosd config chain-id $CHAINID --keyring-backend test --home "${HOMEDIRS[((${counter}))]}"
        ./build/evmosd config node $NODEADDR --keyring-backend test --home "${HOMEDIRS[((${counter}))]}"
        ./build/evmosd keys add "${VALIDATORS[((${counter}))]}" --output json --keyring-backend test --home "${HOMEDIRS[((${counter}))]}" > "./build/hermes/hermes-${CHAINID_NUM}/rkey.json"

        # The argument $MONIKER is the custom username of your node, it should be human-readable.
        ./build/evmosd init $MONIKER --keyring-backend test --chain-id=$CHAINID --home "${HOMEDIRS[((${counter}))]}"
        ((counter--))
    done

    # Input hermes chain configuration data
    echo -e $HERMES_CHAIN_CONFIG > "./build/hermes/hermes-${CHAINID_NUM}/chain.toml"
    sed -i "s+rpc_addr =.*+rpc_addr = \'http://192.255.${CHAINID_NUM}.2:26657\'+g" "./build/hermes/hermes-${CHAINID_NUM}/chain.toml"
    sed -i "s+grpc_addr =.*+grpc_addr = \'http://192.255.${CHAINID_NUM}.2:9090\'+g" "./build/hermes/hermes-${CHAINID_NUM}/chain.toml"
    sed -i "s+id =.*+id = \'${CHAINID}\'+g" "./build/hermes/hermes-${CHAINID_NUM}/chain.toml"
    sed -i "s+websocket_addr =.*+websocket_addr = \'ws://192.255.${CHAINID_NUM}.2:26657/websocket\'+g" "./build/hermes/hermes-${CHAINID_NUM}/chain.toml"
    sed -i "s+key_name =.*+key_name = \'${VALIDATORS[0]}\'+g" "./build/hermes/hermes-${CHAINID_NUM}/chain.toml"

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
        ./build/evmosd add-genesis-account "${VALIDATORS[((${counter}))]}"  100000000000000000000000000stake,100000000000000000000000000aevmos --keyring-backend test --home "${HOMEDIRS[((${counter}))]}"
        ./build/evmosd gentx "${VALIDATORS[((${counter}))]}"   1000000000000000000000aevmos --chain-id $CHAINID --keyring-backend test --home "${HOMEDIRS[((${counter}))]}"

        ./build/evmosd collect-gentxs --keyring-backend test --home "${HOMEDIRS[((${counter}))]}"
        ./build/evmosd validate-genesis --keyring-backend test --home "${HOMEDIRS[((${counter}))]}"
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
    SEED=$(./build/evmosd tendermint show-node-id --keyring-backend test --home "${HOMEDIRS[0]}")"@192.255.${CHAINID_NUM}.2:"${PEERING_PORT}

    # Replace seed in all of the node config files
    counter=0
    while [ $counter -lt $NUM_NODES ]
    do
        sed -i "s/seeds = .*/seeds = \"$SEED\"/g" "${HOMEDIRS[((${counter}))]}/config/config.toml"
        sed -i "s+^laddr = .*tcp://.*\:+laddr = \"tcp://192.255.${CHAINID_NUM}.$(( $counter + 2 ))\:+g" "${HOMEDIRS[((${counter}))]}/config/config.toml"
        ((counter++))
    done

    # Perform option actions
    counter=$(( $NUM_ARGS + 1 ))
    while [ $counter -le $# ]
    do  
        if [ "${!counter}" = "--build" ]; then
            # Build a new docker image
            docker build -t baton:latest --file DockerfileChain .
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
        docker container create --name "${VALIDATORS[((${counter}))]}" --volume "${HOMEDIRS[((${counter}))]}:/evmos" --network "baton-net" --ip "192.255.${CHAINID_NUM}.$(( $counter + 2 ))" baton:latest ./evmosd start --keyring-backend test --home /evmos
        docker container start "${VALIDATORS[((${counter}))]}" && echo "${VALIDATORS[((${counter}))]}" >> "${MEMORY}.txt"
        ((counter++))
    done
elif [ $CMD = "stop" ]; then
    # Usage
    USAGE="Usage: ./deploy.sh stop <chain name> [OPTIONS]\n
    \tOptions:\n
    \t\t--network \t Remove network configuration (baton-net)"
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
elif [ $CMD = "relayer" ]; then
    # Usage
    USAGE="Usage: ./deploy.sh relayer <chain-1-id> <chain-1-port> <chain-2-id> <chain-2-port> <channel-version> [OPTIONS]\n
    \tOptions:\n
    \t\t--build \t Build the relayer image"
    NUM_ARGS=6

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

    # Set variables for channel parameters
    CA=${2}
    PA=${3}
    CB=${4}
    PB=${5}
    CV=${6}

    # Hermes configuration header
    HERMES_CONFIG_HEADER="[global]
log_level = 'error'

[mode]

[mode.clients]
enabled = true
refresh = true
misbehaviour = true

[mode.connections]
enabled = true

[mode.channels]
enabled = true

[mode.packets]
enabled = true
clear_interval = 100
clear_on_start = true
tx_confirmation = true

[telemetry]
enabled = true
host = '127.0.0.1'
port = 3001\n"

    # Perform option actions
    counter=$(( $NUM_ARGS + 1 ))
    while [ $counter -le $# ]
    do  
        if [ "${!counter}" = "--build" ]; then
            # Create bridge network
            docker build -t baton-relayer:latest --file DockerfileRelayer .
        fi
        ((counter++))
    done

    # Start the relayer container
    docker container create --name "baton-relayer" --volume "./build/hermes:/hermes/:Z" --network "baton-net" --ip "192.255.255.1" baton-relayer:latest
    docker container start "baton-relayer"

    # Initialize and start the connection
    docker exec baton-relayer /bin/bash -c "echo -e \"${HERMES_CONFIG_HEADER}\" > config.toml"
    docker exec baton-relayer /bin/bash -c "cat hermes/hermes-${CA}/chain.toml >> config.toml"
    docker exec baton-relayer /bin/bash -c "cat hermes/hermes-${CB}/chain.toml >> config.toml"
    docker exec baton-relayer /bin/bash -c "hermes --config config.toml keys add --hd-path \"${DERIVATION_PATH}\" --chain evmos_9000-${CA} --key-file \"hermes/hermes-${CA}/rkey.json\""
    docker exec baton-relayer /bin/bash -c "hermes --config config.toml keys add --hd-path \"${DERIVATION_PATH}\" --chain evmos_9000-${CB} --key-file \"hermes/hermes-${CB}/rkey.json\""

    # hermes --config config.toml create channel --a-chain evmos_9000-5 --b-chain evmos_9000-6 --a-port chat --b-port chat --channel-version chat-1 --new-client-connection
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