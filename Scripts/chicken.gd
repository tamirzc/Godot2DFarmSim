extends CharacterBody2D

@export var hunger: float
@export var hunger_per_frame := 0.2
@export var hunger_limit := 25
@export var nest_hunger_limit := 60
@export var nest_exists := false
var wheat_supply : Array = []
var choose_direction_x = randi() % 3 - 1
var choose_direction_y = randi() % 3 - 1

var astar_grid: AStarGrid2D
@onready var tile_map = get_node("/root/Level1/Ground")
@onready var hen_house = get_node("/root/Level1/HenHouse")
@onready var nests = get_node("/root/Level1/Nests")
var current_id_path: Array[Vector2i]

var min_distance_to_wheat := 2**32
var chosen_wheat
var speed := 100

var have_nest: bool = false
const nest_scene := preload("res://Scenes/Nest.tscn")
var nest:Node

func _ready():
	hunger = randf_range(25,50)

	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = Vector2(16,16)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	astar_grid.set_point_solid(hen_house.position)
	
	for x in tile_map.get_used_rect().size.x:
		for y in tile_map.get_used_rect().size.y:
			var tile_position = Vector2i(
				x + tile_map.get_used_rect().position.x,
				y + tile_map.get_used_rect().position.y
			)
			
			var tile_data = tile_map.get_cell_tile_data(tile_position)
			
			if tile_data == null or !tile_data.get_custom_data("Walkable"):
				astar_grid.set_point_solid(tile_position)

func _physics_process(delta):
	hunger -= delta * hunger_per_frame
	
	if hunger <= hunger_limit:
		if hunger <= 0:
			chicken_die()

func _process(delta):
	if Engine.get_process_frames() % 100 == 0:
		if hunger<=hunger_limit and !wheat_supply.is_empty():
			for wheat in wheat_supply:
				if distance(wheat.position,position) < min_distance_to_wheat:
					chosen_wheat = wheat
					min_distance_to_wheat = distance(wheat.position,position)
			if chosen_wheat:
				var id_path = astar_grid.get_id_path(
				tile_map.local_to_map(global_position),
				tile_map.local_to_map(chosen_wheat.position)
				).slice(1)
				if !id_path.is_empty():
					current_id_path = id_path
				var target_position = tile_map.map_to_local(current_id_path.front())
				global_position = global_position.move_toward(target_position,speed)
		
		elif have_nest and hunger >= nest_hunger_limit and nest.ready_for_egg:
			var id_path = astar_grid.get_id_path(
			tile_map.local_to_map(global_position),
			tile_map.local_to_map(nest.position)
			).slice(1)
			if !id_path.is_empty():
				current_id_path = id_path
			var target_position = tile_map.map_to_local(current_id_path.front())
			global_position = global_position.move_toward(target_position,speed)

			
		elif Engine.get_process_frames() % (randi() % 3 + 1) == 0:
			var new_pos = global_position + Vector2(16*choose_direction_x,16*choose_direction_y)
			if tile_map.get_used_rect().has_point(tile_map.local_to_map(new_pos)):
				global_position = new_pos
			choose_direction_x = randi() % 3 - 1
			choose_direction_y = randi() % 3 - 1
			if !have_nest and randi() % 5 == 0 and hunger >= nest_hunger_limit:
				nest = nest_scene.instantiate()
				nests.add_child(nest)
				nest.position = new_pos
				have_nest = true


func chicken_die():
	pass
	#queue_free()

func _on_collision_wheat_body_entered(body):
	if body.is_in_group("Food"):
		wheat_supply.append(body)

func _on_collision_wheat_body_exited(body):
	if body.is_in_group("Food"):
		wheat_supply.erase(body)

func distance(Va:Vector2,Vb:Vector2):
	return sqrt((Va.x-Vb.x)**2+(Va.y-Vb.y)**2)


func _on_collision_eat_body_entered(body):
	if body == chosen_wheat:
		chosen_wheat.eat()
		hunger += 70
