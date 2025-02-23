extends Control

var pressed_keys := {}

func _ready() -> void:
	var file_menu = $HBoxContainer/File
	file_menu.get_popup().add_item("New          Ctrl+N", 0)
	file_menu.get_popup().add_item("Open         Ctrl+O", 1)
	file_menu.get_popup().add_separator()
	file_menu.get_popup().add_item("Save         Ctrl+S", 2)
	file_menu.get_popup().add_item("Save As      Ctrl+Shift+S", 3)
	file_menu.get_popup().add_item("Close        Ctrl+W", 4)
	file_menu.get_popup().add_separator()
	file_menu.get_popup().add_item("Export       Ctrl+E", 5)
	file_menu.get_popup().add_separator()
	file_menu.get_popup().add_item("Exit         Ctrl+Q", 6)
	
	file_menu.get_popup().id_pressed.connect(Callable(self, "_on_file_item_selected"))
	
	var edit_menu = $HBoxContainer/Edit
	edit_menu.get_popup().add_item("Delete       Del", 0)
	edit_menu.get_popup().add_separator()
	edit_menu.get_popup().add_item("Preferences  Ctrl+K", 1)
	
	edit_menu.get_popup().id_pressed.connect(Callable(self, "_on_edit_item_selected"))

func _input(event: InputEvent) -> void:	
	if (event is InputEventKey and event.is_pressed() and not event.keycode in pressed_keys):
		pressed_keys[event.keycode] = true
		if (event.ctrl_pressed and event.keycode == KEY_N):
			_on_file_item_selected(0)
		elif (event.ctrl_pressed and event.keycode == KEY_O):
			_on_file_item_selected(1)
		elif (event.ctrl_pressed and not event.shift_pressed and event.keycode == KEY_S):
			_on_file_item_selected(2)
		elif (event.ctrl_pressed and event.shift_pressed and event.keycode == KEY_S):
			_on_file_item_selected(3)
		elif (event.ctrl_pressed and event.keycode == KEY_W):
			_on_file_item_selected(4)
		elif (event.ctrl_pressed and event.keycode == KEY_E):
			_on_file_item_selected(5)
		elif (event.ctrl_pressed and event.keycode == KEY_Q):
			_on_file_item_selected(6)
		elif (event.keycode == KEY_DELETE):
			_on_edit_item_selected(0)
		elif (event.ctrl_pressed and event.keycode == KEY_K):
			_on_edit_item_selected(1)
	elif (event is InputEventKey and not event.is_pressed() and event.keycode in pressed_keys):
		pressed_keys.erase(event.keycode)

func _on_file_item_selected(id):
	match id:
		0: print("New file")
		1: print("Open file")
		2: print("Save file")
		3: print("Save file as")
		4: print("Close window")
		5: _export_image()
		6: _close_program()

func _on_edit_item_selected(id):
	match id:
		0: Global.delete.emit()
		1: print("Open preferenes")

func _close_program():
	var dialog = ConfirmationDialog.new()
	dialog.title = "Close program"
	dialog.dialog_text = "Are you sure you want to close the program?\nAll usaved changes will be deleted!"
	
	dialog.canceled.connect(Callable(self, "_canceled_closing"))
	dialog.confirmed.connect(Callable(self, "_confirm_closing"))
	
	add_child(dialog)
	dialog.popup_centered()
	dialog.show()

func _canceled_closing():
	pass

func _confirm_closing():
	get_tree().quit()

func _export_image():
	var fileDialog = FileDialog.new()
	fileDialog.title = "Export the image"
	fileDialog.add_filter("*.png")
	fileDialog.use_native_dialog = true
	fileDialog.dialog_hide_on_ok = true
	
	fileDialog.file_selected.connect(Callable(self, "_on_exported"))
	
	fileDialog.show()

func _on_exported(dir: String):
	Global.export.emit(dir)
