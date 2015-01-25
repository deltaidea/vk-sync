"use strict"

describe "controllers", ->

	beforeEach module "app.controllers"
	beforeEach module "app.services.vkApi"

	describe "HomeCtrl", ->

		it "should make scope testable", inject ( $rootScope, $controller, vkApi ) ->
			scope = $rootScope.$new()

			ctrl = $controller "HomeCtrl",
				$scope: scope
				vkApi: vkApi

			expect(scope.onePlusOne).toEqual(2)
