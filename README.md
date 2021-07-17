# Hyperledger base


Project base for hyperledger application with nodejs 
## How to use
- Write your chaincode
- Make new routes for your function in your chaincode
- Write service to call chaincode from to outside
- Run network and deploy Chaincode
- Enroll Admin
- Start server
---
**NOTE**
recommend for nodejs ver 12.12.0
---
## Write your application
- make your chaincode in contracts file
- Make new routes for your function in your chaincode
- Write service to call chaincode from to outside
## Start network and deploy CC

Start network
```sh
cd blockchain/script
./network.sh up -createChannel -ca -s couchdb
```
deploy Chaincode
```sh
./network.sh deploy
```
Enroll admin
```sh
cd handlers/users/
node EnrollAdmin.js
```
## Start server

Start api server
```sh
npm i 
npm start
```


