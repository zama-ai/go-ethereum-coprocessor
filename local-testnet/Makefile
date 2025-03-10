KMS_DEV_TAG = 9b94bec
PRYSM_VERSION = v5.0.3
ROOT_DIR = $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
TEST_KEYS_PATH = ${ROOT_DIR}/fhevm-keys
TEMP_KEY_GEN = .temp_keygen
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


.PHONY: gen-keys
gen-keys:
	# make sure to have a fresh dir for keys
	rm -rf ${TEMP_KEY_GEN}
	mkdir ${TEMP_KEY_GEN}
	# start a kms that will generate keys
	docker run --entrypoint=/bin/sh --rm -v $(shell pwd)/${TEMP_KEY_GEN}:/keys ghcr.io/zama-ai/kms-service-dev:${KMS_DEV_TAG} \
		-c 'cd / && /app/kms/core/service/bin/kms-gen-keys centralized --param-path /app/kms/core/service/parameters/default_params.json --write-privkey'
	# move keys
	mkdir -p ${TEST_KEYS_PATH}
	mv -f ${TEMP_KEY_GEN}/PRIV/FhePrivateKey/04a1aa8ba5e95fb4dc42e06add00b0c2ce3ea424 ${TEST_KEYS_PATH}/cks
	mv -f ${TEMP_KEY_GEN}/PUB/ServerKey/04a1aa8ba5e95fb4dc42e06add00b0c2ce3ea424 ${TEST_KEYS_PATH}/sks
	mv -f ${TEMP_KEY_GEN}/PUB/PublicKey/04a1aa8ba5e95fb4dc42e06add00b0c2ce3ea424 ${TEST_KEYS_PATH}/pks
	# cleanup
	rm -rf ${TEMP_KEY_GEN}

prysm-beacon:
	curl -L https://github.com/prysmaticlabs/prysm/releases/download/$(PRYSM_VERSION)/beacon-chain-$(PRYSM_VERSION)-$(PRYSM_SUFFIX) > prysm-beacon.tmp
	chmod +x prysm-beacon.tmp
	mv -f prysm-beacon.tmp prysm-beacon

prysm-validator:
	curl -L https://github.com/prysmaticlabs/prysm/releases/download/$(PRYSM_VERSION)/validator-$(PRYSM_VERSION)-$(PRYSM_SUFFIX) > prysm-validator.tmp
	chmod +x prysm-validator.tmp
	mv -f prysm-validator.tmp prysm-validator

.PHONY: clean
clean:
	rm -rf node*
	rm -rf ../bootnode
