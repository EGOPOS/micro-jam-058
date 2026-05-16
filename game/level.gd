class_name Level
extends Node3D

## Узел с водой (плейн), который будет подниматься и опускаться
@export var water_node: Node3D

## Высота воды при приливе (нормальное состояние у поверхности)
@export var high_tide_y: float = 0.0

## Высота воды при отливе (низкое состояние)
@export var low_tide_y: float = -5.0

## Длительность цикла прилива (в секундах)
@export var high_tide_duration: float = 10.0

## Длительность цикла отлива (в секундах)
@export var low_tide_duration: float = 10.0

## Длительность перехода между приливом и отливом (в секундах)
@export var transition_duration: float = 2.0

## Кривая для плавного перехода между уровнями воды
@export var ease_curve: Curve

# Внутренние переменные
var _timer: float = 0.0
var _is_high_tide: bool = true
var _transitioning: bool = false
var _transition_timer: float = 0.0
var _start_y: float = 0.0
var _target_y: float = 0.0


func _ready() -> void:
	# Если узел воды не назначен, пытаемся найти его в сцене
	if water_node == null:
		water_node = get_node_or_null("Water")
		if water_node == null:
			push_warning("Water node not found in Level scene!")
			return
	
	# Инициализируем положение воды на уровне прилива
	_start_y = water_node.position.y
	_target_y = high_tide_y
	water_node.position.y = high_tide_y


func _process(delta: float) -> void:
	if water_node == null:
		return
	
	_timer += delta
	
	# Если находимся в переходе между приливом и отливом
	if _transitioning:
		_update_transition(delta)
		return
	
	# Проверяем, нужно ли начать переход
	var current_duration: float = high_tide_duration if _is_high_tide else low_tide_duration
	
	if _timer >= current_duration:
		_start_transition()


func _start_transition() -> void:
	_transitioning = true
	_transition_timer = 0.0
	_start_y = water_node.position.y
	
	# Меняем состояние
	_is_high_tide = not _is_high_tide
	_target_y = high_tide_y if _is_high_tide else low_tide_y
	
	# Обнуляем основной таймер
	_timer = 0.0


func _update_transition(delta: float) -> void:
	#create_tween().tween_property(water_node, "position:y", _target_y, transition_duration)
	_transition_timer += delta
	
	if _transition_timer >= transition_duration:
		# Переход завершен
		_transitioning = false
		water_node.position.y = _target_y
		return
	
	# Расчитываем прогресс перехода (от 0 до 1)
	var progress: float = _transition_timer / transition_duration
	
	# Применяем кривую сглаживания, если она назначена
	if ease_curve != null:
		progress = ease_curve.sample(progress)
	else:
		# По умолчанию используем плавный переход
		progress = ease(progress, -2.0)  # ease-in-out
	
	# Интерполируем высоту воды
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
