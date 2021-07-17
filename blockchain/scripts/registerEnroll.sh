

function createIssuer {

  echo
	echo "Enroll the CA admin"
  echo
	mkdir -p ../organizations/peerOrganizations/issuer.com/

	export FABRIC_CA_CLIENT_HOME=${PWD}/../organizations/peerOrganizations/issuer.com/
#  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
#  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-issuer --tls.certfiles ${PWD}/../organizations/fabric-ca/issuer/tls-cert.pem
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-issuer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-issuer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-issuer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-issuer.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/../organizations/peerOrganizations/issuer.com/msp/config.yaml

  echo
	echo "Register peer0"
  echo
  set -x
	fabric-ca-client register --caname ca-issuer --id.name peer0 --id.secret peer0pw --id.type peer  --id.affiliation issuer.department --tls.certfiles ${PWD}/../organizations/fabric-ca/issuer/tls-cert.pem
  { set +x; } 2>/dev/null

  echo
	echo "Register peer1"
  echo
  set -x
	fabric-ca-client register --caname ca-issuer --id.name peer1 --id.secret peer1pw --id.type peer  --id.affiliation issuer.department --tls.certfiles ${PWD}/../organizations/fabric-ca/issuer/tls-cert.pem
  { set +x; } 2>/dev/null


  echo
  echo "Register user"
  echo
  set -x
  fabric-ca-client register --caname ca-issuer --id.name user1 --id.secret user1pw --id.type client --id.affiliation issuer.department --tls.certfiles ${PWD}/../organizations/fabric-ca/issuer/tls-cert.pem
  { set +x; } 2>/dev/null

  echo
  echo "Register the org admin"
  echo
  set -x
  fabric-ca-client register --caname ca-issuer --id.name issueradmin --id.secret issueradminpw --id.type admin --id.affiliation issuer.department --tls.certfiles ${PWD}/../organizations/fabric-ca/issuer/tls-cert.pem
  { set +x; } 2>/dev/null

	mkdir -p ../organizations/peerOrganizations/issuer.com/peers
  mkdir -p ../organizations/peerOrganizations/issuer.com/peers/peer0.issuer.com
  mkdir -p ../organizations/peerOrganizations/issuer.com/peers/peer1.issuer.com


  # GENERATE ARTIFACT FOR EACH PEERS
  echo
  echo "## Generate the peer0 msp"
  echo
  set -x
	fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-issuer -M ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer0.issuer.com/msp --csr.hosts peer0.issuer.com --tls.certfiles ${PWD}/../organizations/fabric-ca/issuer/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/../organizations/peerOrganizations/issuer.com/msp/config.yaml ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer0.issuer.com/msp/config.yaml

  echo
  echo "## Generate the peer1 msp"
  echo
  set -x
	fabric-ca-client enroll -u https://peer1:peer1pw@localhost:7054 --caname ca-issuer -M ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer1.issuer.com/msp --csr.hosts peer1.issuer.com --tls.certfiles ${PWD}/../organizations/fabric-ca/issuer/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/../organizations/peerOrganizations/issuer.com/msp/config.yaml ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer1.issuer.com/msp/config.yaml

  echo
  echo "## Generate the peer0-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-issuer -M ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer0.issuer.com/tls --enrollment.profile tls --csr.hosts peer0.issuer.com --csr.hosts localhost --tls.certfiles ${PWD}/../organizations/fabric-ca/issuer/tls-cert.pem
  { set +x; } 2>/dev/null


  cp ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer0.issuer.com/tls/tlscacerts/* ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer0.issuer.com/tls/ca.crt
  cp ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer0.issuer.com/tls/signcerts/* ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer0.issuer.com/tls/server.crt
  cp ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer0.issuer.com/tls/keystore/* ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer0.issuer.com/tls/server.key

  mkdir -p ${PWD}/../organizations/peerOrganizations/issuer.com/msp/tlscacerts
  cp ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer0.issuer.com/tls/tlscacerts/* ${PWD}/../organizations/peerOrganizations/issuer.com/msp/tlscacerts/ca.crt

  mkdir -p ${PWD}/../organizations/peerOrganizations/issuer.com/tlsca
  cp ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer0.issuer.com/tls/tlscacerts/* ${PWD}/../organizations/peerOrganizations/issuer.com/tlsca/tlsca.issuer.com-cert.pem

  mkdir -p ${PWD}/../organizations/peerOrganizations/issuer.com/ca
  cp ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer0.issuer.com/msp/cacerts/* ${PWD}/../organizations/peerOrganizations/issuer.com/ca/ca.issuer.com-cert.pem

  echo
  echo "## Generate the peer1-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://peer1:peer1pw@localhost:7054 --caname ca-issuer -M ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer1.issuer.com/tls --enrollment.profile tls --csr.hosts peer1.issuer.com --csr.hosts localhost --tls.certfiles ${PWD}/../organizations/fabric-ca/issuer/tls-cert.pem
  { set +x; } 2>/dev/null


  cp ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer1.issuer.com/tls/tlscacerts/* ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer1.issuer.com/tls/ca.crt
  cp ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer1.issuer.com/tls/signcerts/* ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer1.issuer.com/tls/server.crt
  cp ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer1.issuer.com/tls/keystore/* ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer1.issuer.com/tls/server.key

  mkdir -p ${PWD}/../organizations/peerOrganizations/issuer.com/msp/tlscacerts
  cp ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer1.issuer.com/tls/tlscacerts/* ${PWD}/../organizations/peerOrganizations/issuer.com/msp/tlscacerts/ca.crt

  mkdir -p ${PWD}/../organizations/peerOrganizations/issuer.com/tlsca
  cp ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer1.issuer.com/tls/tlscacerts/* ${PWD}/../organizations/peerOrganizations/issuer.com/tlsca/tlsca.issuer.com-cert.pem

  mkdir -p ${PWD}/../organizations/peerOrganizations/issuer.com/ca
  cp ${PWD}/../organizations/peerOrganizations/issuer.com/peers/peer1.issuer.com/msp/cacerts/* ${PWD}/../organizations/peerOrganizations/issuer.com/ca/ca.issuer.com-cert.pem


  mkdir -p ../organizations/peerOrganizations/issuer.com/users
  mkdir -p ../organizations/peerOrganizations/issuer.com/users/User1@issuer.com
  # GENERATE ARTIFACT FOR USERS
  echo
  echo "## Generate the user msp"
  echo
  set -x
	fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca-issuer -M ${PWD}/../organizations/peerOrganizations/issuer.com/users/User1@issuer.com/msp --tls.certfiles ${PWD}/../organizations/fabric-ca/issuer/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/../organizations/peerOrganizations/issuer.com/msp/config.yaml ${PWD}/../organizations/peerOrganizations/issuer.com/users/User1@issuer.com/msp/config.yaml

  mkdir -p ../organizations/peerOrganizations/issuer.com/users/Admin@issuer.com

  #GENERATE ARTIFACT FOR ADMIN ORGANIZATIONS
  echo
  echo "## Generate the org admin msp"
  echo
  set -x
	fabric-ca-client enroll -u https://issueradmin:issueradminpw@localhost:7054 --caname ca-issuer -M ${PWD}/../organizations/peerOrganizations/issuer.com/users/Admin@issuer.com/msp --tls.certfiles ${PWD}/../organizations/fabric-ca/issuer/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/../organizations/peerOrganizations/issuer.com/msp/config.yaml ${PWD}/../organizations/peerOrganizations/issuer.com/users/Admin@issuer.com/msp/config.yaml

}

#Register holder!

function createHolder {

  echo
	echo "Enroll the CA admin"
  echo
	mkdir -p ../organizations/peerOrganizations/holder.com/

	export FABRIC_CA_CLIENT_HOME=${PWD}/../organizations/peerOrganizations/holder.com/
#  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
#  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca-holder --tls.certfiles ${PWD}/../organizations/fabric-ca/holder/tls-cert.pem
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-holder.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-holder.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-holder.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-holder.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/../organizations/peerOrganizations/holder.com/msp/config.yaml

  echo
	echo "Register peer0"
  echo
  set -x
	fabric-ca-client register --caname ca-holder --id.name peer0 --id.secret peer0pw --id.type peer  --id.affiliation holder.department --tls.certfiles ${PWD}/../organizations/fabric-ca/holder/tls-cert.pem
  { set +x; } 2>/dev/null

  echo
	echo "Register peer1"
  echo
  set -x
	fabric-ca-client register --caname ca-holder --id.name peer1 --id.secret peer1pw --id.type peer  --id.affiliation holder.department --tls.certfiles ${PWD}/../organizations/fabric-ca/holder/tls-cert.pem
  { set +x; } 2>/dev/null


  echo
  echo "Register user"
  echo
  set -x
  fabric-ca-client register --caname ca-holder --id.name user1 --id.secret user1pw --id.type client --id.affiliation holder.department --tls.certfiles ${PWD}/../organizations/fabric-ca/holder/tls-cert.pem
  { set +x; } 2>/dev/null

  echo
  echo "Register the org admin"
  echo
  set -x
  fabric-ca-client register --caname ca-holder --id.name holderadmin --id.secret holderadminpw --id.type admin --id.affiliation holder.department --tls.certfiles ${PWD}/../organizations/fabric-ca/holder/tls-cert.pem
  { set +x; } 2>/dev/null

	mkdir -p ../organizations/peerOrganizations/holder.com/peers
    mkdir -p ../organizations/peerOrganizations/holder.com/peers/peer0.holder.com
    mkdir -p ../organizations/peerOrganizations/holder.com/peers/peer1.holder.com

  echo
  echo "## Generate the peer0 msp"
  echo
  set -x
	fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-holder -M ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer0.holder.com/msp --csr.hosts peer0.holder.com --tls.certfiles ${PWD}/../organizations/fabric-ca/holder/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/../organizations/peerOrganizations/holder.com/msp/config.yaml ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer0.holder.com/msp/config.yaml


  echo
  echo "## Generate the peer1 msp"
  echo
  set -x
	fabric-ca-client enroll -u https://peer1:peer1pw@localhost:8054 --caname ca-holder -M ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer1.holder.com/msp --csr.hosts peer1.holder.com --tls.certfiles ${PWD}/../organizations/fabric-ca/holder/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/../organizations/peerOrganizations/holder.com/msp/config.yaml ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer1.holder.com/msp/config.yaml


  echo
  echo "## Generate the peer0-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-holder -M ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer0.holder.com/tls --enrollment.profile tls --csr.hosts peer0.holder.com --csr.hosts localhost --tls.certfiles ${PWD}/../organizations/fabric-ca/holder/tls-cert.pem
  { set +x; } 2>/dev/null

  echo
  echo "## Generate the peer1-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://peer1:peer1pw@localhost:8054 --caname ca-holder -M ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer1.holder.com/tls --enrollment.profile tls --csr.hosts peer1.holder.com --csr.hosts localhost --tls.certfiles ${PWD}/../organizations/fabric-ca/holder/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer0.holder.com/tls/tlscacerts/* ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer0.holder.com/tls/ca.crt
  cp ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer0.holder.com/tls/signcerts/* ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer0.holder.com/tls/server.crt
  cp ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer0.holder.com/tls/keystore/* ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer0.holder.com/tls/server.key

  cp ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer1.holder.com/tls/tlscacerts/* ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer1.holder.com/tls/ca.crt
  cp ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer1.holder.com/tls/signcerts/* ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer1.holder.com/tls/server.crt
  cp ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer1.holder.com/tls/keystore/* ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer1.holder.com/tls/server.key

  mkdir -p ${PWD}/../organizations/peerOrganizations/holder.com/msp/tlscacerts
  cp ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer0.holder.com/tls/tlscacerts/* ${PWD}/../organizations/peerOrganizations/holder.com/msp/tlscacerts/ca.crt
  cp ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer1.holder.com/tls/tlscacerts/* ${PWD}/../organizations/peerOrganizations/holder.com/msp/tlscacerts/ca.crt

  mkdir -p ${PWD}/../organizations/peerOrganizations/holder.com/tlsca
  cp ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer0.holder.com/tls/tlscacerts/* ${PWD}/../organizations/peerOrganizations/holder.com/tlsca/tlsca.holder.com-cert.pem
  cp ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer1.holder.com/tls/tlscacerts/* ${PWD}/../organizations/peerOrganizations/holder.com/tlsca/tlsca.holder.com-cert.pem

  mkdir -p ${PWD}/../organizations/peerOrganizations/holder.com/ca
  cp ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer0.holder.com/msp/cacerts/* ${PWD}/../organizations/peerOrganizations/holder.com/ca/ca.holder.com-cert.pem
  cp ${PWD}/../organizations/peerOrganizations/holder.com/peers/peer1.holder.com/msp/cacerts/* ${PWD}/../organizations/peerOrganizations/holder.com/ca/ca.holder.com-cert.pem

  mkdir -p ../organizations/peerOrganizations/holder.com/users
  mkdir -p ../organizations/peerOrganizations/holder.com/users/User1@holder.com

  echo
  echo "## Generate the user msp"
  echo
  set -x
	fabric-ca-client enroll -u https://user1:user1pw@localhost:8054 --caname ca-holder -M ${PWD}/../organizations/peerOrganizations/holder.com/users/User1@holder.com/msp --tls.certfiles ${PWD}/../organizations/fabric-ca/holder/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/../organizations/peerOrganizations/holder.com/msp/config.yaml ${PWD}/../organizations/peerOrganizations/holder.com/users/User1@holder.com/msp/config.yaml

  mkdir -p ../organizations/peerOrganizations/holder.com/users/Admin@holder.com

  echo
  echo "## Generate the org admin msp"
  echo
  set -x
	fabric-ca-client enroll -u https://holderadmin:holderadminpw@localhost:8054 --caname ca-holder -M ${PWD}/../organizations/peerOrganizations/holder.com/users/Admin@holder.com/msp --tls.certfiles ${PWD}/../organizations/fabric-ca/holder/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/../organizations/peerOrganizations/holder.com/msp/config.yaml ${PWD}/../organizations/peerOrganizations/holder.com/users/Admin@holder.com/msp/config.yaml

}

# Register Orderer!


function createOrderer {

  echo
	echo "Enroll the CA admin"
  echo
	mkdir -p ../organizations/ordererOrganizations/orderer.com

	export FABRIC_CA_CLIENT_HOME=${PWD}/../organizations/ordererOrganizations/orderer.com
#  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
#  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles ${PWD}/../organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/../organizations/ordererOrganizations/orderer.com/msp/config.yaml


  echo
	echo "Register orderer"
  echo
  set -x
	fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/../organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null
  	fabric-ca-client register --caname ca-orderer --id.name orderer1 --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/../organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null
  	fabric-ca-client register --caname ca-orderer --id.name orderer2 --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/../organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null
  	fabric-ca-client register --caname ca-orderer --id.name orderer3 --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/../organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null
  	fabric-ca-client register --caname ca-orderer --id.name orderer4 --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/../organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null

  echo
  echo "Register the orderer admin"
  echo
  set -x
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles ${PWD}/../organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null

    mkdir -p ../organizations/ordererOrganizations/orderer.com/orderers
    mkdir -p ../organizations/ordererOrganizations/orderer.com/orderers/orderer.com
    mkdir -p ../organizations/ordererOrganizations/orderer.com/orderers/orderer1.com
    mkdir -p ../organizations/ordererOrganizations/orderer.com/orderers/orderer2.com
    mkdir -p ../organizations/ordererOrganizations/orderer.com/orderers/orderer3.com
    mkdir -p ../organizations/ordererOrganizations/orderer.com/orderers/orderer4.com

  echo
  echo "## Generate the orderer msp"
  echo
  set -x
	fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/..//organizations/ordererOrganizations/orderer.com/orderers/orderer.com/msp --csr.hosts orderer.com --csr.hosts localhost --tls.certfiles ${PWD}/../organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/msp/config.yaml ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer.com/msp/config.yaml


	fabric-ca-client enroll -u https://orderer1:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer1.com/msp --csr.hosts orderer1.com --csr.hosts localhost --tls.certfiles ${PWD}/../organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/msp/config.yaml ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer1.com/msp/config.yaml

	fabric-ca-client enroll -u https://orderer2:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer2.com/msp --csr.hosts orderer2.com --csr.hosts localhost --tls.certfiles ${PWD}/../organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/msp/config.yaml ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer2.com/msp/config.yaml

	fabric-ca-client enroll -u https://orderer3:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer3.com/msp --csr.hosts orderer3.com --csr.hosts localhost --tls.certfiles ${PWD}/../organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/msp/config.yaml ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer3.com/msp/config.yaml

	fabric-ca-client enroll -u https://orderer4:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer4.com/msp --csr.hosts orderer4.com --csr.hosts localhost --tls.certfiles ${PWD}/../organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/msp/config.yaml ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer4.com/msp/config.yaml

  echo
  echo "## Generate the orderer-tls certificates"
  echo
  set -x
    fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer.com/tls --enrollment.profile tls --csr.hosts orderer.com --csr.hosts localhost --tls.certfiles ${PWD}/../organizations/fabric-ca/ordererOrg/tls-cert.pem
    { set +x; } 2>/dev/null
    fabric-ca-client enroll -u https://orderer1:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer1.com/tls --enrollment.profile tls --csr.hosts orderer1.com --csr.hosts localhost --tls.certfiles ${PWD}/../organizations/fabric-ca/ordererOrg/tls-cert.pem
    { set +x; } 2>/dev/null
    fabric-ca-client enroll -u https://orderer2:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer2.com/tls --enrollment.profile tls --csr.hosts orderer2.com --csr.hosts localhost --tls.certfiles ${PWD}/../organizations/fabric-ca/ordererOrg/tls-cert.pem
    { set +x; } 2>/dev/null
    fabric-ca-client enroll -u https://orderer3:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer3.com/tls --enrollment.profile tls --csr.hosts orderer3.com --csr.hosts localhost --tls.certfiles ${PWD}/../organizations/fabric-ca/ordererOrg/tls-cert.pem
    { set +x; } 2>/dev/null
    fabric-ca-client enroll -u https://orderer4:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer4.com/tls --enrollment.profile tls --csr.hosts orderer4.com --csr.hosts localhost --tls.certfiles ${PWD}/../organizations/fabric-ca/ordererOrg/tls-cert.pem
    { set +x; } 2>/dev/null

  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer.com/tls/tlscacerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer.com/tls/ca.crt
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer.com/tls/signcerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer.com/tls/server.crt
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer.com/tls/keystore/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer.com/tls/server.key


  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer1.com/tls/tlscacerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer1.com/tls/ca.crt
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer1.com/tls/signcerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer1.com/tls/server.crt
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer1.com/tls/keystore/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer1.com/tls/server.key
  

  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer2.com/tls/tlscacerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer2.com/tls/ca.crt
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer2.com/tls/signcerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer2.com/tls/server.crt
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer2.com/tls/keystore/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer2.com/tls/server.key
  

  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer3.com/tls/tlscacerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer3.com/tls/ca.crt
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer3.com/tls/signcerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer3.com/tls/server.crt
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer3.com/tls/keystore/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer3.com/tls/server.key
  
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer4.com/tls/tlscacerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer4.com/tls/ca.crt
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer4.com/tls/signcerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer4.com/tls/server.crt
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer4.com/tls/keystore/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer4.com/tls/server.key

  #
  mkdir -p ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer.com/msp/tlscacerts
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer.com/tls/tlscacerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer.com/msp/tlscacerts/tlsca.com-cert.pem

  mkdir -p ${PWD}/../organizations/ordererOrganizations/orderer.com/msp/tlscacerts
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer.com/tls/tlscacerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/msp/tlscacerts/tlsca.com-cert.pem


  mkdir -p ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer1.com/msp/tlscacerts
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer1.com/tls/tlscacerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer1.com/msp/tlscacerts/tlsca.com-cert.pem

  mkdir -p ${PWD}/../organizations/ordererOrganizations/orderer.com/msp/tlscacerts
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer1.com/tls/tlscacerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/msp/tlscacerts/tlsca.com-cert.pem


  mkdir -p ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer2.com/msp/tlscacerts
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer2.com/tls/tlscacerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer2.com/msp/tlscacerts/tlsca.com-cert.pem

  mkdir -p ${PWD}/../organizations/ordererOrganizations/orderer.com/msp/tlscacerts
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer2.com/tls/tlscacerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/msp/tlscacerts/tlsca.com-cert.pem


  mkdir -p ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer3.com/msp/tlscacerts
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer3.com/tls/tlscacerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer3.com/msp/tlscacerts/tlsca.com-cert.pem

  mkdir -p ${PWD}/../organizations/ordererOrganizations/orderer.com/msp/tlscacerts
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer3.com/tls/tlscacerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/msp/tlscacerts/tlsca.com-cert.pem

  mkdir -p ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer4.com/msp/tlscacerts
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer4.com/tls/tlscacerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer4.com/msp/tlscacerts/tlsca.com-cert.pem

  mkdir -p ${PWD}/../organizations/ordererOrganizations/orderer.com/msp/tlscacerts
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/orderers/orderer4.com/tls/tlscacerts/* ${PWD}/../organizations/ordererOrganizations/orderer.com/msp/tlscacerts/tlsca.com-cert.pem


  mkdir -p ../organizations/ordererOrganizations/orderer.com/users
  mkdir -p ../organizations/ordererOrganizations/orderer.com/users/Admin@com

  echo
  echo "## Generate the admin msp"
  echo
  set -x
	fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M ${PWD}/../organizations/ordererOrganizations/orderer.com/users/Admin@com/msp --tls.certfiles ${PWD}/../organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null
  
  cp ${PWD}/../organizations/ordererOrganizations/orderer.com/msp/config.yaml ${PWD}/../organizations/ordererOrganizations/orderer.com/users/Admin@com/msp/config.yaml


}
