#!/bin/sh

VALIDATOR_ACCOUNT=${VALIDATOR_ACCOUNT:-0x1181a1fb7b6de97d4cb06da82a0037df1ffe32d0}
TARGET_ADDR=$1
AMOUNT=1000000000000000000

if [ -z "$TARGET_ADDR" ]
then
  echo Target address unspecified, exiting
  exit 1
fi

echo "eth.sendTransaction({from:\"$VALIDATOR_ACCOUNT\",to:\"$TARGET_ADDR\",value:\"$AMOUNT\"})" | \
  geth attach /val-data/geth.ipc
