extends Node

@onready var grid_display = $"GrowLand/Grid Display"
var is_wheat_pressed = false
var is_berry_pressed = false
#var is_hen_pressed = false

@onready var hen_button = $PurchaseUI/Panel/HBoxContainer/hen/pick_hen
@onready var berry_button = $PurchaseUI/Panel/HBoxContainer/berry/pick_berry
@onready var wheat_button = $PurchaseUI/Panel/HBoxContainer/wheat/pick_wheat
@onready var hen_label = $PurchaseUI/Panel/HBoxContainer/hen/hen_price
@onready var berry_label = $PurchaseUI/Panel/HBoxContainer/berry/berry_price
@onready var wheat_label = $PurchaseUI/Panel/HBoxContainer/wheat/wheat_price
@onready var hen_house = $HenHouse
@onready var info_label = $PurchaseUI/Panel/InfoLabel
@onready var label_timer = $PurchaseUI/Panel/InfoLabel/Timer
@onready var money_label := $PurchaseUI/Panel/HBoxContainer/Label

var money :int:
	set(value):
		money = value
		money_label.set_text(str(money))
	get:
		return money
@export var init_money = 150
@export var wheat_price :int = 10
@export var berry_price :int = 25
@export var hen_price:int = 80

@onready var crops = $Crops
var crop
var already_used := false

var prevent_walk := false
signal allow_walk(can_walk:bool)

@onready var tilemap := $GrowLand

var basic_cursor := load("res://Assets/Sprout Lands - UI Pack - Basic pack/Sprout Lands - UI Pack - Basic pack/Sprite sheets/Mouse sprites/Catpaw pointing Mouse icon.png")
var wheat_cursor := load("res://Assets/Sprout Lands - Sprites - Basic pack/Sprout Lands - Sprites - Basic pack/Objects/wheat_cursor.png")
var berry_cursor := load("res://Assets/Sprout Lands - Sprites - Basic pack/Sprout Lands - Sprites - Basic pack/Objects/berry_cursor.png")


var wheat := preload("res://Scenes/wheat.tscn")
var berry := preload("res://Scenes/berry.tscn")
var chicken := preload("res://Scenes/chicken.tscn")

func _ready():
	money = init_money
	wheat_label.set_text(str(wheat_price))
	berry_label.set_text(str(berry_price))
	hen_label.set_text(str(hen_price))

func _on_pick_wheat_pressed():
	var tween = get_tree().create_tween()
	if is_wheat_pressed:
		Input.set_custom_mouse_cursor(basic_cursor)
		tween.tween_property(grid_display,"visible",false,0.2)
		prevent_walk = false
		berry_button.disabled = false
		hen_button.disabled = false
	else:
		Input.set_custom_mouse_cursor(wheat_cursor)
		tween.tween_property(grid_display,"visible",true,0.2)
		prevent_walk = true
		berry_button.disabled = true
		hen_button.disabled = true

	is_wheat_pressed = !is_wheat_pressed


func _on_pick_berry_pressed():
	var tween = get_tree().create_tween()
	if is_berry_pressed:
		Input.set_custom_mouse_cursor(basic_cursor)
		tween.tween_property(grid_display,"visible",false,0.2)
		prevent_walk = false
		wheat_button.disabled = false
		hen_button.disabled = false
	else:
		Input.set_custom_mouse_cursor(berry_cursor)
		tween.tween_property(grid_display,"visible",true,0.2)
		prevent_walk = true
		wheat_button.disabled = true
		hen_button.disabled = true
	is_berry_pressed = !is_berry_pressed

func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	if prevent_walk:
		if event.is_action_pressed("mouse_left"):
			already_used = false
			var pos_in_map = tilemap.local_to_map(get_viewport().get_camera_2d().get_global_mouse_position())
			var pos = tilemap.map_to_local(pos_in_map)
			var data = tilemap.get_cell_tile_data(pos_in_map)
			if data:
				var plantable = data.get_custom_data("Plantable")
				if plantable:
					for cell in crops.get_children():
						if cell.position == pos:
							already_used = true
							break
					if !already_used:
						if is_wheat_pressed:
							if money >= wheat_price:
								crop = wheat.instantiate()
								crop.position = pos
								crop.z_index = crops.z_index
								crops.add_child(crop)
								money -= wheat_price
						elif is_berry_pressed:
							if money >= berry_price:
								crop = berry.instantiate()
								crop.position = pos
								crop.z_index = crops.z_index
								crops.add_child(crop)
								money -= berry_price
	allow_walk.emit(!prevent_walk)

func _process(delta):
	if grid_display.is_visible_in_tree():
		# Get mouse world position
		var mouse_world_position = get_viewport().get_camera_2d().get_global_mouse_position()
		# Convert world position to TileMap grid position (snap to nearest tile)
		var tile_position = tilemap.local_to_map(mouse_world_position)
		# Convert the tile position back to world position to align the grid properly
		var snapped_position = tilemap.map_to_local(tile_position)
		# If using a TileMap with half-offset (e.g., isometric), adjust accordingly:
		snapped_position -= grid_display.cell_size * grid_display.grid_size / 2
		# Position the grid_display or highlight at the snapped tile position
		grid_display.global_position = snapped_position
	


func _on_pick_hen_pressed():
	hen_button.set_pressed_no_signal(false)
	if money >= hen_price: 
		var hen = chicken.instantiate()
		hen.position = tilemap.local_to_map(hen_house.global_position)
		hen_house.add_child(hen)
		money -= hen_price
		info_label.show()
		label_timer.start()
	is_wheat_pressed = true
	_on_pick_wheat_pressed()
	is_berry_pressed = true
	_on_pick_berry_pressed()


func _on_timer_timeout():
	info_label.hide()
