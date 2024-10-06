extends StaticBody2D

@onready var phase_timer = $PhaseTimer
@export var egg_time:float = 45
@onready var pb = $ProgressBar
@onready var animation = $AnimatedSprite2D
@onready var game = get_node("/root/Level1")
@onready var label = $harvest_announce
@onready var particles = $particle

@export var egg_worth := 150

var ready_for_egg:bool = false
var incubate_egg:bool = false
var chicken_present:bool = false
var completed:bool = false
var player_proximity :bool= false
@onready var pickup_sound = get_node("/root/Level1/pickup")

func _ready():
	phase_timer.wait_time = egg_time
	pb.max_value = phase_timer.wait_time
	phase_timer.start()

func _process(delta):
	pb.value = phase_timer.wait_time - phase_timer.time_left
	if ready_for_egg and chicken_present:
		animation.play("full_nest")
		ready_for_egg = false
		phase_timer.start()
		incubate_egg = true
		

func _unhandled_input(event):
	if event.is_action_pressed("mouse_left"):
		if completed and player_proximity:
			var tween = get_tree().create_tween()
			game.money += egg_worth
			label.set_text("+" + str(egg_worth) + " money")
			particles.emitting = true
			tween.tween_property(label,"position",Vector2(label.position.x,label.position.y - 2),0.7)
			pickup_sound.play()
			await tween.finished
			animation.play("empty_nest")
			ready_for_egg = false
			completed = false
			incubate_egg = false
			label.set_text("")
			tween.tween_property(label,"position",Vector2(label.position.x,label.position.y + 2),0.7)
			phase_timer.start()

func _on_phase_timer_timeout():
	if !incubate_egg:
		ready_for_egg = true
	else:
		completed = true


func _on_check_for_chicken_body_entered(body):
	if body.is_in_group("Chicken"):
		chicken_present = true


func _on_check_for_chicken_body_exited(body):
	if body.is_in_group("Chicken"):
		chicken_present = false


func _on_check_for_player_body_entered(body):
	if body.is_in_group("player"):
		player_proximity = true


func _on_check_for_player_body_exited(body):
	if body.is_in_group("player"):
		player_proximity = false
