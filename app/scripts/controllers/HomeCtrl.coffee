"use strict"

angular.module( "app.controllers.HomeCtrl", []).controller "HomeCtrl", [
	"$scope"
	"audio"

	( $scope, audio ) ->
		$scope.list = []
		$scope.localPath = localStorage.localPath or "D:/vk-music"

		$scope.getList = ( callback = -> ) ->
			audio.getList $scope.localPath, ( list ) ->
				$scope.list = list
				$scope.$apply()
				callback list
		$scope.getCount = audio.getCount
		$scope.isOfType = audio.isOfType

		_ = require "lodash"

		throttledApply = _.throttle ->
			$scope.$apply()
		, 50

		$scope.upload = ( item, callback = -> ) ->
			audio.upload item, $scope.localPath, ->
				$scope.$apply()
				$( "body" ).scrollspy "refresh"
				callback()
			, throttledApply
		$scope.download = ( item, callback = -> ) ->
			audio.download item, $scope.localPath, ->
				$scope.$apply()
				$( "body" ).scrollspy "refresh"
				callback()
			, throttledApply

		$scope.removeLocal = ( item, callback = -> ) ->
			audio.removeLocal item, $scope.localPath, ->
				$scope.$apply()
				$( "body" ).scrollspy "refresh"
				callback()
		$scope.removeRemote = ( item, callback = -> ) ->
			audio.removeRemote item, ->
				$scope.$apply()
				$( "body" ).scrollspy "refresh"
				callback()

		$scope.isSyncing = no
		$scope.sync = ( callback = -> ) ->
			if $scope.isSyncing
				callback()

			$scope.isSyncing = yes

			syncOne = ( callback ) ->
				if next = audio.getFirst "localShouldRemove"
					$scope.removeLocal next, -> callback yes
				else if next = audio.getFirst "remoteOnly"
					$scope.download next, -> callback yes
				else if next = audio.getFirst "remoteShouldRemove"
					$scope.removeRemote next, -> callback yes
				else if next = audio.getFirst "localOnly"
					$scope.upload next, -> callback yes
				else
					callback no

			syncOneRecursive = ( afterAll, afterEach ) ->
				syncOne ( hadSomethingToSync ) ->
					if hadSomethingToSync
						afterEach()
						syncOneRecursive afterAll, afterEach
					else
						afterAll()

			syncRecursive = ->
				syncedCount = 0
				$scope.getList ->
					afterAll = ->
						if syncedCount > 0
							syncRecursive()
						else
							$scope.isSyncing = no
							$scope.$apply()
							callback()

					afterEach = ->
						syncedCount += 1

					syncOneRecursive afterAll, afterEach

			syncRecursive()

		$scope.$watch "localPath", ->
			unless $scope.isSyncing
				$scope.getList()
				localStorage.localPath = $scope.localPath

		setInterval ->
			$scope.getList()
		, 15 * 1000

]
