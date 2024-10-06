extends CharacterBody2D

@onready var tile_map = %Ground

var astar_grid: AStarGrid2D
var current_id_path: Array[Vector2i]
@export var speed = 1
@onready var animation = $AnimatedSprite2D
@onready var animation_timer = $TimerIdle
@onready var camera = $Camera2D
var fullmap := false
var direction: Vector2
var previous_location = Vector2.ZERO
var theta := 0.0
var direction_str:="down"
var interact := false
var allow_walk
@onready var crops = $"../Crops"


func _ready():
	
	
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = Vector2(16,16)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	for x in tile_map.get_used_rect().size.x:
		for y in tile_map.get_used_rect().size.y:
			var tile_position = Vector2i(
				x + tile_map.get_used_rect().position.x,
				y + tile_map.get_used_rect().position.y
			)
			
			var tile_data = tile_map.get_cell_tile_data(tile_position)
			
			if tile_data == null or !tile_data.get_custom_data("Walkable"):
				astar_grid.set_point_solid(tile_position)

func _unhandled_input(event):
	if event.is_action_pressed("prespective"):
		var tween = get_tree().create_tween()
		if !fullmap:
			tween.tween_property(camera, "zoom", Vector2(1,1), 0.8)
			fullmap = true
		else:
			tween.tween_property(camera, "zoom", Vector2(2.5,2.5), 0.8)
			fullmap = false
	#if !event.is_action_pressed("mouse_left"):
		#return
	if event.is_action_pressed("mouse_left") and allow_walk:
		var id_path = astar_grid.get_id_path(
			tile_map.local_to_map(global_position),
			tile_map.local_to_map(get_global_mouse_position())
		).slice(1)
		if !id_path.is_empty():
			current_id_path = id_path
		for child in crops.get_children():
			child.connect("player_water_plant",_on_player_water_plant)

func _physics_process(delta):
	if current_id_path.is_empty():
		return
	
	var target_position = tile_map.map_to_local(current_id_path.front())
	direction = target_position - global_position
	direction = direction.normalized()
	global_position = global_position.move_toward(target_position,speed)
	if global_position == target_position:
		current_id_path.pop_front()
	theta = rad_to_deg(atan2(direction.y, direction.x))
	if theta >= 0 and theta < 90:
		direction_str = "right"
		set_animation("walk",direction_str)  # Right
	elif theta >= 90 and theta < 180:
		direction_str = "down"
		set_animation("walk",direction_str)  # down
	elif theta >= -90 and theta < 0:
		direction_str = "up"
		set_animation("walk",direction_str)  # up
	elif theta >= 180 and theta < 270:
		direction_str = "left"
		set_animation("walk",direction_str)  # left
	animation_timer.start()

func _on_player_water_plant():
	interact = true
	animation_timer.start()
	set_animation("water",direction_str)

func set_animation(action:String, direction:String) -> void:
	var animation_string = action + "_" + direction
	animation.play(animation_string)


func _on_timer_idle_timeout():
	interact = false
	set_animation("idle",direction_str)


func _on_level_1_allow_walk(can_walk):
	allow_walk = can_walk
