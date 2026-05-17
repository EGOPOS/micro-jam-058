class_name Level
extends Node3D

@export var player: Player
@export var player_from_water_power: float = 40

@export_category("tides")

@export var water_node: Node3D

@export var high_tide_y: float = 0.0
@export var low_tide_y: float = -5.0
@export var high_tide_duration: float = 10.0 # Время, сколько вода побудет ВНИЗУ (в отливе)
@export var low_tide_duration: float = 10.0 # Этот экспорт теперь не используется для автоматического спуска
@export var transition_duration: float = 2.0
@export var ease_curve: Curve

@onready var end_game_marker: Marker3D = %EndGameMarker3D
@onready var end_game_resource: SellableResource = %EndGameResource

@onready var start_tides_interaction_area: InteractionArea = %StartTidesInteractionArea

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


func on_player_start_tides_interated(player: Player) -> void:
	# Если вода УЖЕ уходит, приливает или стоит внизу — кнопку нажимать нельзя
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
	
	# Если цикл не запущен игроком — ничего с движением воды не делаем
	if not _tides_active:
		return
		
	# Если вода сейчас движется (вверх или вниз)
	if _transitioning:
		_update_transition(delta)
		return
		
	# Если движение завершилось, мы проверяем таймер нахождения ВНИЗУ
	# Вода автоматически начнет подниматься только если она сейчас в состоянии отлива (низко)
	if not _is_high_tide:
		_timer += delta
		if _timer >= high_tide_duration:
			print("Время отлива вышло. Вода возвращается обратно наверх...")
			_start_transition()


func _start_transition() -> void:
	_transitioning = true
	_transition_timer = 0.0
	_start_y = water_node.position.y
	
	# Меняем состояние
	_is_high_tide = not _is_high_tide
	_target_y = high_tide_y if _is_high_tide else low_tide_y
	
	_timer = 0.0


func _update_transition(delta: float) -> void:
	_transition_timer += delta
	
	if _transition_timer >= transition_duration:
		_transitioning = false
		water_node.position.y = _target_y
		
		# ФИКС: Если вода вернулась НАВЕРХ (высокий прилив), глушим цикл до следующего нажатия
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


func get_current_water_level() -> float:
	return water_node.position.y if water_node != null else 0.0

func is_high_tide() -> bool:
	return _is_high_tide and not _transitioning

func is_low_tide() -> bool:
	return not _is_high_tide and not _transitioning

func is_transitioning() -> bool:
	return _transitioning
