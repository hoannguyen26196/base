export PATH=${PWD}/../../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/../network
export VERBOSE=false


# Print the usage message
function printHelp() {
  echo "Usage: "
  echo "  network.sh <Mode> [Flags]"
  echo "    Modes:"
  echo "      "$'\e[0;32m'up$'\e[0m' - bring up fabric orderer and peer nodes. No channel is created
  echo "      "$'\e[0;32m'up createChannel$'\e[0m' - bring up fabric network with one channel
  echo "      "$'\e[0;32m'createChannel$'\e[0m' - create and join a channel after the network is created
  echo "      "$'\e[0;32m'deployCC$'\e[0m' - deploy the asset transfer basic chaincode on the channel or specify
  echo "      "$'\e[0;32m'down$'\e[0m' - clear the network with docker-compose down
  echo "      "$'\e[0;32m'restart$'\e[0m' - restart the network
  echo
  echo "    Flags:"
  echo "    Used with "$'\e[0;32m'network.sh up$'\e[0m', $'\e[0;32m'network.sh createChannel$'\e[0m':
  echo "    -ca <use CAs> -  create Certificate Authorities to generate the crypto material"
  echo "    -c <channel name> - channel name to use (defaults to \"blockchain\")"
  echo "    -s <dbtype> - the database backend to use: goleveldb (default) or couchdb"
  echo "    -r <max retry> - CLI times out after certain number of attempts (defaults to 5)"
  echo "    -d <delay> - delay duration in seconds (defaults to 3)"
  echo "    -i <imagetag> - the tag to be used to launch the network (defaults to \"latest\")"
  echo "    -cai <ca_imagetag> - the image tag to be used for CA (defaults to \"${CA_IMAGETAG}\")"
  echo "    -verbose - verbose mode"
  echo "    Used with "$'\e[0;32m'network.sh deployCC$'\e[0m'
  echo "    -c <channel name> - deploy chaincode to channel"
  echo "    -ccn <name> - the short name of the chaincode to deploy: basic (default),ledger, private, sbe, secured"
  echo "    -ccl <language> - the programming language of the chaincode to deploy: go (default), java, javascript, typescript"
  echo "    -ccv <version>  - chaincode version. 1.0 (default)"
  echo "    -ccs <sequence>  - chaincode definition sequence. Must be an integer, 1 (default), 2, 3, etc"
  echo "    -ccp <path>  - Optional, path to the chaincode. When provided the -ccn will be used as the deployed name and not the short name of the known chaincodes."
  echo "    -ccep <policy>  - Optional, chaincode endorsement policy, using signature policy syntax. The default policy requires an endorsement from issuer and holder"
  echo "    -cccg <collection-config>  - Optional, path to a private data collections configuration file"
  echo "    -cci <fcn name>  - Optional, chaincode init required function to invoke. When provided this function will be invoked after deployment of the chaincode and will define the chaincode as initialization required."
  echo
  echo "    -h - print this message"
  echo
  echo " Possible Mode and flag combinations"
  echo "   "$'\e[0;32m'up$'\e[0m' -ca -c -r -d -s -i -verbose
  echo "   "$'\e[0;32m'up createChannel$'\e[0m' -ca -c -r -d -s -i -verbose
  echo "   "$'\e[0;32m'createChannel$'\e[0m' -c -r -d -verbose
  echo "   "$'\e[0;32m'deployCC$'\e[0m' -ccn -ccl -ccv -ccs -ccp -cci -r -d -verbose
  echo
  echo " Taking all defaults:"
  echo "   network.sh up"
  echo
  echo " Examples:"
  echo "   network.sh up createChannel -ca -c mychannel -s couchdb -i 2.0.0"
  echo "   network.sh createChannel -c channelName"
  echo "   network.sh deployCC -ccn basic -ccl javascript"
  echo "   network.sh deployCC -ccn mychaincode -ccp ./user/mychaincode -ccv 1 -ccl javascript"
}

# Obtain CONTAINER_IDS and remove them
# TODO Might want to make this optional - could clear other containers
# This function is called when you bring a network down
function clearContainers() {
  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*/) {print $1}')
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f $CONTAINER_IDS
  fi
}

# Delete any images that were generated as a part of this setup
# specifically the following images are often left behind:
# This function is called when you bring the network down
function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

# Versions of fabric known not to work with the test network
NONWORKING_VERSIONS="^1\.0\. ^1\.1\. ^1\.2\. ^1\.3\. ^1\.4\."

# Do some basic sanity checking to make sure that the appropriate versions of fabric
# binaries/images are available. In the future, additional checking for the presence
# of go or other items could be added.
function checkPrereqs() {
  ## Check if your have cloned the peer binaries and configuration files.
  peer version > /dev/null 2>&1

  if [[ $? -ne 0 || ! -d "../network" ]]; then
    echo "ERROR! Peer binary and configuration files not found.."
    echo
    echo "Follow the instructions in the Fabric docs to install the Fabric Binaries:"
    echo "https://hyperledger-fabric.readthedocs.io/en/latest/install.html"
    exit 1
  fi

  # use the fabric tools container to see if the samples and binaries match your
  # docker images
  LOCAL_VERSION=$(peer version | sed -ne 's/ Version: //p')
  DOCKER_IMAGE_VERSION=$(docker run --rm hyperledger/fabric-tools:$IMAGETAG peer version | sed -ne 's/ Version: //p' | head -1)

  echo "LOCAL_VERSION=$LOCAL_VERSION"
  echo "DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION"

  if [ "$LOCAL_VERSION" != "$DOCKER_IMAGE_VERSION" ]; then
    echo "=================== WARNING ==================="
    echo "  Local fabric binaries and docker images are  "
    echo "  out of  sync. This may cause problems.       "
    echo "==============================================="
  fi

  for UNSUPPORTED_VERSION in $NONWORKING_VERSIONS; do
    echo "$LOCAL_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      echo "ERROR! Local Fabric binary version of $LOCAL_VERSION does not match the versions supported by the test network."
      exit 1
    fi

    echo "$DOCKER_IMAGE_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      echo "ERROR! Fabric Docker image version of $DOCKER_IMAGE_VERSION does not match the versions supported by the test network."
      exit 1
    fi
  done

  ## Check for fabric-ca
  if [ "$CRYPTO" == "Certificate Authorities" ]; then

    fabric-ca-client version > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      echo "ERROR! fabric-ca-client binary not found.."
      echo
      echo "Follow the instructions in the Fabric docs to install the Fabric Binaries:"
      echo "https://hyperledger-fabric.readthedocs.io/en/latest/install.html"
      exit 1
    fi
    CA_LOCAL_VERSION=$(fabric-ca-client version | sed -ne 's/ Version: //p')
    CA_DOCKER_IMAGE_VERSION=$(docker run --rm hyperledger/fabric-ca:$CA_IMAGETAG fabric-ca-client version | sed -ne 's/ Version: //p' | head -1)
    echo "CA_LOCAL_VERSION=$CA_LOCAL_VERSION"
    echo "CA_DOCKER_IMAGE_VERSION=$CA_DOCKER_IMAGE_VERSION"

    if [ "$CA_LOCAL_VERSION" != "$CA_DOCKER_IMAGE_VERSION" ]; then
      echo "=================== WARNING ======================"
      echo "  Local fabric-ca binaries and docker images are  "
      echo "  out of sync. This may cause problems.           "
      echo "=================================================="
    fi
  fi
}

function createOrgs() {

  if [ -d "../organizations/peerOrganizations" ]; then
    rm -Rf ../organizations/peerOrganizations && rm -Rf ../organizations/ordererOrganizations
  fi

  # Create crypto material using cryptogen
  # if [ "$CRYPTO" == "cryptogen" ]; then
  #   which cryptogen
  #   if [ "$?" -ne 0 ]; then
  #     echo "cryptogen tool not found. exiting"
  #     exit 1
  #   fi
  #   echo
  #   echo "##########################################################"
  #   echo "##### Generate certificates using cryptogen tool #########"
  #   echo "##########################################################"
  #   echo
  #
  #   echo "##########################################################"
  #   echo "############ Create issuer Identities ######################"
  #   echo "##########################################################"
  #
  #   set -x
  #   cryptogen generate --config=./../organizations/cryptogen/crypto-configissuer.yaml --output="organizations"
  #   res=$?
  #   { set +x; } 2>/dev/null
  #   if [ $res -ne 0 ]; then
  #     echo $'\e[1;32m'"Failed to generate certificates..."$'\e[0m'
  #     exit 1
  #   fi
  #
  #   echo "##########################################################"
  #   echo "############ Create holder Identities ######################"
  #   echo "##########################################################"
  #
  #   set -x
  #   cryptogen generate --config=./../organizations/cryptogen/crypto-config-holder.yaml --output="organizations"
  #   res=$?
  #   { set +x; } 2>/dev/null
  #   if [ $res -ne 0 ]; then
  #     echo $'\e[1;32m'"Failed to generate certificates..."$'\e[0m'
  #     exit 1
  #   fi
  #
  #   echo "##########################################################"
  #   echo "############ Create Orderer Org Identities ###############"
  #   echo "##########################################################"
  #
  #   set -x
  #   cryptogen generate --config=./../organizations/cryptogen/crypto-config-orderer.yaml --output="organizations"
  #   res=$?
  #   { set +x; } 2>/dev/null
  #   if [ $res -ne 0 ]; then
  #     echo $'\e[1;32m'"Failed to generate certificates..."$'\e[0m'
  #     exit 1
  #   fi
  #
  # fi

  # Create crypto material using Fabric CAs
  if [ "$CRYPTO" == "Certificate Authorities" ]; then

    echo
    echo "##########################################################"
    echo "##### Generate certificates using Fabric CA's ############"
    echo "##########################################################"

    IMAGE_TAG=${CA_IMAGETAG} docker-compose -f $COMPOSE_FILE_CA up -d 2>&1

    . registerEnroll.sh

    sleep 10

    echo "##########################################################"
    echo "############ Create issuer Identities ######################"
    echo "##########################################################"

    createIssuer

    echo "##########################################################"
    echo "############ Create holder Identities ######################"
    echo "##########################################################"

    createHolder

    echo "##########################################################"
    echo "############ Create Orderer Org Identities ###############"
    echo "##########################################################"

    createOrderer

  fi

  echo
  echo "Generate CCP files for issuer and holder"
  ./ccp-generate.sh
}

# Once you create the organization crypto material, you need to create the
# genesis block of the orderer system channel. This block is required to bring
# up any orderer nodes and create any application channels.

# The configtxgen tool is used to create the genesis block. Configtxgen consumes a
# "configtx.yaml" file that contains the definitions for the sample network. The
# genesis block is defiend using the "TwoOrgsOrdererGenesis" profile at the bottom
# of the file. This profile defines a sample consortium, "SampleConsortium",
# consisting of our two Peer Orgs. This consortium defines which organizations are
# recognized as members of the network. The peer and ordering organizations are defined
# in the "Profiles" section at the top of the file. As part of each organization
# profile, the file points to a the location of the MSP directory for each member.
# This MSP is used to create the channel MSP that defines the root of trust for
# each organization. In essense, the channel MSP allows the nodes and users to be
# recognized as network members. The file also specifies the anchor peers for each
# peer org. In future steps, this same file is used to create the channel creation
# transaction and the anchor peer updates.
#
#
# If you receive the following warning, it can be safely ignored:
#
# [bccsp] GetDefault -> WARN 001 Before using BCCSP, please call InitFactories(). Falling back to bootBCCSP.
#
# You can ignore the logs regarding intermediate certs, we are not using them in
# this crypto implementation.

# Generate orderer system channel genesis block.
function createConsortium() {

  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi

  echo "#########  Generating Orderer Genesis block ##############"

  # Note: For some unknown reason (at least for now) the block file can't be
  # named orderer.blockchain.block or the orderer will fail to launch!
  set -x
  configtxgen -profile Genesis -channelID system-channel -outputBlock ./../blockchain.block
  res=$?
  { set +x; } 2>/dev/null
  if [ $res -ne 0 ]; then
    echo $'\e[1;32m'"Failed to generate orderer genesis block..."$'\e[0m'
    exit 1
  fi
}

# After we create the org crypto material and the system channel genesis block,
# we can now bring up the peers and orderering service. By default, the base
# file for creating the network is "docker-compose-test-net.yaml" in the ``docker``
# folder. This file defines the environment variables and file mounts that
# point the crypto material and genesis block that were created in earlier.

# Bring up the peer and orderer nodes using docker compose.
function networkUp() {
  
  checkPrereqs
  docker network create blockchain
  # generate artifacts if they don't exist
  if [ ! -d "../organizations/peerOrganizations" ]; then
    createOrgs

    createConsortium
  fi

  COMPOSE_FILES="-f ${COMPOSE_FILE_BASE} "

  if [ "${DATABASE}" == "couchdb" ]; then
    COMPOSE_FILES="${COMPOSE_FILES} -f ${COMPOSE_FILE_COUCH}"
  fi

  IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILES} up -d 2>&1

  docker ps -a
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to start network"
    exit 1
  fi
}

# function networkStart() {

#   checkPrereqs
#   # generate artifacts if they don't exist
#   if [ ! -d "../organizations/peerOrganizations" ]; then
#     createOrgs

#     createConsortium
#   fi

#   COMPOSE_FILES="-f ${COMPOSE_FILE_BASE} -f ${COMPOSE_FILE_COUCH}"

#   IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILES} start -d 2>&1

#   docker ps -a
#   if [ $? -ne 0 ]; then
#     echo "ERROR !!!! Unable to start network"
#     exit 1
#   fi
# }


function createChannel() {

## Bring up the network if it is not arleady up.

  if [ ! -d "../organizations/peerOrganizations" ]; then
    echo "Bringing up network"
    networkUp
  fi

  # now run the script that creates a channel. This script uses configtxgen once
  # more to create the channel creation transaction and the anchor peer updates.
  # configtx.yaml is mounted in the cli container, which allows us to use it to
  # create the channel artifacts
 ./createChannel.sh $CHANNEL_NAME $CLI_DELAY $MAX_RETRY $VERBOSE
  if [ $? -ne 0 ]; then
    echo "Error !!! Create channel failed"
    exit 1
  fi

}


## Call the script to isntall and instantiate a chaincode on the channel
function deployCC() {

  ./deployCC.sh

  if [ $? -ne 0 ]; then
    echo "ERROR !!! Deploying chaincode failed"
    exit 1
  fi

  exit 0
}
# Stop network
function networkStop(){
  docker-compose -f $COMPOSE_FILE_BASE -f $COMPOSE_FILE_CA stop 
}

# Start network
function networkStart(){
  docker-compose -f $COMPOSE_FILE_BASE -f $COMPOSE_FILE_CA start
}

function networkMonitor(){
  docker-compose -f $COMPOSE_MONITOR_FILE  up -d
}

function networkStopMonitor(){
  docker-compose -f $COMPOSE_MONITOR_FILE  down -v
}

# Tear down running network
function networkDown() {
  # stop org3 containers also in addition to issuer and holder, in case we were running sample to add org3
  docker-compose -f $COMPOSE_FILE_BASE -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_CA  down --volumes --remove-orphans
  #docker-compose -f $COMPOSE_FILE_COUCH_ORG3 -f $COMPOSE_FILE_ORG3 down --volumes --remove-orphans
  # Don't remove the generated artifacts -- note, the ledgers are always removed
  if [ "$MODE" != "restart" ]; then
    # Bring down the network, deleting the volumes
    #Cleanup the chaincode containers
    clearContainers
    #Cleanup images
    removeUnwantedImages
    # remove orderer block and other channel configuration transactions and certs
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf ../*.block ../organizations/peerOrganizations ../organizations/ordererOrganizations'
    ## remove fabric ca artifacts
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf ../organizations/fabric-ca/issuer/msp ../organizations/fabric-ca/issuer/tls-cert.pem ../organizations/fabric-ca/issuer/ca-cert.pem ../organizations/fabric-ca/issuer/IssuerPublicKey ../organizations/fabric-ca/issuer/IssuerRevocationPublicKey ../organizations/fabric-ca/issuer/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf ../organizations/fabric-ca/holder/msp ../organizations/fabric-ca/holder/tls-cert.pem ../organizations/fabric-ca/holder/ca-cert.pem ../organizations/fabric-ca/holder/IssuerPublicKey ../organizations/fabric-ca/holder/IssuerRevocationPublicKey ../organizations/fabric-ca/holder/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf ../organizations/fabric-ca/ordererOrg/msp ../organizations/fabric-ca/ordererOrg/tls-cert.pem ../organizations/fabric-ca/ordererOrg/ca-cert.pem ../organizations/fabric-ca/ordererOrg/IssuerPublicKey ../organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey ../organizations/fabric-ca/ordererOrg/fabric-ca-server.db'
    #docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf addOrg3/fabric-ca/org3/msp addOrg3/fabric-ca/org3/tls-cert.pem addOrg3/fabric-ca/org3/ca-cert.pem addOrg3/fabric-ca/org3/IssuerPublicKey addOrg3/fabric-ca/org3/IssuerRevocationPublicKey addOrg3/fabric-ca/org3/fabric-ca-server.db'
    #remove channel and script artifacts
    #docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf channel-artifacts log.txt fabcar.tar.gz fabcar'
  fi
  pushd ../
  rm blockchain.block blockchain.tx issueranchors.tx holderanchors.tx
  sudo rm -rf organizations/*
  popd
  docker network prune
}

# Obtain the OS and Architecture string that will be used to select the correct
# native binaries for your platform, e.g., darwin-amd64 or linux-amd64
OS_ARCH=$(echo "$(uname -s | tr '[:upper:]' '[:lower:]' | sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
# Using crpto vs CA. default is cryptogen
CRYPTO="cryptogen"
# timeout duration - the duration the CLI should wait for a response from
# another container before giving up
MAX_RETRY=5
# default for delay between commands
CLI_DELAY=3
# channel name defaults to "mychannel"
CHANNEL_NAME="blockchain"
# chaincode name defaults to "basic"
CC_NAME="blockchain-cc"
# chaincode path defaults to "NA"
CC_SRC_PATH="NA"
# endorsement policy defaults to "NA". This would allow chaincodes to use the majority default policy.
CC_END_POLICY="NA"
# collection configuration defaults to "NA"
CC_COLL_CONFIG="NA"
# chaincode init function defaults to "NA"
CC_INIT_FCN="NA"
# use this as the default docker-compose yaml definition
COMPOSE_FILE_BASE=../docker/docker-compose-peer.yaml
# docker-compose.yaml file if you are using couchdb
COMPOSE_FILE_COUCH=../docker/docker-compose-couch.yaml
# certificate authorities compose file
COMPOSE_FILE_CA=../docker/docker-compose-ca.yaml
#monitor compose file
COMPOSE_MONITOR_FILE=../docker/docker-compose-explorer.yaml

# use this as the docker compose couch file for org3
#COMPOSE_FILE_COUCH_ORG3=addOrg3/docker/docker-compose-couch-org3.yaml
# use this as the default docker-compose yaml definition for org3
#COMPOSE_FILE_ORG3=addOrg3/docker/docker-compose-org3.yaml
#
# use go as the default language for chaincode
CC_SRC_LANGUAGE="go"
# Chaincode version
CC_VERSION="1.0"
# Chaincode definition sequence
CC_SEQUENCE=1
# default image tag
IMAGETAG="latest"
# default ca image tag
CA_IMAGETAG="latest"
# default database
DATABASE="couchdb"

# Parse commandline args

## Parse mode
if [[ $# -lt 1 ]] ; then
  printHelp
  exit 0
else
  MODE=$1
  shift
fi

# parse a createChannel subcommand if used
if [[ $# -ge 1 ]] ; then
  key="$1"
  if [[ "$key" == "createChannel" ]]; then
      export MODE="createChannel"
      shift
  fi
fi

# parse flags

while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -h )
    printHelp
    exit 0
    ;;
  -c )
    CHANNEL_NAME="$2"
    shift
    ;;
  -ca )
    CRYPTO="Certificate Authorities"
    ;;
  -r )
    MAX_RETRY="$2"
    shift
    ;;
  -d )
    CLI_DELAY="$2"
    shift
    ;;
  -s )
    DATABASE="$2"
    shift
    ;;
  -ccl )
    CC_SRC_LANGUAGE="$2"
    shift
    ;;
  -ccn )
    CC_NAME="$2"
    shift
    ;;
  -ccv )
    CC_VERSION="$2"
    shift
    ;;
  -ccs )
    CC_SEQUENCE="$2"
    shift
    ;;
  -ccp )
    CC_SRC_PATH="$2"
    shift
    ;;
  -ccep )
    CC_END_POLICY="$2"
    shift
    ;;
  -cccg )
    CC_COLL_CONFIG="$2"
    shift
    ;;
  -cci )
    CC_INIT_FCN="$2"
    shift
    ;;
  -i )
    IMAGETAG="$2"
    shift
    ;;
  -cai )
    CA_IMAGETAG="$2"
    shift
    ;;
  -verbose )
    VERBOSE=true
    shift
    ;;
  * )
    echo
    echo "Unknown flag: $key"
    echo
    printHelp
    exit 1
    ;;
  esac
  shift
done

# Are we generating crypto material with this command?
if [ ! -d "../organizations/peerOrganizations" ]; then
  CRYPTO_MODE="with crypto from '${CRYPTO}'"
else
  CRYPTO_MODE=""
fi

# Determine mode of operation and printing out what we asked for
if [ "$MODE" == "up" ]; then
  echo "Starting nodes with CLI timeout of '${MAX_RETRY}' tries and CLI delay of '${CLI_DELAY}' seconds and using database '${DATABASE}' ${CRYPTO_MODE}"
  echo
elif [ "$MODE" == "createChannel" ]; then
  echo "Creating channel '${CHANNEL_NAME}'."
  echo
  echo "If network is not up, starting nodes with CLI timeout of '${MAX_RETRY}' tries and CLI delay of '${CLI_DELAY}' seconds and using database '${DATABASE} ${CRYPTO_MODE}"
  echo
elif [ "$MODE" == "down" ]; then
  echo "Stopping network"
  echo
elif [ "$MODE" == "start" ]; then
  echo "Starting network"
  echo
elif [ "$MODE" == "stop" ]; then
  echo "Stoping network"
  echo
elif [ "$MODE" == "restart" ]; then
  echo "Restarting network"
  echo
elif [ "$MODE" == "deployCC" ]; then
  echo "deploying chaincode on channel '${CHANNEL_NAME}'"
  echo
elif [ "$MODE" == "monitor" ]; then
  echo "Starting monitor network"
  echo
else
  printHelp
  exit 1
fi

if [ "${MODE}" == "up" ]; then
  networkUp
elif [ "${MODE}"  == "start" ]; then
  networkStart
elif [ "${MODE}" == "stop" ]; then
  networkStop
elif [ "${MODE}" == "createChannel" ]; then
  createChannel
elif [ "${MODE}" == "deployCC" ]; then
  deployCC
elif [ "${MODE}" == "down" ]; then
  networkDown
elif [ "${MODE}" == "monitor" ]; then
  networkMonitor
elif [ "${MODE}" == "restart" ]; then
  networkDown
  networkUp
else
  printHelp
  exit 1
fi