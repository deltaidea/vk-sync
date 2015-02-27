"use strict"

angular.module( "app.directives", [
		"app.services"
		"app.directive.scrollTo"
	])
	.directive "appVersion", [
		"version"

		( version ) ->
			( scope, elem, attrs ) ->
				elem.text version
	]
