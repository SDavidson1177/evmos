hermes --config config.toml create channel --a-chain evmos_9000-4 --b-chain evmos_9000-5 --a-port transfer --b-port transfer --new-client-connection
hermes --config config.toml create channel --a-chain evmos_9000-4 --a-connection connection-0 --a-port chat --b-port chat --channel-version chat-1
hermes --config config.toml create channel --a-chain evmos_9000-5 --b-chain evmos_9000-6 --a-port transfer --b-port transfer --new-client-connection
hermes --config config.toml create channel --a-chain evmos_9000-6 --a-connection connection-0 --a-port chat --b-port chat --channel-version chat-1
hermes --config config.toml start

# Shoshin demo

# Token Transfer
# Change ibc v6.0.0
# evmosd tx ibc-transfer transfer transfer channel-0 evmos1dxkjxpzl8u2qvj6scync5cusud8z2ue7kzf5p8 5000000000000aevmos --from devearth --fees 1000000000000aevmos --home ~/.earth 
# evmosd query bank balances evmos1my8f93udvqctk7ueqh6rzdfmwd35pqvcem30e6 --home ~/.mars

# Multihop
# evmosd tx chat send-ibc-chat chat channel-1 "from" "to" --from evmos1h5y9f5atwnn4pzr08hrttdkysyjw54vhqm9rx6 --fees 5000000000aevmos --home ~/.earth
# evmosd query chat list-history --home ~/.moon