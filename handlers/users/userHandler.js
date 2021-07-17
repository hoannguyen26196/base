const users = require('./RegisterUser')

exports.signIn = async function(req, res){

}


exports.signUp = async function(req, res){
    try{
        console.log("Create user");
        var message = await users.RegisterUsers(req);
        console.log("done");
        if (!(message.success)) {
            return res.status(400).json({ message: message.message })
        }
        return res.status(200).json({ success: 'Logged', message: message })

    }catch(err){
        return res.status(500).send({
            success: false, 
            errors: err
        });
    }
}

exports.signOut = async function(req, res){
    
}

exports.updateProfile = async function(req, res){
    
}

exports.getProfile = async function (req, res) {
    
}