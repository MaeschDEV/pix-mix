extends Node

signal interactable(yes: bool)

signal undo
signal redo

signal draw
signal erase
signal pick
signal fill
signal line
signal rect

signal rotate(amount: int)

signal newImage(size: Vector2)
signal open(dir: String)

signal delete
signal export(dir: String)

signal color_changed

var ui_scene = null
