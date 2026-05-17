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
@export var camera_animation_jetpack_strength: float = 15.0

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

var interaction_delay: float = 0.1
var last_interaction_time: int #ticks

var max_jump_buffer: int = 1
var jump_buffer: int = max_jump_buffer

var attached_points: Dictionary = {
	"left": null,
	"right": null
}

@onready var stamina: float = max_stamina
var is_climbing: bool = false

var time_not_climbing: int # ticks

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

#func _physics_process(delta: float) -> void:
	# for wind sound
	#if abs(velocity.y) >= wind_velocity:
		#if not wind_player.playing:
			#wind_player.play()
		#wind_player.volume_db = min(abs(velocity.y) + wind_min_db, wind_max_db)
	#else:
		#wind_player.volume_db = lerp(wind_player.volume_db, wind_min_db, delta * 6.0)
		#if round(wind_player.volume_db) == wind_min_db:
			#wind_player.playing = false


func _input(event: InputEvent):
	if is_blocked:
		return
	
	if event is InputEventMouseMotion:
		camera.rotation.x = clamp(camera.rotation.x + -event.relative.y * mouse_sensivity, -camera_clamp_angle, camera_clamp_angle)
		camera.rotation.y += -event.relative.x * mouse_sensivity
	
	if Input.is_action_just_pressed("ui_cancel"):
		DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE if DisplayServer.mouse_get_mode() == DisplayServer.MOUSE_MODE_CAPTURED else DisplayServer.MOUSE_MODE_CAPTURED)

	if Input.is_key_pressed(KEY_R):
		fall_return()



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
	Fade.fade_out(.3)
	await get_tree().create_timer(.3).timeout
	Fade.fade_in(.3)
	position = last_good_pos


func _on_pos_save_timer_timeout() -> void:
	if is_on_floor():
		last_good_pos = position
