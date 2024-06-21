#!/bin/sh

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ "$SCRIPT_DIR" != "$(pwd)" ];
then
	echo setup.sh script must be executed from its own working directory
	exit 1
fi

make -j4 prysm-validator prysm-beacon

pushd ..
make geth
go build ./cmd/bootnode
popd

make gen-keys

# build with 'make geth' in root directory
GETH=../build/bin/geth
# build with 'go build ./cmd/bootnode' in root directory
BOOTNODE=../bootnode

ACL_CONTRACT_ADDRESS='0x168813841d158Ea8508f91f71aF338e4cB4d396e'
COPROCESSOR_CONTRACT_ADDRESS='0x6819e3aDc437fAf9D533490eD3a7552493fCE3B1'
COPROCESSOR_ACCOUNT_ADDRESS='0xc9990FEfE0c27D31D0C2aa36196b085c0c4d456c'

ps aux | grep geth | grep -v grep | awk '{print $2}' | xargs kill
ps aux | grep prysm-beacon | grep -v grep | awk '{print $2}' | xargs kill
ps aux | grep prysm-validator | grep -v grep | awk '{print $2}' | xargs kill
ps aux | grep bootnode | grep '\-nodekey' | grep -v grep | grep -v tmux | awk '{print $2}' | xargs kill
rm -rf node*

#exit

pushd prep
./generate-beacon-genesis.sh
popd

mkdir node-val1 node-rpc1
# keys are generated like that
#$GETH --datadir node-val1 account new
cp -r prep/node1/keystore node-val1/
cp prep/coprocessor.key node-rpc1/
cp -r prep/consensus node-val1/
mkdir -p node-val1/consensus/beacondata/
cp prep/consensus/validator-beacon-static-network-keys node-val1/consensus/beacondata/network-keys
cp -r prep/consensus node-rpc1/

STATE_SCHEME='--state.scheme=hash'

$GETH init $STATE_SCHEME --datadir node-val1 prep/execution/genesis.out.json
$GETH init $STATE_SCHEME --datadir node-rpc1 prep/execution/genesis.out.json

cp prep/boot.key ./boot.key

# $BOOTNODE -genkey boot.key
tmux new -s bootnode -d "$BOOTNODE -nodekey boot.key -addr :30305"

# start the validator nodes
NODE_DIR=node-val1
tmux new -s exec-val1 -d "echo '' | FORCE_TRANSIENT_STORAGE=true $GETH $STATE_SCHEME --datadir $NODE_DIR --port 30306 \
	--bootnodes 'enode://0b7b41ca480f0ef4e1b9fa7323c3ece8ed42cb161eef5bf580c737fe2f33787de25a0c212c0ac7fdb429216baa3342c9b5493bd03122527ffb4c8c114d87f0a6@127.0.0.1:0?discport=30305' \
	--networkid 12345 --unlock 0x1181A1FB7B6de97d4CB06Da82a0037DF1FFe32D0 \
	--authrpc.port 8551 --mine --miner.etherbase 0x1181A1FB7B6de97d4CB06Da82a0037DF1FFe32D0 2>&1 | tee $NODE_DIR/exec.log"

tmux new -s beac-val1 -d "./prysm-beacon --datadir=$NODE_DIR/consensus/beacondata \
	--p2p-static-id \
	--p2p-host-ip=127.0.0.1 \
	--p2p-local-ip=127.0.0.1 \
	--p2p-tcp-port=13000 \
	--p2p-udp-port=12000 \
	--rpc-port=4000 \
	--grpc-gateway-port=3500 \
	--min-sync-peers=0 \
	--genesis-state=$NODE_DIR/consensus/genesis.ssz \
	--bootstrap-node= \
	--interop-eth1data-votes \
	--chain-config-file=$NODE_DIR/consensus/config.yml \
	--contract-deployment-block=0 \
	--chain-id=12345 \
	--rpc-host=127.0.0.1 \
	--grpc-gateway-host=127.0.0.1 \
	--execution-endpoint=$NODE_DIR/geth.ipc \
	--accept-terms-of-use \
	--suggested-fee-recipient=0x123463a4b065722e99115d6c222f267d9cabb524 \
	--minimum-peers-per-subnet=0 \
	--enable-debug-rpc-endpoints \
	--force-clear-db \
	2>&1 | tee $NODE_DIR/beacon.log"

echo Sleeping few seconds before starting validator...
sleep 5
NODE_DIR=node-val1
tmux new -s val-val1 -d "./prysm-validator --datadir=$NODE_DIR/consensus/validatordata \
	--beacon-rpc-provider=127.0.0.1:4000 \
	--accept-terms-of-use \
	--interop-num-validators=64 \
	--interop-start-index=0 \
	--chain-config-file=$NODE_DIR/consensus/config.yml \
	--force-clear-db \
	2>&1 | tee $NODE_DIR/validator.log"

NODE_DIR=node-rpc1
RPC_PARAMS="FORCE_TRANSIENT_STORAGE=true FHEVM_GO_INIT_CKS=1 FHEVM_GO_KEYS_DIR=fhevm-keys FHEVM_CIPHERTEXTS_DB=$NODE_DIR/fhevm_ciphertexts.sqlite FHEVM_CONTRACT_ADDRESS=$COPROCESSOR_CONTRACT_ADDRESS FHEVM_COPROCESSOR_PRIVATE_KEY_FILE=$NODE_DIR/coprocessor.key"

# rpc node
tmux new -s exec-rpc1 -d "$RPC_PARAMS $GETH $STATE_SCHEME --datadir $NODE_DIR --port 30308 --http --http.port 8745 \
	--gcmode archive --vmdebug --http.api \"eth,net,web3,debug\" \
	--bootnodes 'enode://0b7b41ca480f0ef4e1b9fa7323c3ece8ed42cb161eef5bf580c737fe2f33787de25a0c212c0ac7fdb429216baa3342c9b5493bd03122527ffb4c8c114d87f0a6@127.0.0.1:0?discport=30305' \
	--authrpc.port 8553 2>&1 | tee $NODE_DIR/exec.log"

tmux new -s beac-rpc1 -d "./prysm-beacon --datadir=$NODE_DIR/consensus/beacondata \
	--peer=/ip4/127.0.0.1/tcp/13000/p2p/16Uiu2HAmVLcAYZGTyHjgGReWL28tsqnPz8FExJZgjMvGcvToXfWH \
	--p2p-host-ip=127.0.0.1 \
	--p2p-local-ip=127.0.0.1 \
	--p2p-tcp-port=13001 \
	--p2p-udp-port=12001 \
	--rpc-port=4001 \
	--grpc-gateway-port=3501 \
	--min-sync-peers=1 \
	--genesis-state=$NODE_DIR/consensus/genesis.ssz \
	--bootstrap-node= \
	--interop-eth1data-votes \
	--chain-config-file=$NODE_DIR/consensus/config.yml \
	--contract-deployment-block=0 \
	--chain-id=12345 \
	--rpc-host=127.0.0.1 \
	--grpc-gateway-host=127.0.0.1 \
	--execution-endpoint=$NODE_DIR/geth.ipc \
	--accept-terms-of-use \
	--suggested-fee-recipient=0x123463a4b065722e99115d6c222f267d9cabb524 \
	--minimum-peers-per-subnet=1 \
	--enable-debug-rpc-endpoints \
	--force-clear-db \
	2>&1 | tee $NODE_DIR/beacon.log"
