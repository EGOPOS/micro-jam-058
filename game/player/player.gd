class_name Player extends CharacterBody3D

@export_group("movement")
@export var movement_speed: float = 10
@export var movement_acceleration: float = 5
@export var movement_friction: float = 3

@export var air_multiplier: float = 0.6
@export_range(0.0, 1.0) var jump_air_bonus: float = 0.25
@export var jump_air_bonus_multiplier: float = 2.0
@export var jump_release_multiplier: float = 0.6

@export var jump_height : float = 2.5
@export var jump_time_to_peak : float = .5
@export var jump_time_to_descent : float = .4
@export var coyote_time: float = 0.25

@export_group("camera")
@export_range(0, 180, 1, "radians_as_degrees") var camera_clamp_angle: float = 90
@export var mouse_sensivity: float = 0.005
@export_subgroup("animations")
@export var camera_animation_speed: float = 3.0
@export var camera_animation_floor_strength: float = 3.0
@export var camera_animation_air_strength: float = 5.0
@export var max_shake_offset: float = 0.25 # Максимальное смещение камеры в метрах при критическом падении
@export var max_shake_duration: float = 0.2 # Максимальное время тряски
@export var max_air_shake_offset: float = 0.5
@export var fov_falling: float = 20.0 # На сколько градусов увеличится FOV при максимальной скорости падения
@export var fov_acceleration: float = 10.0 # На сколько градусов увеличится FOV при максимальной скорости падения

@export_group("climbing")
@export var climb_jump_velocity_multiplier: float = 1.6
@export var max_attach_distance: float = 3
@export var is_right_side_enabled: bool = false
@export var lean_amount: float = 3
@export var lean_speed: float = 1.0

@export_group("resource grabbing")
@export var max_grab_distance: float = 3

@export_group("stamina")
@export var max_stamina: float = 5.0
@export var recover_stamina_delay: float = 0.8
@export var recover_stamina_muliplier: float = 2.5
@export var start_recover_from: float = 0.3


@export_group("overweight affect")
@export var jump_affect_scale: float = 0.8
@export var stamina_affect_scale: float = 0.8

# for wind sound
#@export_group("sounds")
#@export var wind_velocity: float = 3.0
#@export var wind_max_db: float = 0.0
#@export var wind_min_db: float = -29.0

@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak)
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak))
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent))

@onready var backpack_component: BackpackComponent = %BackpackComponent

@onready var camera_pivot: Node3D = %CameraPivot
@onready var camera: Camera3D = %Camera3D
@onready var state_machine: StateMachine = $StateMachine
@onready var health_component: HealthComponent = $HealthComponent
@onready var camera_animation_strength: float = camera_animation_floor_strength

@onready var pickaxe_left: Node3D = %PickaxeLeft
@onready var pickaxe_right: Node3D = %PickaxeRight
@onready var pickaxe_left_marker: Marker3D = %PickaxeLeftMarker3D
@onready var pickaxe_right_marker: Marker3D = %PickaxeRightMarker3D
@onready var pickaxes = [pickaxe_left, pickaxe_right]
@onready var pickaxe_markers = [pickaxe_left_marker, pickaxe_right_marker]

@onready var hud: PlayerHUD = %PlayerHUD

var interaction_delay: float = 0.1
var last_interaction_time: int #ticks

var camera_shake_tween: Tween
var initial_camera_pos: Vector3 = Vector3()
var default_fov: float = 90

var max_jump_buffer: int = 1
var jump_buffer: int = max_jump_buffer

var attached_points: Dictionary = {
	"left": null,
	"right": null
}

@onready var stamina: float = max_stamina
var is_climbing: bool = false

var time_not_climbing: int # ticks

@export var death_fall_velocity: float = -20.0
var last_good_pos: Vector3


var default_jump_height = 0
var default_jump_time_to_peak = 0
var default_jump_time_to_descent = 0
var default_jump_air_bonus = 0
var default_max_stamina = 0
var default_start_recover_from = 0
var default_max_jump_buffer = 0


signal right_attach_toggled(hit)
signal left_attach_toggled(hit)

static var is_blocked: bool = false


#region movement methods
func apply_acceleration(delta: float, direction: Vector3, multiplier: float = 1.0):
	velocity = velocity.lerp(Vector3(direction.x, 0, direction.z)* movement_speed + Vector3.UP * velocity.y, movement_acceleration * delta * multiplier)

func apply_air_acceleration(delta: float, direction: Vector3, multiplier: float = air_multiplier):
	velocity = velocity.lerp(Vector3(direction.x, 0, direction.z)* movement_speed + Vector3.UP * velocity.y, movement_acceleration * delta * multiplier)

func apply_friction(delta: float, multiplier: float = 1.0):
	velocity = velocity.lerp(Vector3(0, velocity.y, 0), movement_friction * delta * multiplier)

func apply_jump_velocity(multiplier: float = 1.0):
	velocity.y += jump_velocity * multiplier

func apply_jump_gravity(delta: float):
	velocity.y += jump_gravity*delta

func apply_fall_gravity(delta: float):
	velocity.y += fall_gravity*delta

func get_free_direction() -> Vector3:
	var input = get_input_direction()
	var cam_basis = camera.global_transform.basis
	var dir = cam_basis.x * input.x + cam_basis.z * input.y
	return dir.normalized()

func get_direction():
	return Vector3(get_input_direction().x, 0, get_input_direction().y).rotated(Vector3.UP, camera.rotation.y)

func get_input_direction():
	if is_blocked: return Vector2()
	return Input.get_vector("movement_left", "movement_right", "movement_forward", "movement_back")

func lerp_camera(delta: float, camera_rotation: Vector3):
	camera_pivot.rotation = camera_pivot.rotation.lerp(camera_rotation.rotated(Vector3.UP, camera.rotation.y), delta * camera_animation_speed)
	
func reset_jump_buffer():
	jump_buffer = max_jump_buffer

func jump(multiplier: float = 1.0):
	jump_buffer -= 1
	apply_jump_velocity(multiplier)

func is_can_jump():
	return jump_buffer > 0

#endregion

func _ready() -> void:
	state_machine.set_additional_props({
		"player": self
	})
	state_machine.change_state(state_machine.states.Idle)
	
	backpack_component.overweight_changed.connect(on_overweight_changed)
	right_attach_toggled.connect(update_picaxe_transform.bind(false))
	left_attach_toggled.connect(update_picaxe_transform.bind(true))
	right_attach_toggled.emit(null)
	left_attach_toggled.emit(null)
	
	last_good_pos = position
	update_defaults()
	
	if camera:
		default_fov = camera.fov
	
	Global.player = self


#region Changing values
func update_defaults():
	default_jump_height = jump_height
	default_jump_time_to_peak = jump_time_to_peak
	default_jump_time_to_descent = jump_time_to_descent
	default_jump_air_bonus = jump_air_bonus
	default_max_stamina = max_stamina
	default_start_recover_from = start_recover_from
	default_max_jump_buffer = max_jump_buffer


func apply_defaults():
	jump_height = default_jump_height
	jump_time_to_peak = default_jump_time_to_peak
	jump_time_to_descent = default_jump_time_to_descent
	jump_air_bonus = default_jump_air_bonus
	max_stamina = default_max_stamina
	start_recover_from = default_start_recover_from
	max_jump_buffer = default_max_jump_buffer
	if is_on_floor():
		reset_jump_buffer()


func update_jump():
	jump_velocity = ((2.0 * jump_height) / jump_time_to_peak)
	jump_gravity = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak))
	fall_gravity = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent))


func on_overweight_changed():
	apply_defaults()
	
	var jmp_mult = pow(jump_affect_scale, backpack_component.get_overweight())
	if jmp_mult > 0.6:
		multiply_jump(jmp_mult)
	else:
		max_jump_buffer = 0
	
	var stm_mult = pow(jump_affect_scale, backpack_component.get_overweight())
	multiply_stamina(stm_mult)

func multiply_jump(jmp_mult: float):
	jump_height *= jmp_mult
	jump_time_to_peak *= jmp_mult
	jump_time_to_descent *= jmp_mult
	jump_air_bonus *= jmp_mult
	update_jump()

func multiply_stamina(stm_mult: float):
	max_stamina *= stm_mult
	start_recover_from *= stm_mult
#endregion


# Храним ссылки на активные твины для каждой кирки, чтобы они не конфликтовали
var pickaxe_tweens: Dictionary = {}

func update_picaxe_transform(hit, is_left: bool):
	var index = int(not is_left)
	var pickaxe: Node3D = pickaxes[index] 
	var packaxe_marker = pickaxe_markers[index] 
	
	var target_position: Vector3
	var target_rotation: Vector3
	
	# Убиваем предыдущий твин для этой кирки, если он ещё работает
	if pickaxe_tweens.has(index) and pickaxe_tweens[index] is Tween:
		pickaxe_tweens[index].kill()
	
	if hit == null:
		# ВОЗВРАТ КИРКИ В РУКИ
		pickaxe.reparent(camera)
		
		# Высчитываем целевую ЛОКАЛЬНУЮ позицию и поворот относительно нового родителя (camera)
		# Если маркер — прямой дочерний элемент камеры, то его local_position — это то, что нам нужно
		var target_local_pos = packaxe_marker.position
		var target_local_rot = packaxe_marker.rotation
		
		# Создаем твин для локальных координат
		var tween = create_tween().set_parallel(true)
		pickaxe_tweens[index] = tween
		
		# Анимируем именно свойства position и rotation, а не global_position
		# Теперь кирка будет "привязана" к движению камеры прямо во время полета!
		tween.tween_property(pickaxe, "position", target_local_pos, 0.2)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(pickaxe, "rotation", target_local_rot, 0.2)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			
	else:
		# УДАР КИРКОЙ В СТЕНУ/РЕСУРС
		var normal = hit.normal
		target_position = hit.position - normal * randf_range(0.15, 0.45)
		
		var up_vector = Vector3.UP
		if abs(normal.dot(Vector3.UP)) > 0.99:
			up_vector = Vector3.FORWARD 
		
		var target_basis = Basis.looking_at(normal, up_vector, true)
		if abs(normal.dot(Vector3.UP)) > 0.99:
			target_basis = target_basis.rotated(Vector3.UP, camera.rotation.y)
		
		target_rotation = target_basis.get_euler()
		
		pickaxe.reparent(%Reparenter)
		
		# Анимация быстрого и резкого удара (Замах -> Удар)
		var tween = create_tween().set_parallel(true)
		pickaxe_tweens[index] = tween
		
		# Длительность 0.1 секунды (очень быстрый удар, вонзающийся в стену)
		tween.tween_property(pickaxe, "global_position", target_position, 0.2)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		# Запоминаем стартовое вращение перед началом твина
		var start_rotation = pickaxe.global_rotation

		# Твиним float-коэффициент от 0.0 до 1.0
		tween.tween_method(
			func(weight: float):
				pickaxe.global_rotation.x = lerp_angle(start_rotation.x, target_rotation.x, weight)
				pickaxe.global_rotation.y = lerp_angle(start_rotation.y, target_rotation.y, weight)
				pickaxe.global_rotation.z = lerp_angle(start_rotation.z, target_rotation.z, weight),
			0.0, 1.0, 0.2
		).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			
		# Опционально: делаем легкий "отскок" или микро-тряску при ударе
		# Для этого параллельно можно вызвать метод тряски или пустить партиклы

func _process(delta: float) -> void:
	lerp_camera(delta, Vector3(get_input_direction().y, 0.0, get_input_direction().x) * deg_to_rad(camera_animation_strength))
	pickaxe_right.visible = is_right_side_enabled

var was_on_floor: bool = false
var last_velocity_y: float = 0.0

func _physics_process(delta: float) -> void:
	# Проверка приземления
	if is_on_floor() and not was_on_floor:
		if last_velocity_y < -5.0: 
			if last_velocity_y < death_fall_velocity:
				fall_return()
			else:
				trigger_fall_shake(last_velocity_y)

	if not is_on_floor() and velocity.y < -5.0:
		# Считаем интенсивность от 0.0 до 1.0 на основе текущей (!) скорости
		var intensity = remap(velocity.y, -5.0, death_fall_velocity, 0.0, 1.0)
		intensity = clamp(intensity, 0.0, 1.0)
		
		if intensity > 0.0:
			# Вычисляем случайное смещение на этот кадр
			var current_power = max_air_shake_offset * intensity
			var random_offset = Vector3(
				randf_range(-current_power, current_power),
				randf_range(-current_power, current_power),
				randf_range(-current_power * 0.5, current_power * 0.5)
			)
			# Применяем тряску (плавно интерполируем от текущей позиции к целевой, чтобы не было микро-телепортов)
			var target_pos = initial_camera_pos + random_offset
			camera.position = camera.position.lerp(target_pos, delta * 30.0)
			
			# Динамически увеличиваем FOV в зависимости от скорости падения
			#var target_fov = default_fov + (fov_falling * intensity)
			#camera.fov = lerp(camera.fov, target_fov, delta * 10.0)
	
	# 2. Если игрок на земле или летит вверх (прыгает) — плавно возвращаем камеру на место
	else:
		if camera.position != initial_camera_pos:
			camera.position = camera.position.lerp(initial_camera_pos, delta * 15.0)
			# Маленькая оптимизация: если почти вернулись в ноль, ставим точный ноль
			if camera.position.distance_to(initial_camera_pos) < 0.001:
				camera.position = initial_camera_pos
		
	# Плавно возвращаем FOV к исходному значению
	#if camera.fov != default_fov:
	var intensity = remap(velocity.length(), movement_speed, movement_speed * 3, 0.0, 1.0)
	intensity = clamp(intensity, 0.0, 1.0)
	var target_fov = default_fov + (fov_acceleration * intensity)
	camera.fov = lerp(camera.fov, target_fov, delta * movement_speed)
	
	if target_fov == default_fov and abs(camera.fov - default_fov) < 0.01:
		camera.fov = default_fov
	
	last_velocity_y = velocity.y
	was_on_floor = is_on_floor()

func trigger_fall_shake(fall_velocity: float) -> void:
	if not camera: return
	
	# 1. Считаем интенсивность падения от 0.0 (едва заметно) до 1.0 (на грани смерти)
	# Используем remap, чтобы перевести скорость из диапазона [от -5.0 до death_fall_velocity] в [0.0 - 1.0]
	var intensity = remap(fall_velocity, -5.0, death_fall_velocity, 0.0, 1.0)
	intensity = clamp(intensity, 0.0, 1.0)
	
	# Вычисляем силу и время тряски для этого конкретного падения
	var shake_power = max_shake_offset * intensity
	var shake_time = max_shake_duration * intensity
	
	# Сбрасываем старый твин тряски, если игрок умудрился упасть дважды
	if camera_shake_tween and camera_shake_tween.is_valid():
		camera_shake_tween.kill()
		
	camera_shake_tween = create_tween()
	
	# Сколько раз камера дернется за время тряски (частота)
	var shake_steps = 6
	var step_duration = shake_time / shake_steps
	
	# 2. Создаем цепочку случайных смещений, которая затухает к концу
	for i in range(shake_steps):
		# С каждым шагом уменьшаем силу тряски (затухание)
		var current_power = shake_power * (float(shake_steps - i) / shake_steps)
		
		# Генерируем случайное смещение по осям X и Y (и немного Z по желанию)
		var random_offset = Vector3(
			randf_range(-current_power, current_power),
			randf_range(-current_power, current_power),
			randf_range(-current_power * 0.5, current_power * 0.5)
		)
		
		# Прибавляем к стартовой позиции камеры, чтобы она не улетала в космос
		var target_pos = initial_camera_pos + random_offset
		
		camera_shake_tween.tween_property(camera, "position", target_pos, step_duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
	# 3. В самом конце возвращаем камеру строго в исходное положение
	camera_shake_tween.tween_property(camera, "position", initial_camera_pos, step_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _input(event: InputEvent):
	if is_blocked:
		return
	
	if event is InputEventMouseMotion:
		camera.rotation.x = clamp(camera.rotation.x + -event.relative.y * mouse_sensivity, -camera_clamp_angle, camera_clamp_angle)
		camera.rotation.y += -event.relative.x * mouse_sensivity
	
	if Input.is_action_just_pressed("ui_cancel"):
		DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE if DisplayServer.mouse_get_mode() == DisplayServer.MOUSE_MODE_CAPTURED else DisplayServer.MOUSE_MODE_CAPTURED)

	#if Input.is_key_pressed(KEY_R):
		#fall_return()


#region Climbing
func apply_climb_attaching(delta: float, target_velocity: Vector3, multiplier: float):
	velocity = velocity.lerp(target_velocity, delta * multiplier)

func is_attaching():
	return (Input.is_action_pressed("mouse_left") and attached_points.left == null) or (Input.is_action_pressed("mouse_right") and attached_points.right == null and is_right_side_enabled)

func is_left_unattaching():
	return not Input.is_action_pressed("mouse_left") and attached_points.left != null

func is_right_unattaching():
	return not Input.is_action_pressed("mouse_right") and attached_points.right != null

func get_attaching_side():
	return "left" if (Input.is_action_pressed("mouse_left") and attached_points.left == null) else "right" if (Input.is_action_pressed("mouse_right") and attached_points.right == null) else ""

func get_attached_positions():
	return attached_points.values().filter(func(a): return a != null).map(func(a): return a.position)

func spend_stamina(value: float):
	stamina -= value
	stamina = max(0, stamina)

func restore_stamina(value: float):
	if stamina == 0:
		stamina += start_recover_from + value
	stamina += value
	stamina = min(stamina, max_stamina)

func is_can_climb():
	return stamina > 0
#endregion

func fall_return():
	drop_resources()
	Fade.fade_out(.3)
	
	await get_tree().create_timer(.15).timeout
	create_tween().tween_method(func(a):
			global_position = last_good_pos,
		0, 100, .15)
	await get_tree().create_timer(.15).timeout
	
	Fade.fade_in(.3)

func drop_resources(count: int = -1):
	var drop_center = global_position
	var item = backpack_component.take_from_storage()
	var space_state = get_world_3d().direct_space_state
	
	while item != null and (count > 0 or count == -1):
		if item.get_parent() == null:
			get_parent().add_child(item)
			
		item.show()
		
		var random_radius = randf_range(0.5, 2.0)
		var random_angle = randf_range(0.0, TAU)
		
		var offset = Vector3(
			cos(random_angle) * random_radius,
			0.0,
			sin(random_angle) * random_radius
		)
		
		var target_horizontal_pos = drop_center + offset
		var ray_start = target_horizontal_pos + Vector3(0.0, 2.0, 0.0)
		var ray_end = target_horizontal_pos + Vector3(0.0, -100.0, 0.0)
		
		var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
		query.exclude = [get_rid(), item.get_rid()] 
		
		var result = space_state.intersect_ray(query)
		
		if result.has("position"):
			item.global_position = drop_center
			var time = ray_start.distance_to(ray_end)/100
			create_tween().tween_property(item, "global_position", result.position, time)
			
			var floor_normal = result.normal
			if floor_normal.dot(Vector3.UP) < 0.99:
				var axis = Vector3.UP.cross(floor_normal).normalized()
				var angle = Vector3.UP.angle_to(floor_normal)
				if axis.length() > 0.001:
					item.global_rotation = Vector3.ZERO
					item.rotate(axis, angle)
		else:
			item.global_position = target_horizontal_pos
			item.queue_free()
		
		item.rotate_object_local(Vector3.UP, randf_range(0.0, TAU))
		item = backpack_component.take_from_storage()
		if count != -1:
			count -= 1
