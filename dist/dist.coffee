childProcess = require "child_process"
os = require "os"
fs = require "fs-extra"
packageManifest = require "./cache/package.json"

isWindows = os.type() is "Windows_NT"

pathToRar = "C:/Program Files/WinRAR/WinRAR.exe"
pathsToConf =
	portable: "sfx-portable.conf"
	installer: "sfx-installer.conf"
pathToIcon = "cache/icon.ico"
pathToContent = "cache/"
targetFilenames =
	portable: "releases/vk-sync-#{packageManifest.version}-portable.exe"
	installer: "releases/vk-sync-#{packageManifest.version}-install.exe"

# We apparently have ../ (project root) as cwd in this script.
fs.mkdirpSync "dist/releases"
fs.copySync "node_modules/nw/nwjs", "dist/cache"

# WinRAR CLI documentation:
# http://acritum.com/software/manuals/winrar/index.html?page=html%2Fhelpswitches.htm
rarArgs =
	portable: [
		"a" # Add files == create an archive if it doesn't exist
		"-ibck" # Run in background == no GUI
		"-inul" # Don't show GUI messages on errors
		"-sfx" # Create a self-extracting archive
		"-r" # Recursively add all folders and files
		"-m1" # Compression method (m0 - Store .. m5 - Best)
		"-ep1" # Trim base directory from file paths == add to the root of the archive
		"-z#{pathsToConf.portable}" # Config with SFX options
		"-iicon#{pathToIcon}" # The archive file will have this icon
		"#{targetFilenames.portable}"
		"#{pathToContent}"
	]
	installer: [
		"a"
		"-ibck"
		"-inul"
		"-sfx"
		"-r"
		"-m5"
		"-ep1"
		"-z#{pathsToConf.installer}" # Different SFX config
		"-iicon#{pathToIcon}"
		"#{targetFilenames.installer}" # Different target name
		"#{pathToContent}"
	]

if isWindows
	childProcess.spawnSync pathToRar, rarArgs.portable, cwd: "dist/"
	console.log "Compiled #{targetFilenames.portable}"
	childProcess.spawnSync pathToRar, rarArgs.installer, cwd: "dist/"
	console.log "Compiled #{targetFilenames.installer}"
else
	console.error "Nope - not Windows, can't use WinRAR"
