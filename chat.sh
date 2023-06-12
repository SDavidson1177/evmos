# Get devearth key on earth
export devearth=$(evmosd keys show --home ~/.earth devearth -a)

# send chat to mars
evmosd tx chat send-ibc-chat chat channel-1 "devearth" "A message from Earth!" --from $devearth --fees 5000000000000aevmos --home ~/.earth

# wait for blockchain to update
sleep 15

# show messages on mars
evmosd query chat list-history --home ~/.mars
