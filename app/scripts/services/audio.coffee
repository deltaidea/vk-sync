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
			, ( err, filenames ) ->
				if err
					throw err

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
				if err
					throw err
				callback not err?

		getList = ( folder, callback ) ->
			getRemoteList ( remoteList ) ->
				getLocalList folder, ( localList ) ->
					getSavedSyncedList folder, ( syncedList ) ->
						newList = remoteList

						remoteList.forEach ( remoteItem ) ->
							foundLocal = null
							localList.some ( localItem ) ->
								if localItem.filename is localItem.filename
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
							else if shouldRemove
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

						callback list = newList

		isOfType = ( item, type ) ->
			if not type?
				type = item
				( item ) ->
					switch type
						when "local" then not item.id? or item.isSynced
						when "localOnly" then not item.id?
						when "remote" then item.id?
						when "remoteOnly" then item.id? and not item.isSynced
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

		upload = ( item, folder, callback ) ->
			request = require "request"
			path = require "path"
			fs = require "fs"

			vkApi.request
				method: "audio.getUploadServer"
				callback: ( result ) ->
					uploadUrl = result.response.upload_url

					req = request.post uploadUrl, ( err, res, body ) ->
						if err
							throw err

						saveAudioParams = JSON.parse body
						saveAudioParams.artist = item.artist
						saveAudioParams.title = item.title

						vkApi.request
							method: "audio.save"
							data: saveAudioParams
							callback: ( result ) ->
								item.id = result.response.id
								item.isSynced = yes
								item.hasConflict = no
								item.shouldRemove = no
								saveSyncedList folder, ->
									callback item

					filename = path.join folder, item.filename
					req.form().append "file", fs.createReadStream filename
		download = ( item, folder, callback, onProgress = ( -> ), onStart = -> ) ->
			request = require "request"
			path = require "path"
			fs = require "fs"

			filename = path.join folder, item.filename

			request( item.url )
				.on( "end", ->
					item.isSynced = yes
					item.hasConflict = no
					item.shouldRemove = no
					saveSyncedList folder, ->
						callback item
				)
				.on( "response", ( response ) ->
					item.size = response.headers[ "content-length" ]
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
			console.log "removeLocal:", item, folder, callback
		removeRemote = ( item, callback ) ->
			console.log "removeRemote:", item, callback

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
