"use strict"

angular.module( "app.controllers.HomeCtrl", []).controller "HomeCtrl", [
	"$scope"
	"audio"

	( $scope, audio ) ->
		$scope.localPath = "D:/vk-music"

		$scope.list = []
		$scope.getCount = audio.getCount
		$scope.isOfType = audio.isOfType

		$scope.upload = ( item, callback = -> ) ->
			audio.upload item, $scope.localPath, ->
				$scope.$apply()
				callback()

		$scope.download = ( item, callback = -> ) ->
			audio.download item, $scope.localPath, ->
				$scope.$apply()
				callback()

		$scope.getList = ( callback = -> ) ->
			audio.getList $scope.localPath, ( list ) ->
				$scope.list = list
				$scope.$apply()
				callback list

		$scope.getList ->
			$( "body" ).scrollspy target: "#menu"


]
