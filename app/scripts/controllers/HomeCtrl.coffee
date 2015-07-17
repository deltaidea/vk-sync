"use strict"

angular.module( "app.controllers.HomeCtrl", []).controller "HomeCtrl", [
	"$scope"
	"audio"

	( $scope, audio ) ->
		$scope.list = []
		$scope.localPath = "D:/vk-music"

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
		$scope.syncDown = ( callback = -> ) ->
			unless $scope.isSyncing
				$scope.isSyncing = yes
				$scope.$apply()

				downloadRecursive = ->
					next = audio.getFirst "remoteOnly"
					if next?
						$scope.download next, downloadRecursive
					else
						$scope.isSyncing = no
						$scope.$apply()
						callback()

				removeLocalRecursive = ->
					next = audio.getFirst "localShouldRemove"
					if next?
						$scope.removeLocal next, removeLocalRecursive
					else
						downloadRecursive()

				removeLocalRecursive()
			else
				callback()
		$scope.syncUp = ( callback = -> ) ->
			unless $scope.isSyncing
				$scope.isSyncing = yes
				$scope.$apply()

				uploadRecursive = ->
					next = audio.getFirst "localOnly"
					if next?
						$scope.upload next, uploadRecursive
					else
						$scope.isSyncing = no
						$scope.$apply()
						callback()

				removeRemoteRecursive = ->
					next = audio.getFirst "remoteShouldRemove"
					if next?
						$scope.removeRemote next, removeRemoteRecursive
					else
						uploadRecursive()

				removeRemoteRecursive()
			else
				callback()

		$scope.sync = ( callback = -> ) ->
			unless $scope.isSyncing
				$scope.getList ->
					$scope.syncDown ->
						$scope.syncUp ->
							callback()

		$scope.$watch "localPath", ->
			unless $scope.isSyncing
				$scope.getList()

		setInterval ->
			unless $scope.isSyncing
				$scope.getList()
		, 15 * 1000

]
