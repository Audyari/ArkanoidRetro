extends Sprite2D

# === Konstanta dan variabel gerakan ===
var velocity := Vector2.ZERO
var max_speed := 280.0               # Kecepatan maksimal (sedikit lebih lambat)
var acceleration := 1000.0           # Akselerasi
var friction := 800.0                # Friksi
var air_resistance := 50.0           # Hambatan udara saat bergerak cepat
var left_limit := 60.0
var right_limit := 740.0

# === Variabel momentum dan physics ===
var momentum_factor := 0.95          # Faktor momentum (0-1)
var input_buffer := 0.0              # Buffer untuk input yang lebih smooth
var direction_change_penalty := 0.3  # Penalti saat mengubah arah

# === Variabel visual effects ===
var base_scale := Vector2.ONE
var squash_stretch_factor := 0.1
var tilt_angle := 0.0
var max_tilt := 15.0                 # Derajat kemiringan maksimal
var shake_intensity := 0.0
var dust_timer := 0.0

# === Variabel ground interaction ===
var ground_friction_multiplier := 1.0
var is_on_ground := true
@onready var original_y := position.y

# === Audio dan particle (simulasi) ===
var step_timer := 0.0
var step_interval := 0.3

func _ready():
	base_scale = scale

func _process(delta: float) -> void:
	handle_input(delta)
	apply_physics(delta)
	update_position(delta)
	apply_visual_effects(delta)
	handle_audio_effects(delta)

func handle_input(delta: float) -> void:
	var input_direction := 0.0
	
	# Baca input dengan smoothing
	if Input.is_action_pressed("ui_left"):
		input_direction = -1.0
	elif Input.is_action_pressed("ui_right"):
		input_direction = 1.0
	
	# Smooth input buffer untuk gerakan yang lebih natural
	input_buffer = lerp(input_buffer, input_direction, 12.0 * delta)
	
	# Penalti saat mengubah arah (lebih realistis)
	if sign(input_buffer) != sign(velocity.x) and abs(velocity.x) > 50.0:
		velocity.x *= (1.0 - direction_change_penalty)

func apply_physics(delta: float) -> void:
	# Akselerasi berdasarkan input
	if abs(input_buffer) > 0.1:
		var target_velocity = input_buffer * max_speed
		velocity.x = move_toward(velocity.x, target_velocity, acceleration * delta)
	else:
		# Friksi dengan faktor ground
		var current_friction = friction * ground_friction_multiplier
		velocity.x = move_toward(velocity.x, 0, current_friction * delta)
	
	# Air resistance (hambatan udara) - semakin cepat semakin besar hambatan
	var air_drag = air_resistance * abs(velocity.x) / max_speed
	velocity.x = move_toward(velocity.x, 0, air_drag * delta)
	
	# Momentum preservation
	velocity.x *= momentum_factor

func update_position(delta: float) -> void:
	# Update posisi dengan velocity
	position.x += velocity.x * delta
	
	# Boundary collision dengan bounce effect
	if position.x <= left_limit:
		position.x = left_limit
		velocity.x = abs(velocity.x) * 0.2  # Bounce back dengan energi berkurang
		create_collision_effect()
	elif position.x >= right_limit:
		position.x = right_limit
		velocity.x = -abs(velocity.x) * 0.2  # Bounce back
		create_collision_effect()

func apply_visual_effects(delta: float) -> void:
	# === Squash and Stretch berdasarkan kecepatan ===
	var speed_ratio = abs(velocity.x) / max_speed
	var stretch_x = 1.0 + (speed_ratio * squash_stretch_factor)
	var squash_y = 1.0 - (speed_ratio * squash_stretch_factor * 0.5)
	scale = base_scale * Vector2(stretch_x, squash_y)
	
	# === Tilt/lean ke arah gerakan ===
	var target_tilt = -(velocity.x / max_speed) * max_tilt
	tilt_angle = lerp_angle(tilt_angle, deg_to_rad(target_tilt), 8.0 * delta)
	rotation = tilt_angle
	
	# === Screen shake saat bergerak cepat ===
	if abs(velocity.x) > max_speed * 0.7:
		shake_intensity = (abs(velocity.x) / max_speed) * 2.0
		position.y = original_y + sin(Time.get_ticks_msec() * 0.03) * shake_intensity
	else:
		shake_intensity = lerp(shake_intensity, 0.0, 5.0 * delta)
		position.y = lerp(position.y, original_y, 8.0 * delta)
	
	# === Dust particles simulation ===
	if abs(velocity.x) > 100.0:
		dust_timer += delta
		if dust_timer >= 0.1:  # Setiap 0.1 detik
			create_dust_effect()
			dust_timer = 0.0

func handle_audio_effects(delta: float) -> void:
	# Simulasi suara langkah berdasarkan kecepatan
	if abs(velocity.x) > 50.0:
		step_timer += delta * (abs(velocity.x) / max_speed + 0.5)
		if step_timer >= step_interval:
			play_step_sound()
			step_timer = 0.0

func create_collision_effect() -> void:
	# Simulasi efek collision
	shake_intensity = 3.0
	print("Collision effect triggered!")
	# Di sini bisa ditambahkan particle effect atau screen shake

func create_dust_effect() -> void:
	# Simulasi particle debu
	print("Dust particle created at: ", position)
	# Di sini bisa ditambahkan CPUParticles2D atau GPUParticles2D

func play_step_sound() -> void:
	# Simulasi suara langkah
	var pitch_variation = randf_range(0.8, 1.2)
	print("Step sound played with pitch: ", pitch_variation)
	# Di sini bisa ditambahkan AudioStreamPlayer dengan pitch variation

# === Fungsi tambahan untuk interaksi dengan lingkungan ===
func set_ground_type(friction_multiplier: float) -> void:
	"""Ubah jenis tanah (es = 0.3, normal = 1.0, pasir = 1.5)"""
	ground_friction_multiplier = friction_multiplier

func apply_external_force(force: Vector2) -> void:
	"""Tambahkan gaya eksternal (angin, ledakan, dll)"""
	velocity += force

func get_movement_state() -> String:
	"""Return status gerakan untuk debugging atau UI"""
	if abs(velocity.x) < 10.0:
		return "idle"
	elif abs(velocity.x) < max_speed * 0.3:
		return "walking"
	elif abs(velocity.x) < max_speed * 0.7:
		return "running"
	else:
		return "sprinting"

# === Debug info ===
func _draw() -> void:
	if OS.is_debug_build():
		# Tampilkan velocity vector
		draw_line(Vector2.ZERO, velocity * 0.1, Color.RED, 2.0)
		# Tampilkan informasi kecepatan
		var font = ThemeDB.fallback_font
		draw_string(font, Vector2(-50, -60), "Speed: %.0f" % abs(velocity.x), HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
