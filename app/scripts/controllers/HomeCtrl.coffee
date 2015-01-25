"use strict"

angular.module( "app.controllers.HomeCtrl", []).controller "HomeCtrl", [
	"$scope"
	"vkApi"

	( $scope, vkApi ) ->
		request = require "request"
		fs = require "fs"
		sanitizeFilename = require "sanitize-filename"

		$scope._ = _ = require "lodash"

		$scope.localPath = "D:/vk-music/"
		configFilename = $scope.localPath + ".vk-sync.json"

		$scope.syncList = {}
		$scope.remoteList = {}

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
					callback remoteFromVk

		saveAsSynced = ( audio ) ->
			safeAudio =
				artist: audio.artist
				title: audio.title
			$scope.syncList[ audio.id ] = safeAudio
			saveSyncListToFile()

		removeFromSynced = ( audio ) ->
			delete $scope.syncList[ audio.id ]
			saveSyncListToFile()

		$scope.download = ( audio, callback = -> ) ->
			unless audio.downloading
				audio.downloading = yes
				audio.downloaded = no
				$scope.$apply()
				request( audio.url )
					.on( "response", ( response ) ->
						audio.size = response.headers[ "content-length" ]
						audio.progress = 0
						audio.percentage = 0
					)
					.on( "end", ->
						audio.downloading = no
						audio.downloaded = yes
						saveAsSynced audio
						callback audio
						$scope.$apply()
					)
					.on( "data", ( data ) ->
						audio.progress += data.length
						audio.percentage = ( audio.progress / audio.size ) * 100
						$scope.$apply()
					)
					.pipe( fs.createWriteStream $scope.localPath +
						sanitizeFilename( audio.artist + " - " + audio.title ) + ".mp3" )

		$scope.isSyncing = no
		$scope.syncDown = ->
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

				downloadNext()

		loadSyncListFromFile ( syncList ) ->
			getVkAudioList ( remoteFromVk ) ->
				$scope.syncList = syncList
				$scope.remoteList = remoteFromVk
				_.each _.keys( syncList ), ( id ) ->
					$scope.remoteList[ id ]?.downloaded = yes
				$scope.$apply()

		syncIntervalId = null

		startAutoSync = ->
			syncIntervalId = setInterval ->
				unless $scope.isSyncing
					getVkAudioList ( remoteFromVk ) ->
						$scope.remoteList = remoteFromVk
						$scope.syncDown()
			, 30000

		stopAutoSync = ->
			clearInterval syncIntervalId

]
