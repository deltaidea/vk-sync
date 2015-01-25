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
		$scope.rawRemoteList = []

		$scope.localList = {}
		$scope.remoteList = {}
		saveListsToFile = _.throttle ->
			console.error "saveListsToFile called, see stack"
			content =
				local: $scope.localList
				remote: $scope.remoteList
			fs.writeFile configFilename, JSON.stringify( content ), ( err ) ->
				if err
					throw err
				console.log "Saved config to file", configFilename, content
		, 1000

		loadListsFromFile = ( callback ) ->
			fs.readFile configFilename, ( err, data ) ->
				try
					content = JSON.parse data
				catch
					content =
						local: {}
						remote: {}
				callback content?.local, content?.remote

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
						remoteFromVk[ audio.owner_id + "_" + audio.id ] = yes
					console.log "got list from vk; proccessed and raw:", remoteFromVk, rawRemoteFromVk
					callback remoteFromVk, rawRemoteFromVk

		saveAsSynced = ( audio ) ->
			$scope.syncList[ audio.id ] = audio
			saveSyncListToFile()

		removeFromSynced = ( audio ) ->
			delete $scope.syncList[ audio.id ]
			saveSyncListToFile()

		$scope.download = ( audio, callback = -> ) ->
			if _.isString audio
				[ ownerId, audioId ] = audio.split( "_" )
				ownerId = parseInt ownerId
				audioId = parseInt audioId
				console.log "download: audio is a string:", audio, ownerId, audioId
				audio = _.find $scope.rawRemoteList, ( audio ) ->
					( audio.id is audioId ) and ( audio.owner_id is ownerId )
				console.log "download: audio was a string, found", audio, "using", ownerId, audioId
			unless audio.downloading
				audio.downloading = yes
				audio.downloaded = no
				$scope.$apply()
				request( audio.url )
					.on( "response", ( response ) ->
						audio.size = response.headers[ "content-length" ]
						audio.progress = 0
					)
					.on( "end", ->
						console.info audio.artist + " - " + audio.title + ".mp3 - completed!"
						audio.downloading = no
						audio.downloaded = yes
						saveAsPresentLocally audio
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
			if not $scope.isSyncing
				$scope.isSyncing = yes

				console.log "starting sync down:",
					$scope.remoteList, $scope.localList
				whatToDownload = []

				downloadNext = ->
					next = _.find _.keys( $scope.remoteList ), ( key ) ->
						not $scope.localList[ key ]
					if next
						console.log "found next to download:", next
						$scope.download next, ( audio ) ->
							downloadNext()
					else
						$scope.isSyncing = no
						console.log "sync down completed!"

				downloadNext()

		loadListsFromFile ( localFromFile, remoteFromFile ) ->
			getVkAudioList ( remoteFromVk, rawRemoteFromVk ) ->
				$scope.localList = localFromFile
				$scope.remoteList = remoteFromVk
				$scope.rawRemoteList = rawRemoteFromVk
				_.each _.keys( localFromFile ), ( id ) ->
					[ ownerId, audioId ] = id.split( "_" )
					ownerId = parseInt ownerId
					audioId = parseInt audioId
					audio = _.find $scope.rawRemoteList, ( audio ) ->
						( audio.id is audioId ) and ( audio.owner_id is ownerId )
					audio?.downloaded = yes
				$scope.$apply()

				arrayDiff = ( a, b ) ->
					bHashtable = {}
					b.forEach ( obj ) -> bHashtable[ obj.id ] = obj
					a.filter ( obj ) -> not `( obj.id in bHashtable )`

				setInterval ->
					console.log "syncing list..."
					getVkAudioList ( remoteFromVk, rawRemoteFromVk ) ->
						removedRemote = arrayDiff $scope.rawRemoteList, rawRemoteFromVk
						addedRemote = arrayDiff rawRemoteFromVk, $scope.rawRemoteList

						console.log "removed:", removedRemote, "added:", addedRemote


						# _.eachRight rawRemoteFromVk, ( audio ) ->
						# 	id = audio.owner_id + "_" + audio.id
						# 	if not $scope.remoteList[ id ]
						# 		console.log "found new audio", audio
						# 		$scope.rawRemoteList.unshift audio
						# 		saveAsPresentRemotely audio
						# _.each $scope.rawRemoteList, ( audio ) ->

						# $scope.$apply()
						console.log "synced list"
						# $scope.syncDown()
				, 30000
]
