#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts

source scriptUtils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer.com/msp/tlscacerts/tlsca.com-cert.pem
export PEER0_issuer_CA=${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer0.issuer.com/tls/ca.crt
export PEER1_issuer_CA=${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer1.issuer.com/tls/ca.crt

export PEER0_holder_CA=${PWD}/../organizations/peerOrganizations/holder.com/peers/peer0.holder.com/tls/ca.crt
export PEER1_holder_CA=${PWD}/../organizations/peerOrganizations/holder.com/peers/peer1.holder.com/tls/ca.crt


# Set OrdererOrg.Admin globals
setOrdererGlobals() {
  export CORE_PEER_LOCALMSPID="ordererMSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer.com/msp/tlscacerts/tlsca.com-cert.pem
  export CORE_PEER_MSPCONFIGPATH=${PWD}/../organizations/ordererOrganizations/orderer.com/users/Admin@com/msp
}

# Set environment variables for the peer org
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  
  if [ $USING_ORG -eq 1 ]; then
    infoln "Using organization issuer"
    export CORE_PEER_LOCALMSPID="issuer"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_issuer_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../organizations/peerOrganizations/issuer.com/users/Admin@issuer.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
    export OG_NAME="issuer"
  elif [ $USING_ORG -eq 2 ]; then
    infoln "Using organization issuer"
    export CORE_PEER_LOCALMSPID="issuer"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER1_issuer_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../organizations/peerOrganizations/issuer.com/users/Admin@issuer.com/msp
    export CORE_PEER_ADDRESS=localhost:8051
    export OG_NAME="issuer"

  elif [ $USING_ORG -eq 3 ]; then
    infoln "Using organization holder"
    export CORE_PEER_LOCALMSPID="holder"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_holder_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../organizations/peerOrganizations/holder.com/users/Admin@holder.com/msp
    export CORE_PEER_ADDRESS=localhost:7052
    export OG_NAME="holder"
  elif [ $USING_ORG -eq 4 ]; then
    infoln "Using organization holder"
    export CORE_PEER_LOCALMSPID="holder"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER1_holder_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../organizations/peerOrganizations/holder.com/users/Admin@holder.com/msp
    export CORE_PEER_ADDRESS=localhost:8052
    export OG_NAME="holder"
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
parsePeerConnectionParameters() {

  PEER_CONN_PARMS=""
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer0.${OG_NAME}"
    ## Set peer addresses
    PEERS="$PEERS $PEER"
    PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $CORE_PEER_ADDRESS"
    ## Set path to TLS certificate
    TLSINFO=$(eval echo "--tlsRootCertFiles \$PEER0_${OG_NAME}_CA")
    PEER_CONN_PARMS="$PEER_CONN_PARMS $TLSINFO"
    # shift by one to get to the next organization
    shift
  done
  # remove leading space for output
  PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
