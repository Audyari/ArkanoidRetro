extends Sprite2D

const INITIAL_SPEED_X := 300
const INITIAL_SPEED_Y := 300
const SCREEN_WIDTH := 800.0
const SCREEN_HEIGHT := 600.0
const BOUNCE_DAMPING := 0.9
const MIN_SPEED := 50.0

var velocity := Vector2.ZERO
var ball_radius := 32.0

signal ball_hit_wall(wall_side: String)
signal ball_hit_paddle(paddle_position: Vector2)

func _ready() -> void:
	pause_ball()
	auto_detect_radius()
	velocity = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	move_ball(_delta)
	check_boundaries()

func move_ball(delta: float) -> void:
	position += velocity * delta

func check_boundaries() -> void:
	var collision := false

	if position.x - ball_radius <= 0:
		position.x = ball_radius
		velocity.x = abs(velocity.x) * BOUNCE_DAMPING
		ball_hit_wall.emit("left")
		collision = true
	elif position.x + ball_radius >= SCREEN_WIDTH:
		position.x = SCREEN_WIDTH - ball_radius
		velocity.x = -abs(velocity.x) * BOUNCE_DAMPING
		ball_hit_wall.emit("right")
		collision = true

	if position.y - ball_radius <= 0:
		position.y = ball_radius
		velocity.y = abs(velocity.y) * BOUNCE_DAMPING
		ball_hit_wall.emit("top")
		collision = true
	elif position.y + ball_radius >= SCREEN_HEIGHT:
		print("Game Over")
		velocity = Vector2.ZERO
		pause_ball()
		get_tree().reload_current_scene()

	if collision:
		maintain_minimum_speed()

func maintain_minimum_speed() -> void:
	if velocity.length() < MIN_SPEED:
		velocity = velocity.normalized() * MIN_SPEED

func _on_area_2d_area_entered(area: Area2D) -> void:
	velocity.y = -velocity.y * randf_range(0.95, 1.05)
	var offset = position.x - area.global_position.x
	velocity.x += offset * 2.0

	maintain_minimum_speed()
	ball_hit_paddle.emit(area.global_position)

	if area.get_parent().is_in_group("bricks"):
		var brick = area.get_parent()
		var tween = create_tween()
		tween.tween_property(brick, "scale", Vector2(0, 0), 0.3)
		tween.tween_property(brick, "modulate:a", 0.0, 0.3)
		tween.tween_callback(Callable(brick, "queue_free"))

		await tween.finished
		_check_win()

func _check_win():
	if get_tree().get_nodes_in_group("bricks").size() == 0:
		print("You Win!")
		get_tree().reload_current_scene()

func auto_detect_radius() -> void:
	if texture:
		ball_radius = min(texture.get_width(), texture.get_height()) * 0.5 * scale.x

# === Public Methods ===
func reset_position(pos: Vector2) -> void:
	position = pos
	initialize_ball()

func initialize_ball() -> void:
	velocity = Vector2(INITIAL_SPEED_X, -abs(INITIAL_SPEED_Y))
	if randf() > 0.5:
		velocity.x *= -1

func pause_ball() -> void:
	set_physics_process(false)

func resume_ball() -> void:
	set_physics_process(true)

func set_speed(s: float) -> void:
	velocity = velocity.normalized() * s

func get_speed() -> float:
	return velocity.length()
