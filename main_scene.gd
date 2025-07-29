extends Node2D

var brick_scene = preload("res://brick.tscn")

@onready var ball = $Ball
@onready var timer = $Timer
@onready var label = $Label

var initial_position := Vector2.ZERO

func _ready():
	initial_position = ball.position

	# Spawn bricks
	for i in range(5):
		for j in range(5):
			var brick = brick_scene.instantiate()
			add_child(brick)
			brick.position = Vector2(100 + 150 * i, 50 + 50 * j)
			brick.add_to_group("bricks")

	# Mulai timer countdown sebelum main
	timer.start()
	ball.pause_ball()
	ball.reset_position(initial_position)

func _on_timer_timeout() -> void:
	ball.reset_position(initial_position)
	ball.set_speed(300)
	ball.resume_ball()
	label.text = ""

func _process(_delta: float) -> void:
	var t = floor(timer.time_left)
	label.text = "%d" % t if t > 0 else ""
