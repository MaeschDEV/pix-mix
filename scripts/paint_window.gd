extends Node2D

var size_x = 32
var size_y = 32

var background
var ebeneOne

var backgroundImage = Image.create_empty(size_x, size_y, false, Image.FORMAT_RGBA8)
var backgroundTexture = ImageTexture.create_from_image(backgroundImage)

var image = Image.create_empty(size_x, size_y, false, Image.FORMAT_RGBA8)
var texture = ImageTexture.create_from_image(image)
var drawing = false
var erasing = false

func _ready() -> void:
	background = $Background
	ebeneOne = $Ebene1
	
	backgroundTexture = ImageTexture.create_from_image(backgroundImage)
	texture = ImageTexture.create_from_image(image)
	background.texture = backgroundTexture
	ebeneOne.texture = texture
	_setBackground()
	
func _input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			drawing = event.pressed
		
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			erasing = event.pressed
	
	if event is InputEventMouseMotion and drawing:
		var mouse_pos = get_global_mouse_position() - ebeneOne.global_position
		
		var scale_x = size_x / ebeneOne.size.x
		var scale_y = size_y / ebeneOne.size.y
		
		var x = int(mouse_pos.x * scale_x)
		var y = int(mouse_pos.y * scale_y)
		
		if x >= 0 and x < size_x and y >= 0 and y < size_y:
			image.set_pixel(x, y, Color(0, 0, 0, 1))
			texture.update(image)
	
	if event is InputEventMouseMotion and erasing:
		var mouse_pos = get_global_mouse_position() - ebeneOne.global_position
		
		var scale_x = size_x / ebeneOne.size.x
		var scale_y = size_y / ebeneOne.size.y
		
		var x = int(mouse_pos.x * scale_x)
		var y = int(mouse_pos.y * scale_y)
		
		if x >= 0 and x < size_x and y >= 0 and y < size_y:
			image.set_pixel(x, y, Color(0, 0, 0, 0))
			texture.update(image)

func _setBackground() -> void:
	var useLightGrey = true
	var lightGrey = Color(0.4, 0.4, 0.4, 1)
	var darkGrey = Color(0.5, 0.5, 0.5, 1)
	
	for x in size_x:
		useLightGrey = !useLightGrey
		for y in size_y:
			useLightGrey = !useLightGrey
			
			if useLightGrey:
				backgroundImage.set_pixel(x, y, lightGrey)
			else:
				backgroundImage.set_pixel(x, y, darkGrey)
	
	for x in size_x:
		for y in size_y:
			image.set_pixel(x, y, Color(1, 0, 0, 0))
	
	backgroundTexture.update(backgroundImage)
	background.texture = backgroundTexture
	texture.update(image)
