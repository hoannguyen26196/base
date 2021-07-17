const {BlockDecoder} = require('fabric-common');
const {Gateway, Wallets, DefaultEventHandlerStrategies,DefaultQueryHandlerStrategies,DefaultCheckpointers} = require('fabric-network');
const fabprotos = require("fabric-protos");
const fs = require('fs');
const path = require('path');
const decode = require('./decode/decode')

async function Invokecc(fcn,params,user){
  var gateway = new Gateway();
  try {
    const ccpPath = path.resolve(process.cwd(),'blockchain', 'organizations', 'peerOrganizations', 'issuer.com', 'connection-issuer.json');
    const ccp = JSON.parse(fs.readFileSync(ccpPath,'utf-8'));

    const walletPath = path.join(process.cwd(),'blockchain','wallets');
    const wallet = await Wallets.newFileSystemWallet(walletPath);

    const identity = await wallet.get(user);
    if(!identity){
      return {
        success: false,
        result: "Identity user does not exist in system"
      }
    }
    const gatewayOptions=  {
      wallet,
      identity: user,
      discovery: {
        enabled: true,
        asLocalhost: true
      },
      eventHandlerOptions:{
        strategy: DefaultEventHandlerStrategies.NONE
      }
    }
    await gateway.connect(ccp,gatewayOptions);
    const network = await gateway.getNetwork('blockchain');
    const contract = await network.getContract('blockchain-cc');
    // function name in your chaincode
    await contract.submitTransaction(fcn,params);
    
    return {
      success : true,
      result : params
    }

  }catch(err){
    console.log(err)
    return {
      success : false,
      result : err
    }
  }finally{
    await gateway.disconnect();
  }
  
}

async function Querycc(fcn, params, user) {
  var gateway = new Gateway();
  try {
    var res = {
        success: false,
        result: ""
    };

    const ccpPath = path.resolve(process.cwd(),'blockchain', 'organizations', 'peerOrganizations', 'issuer.com', 'connection-issuer.json');
    const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf-8'));

    const walletPath = path.join(process.cwd(),'blockchain','wallets');
    const wallet = await Wallets.newFileSystemWallet(walletPath);

    const identity = await wallet.get(user);
    if (!identity) {
        res.result = 'Identity user does not exist in system';
        return res;
    }
    const gatewayOptions=  {
    wallet,
    identity: user,
    discovery: {
        enabled: true,
        asLocalhost: true
    },
    queryHandlerOptions:{
        timeout: 60, 
        strategy: DefaultQueryHandlerStrategies.MSPID_SCOPE_ROUND_ROBIN

    }
    } 
    await gateway.connect(ccp,gatewayOptions);

    const network = await gateway.getNetwork('blockchain');

    const contract = await network.getContract('blockchain-cc');


    const result = await contract.evaluateTransaction(fcn ,params);
   
    return {
      result : result.toString()
    }

  } catch (err) {
    console.log(err)
      var res = {
          success: false,
          result: err,
      }
      return res
  } finally {
      await gateway.disconnect();
  }
}



async function GetChainInfo(user) {
  var gateway = new Gateway();
  try {
      var res = {
          success: false,
          result: ""
      };

      const ccpPath = path.resolve(process.cwd(),'blockchain', 'organizations', 'peerOrganizations', 'issuer.com', 'connection-issuer.json');
      const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf-8'));

      const walletPath = path.join(process.cwd(),'blockchain','wallets');
      const wallet = await Wallets.newFileSystemWallet(walletPath);

      const identity = await wallet.get(user);
      if (!identity) {
          res.result = 'Identity user does not exist in system';
          return res;
      }
      const gatewayOptions=  {
      wallet,
      identity: user,
      discovery: {
          enabled: true,
          asLocalhost: true
      },
      queryHandlerOptions:{
          timeout: 60, 
          strategy: DefaultQueryHandlerStrategies.MSPID_SCOPE_ROUND_ROBIN

      }
      } 
      await gateway.connect(ccp,gatewayOptions);
  
      await gateway.connect(ccp, {
          wallet,
          identity: user,
          discovery: {
              enabled: true,
              asLocalhost: true
          }
      });

    const network = await gateway.getNetwork('blockchain');

    const contract = await network.getContract('qscc');

    const result = await contract.evaluateTransaction('GetChainInfo','blockchain');

    const resultJson = fabprotos.common.BlockchainInfo.decode(result);


    var blockNumber = null;

    await network.addBlockListener(
        async(event) => {
          blockNumber= {
            success: true,
            result: event.blockNumber
          }
      }
    );
    return {
      blocknumber: blockNumber,
      result: resultJson
    }
  } catch (err) {
      var res = {
          success: false,
          result: err,
      }
      return res
  } finally {
      await gateway.disconnect();
  }
}

async function GetBlock(fcn,user,params) {
  var gateway = new Gateway();
  try {
      var res = {
          success: false,
          result: ""
      };
      
      const ccpPath = path.resolve(process.cwd(),'blockchain', 'organizations', 'peerOrganizations', 'issuer.com', 'connection-issuer.json');
      const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf-8'));
      
      const walletPath = path.join(process.cwd(),'blockchain','wallets');
      const wallet = await Wallets.newFileSystemWallet(walletPath);
      
      const identity = await wallet.get(user);
      if (!identity) {
          res.result = 'Identity user does not exist in system';
          return res;
      }
      
      const gatewayOptions=  {
        wallet,
        identity: user,
        discovery: {
            enabled: true,
            asLocalhost: true
        },
        queryHandlerOptions:{
            timeout: 60, 
            strategy: DefaultQueryHandlerStrategies.MSPID_SCOPE_ROUND_ROBIN

        }
      } 
      await gateway.connect(ccp,gatewayOptions);
      
      await gateway.connect(ccp, {
          wallet,
          identity: user,
          discovery: {
              enabled: true,
              asLocalhost: true
          }
      });
    
    const network = await gateway.getNetwork('blockchain');
    
    const contract = await network.getContract('qscc');
    
    const result = await contract.evaluateTransaction(fcn,'blockchain',params);
    
    var blockData = decode.decodeBlock(result);   
    return {
      success: true,
      message: blockData
    };
  } catch (err) {
    console.log(err)
      var res = {
          success: false,
          result: err,
      }
      return res
  } finally {
      await gateway.disconnect();
  }
}



async function GetTransaction(fcn,user,params) {
  var gateway = new Gateway();
  try {
      var res = {
          success: false,
          result: ""
      };

      const ccpPath = path.resolve(process.cwd(),'blockchain', 'organizations', 'peerOrganizations', 'issuer.com', 'connection-issuer.json');
      const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf-8'));

      const walletPath = path.join(process.cwd(),'blockchain','wallets');
      const wallet = await Wallets.newFileSystemWallet(walletPath);
    
      const identity = await wallet.get(user);
      if (!identity) {
          res.result = 'Identity user does not exist in system';
          return res;
      }
      
      const gatewayOptions=  {
        wallet,
        identity: user,
        discovery: {
            enabled: true,
            asLocalhost: true
        },
        queryHandlerOptions:{
            timeout: 60, 
            strategy: DefaultQueryHandlerStrategies.MSPID_SCOPE_ROUND_ROBIN

        }
      } 
      await gateway.connect(ccp,gatewayOptions);
      
      await gateway.connect(ccp, {
          wallet,
          identity: user,
          discovery: {
              enabled: true,
              asLocalhost: true
          }
      });
    
    const network = await gateway.getNetwork('blockchain');
    
    const contract = await network.getContract('qscc');
    
    const result = await contract.evaluateTransaction(fcn,'blockchain',params);
    
    var trans = decode.decodeTransaction(result, params);

    return {
      success: true,
      message: trans
    };
  } catch (err) {
    console.log(err)
      var res = {
          success: false,
          result: err,
      }
      return res
  } finally {
      await gateway.disconnect();
  }
}

exports.GetChainInfo = GetChainInfo;
exports.GetBlock = GetBlock;
exports.GetTransaction = GetTransaction;
exports.Querycc = Querycc;
exports.Invokecc = Invokecc
exports.InvokeFileData = InvokeFileData

  
