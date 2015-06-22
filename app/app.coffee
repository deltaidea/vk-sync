"use strict"

App = angular.module "app", [
	"ngCookies"
	"ngResource"
	"ngRoute"
	"app.controllers"
	"app.directives"
	"app.filters"
	"app.services"
	"app.templates"
]

App.config [
	"$routeProvider"
	"$locationProvider"

	( $routeProvider, $locationProvider, config ) ->

		$routeProvider
			.when( "/home", templateUrl: "app/partials/home.jade" )
			.otherwise( redirectTo: "/home" )

		# Without server side support html5 must be disabled.
		$locationProvider.html5Mode off
]
