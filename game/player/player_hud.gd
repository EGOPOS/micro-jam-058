class_name PlayerHUD extends CanvasLayer

@onready var vignette: ColorRect = %Vignette
@onready var crosshair: ColorRect = %Crosshair
@onready var stamina_bar: ProgressBar = %StaminaBar
@onready var left_pickaxe_dot: Node3D = %PickaxeDot
@onready var right_pickaxe_dot: Node3D = %PickaxeDot2
@onready var dots = [left_pickaxe_dot, right_pickaxe_dot]

@onready var radar_container: TextureRect = %RadarContainer
@onready var blink_shader_rect: ColorRect = %BlinkShaderRect
@onready var tide_bar: ProgressBar = %TideBar

var radar_mat: ShaderMaterial
var target_resource: SellableResource

var player: Player
var backpack_comp: Node

# --- ПЕРЕМЕННЫЕ ДЛЯ ЗВУКА РАДАРА ---
## Таймер для отсчёта времени между пиками радара
var _radar_sound_timer: float = 0.0
# -----------------------------------

func _ready() -> void:
	await get_tree().process_frame
	player = Global.player
	
	if player:
		backpack_comp = player.backpack_component
		backpack_comp.overweight_changed.connect(_on_overweight_changed)
		_on_overweight_changed()
		
	radar_mat = blink_shader_rect.material as ShaderMaterial
	target_resource = get_tree().get_first_node_in_group("endgame")
	radar_container.hide()

func _process(delta: float) -> void:
	if player:
		stamina_bar.max_value = player.max_stamina
		stamina_bar.value = player.stamina
		update_dots()
		
		tide_bar.max_value = Global.level.tide_duration
		tide_bar.value = Global.level._timer
		tide_bar.visible = not Global.level._is_high_tide and Global.level.timer_multiplier != 0
	
	if radar_container.visible:
		var distance = target_resource.global_position.distance_to(player.global_position)
		var max_speed: float = 10
		var speed = remap(distance, 0.0, 100.0, 0.0, max_speed)
		speed = clamp(speed, 0, max_speed)
		
		# Рассчитываем частоту для шейдера
		var pulse_frequency = max(1, max_speed - speed)
		blink_shader_rect.target_speed = pulse_frequency
		
		# --- ЛОГИКА ЗВУКА РАДАРА ---
		# Переводим частоту в интервал времени (задержку) между пиками.
		# Чем больше pulse_frequency (ближе к цели), тем меньше задержка.
		var sound_delay: float = 1.0 / (pulse_frequency * 0.5) 
		
		_radar_sound_timer += delta
		if _radar_sound_timer >= sound_delay:
			_radar_sound_timer = 0.0
			player.sfx_handler.play("Radar")
		# ---------------------------
	else:
		# Если радар выключили, сбрасываем таймер, чтобы при включении он пикнул сразу
		_radar_sound_timer = 0.0


func update_dots() -> void:
	for dot_indx in dots.size():
		var dot = dots[dot_indx]
		var hit  = player.attached_points.values()[dot_indx]
		if hit == null:
			hit = Help.get_camera_center_hit()
		
		dot.visible = not hit.is_empty()
		right_pickaxe_dot.visible = player.is_right_side_enabled and not hit.is_empty()
		if not hit.is_empty():
			var camera: Camera3D = get_viewport().get_camera_3d()
			var normal = hit.normal
			var target_position = hit.position + normal * 0.1
			
			var up_vector = Vector3.UP
			if abs(normal.dot(Vector3.UP)) > 0.99:
				up_vector = Vector3.FORWARD 
			
			var target_basis = Basis.looking_at(normal, up_vector, true)
			if abs(normal.dot(Vector3.UP)) > 0.99:
				target_basis = target_basis.rotated(Vector3.UP, camera.rotation.y)
			
			var target_rotation = target_basis.get_euler()
			
			dot.global_position = target_position
			dot.global_rotation = target_rotation


func _on_overweight_changed() -> void:
	if backpack_comp:
		if backpack_comp.has_method("get_overweight"):
			var overweight: float = backpack_comp.get_overweight()
			var intensity: float = remap(overweight, 0, 4, 0.0, .4)
			var mat: ShaderMaterial = vignette.material as ShaderMaterial
			if mat:
				var current = mat.get_shader_parameter("fadeAmount")
				var target = intensity
				create_tween().tween_method(func(value):
					mat.set_shader_parameter("fadeAmount", value)
				, current, target, 0.5).set_ease(Tween.EASE_IN_OUT)
