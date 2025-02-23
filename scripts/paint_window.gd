extends Node2D

enum STATE {DRAW, ERASE, PICKING, FILL, LINE, RECT}
var current_state

var size_x = 16
var size_y = 16

var background
var ebeneOne
var preview

var backgroundImage = Image.create_empty(size_x, size_y, false, Image.FORMAT_RGBA8)
var backgroundTexture = ImageTexture.create_from_image(backgroundImage)

var image = Image.create_empty(size_x, size_y, false, Image.FORMAT_RGBA8)
var texture = ImageTexture.create_from_image(image)

var previewImage = Image.create_empty(size_x, size_y, false, Image.FORMAT_RGBA8)
var previewTexture = ImageTexture.create_from_image(previewImage)

var drawing = false
var erasing = false
var picking = false
var filling = false
var doing_a_line = false
var doing_a_rect = false

var starting_point_exists = false
var starting_point = Vector2(0, 0)

var color = Color(0, 0, 0, 1)

func _ready() -> void:
	background = $Background
	ebeneOne = $Ebene1
	preview = $Preview
	
	backgroundTexture = ImageTexture.create_from_image(backgroundImage)
	texture = ImageTexture.create_from_image(image)
	previewTexture = ImageTexture.create_from_image(previewImage)
	background.texture = backgroundTexture
	ebeneOne.texture = texture
	preview.texture = previewTexture
	_setBackground()
	
	Global.color_changed.connect(Callable(self, "_on_color_changed"))
	Global.draw.connect(Callable(self, "_on_draw"))
	Global.erase.connect(Callable(self, "_on_erase"))
	Global.pick.connect(Callable(self, "_on_pick"))
	Global.fill.connect(Callable(self, "_on_fill"))
	Global.line.connect(Callable(self, "_on_line"))
	Global.rect.connect(Callable(self, "_on_rect"))
	
	Global.delete.connect(Callable(self, "_on_delete"))
	Global.export.connect(Callable(self, "_on_export"))
	
	current_state = STATE.DRAW
	
	Global.ui_scene.get_node("ColorPicker").color = Color(0, 0, 0, 1)

func _input(event) -> void:
	if event is InputEventMouseButton:		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if (current_state == STATE.DRAW):
				drawing = event.pressed
				erasing = false
				picking = false
				filling = false
				doing_a_line = false
				doing_a_rect = false
			elif (current_state == STATE.ERASE):
				erasing = event.pressed
				drawing = false
				picking = false
				filling = false
				doing_a_line = false
				doing_a_rect = false
			elif (current_state == STATE.PICKING):
				picking = event.pressed
				drawing = false
				erasing = false
				filling = false
				doing_a_line = false
				doing_a_rect = false
			elif (current_state == STATE.FILL):
				filling = event.pressed
				drawing = false
				erasing = false
				picking = false
				doing_a_line = false
				doing_a_rect = false
			elif (current_state == STATE.LINE):
				doing_a_line = event.pressed
				erasing = false
				drawing = false
				picking = false
				filling = false
				doing_a_rect = false
			elif (current_state == STATE.RECT):
				doing_a_rect = event.pressed
				drawing = false
				erasing = false
				picking = false
				filling = false
				doing_a_line = false
			else:
				drawing = false
				erasing = false
				picking = false
				filling = false
				doing_a_line = false
				doing_a_rect = false
		
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if (current_state == STATE.DRAW):
				erasing = event.pressed
				drawing = false
				picking = false
				filling = false
				doing_a_line = false
				doing_a_rect = false
			else:
				drawing = false
				erasing = false
				picking = false
				filling = false
				doing_a_line = false
				doing_a_rect = false
	
	if drawing:
		var mouse_pos = get_global_mouse_position() - ebeneOne.global_position
		
		var scale_x = size_x / ebeneOne.size.x
		var scale_y = size_y / ebeneOne.size.y
		
		var x = int(mouse_pos.x * scale_x)
		var y = int(mouse_pos.y * scale_y)
		
		if x >= 0 and x < size_x and y >= 0 and y < size_y:
			image.set_pixel(x, y, color)
			texture.update(image)
	
	if erasing:
		var mouse_pos = get_global_mouse_position() - ebeneOne.global_position
		
		var scale_x = size_x / ebeneOne.size.x
		var scale_y = size_y / ebeneOne.size.y
		
		var x = int(mouse_pos.x * scale_x)
		var y = int(mouse_pos.y * scale_y)
		
		if x >= 0 and x < size_x and y >= 0 and y < size_y:
			image.set_pixel(x, y, Color(0, 0, 0, 0))
			texture.update(image)
	
	if picking:
		var mouse_pos = get_global_mouse_position() - ebeneOne.global_position
		
		var scale_x = size_x / ebeneOne.size.x
		var scale_y = size_y / ebeneOne.size.y
		
		var x = int(mouse_pos.x * scale_x)
		var y = int(mouse_pos.y * scale_y)
		
		if x >= 0 and x < size_x and y >= 0 and y < size_y:
			var pixel = image.get_pixel(x, y)
			
			Global.ui_scene.get_node("ColorPicker").color = pixel
			
			color = pixel
	
	if filling:
		var mouse_pos = get_global_mouse_position() - ebeneOne.global_position
		
		var scale_x = size_x / ebeneOne.size.x
		var scale_y = size_y / ebeneOne.size.y
		
		var x = int(mouse_pos.x * scale_x)
		var y = int(mouse_pos.y * scale_y)
		
		if x >= 0 and x < size_x and y >= 0 and y < size_y:
			var target_color = image.get_pixel(x, y)
			
			image.set_pixel(x, y, color)
			
			var comparisonColor = image.get_pixel(x, y)
			
			if (!target_color.is_equal_approx(comparisonColor)):
				print("Not the same!")
				image.set_pixel(x, y, target_color)
				_flood_fill(x, y, target_color, color)
			else:
				image.set_pixel(x, y, target_color)
	
	if doing_a_line:
		var mouse_pos = get_global_mouse_position() - ebeneOne.global_position
		
		var scale_x = size_x / ebeneOne.size.x
		var scale_y = size_y / ebeneOne.size.y
		
		var x = int(mouse_pos.x * scale_x)
		var y = int(mouse_pos.y * scale_y)
		
		if (!starting_point_exists):
			starting_point = Vector2(x, y)
			starting_point_exists = true
		
		_create_line(starting_point.x, starting_point.y, x, y, color, true)
	
	if (!doing_a_line and current_state == STATE.LINE):
		starting_point_exists = false
		for x in size_x:
			for y in size_y:
				var preview_pixel = previewImage.get_pixel(x, y)
				if (preview_pixel.a8 != 0):
					image.set_pixel(x, y, preview_pixel)

		previewImage.fill(Color(0, 0, 0, 0))
		previewTexture.update(previewImage)
		preview.texture = previewTexture
		texture.update(image)
		ebeneOne.texture = texture
	
	if doing_a_rect:
		var mouse_pos = get_global_mouse_position() - ebeneOne.global_position
		
		var scale_x = size_x / ebeneOne.size.x
		var scale_y = size_y / ebeneOne.size.y
		
		var x = int(mouse_pos.x * scale_x)
		var y = int(mouse_pos.y * scale_y)
		
		if (!starting_point_exists):
			starting_point = Vector2(x, y)
			starting_point_exists = true
		
		_create_rect(starting_point.x, starting_point.y, x, y, color)
	
	if (!doing_a_rect and current_state == STATE.RECT):
		starting_point_exists = false
		for x in size_x:
			for y in size_y:
				var preview_pixel = previewImage.get_pixel(x, y)
				if (preview_pixel.a8 != 0):
					image.set_pixel(x, y, preview_pixel)

		previewImage.fill(Color(0, 0, 0, 0))
		previewTexture.update(previewImage)
		preview.texture = previewTexture
		texture.update(image)
		ebeneOne.texture = texture

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
			image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	backgroundTexture.update(backgroundImage)
	background.texture = backgroundTexture
	texture.update(image)

func _process(delta: float) -> void:
	_resizeCanvas()

func _resizeCanvas() -> void:
	var screen_size = get_viewport_rect().size
	var base_resolution = Vector2(1152, 648)
	var scale_factor = min(screen_size.x / base_resolution.x, screen_size.y / base_resolution.y)

	
	var new_size = Vector2(500, 500) * scale_factor
	
	background.size = new_size
	ebeneOne.size = new_size
	preview.size = new_size
	
	background.position = (screen_size - new_size) / 2
	ebeneOne.position = (screen_size - new_size) / 2
	preview.position = (screen_size - new_size) / 2

func _flood_fill(x: int, y: int, target_color: Color, fill_color: Color) -> void:
	if (x < 0 or x >= size_x or y < 0 or y >= size_y):
		return
	
	var current_color = image.get_pixel(x, y)
	
	if (current_color != target_color or current_color == fill_color):
		return
	
	image.set_pixel(x, y, fill_color)
	texture.update(image)
	
	if (size_x <= 32):
		await get_tree().create_timer(0.01).timeout
	else:
		await get_tree().create_timer(0).timeout
	
	_flood_fill(x + 1, y, target_color, fill_color)
	_flood_fill(x - 1, y, target_color, fill_color)
	_flood_fill(x, y + 1, target_color, fill_color)
	_flood_fill(x, y - 1, target_color, fill_color)

func _create_line(x0: int, y0: int, x1: int, y1: int, color: Color, delete: bool) -> void:
	if delete:
		previewImage.fill(Color(0, 0, 0, 0))
	
	var dx = abs(x1 - x0)				# Abstand zwischen x0 und x1
	var dy = abs(y1 - y0)				# Abstand zwischen y0 und y1
	var sx = 1 if (x1 > x0) else -1		# 1 = nach rechts; -1 = nach links
	var sy = 1 if (y1 > y0) else -1		# 1 = nach oben; -1 = nach unten
	var err = dx - dy					# Fehlerterm im Bresenham-Algorithmus
	
	while true:
		if (x0 >= 0 and x0 < size_x and y0 >= 0 and y0 < size_y):
			previewImage.set_pixel(x0, y0, color)
			previewTexture.update(previewImage)
			preview.texture = previewTexture
		
		if (x0 == x1 and y0 == y1):
			break
		
		var e2 = 2 * err
		if (e2 > -dy):
			err -= dy
			x0 += sx
		if (e2 < dx):
			err += dx
			y0 += sy

func _create_rect(x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	previewImage.fill(Color(0, 0, 0, 0))
	
	_create_line(x0, y0, x1, y0, color, false)
	_create_line(x1, y0, x1, y1, color, false)
	_create_line(x1, y1, x0, y1, color, false)
	_create_line(x0, y1, x0, y0, color, false)

func _on_color_changed(newColor: Color):	
	color = newColor

func _on_draw():	
	current_state = STATE.DRAW

func _on_erase():	
	current_state = STATE.ERASE

func _on_pick():
	current_state = STATE.PICKING

func _on_fill():
	current_state = STATE.FILL

func _on_line():
	current_state = STATE.LINE

func _on_rect():
	current_state = STATE.RECT

func _on_delete():
	print("Deleted!")
	image.fill(Color(0, 0, 0, 0))
	texture.update(image)
	ebeneOne.texture = texture

func _on_export(dir: String):
	print("Exported!")
	image.save_png(dir)
