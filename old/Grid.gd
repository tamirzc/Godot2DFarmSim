class_name Grid
extends Resource

@export var size:Vector2 = Vector2(32,32)
@export var cell_size:Vector2 = Vector2(16*2,16*2)

var _half_cell_size:Vector2 = cell_size/2

func calculate_map_position(grid_position:Vector2) -> Vector2:
	return grid_position * cell_size + _half_cell_size

func calculate_grid_coordinates(map_position: Vector2) -> Vector2:
	return (map_position / cell_size).floor()

func is_within_bounds(cell_coordinates:Vector2) -> bool:
	return cell_coordinates.x>=0 and cell_coordinates.x<size.x and cell_coordinates.y>=0 and cell_coordinates.y<size.y

func clamp(grid_position: Vector2) -> Vector2:
	var out := grid_position
	out.x = clamp(out.x, 0, size.x - 1.0)
	out.y = clamp(out.y, 0, size.y - 1.0)
	return out

func as_index(cell: Vector2) -> int:
	return int(cell.x + size.x * cell.y)
