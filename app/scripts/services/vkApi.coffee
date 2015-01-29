"use strict"

angular.module( "app.services.vkApi", []).factory "vkApi", ->
	request = require "request"
	_ = require "lodash"

	apiAppInfo =
		id: 4598775
		permissions: [
			"audio"
		]

	apiVersion = "5.25"

	authUrlParams =
		client_id: apiAppInfo.id
		scope: apiAppInfo.permissions.join ","
		redirect_uri: encodeURIComponent "https://oauth.vk.com/blank.html"
		display: "page"
		v: apiVersion
		response_type: "token"
		revoke: 1

	authUrl = "https://oauth.vk.com/authorize?" +
		( "#{param}=#{value}" for param, value of authUrlParams ).join "&"

	requestBaseUrl = "https://api.vk.com/method/"

	_apiVersion: apiVersion

	_performAuth: ( callback ) ->
		authWindow = require( "nw.gui" ).Window.open authUrl, show: no

		authWindow.on "loaded", ->
			_getArgsFromUrl = ->
				authWindowUrl = authWindow.window.location.href
				if -1 is authWindowUrl.indexOf "oauth.vk.com/blank.html"
					false
				else
					if -1 is authWindowUrl.indexOf "#"
						null
					else
						rawArgs = authWindowUrl
							.split( "#" )[ 1 ]
							.split( "&" )

						_.chain( rawArgs )
							.map( ( arg ) -> arg.split "=" )
							.object()
							.value()

			authArgs = _getArgsFromUrl()
			if authArgs is false
				authWindow.show()
				authWindow.focus()

				checkAuthIntervalObj = setInterval ->
					authArgs = _getArgsFromUrl()
					if authArgs
						clearInterval checkAuthIntervalObj
						authWindow.close()
						callback authArgs
				, 50
			else
				authWindow.close()
				callback authArgs

	APP_ID: apiAppInfo.id

	_authArgs: null
	_isAuthing: no
	_authArgsCallbackList: []
	getAuthArgs: ({ callback, force } = {}) ->
		callback ?= ->
		if @_authArgs and not force
			callback @_authArgs
		else
			@_authArgsCallbackList.push callback
			if not @_isAuthing
				@_isAuthing = yes
				context = @
				@_performAuth ( authArgs ) ->
					context._authArgs = authArgs
					context._isAuthing = no
					for callback in context._authArgsCallbackList
						callback authArgs
					context._authArgsCallbackList = []

	_requestQueue: []
	_isBusy: no
	_enqueue: ( requestData ) ->
		@_requestQueue.push requestData
		if not @_isBusy
			@_isBusy = yes
			@_next()

	_next: ->
		if @_requestQueue.length > 0
			req = @_requestQueue.shift()
			originalCallback = req.callback
			context = @
			req.callback = ( args... ) ->
				originalCallback args...
				context._next()
			@_request req
		else
			@_isBusy = no

	_retryDelay: 1000
	_request: ({ method, data, callback }) ->
		requestUrl = requestBaseUrl + method

		context = @
		@getAuthArgs callback: ( authArgs ) ->
			data.access_token = authArgs.access_token
			do retry = ->
				request.get
					url: requestUrl
					qs: data
				, ( error, event, rawResult ) ->
					try
						result = JSON.parse rawResult
					catch
						setTimeout retry, context._retryDelay
					finally
						if result.error?.error_code is 6
							setTimeout retry, context._retryDelay
						else
							callback result

	request: ({ method, data, callback } = {}) ->
		throw Error "vkApi.request - method is missing!" if not method

		data ?= {}
		data.v ?= apiVersion
		callback ?= ->

		@_enqueue { method, data, callback }
