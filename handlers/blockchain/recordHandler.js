recordServices = require('../../services/recordsServices')
var xlsx = require('node-xlsx');
const APIKey = require('../../services/db/db')

exports.createRecord = async function(req, res) {
    try{
        var user  =  await APIKey.findOne({
          'APIKey.hashKey':  req.headers['appid'],
        },'APIKey.username').exec();
        var content = Buffer.from(req.file.buffer).toString("utf-8");
        params = {
          value: content,
          signature: req.body.signature
        }
        // fill your smart contract name in your chaincode in "chaincodeFunction" field
        let message = await recordServices.Invokecc('chaincodeFunction',params,user.APIKey.username);
        if(message.success){
          return res.status(201).send(message);
        }else{
          return res.status(400).send(message);
        }
      }catch(err){
        console.log(err)
        return res.status(500).send({
          success: false,
          message: err,
        });
      }
}


exports.updateRecord = async function(req, res) {
    try{
      var user  =  await APIKey.findOne({
        'APIKey.hashKey':  req.headers['appid'],
      },'APIKey.username');
    var content = Buffer.from(req.file.buffer).toString("utf-8");
    params = {
      value: content,
      signature: req.body.signature
    }
    // fill your smart contract name in your chaincode in "chaincodeFunction" field
    let message = await recordServices.Invokecc('chaincodeFunction',params,user.APIKey.username);

    if(message.success){
      return res.status(200).send(message);
    }else{
      return res.status(400).send(message);
    }
  }catch(err){
    return res.status(500).send({
      success: false,
      message: err,
    });
  }
}

exports.getRecord = async function(req, res) {
    try{
      var user = 'admin';
      // fill your smart contract name in your chaincode in "chaincodeFunction" field
      let message = await recordServices.Querycc('chaincodeFunction',req.query.key,user);
      if(message.success){
        return res.status(200).send(message);
      }else{
        return res.status(400).send(message);
      }
    }catch(err){
      return res.status(500).send({
        success: false,
        message: err,
    });
  }
}



