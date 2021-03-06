exports.config =
	# See docs at http://brunch.readthedocs.org/en/latest/config.html.
	conventions:
		assets:  /^app[\/\\]+assets[\/\\]+/
		ignored: /^(bower_components[\/\\]+bootstrap-less(-themes)?)/
	modules:
		definition: false
		wrapper: false
	paths:
		public: '_public'
	files:
		javascripts:
			joinTo:
				'js/app.js': /^app/
				'js/vendor.js': /^(bower_components|vendor)/

		stylesheets:
			joinTo:
				'css/app.css': /^(app|vendor|bower_components)/
			order:
				after: [
					'app/styles/app.styl'
				]

		templates:
			joinTo:
				'js/dontUseMe' : /^app/ # dirty hack for Jade compiling.

	plugins:
		autoReload:
			delay: 500
		jade:
			# Adds pretty-indentation whitespaces to output (false by default)
			pretty: yes
		jade_angular:
			modules_folder: 'partials'
			locals: {}

	overrides:
		production:
			paths:
				public: "dist/cache"
			optimize: true
			sourceMaps: false
			plugins:
				autoReload:
					enabled: false
				jade:
					pretty: false

	# Enable or disable minifying of result js / css files.
	minify: true
