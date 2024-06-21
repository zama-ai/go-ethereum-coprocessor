#!/bin/sh

PRYSMCTL_IMAGE='gcr.io/prysmaticlabs/prysm/cmd/prysmctl@sha256:bae76f09edbaf8f56075c9e6848d9618fc412859571ec8ec2f4a0c79ade6b15e'

rm -f consensus/genesis.ssz

docker run \
	--name init_beacon_chain_genesis \
	-i --rm \
	-v $(pwd)/consensus:/consensus \
	-v $(pwd)/execution:/execution \
	$PRYSMCTL_IMAGE -- \
  testnet \
  generate-genesis \
  --fork=capella \
  --num-validators=64 \
  --genesis-time-delay=15 \
  --output-ssz=/consensus/genesis.ssz \
  --chain-config-file=/consensus/config.yml \
  --geth-genesis-json-in=/execution/genesis.json \
  --geth-genesis-json-out=/execution/genesis.out.json
