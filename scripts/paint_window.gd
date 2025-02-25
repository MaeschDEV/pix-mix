extends Node2D

enum STATE {DRAW, ERASE, PICKING, FILL, LINE, RECT}
var current_state

var mouseHold = false

var interactable = true

var undoHistory: Array[Image] = []
var historyPointer = 0

var size_x: int = 16
var size_y: int = 16

var layers: Array[TextureRect] = []
var images: Array[Image] = []
var textures: Array[ImageTexture]
var layerAmount = 3

var starting_point_exists = false
var starting_point = Vector2(0, 0)

var color = Color(0, 0, 0, 1)

var cursor_pen = load("res://graphics/Pencil.png")
var cursor_erasor = load("res://graphics/Eraser.png")
var cursor_eyedropper = load("res://graphics/Eyedropper.png")
var cursor_bucket = load("res://graphics/Bucket.png")

func _ready() -> void:
	for i in layerAmount:
		var tex_rect = TextureRect.new()
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex_rect.add_to_group("TexRects")
		add_child(tex_rect)
		layers.append(tex_rect)
	
	for i in layerAmount:
		var image = Image.create_empty(size_x, size_y, false, Image.FORMAT_RGBA8)
		images.append(image)
	
	for i in layerAmount:
		var texture = ImageTexture.create_from_image(images[i])
		textures.append(texture)
	
	for i in layerAmount:
		layers[i].texture = textures[i]
	
	undoHistory.append(images[1].duplicate())
	_setBackground()
	
	Global.undo.connect(Callable(self, "_undo"))
	Global.redo.connect(Callable(self, "_redo"))
	
	Global.interactable.connect(Callable(self, "_change_interaction"))
	
	Global.color_changed.connect(Callable(self, "_on_color_changed"))
	Global.draw.connect(Callable(self, "_on_draw"))
	Global.erase.connect(Callable(self, "_on_erase"))
	Global.pick.connect(Callable(self, "_on_pick"))
	Global.fill.connect(Callable(self, "_on_fill"))
	Global.line.connect(Callable(self, "_on_line"))
	Global.rect.connect(Callable(self, "_on_rect"))
	
	Global.newImage.connect(Callable(self, "_on_new_image"))
	Global.open.connect(Callable(self, "_on_open_image"))
	
	Global.delete.connect(Callable(self, "_on_delete"))
	Global.export.connect(Callable(self, "_on_export"))
	
	current_state = STATE.DRAW
	
	Global.ui_scene.get_node("ColorPicker").color = Color(0, 0, 0, 1)

func _change_interaction(yes: bool) -> void:
	interactable = yes

func _setBackground() -> void:
	var useLightGrey = true
	var lightGrey = Color(0.4, 0.4, 0.4, 1)
	var darkGrey = Color(0.5, 0.5, 0.5, 1)
	
	for x in size_x:
		if (size_y % 2 == 0):
			useLightGrey = !useLightGrey
			
		for y in size_y:
			useLightGrey = !useLightGrey
			
			if useLightGrey:
				images[0].set_pixel(x, y, lightGrey)
			else:
				images[0].set_pixel(x, y, darkGrey)
	
	textures[0].update(images[0])
	layers[0].texture = textures[0]

func _process(delta: float) -> void:
	_resizeCanvas()
	_show_preview()
	_change_cursor()
	
	if (!interactable):
		return
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):		
		mouseHold = true
	
	if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and !Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var mouse_pos = get_global_mouse_position() - layers[1].global_position
		
		var scale_x = size_x / layers[1].size.x
		var scale_y = size_y / layers[1].size.y
		
		var x = int(mouse_pos.x * scale_x)
		var y = int(mouse_pos.y * scale_y)
		
		if x >= 0 and x < size_x and y >= 0 and y < size_y and current_state != STATE.PICKING:
			if mouseHold:
				historyPointer += 1
				undoHistory.resize(historyPointer + 1)
				undoHistory[historyPointer] = images[1].duplicate()
		
		mouseHold = false
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and current_state == STATE.DRAW:
		var mouse_pos = get_global_mouse_position() - layers[1].global_position
		
		var scale_x = size_x / layers[1].size.x
		var scale_y = size_y / layers[1].size.y
		
		var x = int(mouse_pos.x * scale_x)
		var y = int(mouse_pos.y * scale_y)
		
		if x >= 0 and x < size_x and y >= 0 and y < size_y:
			images[1].set_pixel(x, y, color)
			textures[1].update(images[1])
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and current_state == STATE.ERASE or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and current_state == STATE.DRAW:
		var mouse_pos = get_global_mouse_position() - layers[1].global_position
		
		var scale_x = size_x / layers[1].size.x
		var scale_y = size_y / layers[1].size.y
		
		var x = int(mouse_pos.x * scale_x)
		var y = int(mouse_pos.y * scale_y)
		
		if x >= 0 and x < size_x and y >= 0 and y < size_y:
			images[1].set_pixel(x, y, Color(0, 0, 0, 0))
			textures[1].update(images[1])
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and current_state == STATE.PICKING:
		var mouse_pos = get_global_mouse_position() - layers[1].global_position
		
		var scale_x = size_x / layers[1].size.x
		var scale_y = size_y / layers[1].size.y
		
		var x = int(mouse_pos.x * scale_x)
		var y = int(mouse_pos.y * scale_y)
		
		if x >= 0 and x < size_x and y >= 0 and y < size_y:
			var pixel = images[1].get_pixel(x, y)
			
			Global.ui_scene.get_node("ColorPicker").color = pixel
			
			color = pixel
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and current_state == STATE.FILL:
		var mouse_pos = get_global_mouse_position() - layers[1].global_position
		
		var scale_x = size_x / layers[1].size.x
		var scale_y = size_y / layers[1].size.y
		
		var x = int(mouse_pos.x * scale_x)
		var y = int(mouse_pos.y * scale_y)
		
		if x >= 0 and x < size_x and y >= 0 and y < size_y:
			var target_color = images[1].get_pixel(x, y)
			
			images[1].set_pixel(x, y, color)
			
			var comparisonColor = images[1].get_pixel(x, y)
			
			if (!target_color.is_equal_approx(comparisonColor)):
				print("Not the same!")
				images[1].set_pixel(x, y, target_color)
				_flood_fill(x, y, target_color, color)
			else:
				images[1].set_pixel(x, y, target_color)
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and current_state == STATE.LINE:
		var mouse_pos = get_global_mouse_position() - layers[1].global_position
		
		var scale_x = size_x / layers[1].size.x
		var scale_y = size_y / layers[1].size.y
		
		var x = int(mouse_pos.x * scale_x)
		var y = int(mouse_pos.y * scale_y)
		
		if (!starting_point_exists):
			starting_point = Vector2(x, y)
			starting_point_exists = true
		
		_create_line(starting_point.x, starting_point.y, x, y, color, true)
	
	if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and current_state == STATE.LINE:
		starting_point_exists = false
		for x in size_x:
			for y in size_y:
				var preview_pixel = images[2].get_pixel(x, y)
				if (preview_pixel.a8 != 0):
					images[1].set_pixel(x, y, preview_pixel)

		images[2].fill(Color(0, 0, 0, 0))
		textures[2].update(images[2])
		layers[2].texture = textures[2]
		textures[1].update(images[1])
		layers[1].texture = textures[1]
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and current_state == STATE.RECT:
		var mouse_pos = get_global_mouse_position() - layers[1].global_position
		
		var scale_x = size_x / layers[1].size.x
		var scale_y = size_y / layers[1].size.y
		
		var x = int(mouse_pos.x * scale_x)
		var y = int(mouse_pos.y * scale_y)
		
		if (!starting_point_exists):
			starting_point = Vector2(x, y)
			starting_point_exists = true
		
		_create_rect(starting_point.x, starting_point.y, x, y, color)
	
	if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and current_state == STATE.RECT:
		starting_point_exists = false
		for x in size_x:
			for y in size_y:
				var preview_pixel = images[2].get_pixel(x, y)
				if (preview_pixel.a8 != 0):
					images[1].set_pixel(x, y, preview_pixel)

		images[2].fill(Color(0, 0, 0, 0))
		textures[2].update(images[2])
		layers[2].texture = textures[2]
		textures[1].update(images[1])
		layers[1].texture = textures[1]

func _undo():
	print("Undo")
	print(historyPointer)
	print(undoHistory)
	if (historyPointer >= 1):
		historyPointer -= 1
		images[1] = undoHistory[historyPointer].duplicate()
		textures[1].update(undoHistory[historyPointer].duplicate())
		layers[1].texture = textures[1]

func _redo():
	print("Redo")
	print(historyPointer)
	print(undoHistory)
	if (historyPointer <= undoHistory.size() - 2):
		historyPointer += 1
		images[1] = undoHistory[historyPointer].duplicate()
		textures[1].update(undoHistory[historyPointer].duplicate())
		layers[1].texture = textures[1]

func _resizeCanvas() -> void:
	var screen_size = get_viewport_rect().size
	var base_resolution = Vector2(1152, 648)
	var scale_factor = min(screen_size.x / base_resolution.x, screen_size.y / base_resolution.y)

	
	var new_size = Vector2(500, 500) * scale_factor
	var border_size = Vector2(507, 507) * scale_factor
	
	layers[0].size = new_size
	layers[1].size = new_size
	layers[2].size = new_size
	$TextureRect.size = border_size
	
	layers[0].position = (screen_size - new_size) / 2
	layers[1].position = (screen_size - new_size) / 2
	layers[2].position = (screen_size - new_size) / 2
	$TextureRect.position = (screen_size - border_size) / 2

func _flood_fill(x: int, y: int, target_color: Color, fill_color: Color) -> void:
	if (x < 0 or x >= size_x or y < 0 or y >= size_y):
		return
	
	var current_color = images[1].get_pixel(x, y)
	
	if (current_color != target_color or current_color == fill_color):
		return
	
	images[1].set_pixel(x, y, fill_color)
	textures[1].update(images[1])
	
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
		images[2].fill(Color(0, 0, 0, 0))
	
	var dx = abs(x1 - x0)				# Abstand zwischen x0 und x1
	var dy = abs(y1 - y0)				# Abstand zwischen y0 und y1
	var sx = 1 if (x1 > x0) else -1		# 1 = nach rechts; -1 = nach links
	var sy = 1 if (y1 > y0) else -1		# 1 = nach oben; -1 = nach unten
	var err = dx - dy					# Fehlerterm im Bresenham-Algorithmus
	
	while true:
		if (x0 >= 0 and x0 < size_x and y0 >= 0 and y0 < size_y):
			images[2].set_pixel(x0, y0, color)
			textures[2].update(images[2])
			layers[2].texture = textures[2]
		
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
	images[2].fill(Color(0, 0, 0, 0))
	
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

func _on_new_image(size: Vector2):
	size_x = size.x
	size_y = size.y
	
	layers.clear()
	images.clear()
	textures.clear()
	
	for i in get_tree().get_nodes_in_group("TexRects").size():
		get_tree().get_nodes_in_group("TexRects")[i].queue_free()
	
	for i in layerAmount:
		var tex_rect = TextureRect.new()
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex_rect.add_to_group("TexRects")
		add_child(tex_rect)
		layers.append(tex_rect)
	
	for i in layerAmount:
		var image = Image.create_empty(size_x, size_y, false, Image.FORMAT_RGBA8)
		images.append(image)
	
	for i in layerAmount:
		var texture = ImageTexture.create_from_image(images[i])
		textures.append(texture)
	
	for i in layerAmount:
		layers[i].texture = textures[i]
	
	undoHistory.clear()
	historyPointer = 0
	
	undoHistory.append(images[1].duplicate())
	_setBackground()

func _on_open_image(dir: String):
	size_x = Image.load_from_file(dir).get_size().x
	size_y = Image.load_from_file(dir).get_size().y
	
	layers.clear()
	images.clear()
	textures.clear()
	
	for i in get_tree().get_nodes_in_group("TexRects").size():
		get_tree().get_nodes_in_group("TexRects")[i].queue_free()
	
	for i in layerAmount:
		var tex_rect = TextureRect.new()
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex_rect.add_to_group("TexRects")
		add_child(tex_rect)
		layers.append(tex_rect)
	
	for i in layerAmount:
		var image
		if (i != 1):
			image = Image.create_empty(size_x, size_y, false, Image.FORMAT_RGBA8)
		else:
			image = Image.load_from_file(dir)
		images.append(image)
	
	for i in layerAmount:
		var texture = ImageTexture.create_from_image(images[i])
		textures.append(texture)
	
	for i in layerAmount:
		layers[i].texture = textures[i]
	
	undoHistory.clear()
	historyPointer = 0
	
	undoHistory.append(images[1].duplicate())
	_setBackground()

func _on_delete():
	print("Deleted!")
	images[1].fill(Color(0, 0, 0, 0))
	textures[1].update(images[1])
	layers[1].texture = textures[1]
	
	undoHistory.clear()
	historyPointer = 0
	
	undoHistory.append(images[1].duplicate())

func _on_export(dir: String):
	print("Exported!")
	images[1].save_png(dir)

func _show_preview():
	if (current_state == STATE.DRAW or current_state == STATE.FILL):
		images[2].fill(Color(0, 0, 0, 0))
		
		var mouse_pos = get_global_mouse_position() - layers[1].global_position
		
		var scale_x = size_x / layers[1].size.x
		var scale_y = size_y / layers[1].size.y
		
		var x = int(mouse_pos.x * scale_x)
		var y = int(mouse_pos.y * scale_y)
		
		if x >= 0 and x < size_x and y >= 0 and y < size_y:
			images[2].set_pixel(x, y, Color(color.r, color.g, color.b, 0.75))
			textures[2].update(images[2])
			layers[2].texture = textures[2]
		else:
			images[2].fill(Color(0, 0, 0, 0))
			textures[2].update(images[2])
			layers[2].texture = textures[2]
	
	if (current_state == STATE.ERASE):
		images[2].fill(Color(0, 0, 0, 0))
		
		var mouse_pos = get_global_mouse_position() - layers[1].global_position
		
		var scale_x = size_x / layers[1].size.x
		var scale_y = size_y / layers[1].size.y
		
		var x = int(mouse_pos.x * scale_x)
		var y = int(mouse_pos.y * scale_y)
		
		if x >= 0 and x < size_x and y >= 0 and y < size_y:
			images[2].set_pixel(x, y, Color(1, 1, 1, 1))
			textures[2].update(images[2])
			layers[2].texture = textures[2]
		else:
			images[2].fill(Color(0, 0, 0, 0))
			textures[2].update(images[2])
			layers[2].texture = textures[2]

func _change_cursor():
	var mouse_pos = get_global_mouse_position() - layers[1].global_position
		
	var scale_x = size_x / layers[1].size.x
	var scale_y = size_y / layers[1].size.y
	
	var x = int(mouse_pos.x * scale_x)
	var y = int(mouse_pos.y * scale_y)
	
	if x >= 0 and x < size_x and y >= 0 and y < size_y:
		match current_state:
			STATE.DRAW:
				Input.set_custom_mouse_cursor(cursor_pen, Input.CURSOR_ARROW, Vector2(0, 12))
			STATE.ERASE:
				Input.set_custom_mouse_cursor(cursor_erasor, Input.CURSOR_ARROW, Vector2(0, 12))
			STATE.PICKING:
				Input.set_custom_mouse_cursor(cursor_eyedropper, Input.CURSOR_ARROW, Vector2(0, 12))
			STATE.FILL:
				Input.set_custom_mouse_cursor(cursor_bucket, Input.CURSOR_ARROW, Vector2(0, 12))
	else:
		Input.set_custom_mouse_cursor(null)
