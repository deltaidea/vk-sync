"use strict"

angular.module( "app.filters", [
	"app.filters.bytes"
])
	.filter( "interpolate", [
		# Dependency `version` resolves to `scripts/services.coffee`.
		"version",

		(version) ->
			(text) ->
				String( text ).replace /\%VERSION\%/mg, version
	])
