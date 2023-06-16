hermes --config config.toml create channel --a-chain evmos_9000-4 --b-chain evmos_9000-5 --a-port transfer --b-port transfer --new-client-connection
hermes --config config.toml create channel --a-chain evmos_9000-4 --a-connection connection-0 --a-port chat --b-port chat --channel-version chat-1
hermes --config config.toml create channel --a-chain evmos_9000-5 --b-chain evmos_9000-6 --a-port transfer --b-port transfer --new-client-connection
hermes --config config.toml create channel --a-chain evmos_9000-6 --a-connection connection-0 --a-port chat --b-port chat --channel-version chat-1
hermes --config config.toml start