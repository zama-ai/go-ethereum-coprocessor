#!/bin/sh

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ "$SCRIPT_DIR" != "$(pwd)" ];
then
	echo setup.sh script must be executed from its own working directory
	exit 1
fi

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
ps aux | grep bootnode | grep '\-nodekey' | grep -v grep | grep -v tmux | awk '{print $2}' | xargs kill
rm -rf node*

mkdir node1 node2 node3
# keys are generated like that
#$GETH --datadir node1 account new
#$GETH --datadir node2 account new
cp -r prep/node1/keystore node1/
cp -r prep/node2/keystore node2/
cp prep/coprocessor.key node3/
cp prep/genesis.json ./

$GETH init --datadir node1 genesis.json
$GETH init --datadir node2 genesis.json
$GETH init --datadir node3 genesis.json

cp prep/boot.key ./boot.key

# $BOOTNODE -genkey boot.key
tmux new -s bootnode -d "$BOOTNODE -nodekey boot.key -addr :30305"

# start the nodes
tmux new -s val1 -d "echo '' | FORCE_TRANSIENT_STORAGE=true $GETH --datadir node1 --port 30306 \
	--bootnodes 'enode://0b7b41ca480f0ef4e1b9fa7323c3ece8ed42cb161eef5bf580c737fe2f33787de25a0c212c0ac7fdb429216baa3342c9b5493bd03122527ffb4c8c114d87f0a6@127.0.0.1:0?discport=30305' \
	--networkid 12345 --unlock 0x1181A1FB7B6de97d4CB06Da82a0037DF1FFe32D0 \
	--authrpc.port 8551 --mine --miner.etherbase 0x1181A1FB7B6de97d4CB06Da82a0037DF1FFe32D0 2>&1 | tee node1/exec.log"

tmux new -s val2 -d "echo '' | FORCE_TRANSIENT_STORAGE=true $GETH --datadir node2 --port 30307 \
	--bootnodes 'enode://0b7b41ca480f0ef4e1b9fa7323c3ece8ed42cb161eef5bf580c737fe2f33787de25a0c212c0ac7fdb429216baa3342c9b5493bd03122527ffb4c8c114d87f0a6@127.0.0.1:0?discport=30305' \
	--networkid 12345 --unlock 0xc69587634CaF07DF2ab35893Ea35B9512F66b854 \
	--authrpc.port 8552 --mine --miner.etherbase 0xc69587634CaF07DF2ab35893Ea35B9512F66b854 2>&1 | tee node2/exec.log"

RPC_PARAMS="FORCE_TRANSIENT_STORAGE=true FHEVM_GO_INIT_CKS=1 FHEVM_GO_KEYS_DIR=fhevm-keys FHEVM_CIPHERTEXTS_DB=node3/fhevm_ciphertexts.sqlite FHEVM_CONTRACT_ADDRESS=$COPROCESSOR_CONTRACT_ADDRESS FHEVM_COPROCESSOR_PRIVATE_KEY_FILE=node3/coprocessor.key"

# rpc node
tmux new -s rpc1 -d "$RPC_PARAMS $GETH --datadir node3 --port 30308 --http --http.port 8745 \
	--gcmode archive --vmdebug --http.api \"eth,net,web3,debug\" \
	--bootnodes 'enode://0b7b41ca480f0ef4e1b9fa7323c3ece8ed42cb161eef5bf580c737fe2f33787de25a0c212c0ac7fdb429216baa3342c9b5493bd03122527ffb4c8c114d87f0a6@127.0.0.1:0?discport=30305' \
	--authrpc.port 8553 2>&1 | tee node3/exec.log"