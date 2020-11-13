# ComputerCraft-NodeJS-Video-Server
Regularly parses input.jpg through a ditherer and sends that to any connected ComputerCraft terminal

## Notice
This is an experiment and far from perfect. If it doesn't work for you leave an Issue and I'll review when I get any spare time. Don't get your hopes up though.

Also be aware, there is **no sound** from this whatsoever. I know of no way to stream sound into ComputerCraft computers.

## Requirements

### Minecraft
* ComputerCraft mod version 1.8+ or CC:Tweaked (this is packaged with, say, FTB Revelations 1.12.2)
* An 8x6 grid of Advanced Monitors and an Advanced Computer connected directly or through networking cables
* A fairly good Minecraft server CPU if playing MP

### NodeJS server
* Any recent version of NodeJS should work, I wrote this using v12.18.3
* A good CPU (I tested this on a dual core virtual machine on an Intel Xeon E5-2643 v2 CPU)

### Misc / recommended
* ffmpeg to convert video to still images on the fly
* nginx or another web server with HTTPS / SSL termination in front for good web security (not required but wise)

## Installation
1. Clone down the git repo to wherever you want to run the code
2. run `npm install` to download all the libraries required

## Configuration
1. Copy `config.EXAMPLE.json` to `config.json`
2. Edit the file and fill in the following fields;

* **server_base_url**: The URL or IP address of your NodeJS server or HTTPS / SSL termination web server __without__ http:// or https:// at the start ie. `my.awesomeserver.com/optional/paths`
* **https_enabled**: `true` or `false` depending on whether there's SSL termination - this tunes the prefixes for both the LUA file downloads and WebSocket
* **service_listen_port**: The TCP port to listen on - unless you're running other NodeJS services or something else on port 8080 chances are you won't need to change this
* **input_poll_delay_ms**: The millisecond delay between re-reading `input.jpg` - default 125 is circa 8 frames per second, lower this if you get delays between frames, increase it for more frames per second (keep an eye on your CPU load)

## Running it as a test
1. Find a suitable jpeg image circa 320x240 resolution and save it as `input.jpg` in the git repo folder
2. Run `nodejs index.js` and you should see something like this...

```
[[01:28:17.678]] [LOG]    Starting server...
[[01:28:17.824]] [LOG]    listening on *:8080
```

3. Confirm you can get to the web server by navigating to the `server_base_url` URL you set in the config in your web browser ie. https://my.awesomeserver.com/ (example only)

4. If successful, you should be redirected automatically to a URL ending in `Video-Playback-init.lua` ie. https://my.awesomeserver.com/Video-Playback-init.lua

5. Once you confirmed you can see the LUA code, copy that URL to your clipboard and go to your Computer in Minecraft and run the following commands...

```
wget https://my.awesomeserver.com/Video-Playback-init.lua

Video-Playback-init
```

6. If all is well, you should now see your sample input.jpg image on your ComputerCraft screen :)

## Running it permanently
For this I recommend using `forever` or my personal favourite, `pm2` which you can get by running something like `npm install forever` or `npm install pm2`.

I only have experience with `pm2` so this guide focuses on that.

1. If you haven't already, stop the test run by pressing `ctrl+c` to return to the terminal

2. Install `pm2` as required

3. Run `pm2 start index.js --name="ComputerCraft-NodeJS-Video-Server"` to start it (`--name="ComputerCraft-Video"` is optional but gives it a nice name)

4. Run `pm2 save` to record the current state as good

## Feeding in video
So this part is fun. You can do this plenty of ways, but the best way would be with ffmpeg with something like this...

```
ffmpeg -re -i /path/to/my/videofile.avi -s 320x240 -update 1 -y /path/to/ComputerCraft-NodeJS-Video-Server/input.jpg
```

The `ffmpeg` flags are as follows;

* `-re` = Read the file input file and play back at the original rate (otherwise you get fast video playback)
* `-i /path/to/file` = The video file to play
* `-s 320x240` = Rescale the output image to 320x240 (which seems like an ideal image size for speed and quality)
* `-update 1` = Only write to one singular input.jpg file (instead of creating a sequence)
* `-y` = Overwrite the file without prompting
* `/path/to/ComputerCraft-NodeJS-Video-Server/input.jpg` = The image file to write the video frames to

## Support
If you have issues with this, please file an issue above.

Alternatively, you can visit the [computercraft.cc Discord](https://discord.computercraft.cc/) and find me lurking in the #computercraft channel.

## Credits
* SquidDev for support
* JackMacWindows for support
* Monolith Dev for support
* Any other helpful person in #computercraft whose name I've missed
* [computercraft.cc creators and contributors](https://computercraft.cc/)
* ElvishJerricco for the [json.lua library](http://www.computercraft.info/forums2/index.php?/topic/5854-json-api-v201-for-computercraft/)
