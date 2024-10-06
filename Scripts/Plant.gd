extends StaticBody2D
class_name Plant

var allow_interact := false
var proximity_interact:bool = false
@onready var sprite := $AnimatedSprite2D
var frame_num :int = 0
@export var max_frames := 3
#@onready var player = %PlayerCharacter
@onready var label = $harvest_announce
@onready var particles = $particle
@onready var phase_timer = $PhaseTimer
@onready var pb = $ProgressBar
var phase_completed :bool = false
var wheat_time_per_phase :float= 7
var berry_time_per_phase :float= 8

@onready var game = get_node("/root/Level1")
var wheat_sell_price = 25
var berry_sell_price = 40

@onready var pickup_sound = get_node("/root/Level1/pickup")


signal ready_to_harvest
signal player_water_plant # signal that change player animation. after finish, change frame.

func _ready():
	if self.is_in_group("Wheat"):
		phase_timer.wait_time = wheat_time_per_phase
	elif self.is_in_group("Berry"):
		phase_timer.wait_time = berry_time_per_phase
	pb.max_value = phase_timer.wait_time

func _process(delta):
	pb.value = phase_timer.wait_time - phase_timer.time_left
	if proximity_interact and phase_completed:
		allow_interact = true

func _on_area_2d_input_event(viewport, event: InputEvent, shape_idx):
	if event.is_action_pressed("mouse_left"):
		if allow_interact:
			player_water_plant.emit()
			if frame_num<max_frames:
				var tween = get_tree().create_tween()
				tween.tween_property(sprite,"frame",frame_num+1,0.65)
				frame_num += 1
				phase_timer.start()
				phase_completed = false
				allow_interact = false
			else:
				pb.hide()
				ready_to_harvest.emit()


func _on_interact_body_entered(body):
	if body.is_in_group("player"):
		proximity_interact = true


func _on_interact_body_exited(body):
	if body.is_in_group("player"):
		proximity_interact = false


func _on_ready_to_harvest():
	harvest()

func harvest():
	var tween = get_tree().create_tween()
	if self.is_in_group("Wheat"):
		game.money += wheat_sell_price
		label.set_text("+" + str(wheat_sell_price) + " money")
	elif self.is_in_group("Berry"):
		game.money += berry_sell_price
		label.set_text("+" + str(berry_sell_price) + " money")
	particles.emitting = true
	pickup_sound.play()
	tween.tween_property(label,"position",Vector2(label.position.x,label.position.y - 2),0.7)
	await tween.finished
	queue_free()

func eat():
	# play eating sfx?
	particles.emitting = true
	queue_free()


func _on_phase_timer_timeout():
	phase_completed = true
