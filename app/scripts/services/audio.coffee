"use strict"

angular.module( "app.services.audio", []).factory "audio", [
	"vkApi"

	( vkApi ) ->

		getLocalAudioList: ( folder, callback ) ->
			glob = require "glob"

			glob "*.mp3",
				cwd: folder
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

		getVkAudioList: ( callback = (->), page = 1, itemsPerPage = 5000 ) ->
			vkApi.request
				method: "audio.get"
				data:
					offset: ( page - 1 ) * itemsPerPage
					count: itemsPerPage
				callback: ( result ) ->
					rawRemoteFromVk = result.response.items
					remoteFromVk = {}
					rawRemoteFromVk.forEach ( item ) ->
						remoteFromVk[ item.id ] =
							id: item.id
							artist: item.artist
							title: item.title
							url: item.url

					callback remoteFromVk

		upload: ( audioInfo, readStream, callback = -> ) ->
			request = require "request"

			vkApi.request
				method: "audio.getUploadServer"
				callback: ( result ) ->
					uploadUrl = result.response.upload_url

					req = request.post uploadUrl, ( err, res, body ) ->
						saveAudioParams = JSON.parse body
						saveAudioParams.artist = audioInfo.artist
						saveAudioParams.title = audioInfo.title

						vkApi.request
							method: "audio.save"
							data: saveAudioParams
							callback: ( result ) ->
								uploadedAudio = result.response
								uploadedAudio.filename = audioInfo.filename
								callback uploadedAudio

					req.form().append "file", readStream

		download: ({ audioInfo, writeStream, onEnd, onStart, onProgress }) ->
			if audioInfo.downloading
				return

			onEnd ?= ->
			onStart ?= ->
			onProgress ?= ->

			audioInfo.downloading = yes
			audioInfo.downloaded = no

			request = require "request"

			request( audioInfo.url )
				.on( "end", ->
					audioInfo.downloading = no
					audioInfo.downloaded = yes
					onEnd audioInfo
				)
				.on( "response", ( response ) ->
					audioInfo.size = response.headers[ "content-length" ]
					audioInfo.progress = 0
					audioInfo.percentage = 0
					onStart audioInfo
				)
				.on( "data", ( data ) ->
					audioInfo.progress += data.length
					audioInfo.percentage = ( audioInfo.progress / audioInfo.size ) * 100
					onProgress audioInfo
				)
				.pipe writeStream

]
