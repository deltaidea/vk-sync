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
				callback()
			, throttledApply
		$scope.download = ( item, callback = -> ) ->
			audio.download item, $scope.localPath, ->
				$scope.$apply()
				callback()
			, throttledApply

		$scope.isSyncing = no
		$scope.syncDown = ( callback = -> ) ->
			unless $scope.isSyncing
				$scope.isSyncing = yes

				downloadRecursive = ->
					next = audio.getFirst "remoteOnly"
					if next?
						$scope.download next, downloadRecursive
					else
						$scope.isSyncing = no
						callback()

				downloadRecursive()
		$scope.syncUp = ( callback = -> ) ->
			unless $scope.isSyncing
				$scope.isSyncing = yes

				uploadRecursive = ->
					next = audio.getFirst "localOnly"
					if next?
						$scope.upload next, uploadRecursive
					else
						$scope.isSyncing = no
						callback()

				uploadRecursive()

		$scope.getList ->
			$( "body" ).scrollspy target: "#menu"
			window.scroll 0, $( "#remote" ).offset().top


]
