extends Control

func _ready() -> void:
	Global.ui_scene = self

func _process(delta: float) -> void:
	size = get_viewport_rect().size

func _on_color_picker_color_changed(color: Color) -> void:
	Global.color_changed.emit(color)

func _on_texture_button_button_down() -> void:
	Global.draw.emit()

func _on_texture_button_2_button_down() -> void:
	Global.erase.emit()

func _on_texture_button_3_button_down() -> void:
	Global.pick.emit()

func _on_texture_button_4_button_down() -> void:
	Global.fill.emit()

func _on_texture_button_5_button_down() -> void:
	Global.line.emit()

func _on_texture_button_6_button_down() -> void:
	Global.rect.emit()
