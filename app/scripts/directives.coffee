"use strict"

angular.module( "app.directives", [ "app.services" ])
	.directive "appVersion", [
		"version"

		( version ) ->
			( scope, elem, attrs ) ->
				elem.text version
	]
