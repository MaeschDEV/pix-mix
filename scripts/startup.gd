extends Control

func _ready() -> void:
	Input.set_custom_mouse_cursor(null)

func _on_new_image_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/paint_window.tscn")

func _on_open_image_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/paint_window.tscn")
