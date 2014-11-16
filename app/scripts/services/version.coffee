"use strict"

angular.module( "app.services.version", [])
	.factory "version", ->
		fs = require "fs"
		# File `app/assets/package.json` goes straight into `_public`
		# which is the cwd inside the app.
		raw = fs.readFileSync "package.json", encoding: "utf8"
		appPackage = JSON.parse raw

		appPackage.version
