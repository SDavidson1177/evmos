MONIKER=moon
CHAINID="evmos_9000-6"
HOMEDIR="$HOME/.moon"
VALIDATOR="devmoon"
NODEADDR="tcp://localhost:26757"
GENESIS=$HOMEDIR/config/genesis.json
TMP_GENESIS=$HOMEDIR/config/tmp_genesis.json

rm -rf $HOMEDIR

# The argument $MONIKER is the custom username of your node, it should be human-readable.
evmosd config chain-id $CHAINID --home "$HOMEDIR"
evmosd config node $NODEADDR --home "$HOMEDIR"
evmosd keys add $VALIDATOR --output json --home $HOMEDIR > devmoon-key-info
evmosd keys add moonsolomon --home $HOMEDIR
evmosd init $MONIKER --chain-id=$CHAINID --home $HOMEDIR

# Change parameter token denominations to aevmos
jq '.app_state["staking"]["params"]["bond_denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["crisis"]["constant_fee"]["denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["evm"]["params"]["evm_denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["inflation"]["params"]["mint_denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

jq '.consensus_params["block"]["max_gas"]="10000000"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

evmosd add-genesis-account $VALIDATOR  100000000000000000000000000stake,100000000000000000000000000aevmos --home $HOMEDIR
evmosd add-genesis-account moonsolomon 100000000000000000000000000aevmos --home $HOMEDIR
evmosd gentx $VALIDATOR  1000000000000000000000aevmos --chain-id $CHAINID --home $HOMEDIR

evmosd collect-gentxs --home $HOMEDIR
evmosd validate-genesis --home $HOMEDIR

# copy over config
cp ./moon_config/app.toml "$HOMEDIR/config/app.toml"
cp ./moon_config/config.toml "$HOMEDIR/config/config.toml"

# hermes add keys
hermes --config config.toml keys delete --chain evmos_9000-6 --all
hermes --config config.toml keys add --hd-path "m/44'/60'/0'/0/0" --chain evmos_9000-6 --key-file devmoon-key-info

evmosd start --json-rpc.enable --home $HOMEDIR