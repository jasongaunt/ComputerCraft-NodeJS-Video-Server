--[[
ComputerCraft init script that automatically updates code and attempts to keep your script running indefinitely
Written by JBG 20201107

This init script strongly assumes that this init script is called: my_awesome_script-init.lua
and that the main script to run after we have booted up is called: my_awesome_script-main.lua

"my_awesome_script" can be any combination of letters, numbers, underscores or dashes, but it must start
with either a letter or a number and the filenames MUST always end in either of the following...

	"-init.lua" for this init script
	and
	"-main.lua" for the main program / script

It is highly recommended that you store your programs runtime configuration in a file such as "config.txt" and read this every time your program runs.
--]]


-------------------------------------
-- Configuration block starts here --
-------------------------------------

-- Base URL to get our files from, you will need to change this to your own web server
baseURL = "%%BASEURL%%"

-- Extra command line flags for your program go here or leave empty "" if you have none
runCommandFlags = "%%WSURL%%"

-- List of additional files to download such as support libraries or leave empty as {} if you have none
filesToInstall = {
	"json.lua"             -- LUA JSON decoding support
}

-- Attempt to push all our boot-up diagnostic output to a monitor if its connected, set this to false if you have monitor-based issues
outputToMonitor = true 

-----------------------------------
-- Configuration block ends here --
-----------------------------------


-- Do not edit below this point unless you REALLY know what you're doing

-- Locate monitor and redirect console output to it if present
if outputToMonitor == true then
	local monitor = { }
	local sides = peripheral.getNames()
	for i = 1, #sides do
		if peripheral.getType(sides[i]) == "monitor" then
			monitor = peripheral.wrap(sides[i])
			break
		end
	end
	if monitor ~= { } then
		monitor.setTextScale(0.5)
		monitor.setTextColor(colors.white)
		monitor.setBackgroundColor(colors.black)
		monitor.clear()
		monitor.setCursorPos(1, 1)
		term.redirect(monitor)
	end
end

-- Get our init script name and then derive our main script name from it
initScriptName = shell.getRunningProgram()
mainScriptName = initScriptName:gsub("-init%.lua", "-main.lua")

-- Delete existing files and download fresh every reboot
table.insert(filesToInstall, initScriptName)
table.insert(filesToInstall, mainScriptName)
for index,file in pairs(filesToInstall) do
	if fs.exists(file) == true then
		shell.run("rm "..file)
	end
	shell.run("wget "..baseURL..file)
end

-- Copy our init program to startup.lua so that it runs on boot
if fs.exists("startup.lua") == true then shell.run("rm startup.lua") end
local startupFile = fs.open("startup.lua", "w")
startupFile.write("if fs.exists(\""..initScriptName.."\") == false then shell.run(\"wget "..baseURL..initScriptName.."\") end\n")
startupFile.write("shell.run(\""..initScriptName.."\")\n")
startupFile.write("sleep(5.0)\n")
startupFile.write("os.reboot()")
startupFile.close()

-- Set our computer label
shell.run("label set "..mainScriptName)

-- Run program and reboot computer if it crashes
while true do
	shell.run(mainScriptName.." "..runCommandFlags)
	print("Program \"".. mainScriptName .."\" stopped or crashed, rebooting in 5 seconds (press CTRL+T to abort)...")
	sleep(5.0)
	os.reboot()
end