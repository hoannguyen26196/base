const FabricCaServices = require('fabric-ca-client');
const { Wallets, X509WalletMixin } = require('fabric-network');
const fs = require('fs');
const path = require('path');
const APIKey = require('./db/db')
const crypto = require('crypto');


async function RegisterUsers(req) {
    try {
        console.log("start");
        var res = {
            success: false,
            message: ""
        };

        const ccpPath = path.resolve(__dirname, '..', 'blockchain', 'organizations', 'peerOrganizations', 'issuer.com', 'connection-issuer.json');
        const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf-8'));
        const caUrl = ccp.certificateAuthorities["ca.issuer.com"].url;
        const ca = new FabricCaServices(caUrl);

        const walletPath = path.join(process.cwd(),'blockchain','wallets');
        const wallet = await Wallets.newFileSystemWallet(walletPath);

        const userExist = await wallet.get(req.body.username);
        if (userExist) {
            res.message = 'An identity for the "user" already exists in the wallets';
            return res;
        }

        const adminIdentity = await wallet.get('admin');
        
        if (!adminIdentity) {
            res.message = 'An identity for the admin user "admin" not already exists in the wallets';
            return res;
        }

        const provider = wallet.getProviderRegistry().getProvider(adminIdentity.type);

        const adminUser = await provider.getUserContext(adminIdentity, 'admin');

        const secret = await ca.register({
            affiliation: 'issuer.department',
            enrollmentID: req.body.username,
            role: 'admin'
        }, adminUser);

        const enrollment = await ca.enroll({
            enrollmentID: req.body.username,
            enrollmentSecret: secret
        });

        const X509Identity = {
            credentials: {
                certificate: enrollment.certificate,
                privateKey: enrollment.key.toBytes(),
            },
            mspId: 'issuer',
            type: 'X.509',
        };

        await wallet.put(req.body.username, X509Identity);
        if(req.body.username != "guest"){
            
            var hashkey = crypto.createHash('md5').update(req.body.username + Date.now()).digest('hex')

            APIKey.findOne({
                'APIKey.hashKey': req.headers.apikey
            }, function(err, user) {
                if (err) {
                    throw res;
                }
                var apiKey = new APIKey();
                apiKey.APIKey.hashKey = hashkey,
                apiKey.APIKey.username = req.body.username;
                apiKey.save(function(err) {
                    if (err)
                        throw err;
                });
            })


            res.success = true
            res.message = hashkey
            return res
        }else{
            res.success = true
            res.message = "Guest role was created"
            return res
        }
    } catch (err) {
        console.log(err)
        var res = {
            success: false,
            message: err.toString()
        };
        return res;
    }
}

exports.RegisterUsers = RegisterUsers;
