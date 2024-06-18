#!/bin/sh

ACL_CONTRACT_ADDRESS='0x168813841d158Ea8508f91f71aF338e4cB4d396e'
COPROCESSOR_CONTRACT_ADDRESS='0x6819e3aDc437fAf9D533490eD3a7552493fCE3B1'
COPROCESSOR_ACCOUNT_ADDRESS='0xc9990FEfE0c27D31D0C2aa36196b085c0c4d456c'

# serve keys so fhevm-go-coproc library can download at initialization
python3 -m http.server -d /usr/share/devnet-resources/fhevm-keys 8000 &

geth init --datadir /val-data /usr/share/devnet-resources/genesis.json
geth init --datadir /rpc-data /usr/share/devnet-resources/genesis.json

echo Running bootnode
bootnode -nodekey /usr/share/devnet-resources/boot.key -addr :30305 &

echo Running RPC node
FHEVM_GO_INIT_CKS=1 \
	FHEVM_GO_SKS_URL=http://127.0.0.1:8000/sks \
	FHEVM_GO_PKS_URL=http://127.0.0.1:8000/pks \
	FHEVM_GO_CKS_URL=http://127.0.0.1:8000/cks \
	FORCE_TRANSIENT_STORAGE=true \
	FHEVM_GO_KEYS_DIR=/usr/share/devnet-resources/fhevm-keys \
	FHEVM_CIPHERTEXTS_DB=/rpc-data/fhevm_ciphertexts.sqlite \
	FHEVM_CONTRACT_ADDRESS=$COPROCESSOR_CONTRACT_ADDRESS \
	FHEVM_COPROCESSOR_PRIVATE_KEY_FILE=/rpc-data/coprocessor.key \
	FORCE_TRANSIENT_STORAGE=true \
	geth --datadir /rpc-data --port 30308 --http --http.addr 0.0.0.0 --http.port 8545 \
	--bootnodes 'enode://0b7b41ca480f0ef4e1b9fa7323c3ece8ed42cb161eef5bf580c737fe2f33787de25a0c212c0ac7fdb429216baa3342c9b5493bd03122527ffb4c8c114d87f0a6@127.0.0.1:0?discport=30305' \
	--authrpc.port 8553 &

echo Running Validator node
# validator node
echo '' | FORCE_TRANSIENT_STORAGE=true geth --datadir /val-data --port 30306 \
	--bootnodes 'enode://0b7b41ca480f0ef4e1b9fa7323c3ece8ed42cb161eef5bf580c737fe2f33787de25a0c212c0ac7fdb429216baa3342c9b5493bd03122527ffb4c8c114d87f0a6@127.0.0.1:0?discport=30305' \
	--networkid 12345 --unlock 0x1181A1FB7B6de97d4CB06Da82a0037DF1FFe32D0 \
	--authrpc.port 8551 --mine --miner.etherbase 0x1181A1FB7B6de97d4CB06Da82a0037DF1FFe32D0
