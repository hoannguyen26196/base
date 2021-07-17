#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error
set -e pipefail

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1
starttime=$(date +%s)
CC_SRC_LANGUAGE=golang
CC_RUNTIME_LANGUAGE=golang
CC_SRC_PATH=${PWD}/../chaincodes
CC_NAME=blockchain
ORG1=issuer
ORG2=holder

echo Vendoring Go dependencies ...
pushd ../chaincodes
GO111MODULE=on go mod vendor
popd
echo Finished vendoring Go dependencies

# launch network; create channel and join peer to channel

export PATH=${PWD}/../../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/../network

# import environment variables
. envVar.sh

echo "Packaging the marbles smart contract"

setGlobals 1

peer lifecycle chaincode package ${CC_NAME}.tar.gz  \
  --path $CC_SRC_PATH \
  --lang $CC_RUNTIME_LANGUAGE \
  --label ${CC_NAME}-cc

echo "Installing smart contract on peer0.${ORG1}.com"

peer lifecycle chaincode install ${CC_NAME}.tar.gz


setGlobals 2

peer lifecycle chaincode install ${CC_NAME}.tar.gz


echo "Installing smart contract on peer1.${ORG1}.com"


setGlobals 3

peer lifecycle chaincode install ${CC_NAME}.tar.gz

echo "Installing smart contract on peer0.${ORG2}.com"

setGlobals 4

peer lifecycle chaincode install ${CC_NAME}.tar.gz

echo "Installing smart contract on peer1.${ORG2}.com"

setGlobals 1

peer lifecycle chaincode queryinstalled >&log.txt

PACKAGE_ID=$(sed -n "/${CC_NAME}-cc/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
echo $PACKAGE_ID
echo "Approving the chaincode definition for ${ORG1}.com"

peer lifecycle chaincode approveformyorg \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.com \
    --channelID ${CC_NAME} \
    --name ${CC_NAME}-cc \
    --version 1.0 \
    --init-required \
    --signature-policy OutOf"(1,'${ORG1}.member')" \
    --sequence 1 \
    --package-id $PACKAGE_ID \
    --tls \
    --cafile ${ORDERER_CA}


echo "Approving the chaincode definition for ${ORG2}.com"

setGlobals 3

peer lifecycle chaincode approveformyorg \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.com \
    --channelID ${CC_NAME} \
    --name ${CC_NAME}-cc \
    --version 1.0 \
    --init-required \
    --signature-policy OutOf"(1,'${ORG1}.member')" \
    --sequence 1 \
    --package-id $PACKAGE_ID \
    --tls \
    --cafile ${ORDERER_CA}

echo "Checking if the chaincode definition is ready to commit"

peer lifecycle chaincode checkcommitreadiness \
    --channelID ${CC_NAME} \
    --name ${CC_NAME}-cc \
    --version 1.0 \
    --sequence 1 \
    --output json \
    --signature-policy OutOf"(1,'${ORG1}.member')" >&log.txt

rc=0
for var in "\"${ORG1}\": true" "\"${ORG2}\": true"
do
  grep "$var" log.txt &>/dev/null || let rc=1
done

if test $rc -eq 0; then
    echo "Chaincode definition is ready to commit"
else
  sleep 10
fi

parsePeerConnectionParameters 1 3

echo "Commit the chaincode definition to the channel"

peer lifecycle chaincode commit \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.com \
    --channelID ${CC_NAME} \
    --name ${CC_NAME}-cc \
    --version 1.0 \
    --init-required \
    --signature-policy OutOf"(1,'${ORG1}.member')" \
    --sequence 1 \
    --tls \
    --cafile ${ORDERER_CA} \
    $PEER_CONN_PARMS

echo "Check if the chaincode has been committed to the channel ..."

peer lifecycle chaincode querycommitted \
  --channelID ${CC_NAME} \
  --name ${CC_NAME}-cc >&log.txt

EXPECTED_RESULT="Version: 1.0, Sequence: 1, Endorsement Plugin: escc, Validation Plugin: vscc"
VALUE=$(grep -o "Version: 1.0, Sequence: 1, Endorsement Plugin: escc, Validation Plugin: vscc" log.txt)
echo "$VALUE"

if [ "$VALUE" = "Version: 1.0, Sequence: 1, Endorsement Plugin: escc, Validation Plugin: vscc" ] ; then
  echo "chaincode has been committed"
else
  sleep 10
fi

echo "invoke the chaincode init function ... "

peer chaincode invoke \
        -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.com \
        -C ${CC_NAME} \
        -n ${CC_NAME}-cc \
        --isInit \
        -c '{"function":"Init","Args":[""]}' \
        --tls \
        --cafile ${ORDERER_CA} \
        $PEER_CONN_PARMS
echo "$PEER_CONN_PARMS"
rm log.txt

cat <<EOF
Total setup execution time : $(($(date +%s) - starttime)) secs ...
EOF
