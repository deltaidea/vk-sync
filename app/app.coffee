"use strict"

App = angular.module "app", [
	"ngCookies"
	"ngResource"
	"ngRoute"
	"app.controllers"
	"app.directives"
	"app.filters"
	"app.services"
	"partials"
]

App.config [
	"$routeProvider"
	"$locationProvider"

	( $routeProvider, $locationProvider, config ) ->

		$routeProvider
			.when( "/home", templateUrl: "/partials/home.html" )
			.when( "/todo", templateUrl: "/partials/todo.html" )
			.when( "/view1", templateUrl: "/partials/partial1.html" )
			.when( "/view2", templateUrl: "/partials/partial2.html" )
			.otherwise( redirectTo: "/home" )

		# Without server side support html5 must be disabled.
		$locationProvider.html5Mode off
]
