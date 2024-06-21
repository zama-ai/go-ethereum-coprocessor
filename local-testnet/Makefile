KMS_DEV_TAG = v0.3.3-pre-13
PRYSM_VERSION = v5.0.3
ROOT_DIR = $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
TEST_KEYS_PATH = ${ROOT_DIR}/fhevm-keys
TEMP_KEY_GEN = ./.temp_keygen
ifeq ($(shell uname),Darwin)
HOST_OS = darwin
else
HOST_OS = linux
endif
ifeq ($(shell uname -m),arm64)
HOST_ARCH = arm64
else
HOST_ARCH = amd64
endif
PRYSM_SUFFIX = $(HOST_OS)-$(HOST_ARCH)


${TEST_KEYS_PATH}/cks ${TEST_KEYS_PATH}/pks ${TEST_KEYS_PATH}/sks ${TEST_KEYS_PATH}/default-software-keys.bin:
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

# TODO: download different executables for linux
prysm-beacon:
	curl -L https://github.com/prysmaticlabs/prysm/releases/download/$(PRYSM_VERSION)/beacon-chain-$(PRYSM_VERSION)-$(PRYSM_SUFFIX) > prysm-beacon.tmp
	chmod +x prysm-beacon.tmp
	mv -f prysm-beacon.tmp prysm-beacon

prysm-validator:
	curl -L https://github.com/prysmaticlabs/prysm/releases/download/$(PRYSM_VERSION)/validator-$(PRYSM_VERSION)-$(PRYSM_SUFFIX) > prysm-validator.tmp
	chmod +x prysm-validator.tmp
	mv -f prysm-validator.tmp prysm-validator

.PHONY: gen-keys
gen-keys: ${TEST_KEYS_PATH}/cks ${TEST_KEYS_PATH}/pks ${TEST_KEYS_PATH}/sks ${TEST_KEYS_PATH}/default-software-keys.bin

.PHONY: clean
clean:
	rm -rf node*
	rm -rf ../bootnode
