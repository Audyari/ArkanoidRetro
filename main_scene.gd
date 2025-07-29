extends Node2D

var brick_scene = preload("res://brick.tscn")

func _ready():
	for i in range(5):
		for j in range(5):
			var brick = brick_scene.instantiate()
			add_child(brick)
			brick.position = Vector2(100 + 150 * i, 50 + 50 * j)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
