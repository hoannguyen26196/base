const FabricCaServices = require('fabric-ca-client');
const {Wallets, X509WalletMixin} = require('fabric-network');
const fs = require('fs');
const path = require('path');


async function main(){
  try{
    const ccpPath = path.resolve(__dirname,'..','..','blockchain','organizations','peerOrganizations','issuer.com','connection-issuer.json');
    let ccp = JSON.parse(fs.readFileSync(ccpPath,'utf-8'));

    const caUrl = ccp.certificateAuthorities['ca.issuer.com'].url;
    const ca = new FabricCaServices(caUrl);

    const WalletPath = path.join(process.cwd(),'..','..','blockchain','wallets');
    const wallet = await Wallets.newFileSystemWallet(WalletPath)

    const adminExist = await wallet.get('admin');

    var res = {
      success: false,
      exists: false,
      message: ""
    }

    if(adminExist) {
        console.log('An identity for the admin user "admin" already exists in the wallets');
        res.message = 'An identity for the admin user "admin" already exists in the wallets'
        res.exists = 1;
        return res
    }

    // parameter ADMINID - admin  and ADMINPW - adminpw
    const enrollment = await ca.enroll({
      enrollmentID: 'admin',
      enrollmentSecret: 'adminpw'
    });

    const X509Identity = {
      credentials:{
        certificate: enrollment.certificate,
        privateKey: enrollment.key.toBytes(),
      },
      mspId: 'issuer',
      type: 'X.509',
    }
    
    await wallet.put('admin',X509Identity);
    console.log('Enroll admin successfully');
    return;

  }catch(err){
      console.log(err);
      return;
  }
}

main();