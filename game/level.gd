class_name Level
extends Node3D

@export var player: Player
@export var player_from_water_power: float = 40

@export_category("tides")

@export var water_node: Node3D

@export var high_tide_y: float = 0.0
@export var low_tide_y: float = -5.0
@export var high_tide_duration: float = 10.0 # Время, сколько вода побудет ВНИЗУ (в отливе)
@export var low_tide_duration: float = 10.0 
@export var transition_duration: float = 2.0
@export var ease_curve: Curve
var timer_multiplier: float = 1.0

@onready var end_game_marker: Marker3D = %EndGameMarker3D
@onready var end_game_resource: SellableResource = %EndGameResource

@onready var start_tides_interaction_area: InteractionArea = %StartTidesInteractionArea

# Наш локальный менеджер звуков
@onready var sfx_handler: SfxHandler = $SfxHandler 

# Внутренние переменные
var _timer: float = 0.0
var _is_high_tide: bool = true
var _transitioning: bool = false
var _transition_timer: float = 0.0
var _start_y: float = 0.0
var _target_y: float = 0.0

# Флаг активности: true только когда вода опускается, стоит внизу или поднимается назад
var _tides_active: bool = false

var drop_resource_timer: float = 0.0
var drop_resource_rate: float = 0.5

# Ссылка на зацикленный плеер звука насоса
var _sucker_loop_player: AudioStreamPlayer3D = null

func _ready() -> void:
	Global.level = self
	
	if water_node == null:
		water_node = get_node_or_null("Water")
		if water_node == null:
			push_warning("Water node not found in Level scene!")
			return
	
	start_tides_interaction_area.interacted.connect(on_player_start_tides_interated)
	
	# Изначально вода стоит на верхнем уровне
	_start_y = water_node.position.y
	_target_y = high_tide_y
	water_node.position.y = high_tide_y
	
	_sucker_loop_player = sfx_handler.get_player("Suck")
	if _sucker_loop_player:
		_sucker_loop_player.volume_db = -80.0 # Полная тишина на старте
		_sucker_loop_player.play()
		
		# Привязываем звук СТРОГО к позиции кнопки/рычага насоса, чтобы он не двигался
		_sucker_loop_player.global_position = $StartTidesButton.global_position


func on_player_start_tides_interated(player: Player) -> void:
	if _tides_active or _transitioning or not _is_high_tide:
		return
	
	$StartTidesButton/CSGCylinder3D.transparency = .5
	
	_tides_active = true
	_start_transition()


func _process(delta: float) -> void:
	if water_node == null:
		return

	# Логика выталкивания игрока из воды
	var gloal_wl = water_node.global_position.y
	if player.global_position.y < gloal_wl:
		player.velocity += Vector3.UP * (gloal_wl - player.global_position.y) * player_from_water_power * delta
		player.velocity = player.velocity.clampf(-40, 40)
		
		player.restore_stamina(delta * 0.1)
		
		if drop_resource_timer > drop_resource_rate:
			drop_resource_timer = 0
			player.drop_resources(1)
	
	drop_resource_timer += delta
	
	# --- ЗВУКОВОЙ ПРОЦЕССОР НАСОСА ---
	_process_sucker_sound(delta)
	# ---------------------------------
	
	if not _tides_active:
		return
		
	if _transitioning:
		_update_transition(delta)
		return
		
	if not _is_high_tide:
		_timer += delta * timer_multiplier
		if _timer >= high_tide_duration:
			print("Время отлива вышло. Вода возвращается обратно наверх...")
			_start_transition()


func _start_transition() -> void:
	_transitioning = true
	_transition_timer = 0.0
	_start_y = water_node.position.y
	
	_is_high_tide = not _is_high_tide
	_target_y = high_tide_y if _is_high_tide else low_tide_y
	
	_timer = 0.0


func _update_transition(delta: float) -> void:
	_transition_timer += delta * timer_multiplier
	
	if _transition_timer >= transition_duration:
		_transitioning = false
		water_node.position.y = _target_y
		
		if _is_high_tide:
			_tides_active = false
			$StartTidesButton/CSGCylinder3D.transparency = 0
			
		return
	
	var progress: float = _transition_timer / transition_duration
	if ease_curve != null:
		progress = ease_curve.sample(progress)
	else:
		progress = ease(progress, -2.0)
	
	var new_y: float = lerp(_start_y, _target_y, progress)
	water_node.position.y = new_y


## Логика плавного изменения громкости неподвижного насоса
func _process_sucker_sound(delta: float) -> void:
	if not _sucker_loop_player:
		return
		
	# Насос должен гудеть на полную (0 dB), пока активна фаза откачки.
	# Когда вода вернулась и механизм отключился, уводим громкость в тишину (-80 dB)
	var target_volume: float = -80.0
	
	if _tides_active:
		target_volume = 0.0 # Отрегулируй это значение, если в игре гудит слишком громко
		
	# Плавное нарастание и затухание гула (без резких щелчков)
	_sucker_loop_player.volume_db = move_toward(_sucker_loop_player.volume_db, target_volume, delta * 35.0)


func get_current_water_level() -> float:
	return water_node.position.y if water_node != null else 0.0

func is_high_tide() -> bool:
	return _is_high_tide and not _transitioning

func is_low_tide() -> bool:
	return not _is_high_tide and not _transitioning

func is_transitioning() -> bool:
	return _transitioning
