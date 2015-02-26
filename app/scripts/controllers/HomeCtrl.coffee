"use strict"

angular.module( "app.controllers.HomeCtrl", []).controller "HomeCtrl", [
	"$scope"
	"vkApi"
	"audio"

	( $scope, vkApi, audio ) ->
		request = require "request"
		fs = require "fs"
		sanitizeFilename = require "sanitize-filename"

		$scope._ = _ = require "lodash"

		$scope.localPath = "D:/vk-music/"
		configFilename = $scope.localPath + ".vk-sync.json"

		$scope.syncList = {}
		$scope.remoteList = {}
		$scope.localList = []

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

		$scope.upload = ( audioInfo, callback = -> ) ->
			readStream = fs.createReadStream $scope.localPath + audioInfo.filename
			audio.upload audioInfo, readStream, callback

		$scope.download = ( audioInfo, callback = -> ) ->
			filename = sanitizeFilename( audioInfo.artist + " - " +
				audioInfo.title ) + ".mp3"

			audio.download
				audioInfo: audioInfo
				writeStream: fs.createWriteStream $scope.localPath + filename
				onEnd: ( audioInfo ) ->
					audioInfo.filename = filename
					saveAsSynced audioInfo
					callback audioInfo
					$scope.$apply()
				onStart: ->
					$scope.$apply()
				onProgress: _.throttle ->
					$scope.$apply()
				, 40

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
			audio.getVkAudioList ( remoteFromVk ) ->
				_.each _.keys( $scope.syncList ), ( id ) ->
					remoteFromVk[ id ]?.downloaded = yes

				$scope.remoteList = remoteFromVk
				audio.getLocalAudioList $scope.localPath, ( localList ) ->
					$scope.localList = localList
					$scope.$apply()

		syncIntervalId = null
		$scope.autoSyncEnabled = no

		$scope.startAutoSync = ->
			$scope.autoSyncEnabled = yes

			doTheThing = ->
				unless $scope.isSyncing
					audio.getVkAudioList ( remoteFromVk ) ->
						_.each _.keys( $scope.syncList ), ( id ) ->
							remoteFromVk[ id ]?.downloaded = yes

						$scope.remoteList = remoteFromVk
						$scope.$apply()
						$scope.syncDown ->
							audio.getLocalAudioList $scope.localPath, ( localList ) ->
								$scope.localList = localList
								$scope.syncUp()

			doTheThing()
			syncIntervalId = setInterval doTheThing, 30000

		$scope.stopAutoSync = ->
			clearInterval syncIntervalId
			$scope.autoSyncEnabled = no

]
