"use strict"

angular.module( "app.directive.scrollTo", []).directive "scrollTo", ->
	restrict: "A"
	scope:
		scrollTo: "@"
	link: ( scope, element ) ->
		element.attr "href", scope.scrollTo

		$( element ).on "click", ->
			target = $ @.hash
			window.scroll 0, target.offset().top
			off
