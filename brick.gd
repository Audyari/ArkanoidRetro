extends Sprite2D

# === Physics Constants ===
var velocity := Vector2(300.0, -200.0)      # Kecepatan awal (pixel/detik)
var gravity := 980.0                        # Gravitasi (pixel/detik²)
var bounce_damping := 0.85                  # Kehilangan energi saat bounce (0-1)
var air_resistance := 0.98                  # Hambatan udara per frame
var min_bounce_velocity := 50.0             # Kecepatan minimum untuk bounce
var rolling_friction := 0.95                # Friksi saat menggelinding

# === Boundaries ===
var left_bound := 0.0
var right_bound := 800.0
var top_bound := 0.0
var bottom_bound := 600.0
var ball_radius := 32.0                     # Radius bola (sesuaikan dengan sprite)

# === Spin and Rotation ===
var angular_velocity := 0.0                 # Kecepatan rotasi (radian/detik)
var spin_factor := 0.01                     # Seberapa besar pengaruh spin
var magnus_effect := 50.0                   # Efek Magnus (spin mempengaruhi trajectory)

# === Visual Effects ===
var base_scale := Vector2.ONE
var squash_factor := 0.15                   # Seberapa besar deformasi
var trail_positions := []                   # Array untuk trail effect
var max_trail_length := 10
var impact_scale_timer := 0.0

# === Sound and Particles ===
var bounce_sound_timer := 0.0
var last_bounce_velocity := 0.0

# === Ground Detection ===
var is_rolling := false
var ground_level := 568.0                   # Y position lantai (600 - radius)

func _ready():
	base_scale = scale
	# Set posisi awal
	position = Vector2(100, 100)

func _process(delta: float) -> void:
	apply_physics(delta)
	handle_collisions(delta)
	update_visual_effects(delta)
	update_trail_effect()
	check_rolling_state()

func apply_physics(delta: float) -> void:
	# === Gravitasi ===
	if not is_rolling:
		velocity.y += gravity * delta
	
	# === Air Resistance ===
	velocity *= air_resistance
	
	# === Magnus Effect (spin mempengaruhi lintasan) ===
	if abs(angular_velocity) > 0.1:
		var magnus_force = Vector2(-angular_velocity * magnus_effect, 0).rotated(velocity.angle() + PI/2)
		velocity += magnus_force * delta
	
	# === Rolling Friction ===
	if is_rolling:
		velocity.x *= rolling_friction
		angular_velocity *= 0.95
	
	# === Update posisi ===
	position += velocity * delta
	
	# === Update rotasi berdasarkan gerakan ===
	if not is_rolling:
		# Rotasi natural saat di udara
		angular_velocity += (velocity.x / ball_radius) * 0.1 * delta
	else:
		# Rotasi sesuai kecepatan rolling
		angular_velocity = velocity.x / ball_radius
	
	rotation += angular_velocity * delta

func handle_collisions(delta: float) -> void:
	var collision_occurred = false
	var bounce_velocity_magnitude = velocity.length()
	
	# === Collision dengan dinding kiri dan kanan ===
	if position.x - ball_radius <= left_bound:
		position.x = left_bound + ball_radius
		velocity.x = abs(velocity.x) * bounce_damping
		angular_velocity *= -bounce_damping  # Reverse spin
		collision_occurred = true
	elif position.x + ball_radius >= right_bound:
		position.x = right_bound - ball_radius
		velocity.x = -abs(velocity.x) * bounce_damping
		angular_velocity *= -bounce_damping
		collision_occurred = true
	
	# === Collision dengan langit-langit ===
	if position.y - ball_radius <= top_bound:
		position.y = top_bound + ball_radius
		velocity.y = abs(velocity.y) * bounce_damping
		add_random_spin()
		collision_occurred = true
	
	# === Collision dengan lantai ===
	if position.y + ball_radius >= bottom_bound:
		position.y = bottom_bound - ball_radius
		
		# Cek apakah bounce atau mulai rolling
		if abs(velocity.y) > min_bounce_velocity:
			velocity.y = -abs(velocity.y) * bounce_damping
			# Tambah spin berdasarkan kecepatan horizontal
			angular_velocity += velocity.x * 0.001
			collision_occurred = true
		else:
			# Mulai rolling
			velocity.y = 0
			is_rolling = true
	else:
		is_rolling = false
	
	# === Efek bounce ===
	if collision_occurred:
		create_bounce_effect(bounce_velocity_magnitude)
		last_bounce_velocity = bounce_velocity_magnitude

func update_visual_effects(delta: float) -> void:
	# === Squash and Stretch berdasarkan kecepatan ===
	var speed_ratio = velocity.length() / 500.0  # 500 = kecepatan referensi
	speed_ratio = min(speed_ratio, 1.0)
	
	# Stretch ke arah gerakan
	var velocity_normalized = velocity.normalized()
	var stretch_x = 1.0 + (speed_ratio * squash_factor * abs(velocity_normalized.x))
	var stretch_y = 1.0 + (speed_ratio * squash_factor * abs(velocity_normalized.y))
	
	# Squash saat impact
	if impact_scale_timer > 0:
		stretch_y *= (1.0 - impact_scale_timer * 0.3)
		stretch_x *= (1.0 + impact_scale_timer * 0.2)
		impact_scale_timer -= delta * 5.0
		impact_scale_timer = max(0, impact_scale_timer)
	
	scale = base_scale * Vector2(stretch_x, stretch_y)
	
	# === Shadow effect (simulasi) ===
	if position.y < ground_level:
		var shadow_alpha = 1.0 - ((ground_level - position.y) / 300.0)
		shadow_alpha = clamp(shadow_alpha, 0.3, 1.0)
		modulate.a = shadow_alpha

func update_trail_effect() -> void:
	# Tambah posisi saat ini ke trail
	trail_positions.push_front(position)
	
	# Batasi panjang trail
	if trail_positions.size() > max_trail_length:
		trail_positions.pop_back()

func check_rolling_state() -> void:
	# Cek apakah bola sedang menggelinding
	if position.y + ball_radius >= ground_level - 5 and abs(velocity.y) < 10:
		is_rolling = true
		# Pastikan bola tepat di lantai
		position.y = ground_level
	else:
		is_rolling = false

func create_bounce_effect(impact_velocity: float) -> void:
	# Visual impact effect
	impact_scale_timer = 1.0
	
	# Screen shake berdasarkan kekuatan impact
	var shake_strength = min(impact_velocity / 300.0, 1.0)
	apply_screen_shake(shake_strength)
	
	# Particle effect simulation
	create_impact_particles(impact_velocity)
	
	# Sound effect
	play_bounce_sound(impact_velocity)

func apply_screen_shake(strength: float) -> void:
	# Simulasi screen shake
	print("Screen shake with strength: %.2f" % strength)
	# Di sini bisa ditambahkan actual screen shake

func create_impact_particles(velocity_magnitude: float) -> void:
	# Simulasi particle effects
	var particle_count = int(velocity_magnitude / 50.0)
	print("Creating %d impact particles" % particle_count)
	# Di sini bisa ditambahkan CPUParticles2D

func play_bounce_sound(velocity_magnitude: float) -> void:
	# Sound dengan pitch berdasarkan kekuatan impact
	var pitch = 0.8 + (velocity_magnitude / 500.0) * 0.4
	pitch = clamp(pitch, 0.8, 1.2)
	print("Bounce sound with pitch: %.2f" % pitch)
	# Di sini bisa ditambahkan AudioStreamPlayer

func add_random_spin() -> void:
	# Tambah spin random saat collision
	angular_velocity += randf_range(-5.0, 5.0)

# === Event collision dengan paddle/area ===
func on_area_2d_area_entered(area: Area2D) -> void:
	print("Ball hit paddle!")
	
	# Reverse Y velocity dengan sedikit randomness
	velocity.y = -abs(velocity.y) * randf_range(0.9, 1.1)
	
	# Tambah spin berdasarkan posisi hit
	var hit_offset = position.x - area.global_position.x
	angular_velocity += hit_offset * 0.05
	
	# Tambah sedikit kecepatan horizontal berdasarkan spin
	velocity.x += angular_velocity * 10.0
	
	# Efek visual
	create_bounce_effect(velocity.length())

# === Fungsi utilitas ===
func apply_force(force: Vector2) -> void:
	"""Tambahkan gaya eksternal ke bola"""
	velocity += force

func set_spin(spin: float) -> void:
	"""Set spin bola secara manual"""
	angular_velocity = spin

func reset_ball(new_position: Vector2, new_velocity: Vector2) -> void:
	"""Reset posisi dan kecepatan bola"""
	position = new_position
	velocity = new_velocity
	angular_velocity = 0.0
	is_rolling = false
	trail_positions.clear()

func get_physics_info() -> Dictionary:
	"""Return informasi physics untuk debugging"""
	return {
		"velocity": velocity,
		"speed": velocity.length(),
		"angular_velocity": angular_velocity,
		"is_rolling": is_rolling,
		"kinetic_energy": velocity.length_squared() * 0.5
	}

# === Draw trail dan debug info ===
func _draw() -> void:
	if OS.is_debug_build():
		# Draw velocity vector
		draw_line(Vector2.ZERO, velocity * 0.1, Color.CYAN, 3.0)
		
		# Draw trail
		if trail_positions.size() > 1:
			for i in range(trail_positions.size() - 1):
				var alpha = 1.0 - (float(i) / trail_positions.size())
				var trail_color = Color.WHITE
				trail_color.a = alpha * 0.5
				var start = trail_positions[i] - position
				var end = trail_positions[i + 1] - position
				draw_line(start, end, trail_color, 2.0)
		
		# Debug text
		var font = ThemeDB.fallback_font
		var info_text = "Speed: %.0f | Spin: %.1f | Rolling: %s" % [
			velocity.length(), 
			angular_velocity, 
			"Yes" if is_rolling else "No"
		]
		draw_string(font, Vector2(-80, -50), info_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
