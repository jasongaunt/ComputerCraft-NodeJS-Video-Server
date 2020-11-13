--[[
Quick ComputerCraft program to bounce a cube around the screen
on the first monitor it finds

Written by JBG 20201101
]]

os.loadAPI("json.lua")

local WSSURL = arg[1]
local foregroundColor = colors.white
local backgroundColor = colors.black

-- Locate monitor
local monitor = { }
local sides = peripheral.getNames()
for i = 1, #sides do
	if peripheral.getType(sides[i]) == "monitor" then
		monitor = peripheral.wrap(sides[i])
		break
	end
end

-- Exit if no monitor found
if monitor == { } then
	error("No monitors found")
end

-- Set resolution
monitor.setTextScale(0.5)
-- monitor.clear()
monitor.setTextColor(foregroundColor)
monitor.setBackgroundColor(backgroundColor)

-- Get our resolution
local width, height = monitor.getSize()
local buffer = ""
local pingInterval = 5000
local ws
local err
local readyToDraw = false
local debugMode = false
local configured = false

local renderLine = ""; for i = 1, width, 1 do renderLine = renderLine .. "\143" end

-- Main drawing function
function drawScreen(pic)
	-- Set our palette
	local color = 1;
	for palette = 0, 95, 6 do
		term.setPaletteColor(color, tonumber(pic:sub(palette, palette +6),16));
		color = color * 2;
	end
	-- Draw image
	local max = (width * height * 2) - (width);
	for offset = 96, max, width do
		local foreground = pic:sub(offset + 1, offset + width)
		offset = offset + width;
		local background = pic:sub(offset + 1, offset + width)

		term.setCursorPos(1, (offset / (width * 2)) + 1)
		term.blit(renderLine, foreground, background);
	end

	sleep(0.0)
	sendMessage('42["drawComplete", "true"]')
end

-- Function to send websocket messages
function sendMessage(message)
	if ws then
		ws.send(message)
		if debugMode then print("Message xmit: " .. message) end
		return true
	else
		return false
	end
end

-- Function to process websocket messages
function processMessage(message)
	if not message then return end
	if debugMode then print("Message recv: " .. message) end

	-- Only run these if we are configuring..
	if not configured then
		-- Debug output briefly
		print("Message received: " .. message)
		-- Identify our message type and then strip it from the message and parse as JSON
		local messageType = message:gsub(
			"^(%d+).*",
			"%1"
		)
		message = message:gsub(
			"^([0-9 ]+)",
			""
		):gsub(
			'%["(.-)","(.-)"%]', 
			'{"command": "%1", "value": "%2"}'
		):gsub(
			'([{:])',
			'%1 '
		):gsub(
			'(,")',
			', "'
		):gsub(
			'}',
			' }'
		)
		local obj = json.decode(message)

		-- Perform different action depending on message type
		if messageType == "0" then -- Config received
			pingInterval = obj['pingInterval']
		elseif messageType == "42" then -- Application message received
			if obj['command'] == "sendConfig" then -- Application requests our screen resolution
				sendMessage('42["sendConfig", "' .. width .. 'x' .. height .. '"]')
				configured = true
			elseif obj['command'] == "drawImage" then -- Application requests we draw something
				drawScreen(obj['value'])
			end
		end
	else -- Speed up by only grabbing the characters we need to draw
		if #message < width * height then return end
		drawScreen(message:sub(17,(#message-2)))
	end
end

-- Function to poll websocket and try and keep the connection alive
function pollLoop()
	local message
	while true do
		print("Attempting to connect to "..WSSURL.."...")

		ws, err = http.websocket(WSSURL)

		if ws then
			print("Connected successfully.")
			print("")
			while ws do
				message = ws.receive(2)
				if message ~= nil then processMessage(message) end
			end
		else
			print("Unable to connect: " .. err)
		end

		if ws then ws.close() end
		sleep(5)
	end
end

-- Function to periodically send messages
function pingLoop()
	while true do
		sendMessage("2")
		sleep(pingInterval / 1000)
	end
end

-- Function to monitor touch events
function touchLoop()
	os.pullEvent("monitor_touch")
	monitor.clear()
	monitor.setCursorPos(1,2)
	monitor.setTextScale(3)
	monitor.write("Rebooting!")
	os.reboot()
end

-- Test function to reboot every few seconds for rapid development
function rebootLoop()
	sleep(5.0)
	os.reboot()
end

-- Start all functions
if not debugMode then term.redirect(monitor) end
parallel.waitForAll(pollLoop, pingLoop, touchLoop)