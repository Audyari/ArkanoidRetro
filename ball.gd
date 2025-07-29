extends Sprite2D

# === Constants (lebih mudah untuk tweaking) ===
const INITIAL_SPEED_X := 300.0
const INITIAL_SPEED_Y := 300.0
const SCREEN_WIDTH := 800.0
const SCREEN_HEIGHT := 600.0
const BOUNCE_DAMPING := 0.9          # Sedikit kehilangan energi saat bounce
const MIN_SPEED := 50.0              # Kecepatan minimum

# === Variables ===
var velocity := Vector2.ZERO
var ball_radius := 32.0              # Radius bola (auto-detect dari sprite)

# === Signals (untuk komunikasi dengan game manager) ===
signal ball_hit_wall(wall_side: String)
signal ball_hit_paddle(paddle_position: Vector2)
signal ball_out_of_bounds(side: String)

func _ready() -> void:
	initialize_ball()
	auto_detect_radius()

func _process(delta: float) -> void:
	move_ball(delta)
	check_boundaries()

# === Initialization ===
func initialize_ball() -> void:
	"""Setup nilai awal bola"""
	velocity = Vector2(INITIAL_SPEED_X, INITIAL_SPEED_Y)
	# Randomize arah awal
	if randf() > 0.5:
		velocity.x *= -1
	if randf() > 0.5:
		velocity.y *= -1

func auto_detect_radius() -> void:
	"""Deteksi radius berdasarkan ukuran sprite"""
	if texture:
		ball_radius = min(texture.get_width(), texture.get_height()) * 0.5 * scale.x

# === Core Movement ===
func move_ball(delta: float) -> void:
	"""Update posisi bola berdasarkan velocity"""
	position += velocity * delta

func check_boundaries() -> void:
	"""Cek collision dengan dinding dan emit signals"""
	var collision_occurred := false
	
	# Dinding kiri
	if position.x - ball_radius <= 0:
		position.x = ball_radius
		velocity.x = abs(velocity.x) * BOUNCE_DAMPING
		ball_hit_wall.emit("left")
		collision_occurred = true
	
	# Dinding kanan
	elif position.x + ball_radius >= SCREEN_WIDTH:
		position.x = SCREEN_WIDTH - ball_radius
		velocity.x = -abs(velocity.x) * BOUNCE_DAMPING
		ball_hit_wall.emit("right")
		collision_occurred = true
	
	# Dinding atas
	if position.y - ball_radius <= 0:
		position.y = ball_radius
		velocity.y = abs(velocity.y) * BOUNCE_DAMPING
		ball_hit_wall.emit("top")
		collision_occurred = true
	
	# Dinding bawah (bisa jadi game over)
	elif position.y + ball_radius >= SCREEN_HEIGHT:
		position.y = SCREEN_HEIGHT - ball_radius
		velocity.y = -abs(velocity.y) * BOUNCE_DAMPING
		ball_hit_wall.emit("bottom")
		collision_occurred = true
	
	# Pastikan kecepatan tidak terlalu lambat
	if collision_occurred:
		maintain_minimum_speed()

func maintain_minimum_speed() -> void:
	"""Pastikan bola tidak terlalu lambat"""
	if velocity.length() < MIN_SPEED:
		velocity = velocity.normalized() * MIN_SPEED

# === Collision Events ===
func _on_area_2d_area_entered(area: Area2D) -> void:
	"""Callback function untuk collision detection - connect ini ke Area2D signal"""
	print("Ball hit area!")
	
	# Reverse Y direction dengan sedikit randomness untuk variasi
	velocity.y = -velocity.y * randf_range(0.95, 1.05)
	
	# Tambah sedikit angle berdasarkan posisi hit
	var hit_offset = position.x - area.global_position.x
	velocity.x += hit_offset * 2.0  # Faktor untuk kontrol angle
	
	# Maintain speed
	maintain_minimum_speed()
	
	# Emit signal untuk game manager
	ball_hit_paddle.emit(area.global_position)

func on_paddle_hit(area: Area2D) -> void:
	"""Alternative method - bisa dipanggil manual juga"""
	_on_area_2d_area_entered(area)

# === Public Methods (API untuk game manager) ===
func reset_position(new_pos: Vector2 = Vector2(SCREEN_WIDTH/2, SCREEN_HEIGHT/2)) -> void:
	"""Reset posisi bola ke posisi tertentu"""
	position = new_pos
	initialize_ball()

func set_speed(new_speed: float) -> void:
	"""Ubah kecepatan bola dengan mempertahankan arah"""
	velocity = velocity.normalized() * new_speed

func get_speed() -> float:
	"""Get kecepatan saat ini"""
	return velocity.length()

func pause_ball() -> void:
	"""Pause gerakan bola"""
	set_process(false)

func resume_ball() -> void:
	"""Resume gerakan bola"""
	set_process(true)

func reverse_x() -> void:
	"""Balik arah horizontal"""
	velocity.x *= -1

func reverse_y() -> void:
	"""Balik arah vertikal"""
	velocity.y *= -1

func add_spin_effect(spin_force: Vector2) -> void:
	"""Tambah efek spin/curve pada bola"""
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
	"""Get arah gerakan bola (normalized)"""
	return velocity.normalized()

# === Debug Methods ===
func get_debug_info() -> Dictionary:
	"""Return info untuk debugging"""
	return {
		"position": position,
		"velocity": velocity,
		"speed": velocity.length(),
		"direction": get_direction()
	}

func _draw() -> void:
	"""Draw debug info jika dalam debug mode"""
	if OS.is_debug_build():
		# Draw velocity vector
		var vel_visual = velocity * 0.2
		draw_line(Vector2.ZERO, vel_visual, Color.RED, 2.0)
		
		# Draw speed text
		var font = ThemeDB.fallback_font
		var speed_text = "Speed: %.0f" % velocity.length()
		draw_string(font, Vector2(-30, -40), speed_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
