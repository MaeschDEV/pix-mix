extends Node

signal draw
signal erase
signal pick
signal fill
signal line
signal rect

signal newImage(size: Vector2)

signal delete
signal export(dir: String)

signal color_changed

var ui_scene = null
