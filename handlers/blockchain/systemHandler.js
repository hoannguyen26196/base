recordServices = require('../../services/recordsServices')

exports.GetChainInfo = async function(req, res, next){
  try{
      var user = 'admin';
      let message = await recordServices.GetChainInfo(user);
      if(message.success){
        return res.status(201).send(message);
      }else{
        return res.send(message);
      }
    }catch(err){
      console.log(err)
      return res.status(500).send({
        success: false,
        message: err,
      });
    }
}

exports.getBlockByBlockNum = async function(req, res) {
  try{
    
    var user = 'admin';
    
    let message = await recordServices.GetBlock("GetBlockByNumber",user, req.query.blockNum);

    if(message.success){
      
      return res.status(200).send(message);
    }else{
    
      return res.status(500).send(message);
    }
  }catch(err){
    return res.status(500).send({
      success: false,
      message: err,
    });
  }
}

exports.getBlockByTxID = async function(req, res) {
  try{
    var user = 'admin';
    let message = await recordServices.GetBlock("GetBlockByTxID",user, req.query.TxID);
    var s = message.message.payload[0].channel_header.extension == "blockchain-cc" ? true : false
    console.log(s)
    if(message.success){
      return res.status(200).send(message);
    }else{
      return res.status(500).send(message);
    }
  }catch(err){
    return res.status(500).send({
      success: false,
      message: err,
    });
  }
}

exports.getTransactionByTxID= async function(req, res) {
  try{
    var user = 'admin';
    let message = await recordServices.GetTransaction("GetBlockByTxID",user, req.query.TxID);
    
    if(message.success){
      return res.status(200).send(message);
    }else{
      return res.status(500).send(message);
    }
  }catch(err){
    return res.status(500).send({
      success: false,
      message: err,
    });
  }
}

