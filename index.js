// Activate console timestamp logging
require('console-stamp')(console, '[HH:MM:ss.l]');

// Include our config
const config = require('./config.json');

// Shared constants across all functions
const fs = require('fs');
const Canvas = require('canvas');
const iq = require('image-q');

// Shared variables across all functions
var clientList = [];
var clientTimerList = [];
var image = new Canvas.Image;
var imageData = "3"; // So a blank image spoofs a socket.io ping reply and gets silently ignored
var palette = null;
var paletteArray = null;

// Fatal error capture
process.on('uncaughtException', function (err) {
  console.error(err);
  console.log("Node NOT Exiting...");
});

//
// Functions
//

function uint8ToHex(channel) {
  let buffer = channel.toString(16);
  while (buffer.length < 2) { buffer = "0" + buffer; }
  return buffer;
}

function renderImage() {
  // Render image at maximum potential ComputerCraft monitor resolution 164x81 with double height (162)
  // Sadly there's a bug with creating canvasses where you have to give them constant figures only
  image = new Canvas.Image;
  image.onload = function(){
    let canvas = Canvas.createCanvas(164, 162);
    let ctx = canvas.getContext('2d');
    ctx.drawImage(image, 0, 0, 164, 162);

    // Generate optimum 16 color palette from image
    const inputContainer = iq.utils.PointContainer.fromImageData(ctx.getImageData(0, 0, 164, 162));
    palette = iq.buildPaletteSync([inputContainer], { 
      colorDistanceFormula: 'manhattan-nommyde', // optional
      paletteQuantization: 'neuquant-float', // optional
      colors: 16, // optional
    });
    paletteArray = palette.getPointContainer().toUint8Array();

    // Dither image and apply palette
    const outputContainer = iq.applyPaletteSync(inputContainer, palette, {
      colorDistanceFormula: 'manhattan-nommyde', // optional
      imageQuantization: 'false-floyd-steinberg', // optional
    });
    const outputArray = outputContainer.toUint8Array();

    // Output text string
    let output = "";
    for (let i = 0; i < paletteArray.length; i += 4) {
      output = output + uint8ToHex(paletteArray[i]);
      output = output + uint8ToHex(paletteArray[i+1]);
      output = output + uint8ToHex(paletteArray[i+2]);
    }
    for (let i = 0; i < outputArray.length; i += 4) {
      let index = 0;
      for (let j = 0; j < paletteArray.length; j += 4) {
        if (
          (outputArray[i] == paletteArray[j]) &&
          (outputArray[i+1] == paletteArray[j+1]) &&
          (outputArray[i+2] == paletteArray[j+2])
        ) { break; }
        index += 1;
      }
      output = output + index.toString(16);
    }

    imageData = output;
  };

  image.src = fs.readFileSync(__dirname + '/input.jpg');
}

function addClient(client) {
  clientList[client.socketid] = {
    "screen_x": client.screen_x,
    "screen_y": client.screen_y
  };
}

function deleteClient(client) {
  clientList.removeItem(client);
}

Object.prototype.removeItem = function (key) {
  if (!this.hasOwnProperty(key))
    return
  if (isNaN(parseInt(key)) || !(this instanceof Array))
    delete this[key]
  else
    this.splice(key, 1)
};

//
// Main / startup execution code here
//

// Start our image poller
setInterval(function(){
  renderImage();
}, config.input_poll_delay_ms);

// Set up web and socket.io servers / clients
console.log("Starting server...");
var app = require('express')();
var http = require('http').createServer(app);
var server = require('socket.io')(http);

app.get('/', (req, res) => {
  res.redirect('Video-Playback-init.lua');
});

app.get('/Video-Playback-init.lua', (req, res) => {
  let buffer = fs.readFileSync(__dirname + '/Video-Playback-init.lua', 'utf8');
  if (config.https_enabled) {
    buffer = buffer.replace('%%BASEURL%%', 'https://' + config.server_base_url + '/');
    buffer = buffer.replace('%%WSURL%%', 'wss://' + config.server_base_url + '/socket.io/?transport=websocket');
  } else {
    buffer = buffer.replace('%%BASEURL%%', 'http://' + config.server_base_url + '/');
    buffer = buffer.replace('%%WSURL%%', 'ws://' + config.server_base_url + '/socket.io/?transport=websocket');
  }
  res.setHeader('Content-type', 'text/plain');
  return res.status(200).send(buffer);
});

app.get('/Video-Playback-main.lua', (req, res) => {
  res.sendFile(__dirname + '/Video-Playback-main.lua');
});

app.get('/json.lua', (req, res) => {
  res.sendFile(__dirname + '/json.lua');
});

http.listen(config.service_listen_port, () => {
  console.log('listening on *:' + config.service_listen_port);
});

// SocketIO server code
server.on('error', function(code, reason){
  console.log(reason);
});

server.on("end", function(code, reason){
  console.log('Connection Lost')
});

http.on('error', function(code, reason){
  console.log(reason);
});

app.on('error', function(code, reason){
  console.log(reason);
});

server.on('connection', (socket) => {
  console.log('Client ' + socket.id + ' connected from ' + (socket.handshake.headers["x-real-ip"] || socket.handshake.address) + '.');

  socket.on('error', () => {
    console.log("Error in socket.");
  });

  socket.emit('sendConfig', "Please send your resolution " + socket.id);

  socket.on('sendConfig', (msg) => {
    var [screen_x, screen_y] = msg.split("x");
    console.log("Client " + socket.id + ' connected with resolution of ' + screen_x + " by " + screen_y);
    addClient({
      "socketid": socket.id,
      "screen_x": screen_x,
      "screen_y": screen_y
    });
    socket.emit('drawImage', imageData);
  });

  socket.on('drawComplete', (msg) => {
    if (msg == "true") {
      socket.emit('drawImage', imageData);
    }
  });

  socket.on('disconnect', () => {
    console.log("Client " + socket.id + ' disconnected');
    deleteClient(socket.id);
  });
});


