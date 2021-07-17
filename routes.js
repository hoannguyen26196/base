const userHandler = require('./handlers/users/userHandler');
const recordHandler = require('./handlers/blockchain/recordHandler.js')
const systemHandler = require('./handlers/blockchain/systemHandler')
const upload = require("multer")({
    limits: {
        fileSize: 10 * 1024 * 1024
    }
});

module.exports = function(app) {
    app.post('/api/user/sign-up',userHandler.signUp);

    app.post('/api/blockchain/create',upload.single('record'),recordHandler.createRecord);
    app.put('/api/blockchain/update',upload.single('record'),recordHandler.updateRecord);
    app.get('/api/blockchain/get',recordHandler.getRecord);

    app.get('/api/system/qscc/GetChainInfo',systemHandler.GetChainInfo);
    app.get('/api/system/qscc/GetBlockByBlockNum',systemHandler.getBlockByBlockNum);
    app.get('/api/system/qscc/GetBlockByTxID',systemHandler.getBlockByTxID);
    app.get('/api/system/qscc/GetTransactionByTxID',systemHandler.getTransactionByTxID);
}