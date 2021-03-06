"use strict"

angular.module( "app.services.audio", []).factory "audio", [
	"vkApi"

	( vkApi ) ->

		# id, artist, title, filename, shouldRemove, isSynced, hasConflict, url
		list = []

		titleArtistSeparator = " - "
		toFilename = ( artist, title ) ->
			sanitizeFilename = require "sanitize-filename"
			sanitizeFilename( artist + titleArtistSeparator + title ) + ".mp3"

		getRemoteList = ( callback ) ->
			vkApi.request
				method: "audio.get"
				data:
					count: 5000
				callback: ( result ) ->
					if not result?.response?.items?
						throw JSON.stringify result

					rawRemoteList = result.response.items
					remoteList = rawRemoteList.map ( item ) ->
						id: item.id
						artist: item.artist
						title: item.title
						filename: toFilename item.artist, item.title
						url: item.url

					callback remoteList
		getLocalList = ( folder, callback ) ->
			glob = require "glob"

			glob "*.mp3",
				cwd: folder
				nodir: yes
			, ( err, filenames = [] ) ->
				localList = filenames.map ( filename ) ->
					withoutExt = filename.slice 0, -".mp3".length
					parts = withoutExt.split titleArtistSeparator

					artist: parts.shift()
					title: parts.join titleArtistSeparator
					filename: filename

				callback localList

		syncedListFilename = ".vk-sync.json"
		getSavedSyncedList = ( folder, callback ) ->
			path = require "path"
			fs = require "fs"

			filename = path.join folder, syncedListFilename

			fs.readFile filename, ( err, data ) ->
				try
					savedSyncedList = JSON.parse data
				callback savedSyncedList ? []
		saveSyncedList = ( folder, callback ) ->
			path = require "path"
			fs = require "fs"
			mkdirp = require "mkdirp"

			mkdirp folder, ( err ) ->
				throw err if err

				filename = path.join folder, syncedListFilename

				syncedList = list.filter ( item ) ->
					item.isSynced or item.shouldRemove
				.map ( item ) ->
					safeItem =
						id: item.id
						artist: item.artist
						title: item.title
						filename: item.filename

					if item.isSynced
						safeItem.isSynced = yes
					if item.shouldRemove
						safeItem.shouldRemove = yes

					safeItem

				fs.writeFile filename, JSON.stringify( syncedList ), ( err ) ->
					throw err if err
					callback not err?

		getList = ( folder, callback ) ->
			getRemoteList ( remoteList ) ->
				getLocalList folder, ( localList ) ->
					getSavedSyncedList folder, ( syncedList ) ->
						newList = remoteList

						oldList = list

						syncingItem = null
						oldList.some ( oldItem ) ->
							if oldItem.isSyncing
								syncingItem = oldItem

						remoteList.forEach ( remoteItem ) ->
							foundLocal = null
							localList.some ( localItem ) ->
								if remoteItem.filename is localItem.filename
									foundLocal = localItem

							wasSynced = no
							shouldRemove = no
							syncedList.some ( syncedItem ) ->
								if syncedItem.id is remoteItem.id
									wasSynced = !!syncedItem.isSynced
									shouldRemove = !!syncedItem.shouldRemove

							remoteItem.isSynced = no

							if wasSynced and foundLocal
								remoteItem.isSynced = yes
							else if shouldRemove or ( wasSynced and not foundLocal )
								remoteItem.shouldRemove = yes
							else if foundLocal
								remoteItem.hasConflict = yes

						localList.forEach ( localItem ) ->
							foundRemote = null
							remoteList.some ( remoteItem ) ->
								if remoteItem.filename is localItem.filename
									foundRemote = remoteItem

							wasSynced = no
							shouldRemove = no
							syncedList.some ( syncedItem ) ->
								if syncedItem.filename is localItem.filename
									wasSynced = !!syncedItem.isSynced
									shouldRemove = !!syncedItem.shouldRemove

							if not foundRemote
								if wasSynced or shouldRemove
									localItem.shouldRemove = yes
								localItem.isSynced = no
								newList.push localItem

						if syncingItem
							newList.some ( item, i, list ) ->
								if item.filename is syncingItem.filename
									list[ i ] = syncingItem

						callback list = newList

		isOfType = ( item, type ) ->
			if not type?
				type = item
				( item ) ->
					switch type
						when "local" then not item.id? or item.isSynced
						when "localOnly" then not item.id?
						when "localShouldRemove" then not item.id? and item.shouldRemove
						when "remote" then item.id?
						when "remoteOnly" then item.id? and not item.isSynced
						when "remoteShouldRemove" then item.id? and item.shouldRemove
						when "synced" then item.isSynced
						else no
			else
				isOfType( type ) item
		getFirst = ( type = "all" ) ->
			found = null
			if list.length and type is "all"
				found = list[ 0 ]
			else
				list.some ( item ) ->
					if isOfType item, type
						found = item
						yes
			found
		getCount = ( type = "all" ) ->
			if type is "all"
				list.length
			else
				list.reduce ( count, item ) ->
					count + isOfType item, type
				, 0

		upload = ( item, folder, callback, onProgress = ( -> ), onStart = -> ) ->
			path = require "path"
			fs = require "fs"

			filename = path.join folder, item.filename
			fs.stat filename, ( err, stats ) ->
				item.size = stats.size
				vkApi.request
					method: "audio.getUploadServer"
					callback: ( result ) ->
						uploadUrl = result.response.upload_url

						item.isSyncing = yes
						onStart item

						# See: matlus.com/html5-file-upload-with-progress

						formData = new FormData()
						formData.append "file", new File filename, filename
						xhr = new XMLHttpRequest()

						xhr.upload.addEventListener "progress", ( evt ) ->
							item.progress = evt.loaded
							item.percentage = ( item.progress / item.size ) * 100
							onProgress item

						xhr.addEventListener "load", ( evt ) ->
							saveAudioParams = JSON.parse evt.target.responseText
							saveAudioParams.artist = item.artist
							saveAudioParams.title = item.title

							vkApi.request
								method: "audio.save"
								data: saveAudioParams
								callback: ( result ) ->
									item.id = result.response.id
									item.isSyncing = no
									item.isSynced = yes
									item.hasConflict = no
									item.shouldRemove = no
									saveSyncedList folder, ->
										callback item

						xhr.addEventListener "error", ( evt ) ->
							throw evt

						xhr.open "POST", uploadUrl
						xhr.send formData
		download = ( item, folder, callback, onProgress = ( -> ), onStart = -> ) ->
			request = require "request"
			path = require "path"
			fs = require "fs"
			mkdirp = require "mkdirp"

			mkdirp folder, ( err ) ->
				throw err if err

				filename = path.join folder, item.filename

				request( item.url )
					.on( "end", ->
						item.isSyncing = no
						item.isSynced = yes
						item.hasConflict = no
						item.shouldRemove = no
						saveSyncedList folder, ->
							callback item
					)
					.on( "response", ( response ) ->
						item.size = response.headers[ "content-length" ]
						item.isSyncing = yes
						item.progress = 0
						item.percentage = 0
						onStart item
					)
					.on( "data", ( data ) ->
						item.progress += data.length
						item.percentage = ( item.progress / item.size ) * 100
						onProgress item
					)
					.pipe fs.createWriteStream filename

		removeLocal = ( item, folder, callback ) ->
			path = require "path"
			fs = require "fs"

			filename = path.join folder, item.filename

			fs.unlink filename, ( err ) ->
				throw err if err

				item.isSynced = no
				if item.shouldRemove
					item.shouldRemove = no
					index = list.indexOf item
					list.splice index, 1

				callback item
		removeRemote = ( item, callback ) ->
			vkApi.getAuthArgs
				callback: ({ user_id }) ->
					vkApi.request
						method: "audio.delete"
						data:
							audio_id: item.id
							owner_id: user_id
						callback: ->
							item.isSynced = no
							if item.shouldRemove
								item.shouldRemove = no
								index = list.indexOf item
								list.splice index, 1

							callback item

		{
			toFilename
			getRemoteList
			getLocalList
			getSavedSyncedList
			saveSyncedList
			getList
			isOfType
			getFirst
			getCount
			upload
			download
			removeLocal
			removeRemote
		}

]
