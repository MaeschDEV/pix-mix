extends Control

var pressed_keys := {}

func _ready() -> void:
	var file_menu = $HBoxContainer/File
	file_menu.get_popup().add_item("New          Ctrl+N", 0)
	file_menu.get_popup().add_item("Open         Ctrl+O", 1)
	file_menu.get_popup().add_separator()
	file_menu.get_popup().add_item("Export       Ctrl+E", 2)
	file_menu.get_popup().add_separator()
	file_menu.get_popup().add_item("Exit         Ctrl+Q", 3)
	
	file_menu.get_popup().id_pressed.connect(Callable(self, "_on_file_item_selected"))
	
	var edit_menu = $HBoxContainer/Edit
	edit_menu.get_popup().add_item("Undo         Ctrl+Z", 0)
	edit_menu.get_popup().add_item("Redo         Ctrl+Y", 1)
	edit_menu.get_popup().add_separator()
	edit_menu.get_popup().add_item("Delete       Ctrl+Del", 2)
	
	edit_menu.get_popup().id_pressed.connect(Callable(self, "_on_edit_item_selected"))

func _input(event: InputEvent) -> void:	
	if (event is InputEventKey and event.is_pressed() and not event.keycode in pressed_keys):
		pressed_keys[event.keycode] = true
		if (event.ctrl_pressed and event.keycode == KEY_N):
			_on_file_item_selected(0)
		elif (event.ctrl_pressed and event.keycode == KEY_O):
			_on_file_item_selected(1)
		elif (event.ctrl_pressed and event.keycode == KEY_E):
			_on_file_item_selected(2)
		elif (event.ctrl_pressed and event.keycode == KEY_Q):
			_on_file_item_selected(3)
		elif (event.ctrl_pressed and event.keycode == KEY_Z):
			_on_edit_item_selected(0)
		elif (event.ctrl_pressed and event.keycode == KEY_Y):
			_on_edit_item_selected(1)
		elif (event.ctrl_pressed and event.keycode == KEY_DELETE):
			_on_edit_item_selected(2)
		
	elif (event is InputEventKey and not event.is_pressed() and event.keycode in pressed_keys):
		pressed_keys.erase(event.keycode)

func _on_file_item_selected(id):
	match id:
		0: _new_file()
		1: _open_file()
		2: _export_image()
		3: _close_program()

func _on_edit_item_selected(id):
	match id:
		0: Global.undo.emit()
		1: Global.redo.emit()
		2: Global.delete.emit()

func _close_program():
	Global.interactable.emit(false)
	var dialog = ConfirmationDialog.new()
	dialog.title = "Close program"
	dialog.dialog_text = "Are you sure you want to close the program?\nAll usaved changes will be deleted!"
	
	dialog.canceled.connect(Callable(self, "_canceled_closing"))
	dialog.confirmed.connect(Callable(self, "_confirm_closing"))
	
	add_child(dialog)
	dialog.popup_centered()
	dialog.show()

func _canceled_closing():
	Global.interactable.emit(true)

func _confirm_closing():
	Global.interactable.emit(true)
	get_tree().quit()

func _export_image():
	Global.interactable.emit(false)
	var fileDialog = FileDialog.new()
	fileDialog.title = "Export the image"
	fileDialog.add_filter("*.png")
	fileDialog.use_native_dialog = true
	fileDialog.dialog_hide_on_ok = true
	
	fileDialog.canceled.connect(Callable(self, "_canceled_closing"))
	fileDialog.file_selected.connect(Callable(self, "_on_exported"))
	
	fileDialog.show()

func _on_exported(dir: String):
	Global.interactable.emit(true)
	Global.export.emit(dir)

func _new_file():
	Global.interactable.emit(false)
	$"New Image".show()

func _on_new_image_canceled() -> void:
	Global.interactable.emit(true)

func _on_new_image_confirmed() -> void:
	Global.interactable.emit(true)
	var x = $"New Image/VBoxContainer/HBoxContainer/SpinBox".value
	var y = $"New Image/VBoxContainer/HBoxContainer2/SpinBox".value
	Global.newImage.emit(Vector2(x, y))
	$"New Image".hide()

func _open_file():
	Global.interactable.emit(false)
	var openDialog = FileDialog.new()
	openDialog.title = "Open Image"
	openDialog.file_mode = 0
	openDialog.add_filter("*.png, *.jpg")
	openDialog.use_native_dialog = true
	openDialog.dialog_hide_on_ok = true
	
	openDialog.canceled.connect(Callable(self, "_canceled_closing"))
	openDialog.file_selected.connect(Callable(self, "_on_opened"))
	
	openDialog.show()

func _on_opened(dir: String):
	Global.interactable.emit(true)
	Global.open.emit(dir)
