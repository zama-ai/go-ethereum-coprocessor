KMS_DEV_TAG = v0.3.3-pre-13
ROOT_DIR = $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
TEST_KEYS_PATH = ${ROOT_DIR}/fhevm-keys
TEMP_KEY_GEN = ./.temp_keygen

${TEST_KEYS_PATH}/cks ${TEST_KEYS_PATH}/pks ${TEST_KEYS_PATH}/sks ${TEST_KEYS_PATH}/default-software-keys:
	# make sure to have a fresh dir for keys
	rm -rf ${TEMP_KEY_GEN}
	mkdir ${TEMP_KEY_GEN}
	# start a kms that will generate keys
	docker run --rm -v ${ROOT_DIR}/${TEMP_KEY_GEN}:/keys ghcr.io/zama-ai/kms-dev:${KMS_DEV_TAG} /app/kms/bin/kms-gen /keys/
	# move keys
	mkdir -p ${TEST_KEYS_PATH}
	cp ${TEMP_KEY_GEN}/default-software-keys.bin ${TEST_KEYS_PATH}
	cp ${TEMP_KEY_GEN}/cks.bin ${TEST_KEYS_PATH}/cks
	cp ${TEMP_KEY_GEN}/cks.bin ${TEST_KEYS_PATH}/cks.bin
	cp ${TEMP_KEY_GEN}/sks.bin ${TEST_KEYS_PATH}/sks
	cp ${TEMP_KEY_GEN}/pks.bin ${TEST_KEYS_PATH}/pks
	# clean
	rm -rf ${TEMP_KEY_GEN}

.PHONY: gen-keys
gen-keys: ${TEST_KEYS_PATH}/cks ${TEST_KEYS_PATH}/pks ${TEST_KEYS_PATH}/sks ${TEST_KEYS_PATH}/default-software-keys.bin

.PHONY: clean
clean:
	rm -rf node1
	rm -rf ../node1
	rm -rf node2
	rm -rf ../node2
	rm -rf node3
	rm -rf ../node3
	rm -rf ../bootnode
	rm genesis.json