gui = require "nw.gui"
win = gui.Window.get()

win.on "minimize", ->
	@hide()

	tray = new gui.Tray icon: "icon-16.png"

	tray.on "click", ->
		win.show()
		@remove()
		tray = null
