#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_monitor {
    local AP=$(one_line_pem $1)
    sed -e "s#\${ADMINPEM}#$AP#" \
        ./template/monitor-template.json
}

function json_ccp {
    local PP=$(one_line_pem $5)
    local CP=$(one_line_pem $6)
    local O=$(one_line_pem $7)
    local O1=$(one_line_pem ${8})
    local O2=$(one_line_pem ${9})
    local O3=$(one_line_pem ${10})
    local O4=$(one_line_pem ${11})
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${P1PORT}/$3/" \
        -e "s/\${CAPORT}/$4/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        -e "s#\${ORDEPEM}#$O#" \
        -e "s#\${ORDE1PEM}#$O1#" \
        -e "s#\${ORDE2PEM}#$O2#" \
        -e "s#\${ORDE3PEM}#$O3#" \
        -e "s#\${ORDE4PEM}#$O4#" \
        ./template/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $5)
    local CP=$(one_line_pem $6)
    local O=$(one_line_pem $7)
    local O1=$(one_line_pem ${8})
    local O2=$(one_line_pem ${9})
    local O3=$(one_line_pem ${10})
    local O3=$(one_line_pem ${11})
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${P1PORT}/$3/" \
        -e "s/\${CAPORT}/$4/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        -e "s#\${ORDEPEM}#$O#" \
        -e "s#\${ORDE1PEM}#$O1#" \
        -e "s#\${ORDE2PEM}#$O2#" \
        -e "s#\${ORDE3PEM}#$O3#" \
        -e "s#\${ORDE4PEM}#$O4#" \
        ./template/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

ORG=issuer #1
P0PORT=7051 #2
P1PORT=8051 #3
CAPORT=7054 #6
PEERPEM=../organizations/peerOrganizations/issuer.com/tlsca/tlsca.issuer.com-cert.pem #7
CAPEM=../organizations/peerOrganizations/issuer.com/ca/ca.issuer.com-cert.pem #8
ORDEPEM=../organizations/ordererOrganizations/orderer.com/orderers/orderer.com/tls/ca.crt #9
ORDE1PEM=../organizations/ordererOrganizations/orderer.com/orderers/orderer1.com/tls/ca.crt #10
ORDE2PEM=../organizations/ordererOrganizations/orderer.com/orderers/orderer2.com/tls/ca.crt #11
ORDE3PEM=../organizations/ordererOrganizations/orderer.com/orderers/orderer3.com/tls/ca.crt #12
ORDE4PEM=../organizations/ordererOrganizations/orderer.com/orderers/orderer4.com/tls/ca.crt #13

echo "$(json_ccp $ORG $P0PORT $P1PORT  $CAPORT $PEERPEM $CAPEM $ORDEPEM $ORDE1PEM $ORDE2PEM $ORDE3PEM $ORDE4PEM)" > ../organizations/peerOrganizations/issuer.com/connection-issuer.json
echo "$(yaml_ccp $ORG $P0PORT $P1PORT  $CAPORT $PEERPEM $CAPEM $ORDEPEM $ORDE1PEM $ORDE2PEM $ORDE3PEM $ORDE4PEM)" > ../organizations/peerOrganizations/issuer.com/connection-issuer.yaml

ORG=holder
P0PORT=7052
P1PORT=8052
CAPORT=8054
PEERPEM=../organizations/peerOrganizations/holder.com/tlsca/tlsca.holder.com-cert.pem
CAPEM=../organizations/peerOrganizations/holder.com/ca/ca.holder.com-cert.pem
ORDEPEM=../organizations/ordererOrganizations/orderer.com/orderers/orderer.com/tls/ca.crt
ORDE1PEM=../organizations/ordererOrganizations/orderer.com/orderers/orderer1.com/tls/ca.crt
ORDE2PEM=../organizations/ordererOrganizations/orderer.com/orderers/orderer2.com/tls/ca.crt
ORDE3PEM=../organizations/ordererOrganizations/orderer.com/orderers/orderer3.com/tls/ca.crt
ORDE4PEM=../organizations/ordererOrganizations/orderer.com/orderers/orderer4.com/tls/ca.crt

echo "$(json_ccp $ORG $P0PORT $P1PORT $CAPORT $PEERPEM $CAPEM $ORDEPEM $ORDE1PEM $ORDE2PEM $ORDE3PEM $ORDE4PEM)" > ../organizations/peerOrganizations/holder.com/connection-holder.json
echo "$(yaml_ccp $ORG $P0PORT $P1PORT $CAPORT $PEERPEM $CAPEM $ORDEPEM $ORDE1PEM $ORDE2PEM $ORDE3PEM $ORDE4PEM)" > ../organizations/peerOrganizations/holder.com/connection-holder.yaml

ADMINPEM=../organizations/peerOrganizations/issuer.com/users/Admin@issuer.com/msp/keystore/*_sk
echo "$(json_monitor $ADMINPEM)" > ../explore/network.json
