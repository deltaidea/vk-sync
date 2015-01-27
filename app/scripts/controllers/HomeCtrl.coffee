"use strict"

angular.module( "app.controllers.HomeCtrl", []).controller "HomeCtrl", [
	"$scope"
	"vkApi"

	( $scope, vkApi ) ->
		request = require "request"
		fs = require "fs"
		glob = require "glob"
		sanitizeFilename = require "sanitize-filename"

		$scope._ = _ = require "lodash"

		$scope.localPath = "D:/vk-music/"
		configFilename = $scope.localPath + ".vk-sync.json"

		$scope.syncList = {}
		$scope.remoteList = {}
		$scope.localList = {}

		saveSyncListToFile = _.throttle ->
			fs.writeFile configFilename, JSON.stringify( $scope.syncList ),
			( err ) ->
				if err
					throw err
				$scope.syncList
		, 1000

		loadSyncListFromFile = ( callback ) ->
			fs.readFile configFilename, ( err, data ) ->
				try
					syncList = JSON.parse data
				callback syncList ? {}

		getLocalAudioList = ( callback ) ->
			glob "*.mp3",
				cwd: $scope.localPath
				nodir: yes
			, ( err, files ) ->
				if err
					throw err

				localAudios = files.map ( filename ) ->
					withoutExt = filename.slice 0, -4
					parts = withoutExt.split " - "

					filename: filename
					artist: parts.shift()
					title: parts.join " - "

				callback localAudios

		getVkAudioList = ( callback = (->), page = 1, itemsPerPage = 5000 ) ->
			vkApi.request
				method: "audio.get"
				data:
					offset: ( page - 1 ) * itemsPerPage
					count: itemsPerPage
				callback: ( result ) ->
					rawRemoteFromVk = result.response.items
					remoteFromVk = {}
					_.each result.response.items, ( audio ) ->
						remoteFromVk[ audio.id ] =
							id: audio.id
							artist: audio.artist
							title: audio.title
							url: audio.url

					_.each _.keys( $scope.syncList ), ( id ) ->
						remoteFromVk[ id ]?.downloaded = yes

					callback remoteFromVk

		saveAsSynced = ( audio ) ->
			safeAudio =
				artist: audio.artist
				title: audio.title
				filename: audio.filename
			$scope.syncList[ audio.id ] = safeAudio
			saveSyncListToFile()

		removeFromSynced = ( audio ) ->
			delete $scope.syncList[ audio.id ]
			saveSyncListToFile()

		$scope.upload = ( audio, callback = -> ) ->
			vkApi.request
				method: "audio.getUploadServer"
				callback: ( result ) ->
					uploadUrl = result.response.upload_url
					fullPath = $scope.localPath + audio.filename

					req = request.post uploadUrl, ( err, res, body ) ->
						saveAudioParams = JSON.parse body
						saveAudioParams.artist = audio.artist
						saveAudioParams.title = audio.title

						vkApi.request
							method: "audio.save"
							data: saveAudioParams
							callback: ( result ) ->
								uploadedAudio = result.response
								uploadedAudio.filename = audio.filename
								callback uploadedAudio

					req.form().append "file", fs.createReadStream fullPath

		$scope.download = ( audio, callback = -> ) ->
			unless audio.downloading
				audio.downloading = yes
				audio.downloaded = no
				$scope.$apply()
				filename = sanitizeFilename( audio.artist + " - " + audio.title ) + ".mp3"

				throttledApply = _.throttle ->
					$scope.$apply()
				, 250

				request( audio.url )
					.on( "response", ( response ) ->
						audio.size = response.headers[ "content-length" ]
						audio.progress = 0
						audio.percentage = 0
					)
					.on( "end", ->
						audio.downloading = no
						audio.downloaded = yes
						audio.filename = filename
						saveAsSynced audio
						callback audio
						$scope.$apply()
					)
					.on( "data", ( data ) ->
						audio.progress += data.length
						audio.percentage = ( audio.progress / audio.size ) * 100
						throttledApply()
					)
					.pipe fs.createWriteStream $scope.localPath + filename

		$scope.isSyncing = no
		$scope.syncDown = ( callback = -> ) ->
			unless $scope.isSyncing
				$scope.isSyncing = yes

				downloadNext = ->
					nextId = _.find _.keys( $scope.remoteList ), ( key ) ->
						not $scope.syncList[ key ]?
					if nextId
						next = $scope.remoteList[ nextId ]
						$scope.download next, ( audio ) ->
							downloadNext()
					else
						$scope.isSyncing = no
						callback()

				downloadNext()

		$scope.syncUp = ( callback = -> ) ->
			unless $scope.isSyncing
				$scope.isSyncing = yes

				uploadNext = ->
					next = _.find $scope.localList, ( audio ) ->
						not _.any $scope.syncList, filename: audio.filename
					if next
						$scope.upload next, ( audio ) ->
							saveAsSynced audio
							uploadNext()
					else
						$scope.isSyncing = no
						callback()

				uploadNext()

		loadSyncListFromFile ( syncList ) ->
			$scope.syncList = syncList
			getVkAudioList ( remoteFromVk ) ->
				$scope.remoteList = remoteFromVk
				getLocalAudioList ( localList ) ->
					$scope.localList = localList
					$scope.$apply()

		syncIntervalId = null
		$scope.autoSyncEnabled = no

		$scope.startAutoSync = ->
			$scope.autoSyncEnabled = yes

			doTheThing = ->
				unless $scope.isSyncing
					getVkAudioList ( remoteFromVk ) ->
						$scope.remoteList = remoteFromVk
						$scope.$apply()
						$scope.syncDown ->
							getLocalAudioList ( localList ) ->
								$scope.localList = localList
								$scope.syncUp()

			doTheThing()
			syncIntervalId = setInterval doTheThing, 30000

		$scope.stopAutoSync = ->
			clearInterval syncIntervalId
			$scope.autoSyncEnabled = no

]
