extends Sprite2D

# === Constants (mudah untuk tweaking) ===
const INITIAL_SPEED_X := 300.0
const INITIAL_SPEED_Y := 300.0
const SCREEN_WIDTH := 800.0
const SCREEN_HEIGHT := 600.0
const BOUNCE_DAMPING := 0.9
const MIN_SPEED := 50.0

# === Variables ===
var velocity := Vector2.ZERO
var ball_radius := 32.0
var bricks_list := []

# === Signals ===
signal ball_hit_wall(wall_side: String)
signal ball_hit_paddle(paddle_position: Vector2)
signal ball_out_of_bounds(side: String)

func _ready() -> void:
	initialize_ball()
	auto_detect_radius()

func _process(delta: float) -> void:
	move_ball(delta)
	check_boundaries()

	bricks_list = get_tree().get_nodes_in_group("bricks")
	print("Jumlah brick: ", bricks_list.size())

	if bricks_list.size() == 0:
		print("winn")
		get_tree().change_scene_to_file("res://main_scene.tscn")

# === Initialization ===
func initialize_ball() -> void:
	velocity = Vector2(INITIAL_SPEED_X, INITIAL_SPEED_Y)
	if randf() > 0.5:
		velocity.x *= -1
	if randf() > 0.5:
		velocity.y *= -1

func auto_detect_radius() -> void:
	if texture:
		ball_radius = min(texture.get_width(), texture.get_height()) * 0.5 * scale.x

# === Core Movement ===
func move_ball(delta: float) -> void:
	position += velocity * delta

func check_boundaries() -> void:
	var collision_occurred := false

	if position.x - ball_radius <= 0:
		position.x = ball_radius
		velocity.x = abs(velocity.x) * BOUNCE_DAMPING
		ball_hit_wall.emit("left")
		collision_occurred = true
	elif position.x + ball_radius >= SCREEN_WIDTH:
		position.x = SCREEN_WIDTH - ball_radius
		velocity.x = -abs(velocity.x) * BOUNCE_DAMPING
		ball_hit_wall.emit("right")
		collision_occurred = true

	if position.y - ball_radius <= 0:
		position.y = ball_radius
		velocity.y = abs(velocity.y) * BOUNCE_DAMPING
		ball_hit_wall.emit("top")
		collision_occurred = true
	elif position.y + ball_radius >= SCREEN_HEIGHT:
		position.y = SCREEN_HEIGHT - ball_radius
		velocity.y = -abs(velocity.y) * BOUNCE_DAMPING
		ball_hit_wall.emit("bottom")
		collision_occurred = true

	if collision_occurred:
		maintain_minimum_speed()

func maintain_minimum_speed() -> void:
	if velocity.length() < MIN_SPEED:
		velocity = velocity.normalized() * MIN_SPEED

# === Collision Events ===
func _on_area_2d_area_entered(area: Area2D) -> void:
	print("Ball hit area!")

	velocity.y = -velocity.y * randf_range(0.95, 1.05)
	var hit_offset = position.x - area.global_position.x
	velocity.x += hit_offset * 2.0

	maintain_minimum_speed()
	ball_hit_paddle.emit(area.global_position)

	if area.get_parent().is_in_group("bricks"):
		var brick = area.get_parent()
		print("hit brick")

		var tween = create_tween()
		tween.tween_property(brick, "scale", Vector2(0, 0), 0.3)
		tween.tween_property(brick, "modulate:a", 0.0, 0.3)
		tween.tween_callback(Callable(brick, "queue_free"))

func on_paddle_hit(area: Area2D) -> void:
	_on_area_2d_area_entered(area)

# === Public Methods ===
func reset_position(new_pos: Vector2 = Vector2(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)) -> void:
	position = new_pos
	initialize_ball()

func set_speed(new_speed: float) -> void:
	velocity = velocity.normalized() * new_speed

func get_speed() -> float:
	return velocity.length()

func pause_ball() -> void:
	set_process(false)

func resume_ball() -> void:
	set_process(true)

func reverse_x() -> void:
	velocity.x *= -1

func reverse_y() -> void:
	velocity.y *= -1

func add_spin_effect(spin_force: Vector2) -> void:
	velocity += spin_force

# === Utility Methods ===
func is_moving_left() -> bool:
	return velocity.x < 0

func is_moving_right() -> bool:
	return velocity.x > 0

func is_moving_up() -> bool:
	return velocity.y < 0

func is_moving_down() -> bool:
	return velocity.y > 0

func get_direction() -> Vector2:
	return velocity.normalized()

# === Debugging ===
func get_debug_info() -> Dictionary:
	return {
		"position": position,
		"velocity": velocity,
		"speed": velocity.length(),
		"direction": get_direction()
	}

func _draw() -> void:
	if OS.is_debug_build():
		var vel_visual = velocity * 0.2
		draw_line(Vector2.ZERO, vel_visual, Color.RED, 2.0)

		var font = ThemeDB.fallback_font
		var speed_text = "Speed: %.0f" % velocity.length()
		draw_string(font, Vector2(-30, -40), speed_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
