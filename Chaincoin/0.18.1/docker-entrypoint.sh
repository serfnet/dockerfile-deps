#!/bin/bash
set -e

if [[ "$1" == "chaincoin-cli" || "$1" == "chaincoin-tx" || "$1" == "chaincoind" || "$1" == "test_chaincoin" ]]; then
	mkdir -p "$BITCOIN_DATA"

	CONFIG_PREFIX=""
	if [[ "${BITCOIN_NETWORK}" == "regtest" ]]; then
		CONFIG_PREFIX=$'regtest=1\n[regtest]'
	fi
	if [[ "${BITCOIN_NETWORK}" == "testnet" ]]; then
		CONFIG_PREFIX=$'testnet=1\n[test]'
	fi
	if [[ "${BITCOIN_NETWORK}" == "mainnet" ]]; then
		CONFIG_PREFIX=$'mainnet=1\n[main]'
	fi

	cat <<-EOF > "$BITCOIN_DATA/chaincoin.conf"
	${CONFIG_PREFIX}
	printtoconsole=1
	rpcallowip=::/0
	${BITCOIN_EXTRA_ARGS}
	EOF
	chown bitcoin:bitcoin "$BITCOIN_DATA/chaincoin.conf"

	if [[ "${BITCOIN_TORCONTROL}" ]]; then
		# Because bitcoind only accept torcontrol= host as an ip only, we resolve it here and add to config
		TOR_CONTROL_HOST=$(echo ${BITCOIN_TORCONTROL} | cut -d ':' -f 1)
		TOR_CONTROL_PORT=$(echo ${BITCOIN_TORCONTROL} | cut -d ':' -f 2)
		if [[ "$TOR_CONTROL_HOST" ]] && [[ "$TOR_CONTROL_PORT" ]]; then
			TOR_IP=$(getent hosts $TOR_CONTROL_HOST | cut -d ' ' -f 1)
			echo "torcontrol=$TOR_IP:$TOR_CONTROL_PORT" >> "$BITCOIN_DATA/chaincoin.conf"
			echo "Added "torcontrol=$TOR_IP:$TOR_CONTROL_PORT" to $BITCOIN_DATA/chaincoin.conf"
		else
			echo "Invalid BITCOIN_TORCONTROL"
		fi
	fi

	# ensure correct ownership and linking of data directory
	# we do not update group ownership here, in case users want to mount
	# a host directory and still retain access to it
	chown -R bitcoin "$BITCOIN_DATA"
	ln -sfn "$BITCOIN_DATA" /home/bitcoin/.chaincoincore
	chown -h bitcoin:bitcoin /home/bitcoin/.chaincoincore

	exec gosu bitcoin "$@"
else
	exec "$@"
fi
