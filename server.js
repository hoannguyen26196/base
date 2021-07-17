const express = require('express')
const helmet = require('helmet')
const morgan = require('morgan')
const cors = require('cors')
const bodyParser = require('body-parser')

var app = express()


app.use(helmet())
app.use(bodyParser.json())
app.use(bodyParser.urlencoded({
    extended: false
}));
app.options('*',cors({
    credentials: true
}));

app.use(cors())

app.use(morgan('combined'))

require('./routes')(app)

app.listen(10001, ()=>{
    console.log('listening on port 10001')
})


module.exports = app;