const mongoose = require('mongoose');


APIKey = mongoose.Schema({
    APIKey:{
        username: {
            type: String,
            required: true
        },
        hashKey: {
            type: String,
            required: true
        },
    }
});


module.exports = mongoose.model('APIKey',APIKey);
