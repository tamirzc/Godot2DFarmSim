class_name Player extends Path2D

@export var grid:Resource = preload("res://Resources/Grid.tres")
@export var move_range := 10000
@export var move_speed := 50.0
var cell:=Vector2.ZERO: set=set_cell
var _is_walking := false : set = _set_is_walking

@onready var _path_follow: PathFollow2D = $PathFollow2D
@onready var animation = $PathFollow2D/PlayerCharacter/AnimatedSprite2D
@onready var animation_timer = $PathFollow2D/PlayerCharacter/Timer

var end_point
var start_point
var fullmap := false
var direction: Vector2
var previous_location = Vector2.ZERO
var theta := 0.0
var direction_str:="down"
var interact := false


signal walk_finished

func _ready() -> void:
	# We'll use the `_process()` callback to move the unit along a path. Unless it has a path to
	# walk, we don't want it to update every frame. See `walk_along()` below.
	set_process(false)

	# The following lines initialize the `cell` property and snap the unit to the cell's center on the map.
	self.cell = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(cell)

	if not curve:
		# We create the curve resource here because creating it in the editor prevents us from
		# moving the unit.
		curve = Curve2D.new()
		
	#var points := [
		#Vector2(5, 4),
		#Vector2(5, 5)
	#]
	#walk_along(PackedVector2Array(points))


# When active, moves the unit along its `curve` with the help of the PathFollow2D node.
func _process(delta: float) -> void:
	# Every frame, the `PathFollow2D.offset` property moves the sprites along the `curve`.
	# The great thing about this is it moves an exact number of pixels taking turns into account.
	_path_follow.progress += move_speed * delta
	
	direction = _path_follow.global_position - previous_location
	previous_location = _path_follow.global_position
	direction = direction.normalized()
	theta = rad_to_deg(atan2(direction.y, direction.x))
	print(theta)
	if theta >= 0 and theta < 90:
		direction_str = "right"
		set_animation("walk",direction_str)  # Right
	elif theta >= 90 and theta < 180:
		direction_str = "down"
		set_animation("walk",direction_str)  # down
	elif theta >= -90 and theta < 0:
		direction_str = "up"
		set_animation("walk",direction_str)  # up
	elif theta >= -180 and theta < -90:
		direction_str = "left"
		set_animation("walk",direction_str)  # left
	
	# When we increase the `offset` above, the `unit_offset` also updates. It represents how far you
	# are along the `curve` in percent, where a value of `1.0` means you reached the end.
	# When that is the case, the unit is done moving.
	if _path_follow.progress_ratio >= 1.0:
		# Setting `_is_walking` to `false` also turns off processing.
		self._is_walking = false
		# Below, we reset the offset to `0.0`, which snaps the sprites back to the Unit node's
		# position, we position the node to the center of the target grid cell, and we clear the
		# curve.
		# In the process loop, we only moved the sprite, and not the unit itself. The following
		# lines move the unit in a way that's transparent to the player.
		_path_follow.progress = 0.0
		position = grid.calculate_map_position(cell)
		curve.clear_points()
		# Finally, we emit a signal. We'll use this one with the game board.
		emit_signal("walk_finished")
		set_animation("idle",direction_str)


func set_cell(value: Vector2) -> void:
	cell = grid.clamp(value)

func _set_is_walking(value: bool) -> void:
	_is_walking = value
	set_process(_is_walking)


# Starts walking along the `path`.
# `path` is an array of grid coordinates that the function converts to map coordinates.
func walk_along(path) -> void:
	if path == null:
		return
	# This code converts the `path` to points on the `curve`. That property comes from the `Path2D`
	# class the Unit extends.
	if !_is_walking:
		curve.add_point(Vector2.ZERO)
	for point in path:
		curve.add_point(grid.calculate_map_position(point) - position)
	# We instantly change the unit's cell to the target position. You could also do that when it
	# reaches the end of the path, using `grid.calculate_grid_coordinates()`, instead.
	# I did it here because we have the coordinates provided by the `path` argument.
	# The cell itself represents the grid coordinates the unit will stand on.
	cell = path[-1]
	# The `_is_walking` property triggers the move animation and turns on `_process()`. See
	# `_set_is_walking()` below.
	self._is_walking = true

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if !interact:
			var world_position = get_global_mouse_position()  # Get mouse position in world coordinates
			end_point = Vector2(int(world_position.x/32),int(world_position.y/32))
			start_point = position
			var points:= [end_point]
			walk_along(PackedVector2Array(points))
	if event.is_action_pressed("ui_accept"):
		var tween = get_tree().create_tween()
		if !fullmap:
			tween.tween_property($PathFollow2D/PlayerCharacter/Camera2D, "zoom", Vector2(1,1), 0.8)
			fullmap = true
		else:
			tween.tween_property($PathFollow2D/PlayerCharacter/Camera2D, "zoom", Vector2(2.5,2.5), 0.8)
			fullmap = false


func _on_wheat_player_water_plant():
	interact = true
	animation_timer.start()
	set_animation("water",direction_str)

func _on_timer_timeout():
	interact = false
	set_animation("idle",direction_str)

func set_animation(action:String, direction:String) -> void:
	var animation_string = action + "_" + direction
	animation.play(animation_string)
