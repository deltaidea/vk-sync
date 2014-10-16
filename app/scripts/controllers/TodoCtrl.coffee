"use strict"

angular.module( "app.controllers.TodoCtrl", []).controller "TodoCtrl", [
	"$scope"

	( $scope ) ->
		$scope.todos = [
			text: "learn angular"
			done: true
		,
			text: "build an angular app"
			done: false
		]

		$scope.addTodo = ->
			$scope.todos.push
				text: $scope.newTodoText
				done: false

			$scope.newTodoText = ""

		$scope.remainingCount = ->
			count = 0
			angular.forEach $scope.todos, ( todo ) ->
				count += if todo.done then 0 else 1

			count

		$scope.areAnyTodosDone = ->
			$scope.remainingCount() < $scope.todos.length

		$scope.archive = ->
			oldTodos = $scope.todos
			$scope.todos = []
			angular.forEach oldTodos, ( todo ) ->
				$scope.todos.push todo unless todo.done
]
