extends Node

var cash: int = 0:
	set(value):
		cash = value
		cash_changed.emit()

var shop_products: Dictionary = {
	"second_pickaxe": {"name": "Second pickaxe", "price": 100, "callback": second_pickaxe_callback},
	"stamine_increase": {"name": "Increase Stamina", "price": 50, "callback": increase_stamina_callback, "level": 0},
	"weight_increase": {"name": "Increase max weight", "price": 50, "callback": increase_weight_capacity_callback, "level": 0},
	"deep_increase": {"name": "Increase tides depth", "price": 30, "callback": increase_tides_deep_callback, "level": 0},
	"duration_increase": {"name": "Increase tides duration", "price": 20, "callback": increase_tides_duration_callback, "level": 0},
	"climbing_speed": {"name": "Climbing speed", "price": 200, "callback": increase_climbing_speed_callback, "level": 0},
	"radar": {"name": "Target radar", "price": 5000, "callback": radar_callback},
}
var default_shop_products = shop_products.duplicate(true)
var shop_interface: Control

var player: Player:
	set(value):
		player = value
		default_max_stamina = player.max_stamina
		default_climbing_speed = player.lean_speed # Или movement_speed, в зависимости от того, какой параметр у тебя отвечает за вертикальный подъем
		# Если у BackpackComponent есть изначальный лимит веса, сохраняем его здесь:
		if player.backpack_component:
			default_max_weight = player.backpack_component.payload

var level: Level:
	set(value):
		level = value
		default_duration = level.tide_duration
		default_deep = abs(level.low_tide_y)

var default_duration: float
var default_deep: float
var default_max_stamina: float
var default_climbing_speed: float  # Новая переменная
var default_max_weight: float      # Новая переменная

signal cash_changed
signal endgame_founded
signal comics_readed

func _ready() -> void:
	endgame_founded.connect(_on_endgame_founded)
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
	
	comics_readed.connect(func():
		AmbientPlayer.play_ambient(preload("uid://cmh88cprg8o0k"))
		AmbientPlayer.play_music(preload("uid://t8oqsfwkyu20"), Vector3(0, 3, 0), 80)
	)


func _on_endgame_founded():
	#player.is_blocked = true
	player.hud.radar_container.hide()
	
	level.low_tide_y -= 500
	level.transition_duration = 5
	
	#if level._is_high_tide or (level._transitioning and level._target_y == level.high_tide_y):
	# Принудительно включаем режим отлива
	level._is_high_tide = false
	level._target_y = level.low_tide_y
	
	# Запускаем переход заново из текущей точки, где бы ни находилась вода
	level._transitioning = true
	level._transition_timer = 0.0
	level._start_y = level.water_node.position.y
	level._timer = 0.0
	
	await get_tree().create_timer(level.transition_duration).timeout
	level.timer_multiplier = 0.0



func second_pickaxe_callback():
	player.is_right_side_enabled = true
	shop_products.erase("second_pickaxe")


func increase_stamina_callback():
	# 1. Задаем шаг увеличения выносливости (например, +2.0 секунды/единицы к максимальной)
	const increase_value = 2.0
	
	# 2. Повышаем уровень этого улучшения в словаре shop_products
	next_lvl("stamine_increase")
	
	# 3. Пересчитываем цену для следующей покупки (базовая цена * 2 в степени текущего уровня)
	shop_products.stamine_increase.price = default_shop_products.stamine_increase.price * get_mult("stamine_increase", 2)
	
	# 4. Обновляем имя товара в интерфейсе, чтобы игрок видел, сколько выносливости будет на следующем уровне
	shop_products.stamine_increase.name = "Stamina: " + str(default_max_stamina + increase_value * (get_lvl("stamine_increase") + 1))
	
	# 5. Применяем улучшение к игроку
	player.max_stamina += increase_value
	player.default_max_stamina += increase_value # Обновляем дефолтное значение, чтобы overweight-система не сбрасывала прогресс
	player.restore_stamina(increase_value)       # Сразу восполняем игроку купленную выносливость
	
	# 6. Опционально: ветка ограничителя (максимальный уровень прокачки)
	# Если уровень прокачки дошел, например, до 5, удаляем товар из магазина
	if get_lvl("stamine_increase") >= 5:
		shop_products.erase("stamine_increase")


func increase_climbing_speed_callback():
	# 1. Шаг увеличения скорости карабканья (например, +0.5 к скорости наклона/перемещения)
	const increase_value = 0.5
	
	# 2. Повышаем уровень улучшения
	next_lvl("climbing_speed")
	
	# 3. Рассчитываем новую цену (умножаем базовую на 3 в степени уровня)
	shop_products.climbing_speed.price = default_shop_products.climbing_speed.price * get_mult("climbing_speed", 3)
	
	# 4. Обновляем имя для вывода в интерфейс магазина
	shop_products.climbing_speed.name = "Climb Speed: " + str(default_climbing_speed + increase_value * (get_lvl("climbing_speed") + 1))
	
	# 5. Применяем улучшение к игроку
	# ПРИМЕЧАНИЕ: Если за скорость карабканья отвечает другой параметр (например, отдельная переменная в стейт-машине), замени player.lean_speed на неё.
	player.lean_speed += increase_value
	default_climbing_speed += increase_value
	
	# 6. Ограничение прокачки (максимум 5 уровней)
	if get_lvl("climbing_speed") >= 5:
		shop_products.erase("climbing_speed")


func increase_weight_capacity_callback():
	# 1. Шаг увеличения грузоподъемности (например, увеличиваем максимальный вес на 10 единиц)
	const increase_value = 2.0
	
	# 2. Повышаем уровень улучшения
	next_lvl("weight_increase")
	
	# 3. Рассчитываем новую цену (множитель цены x2 за уровень)
	shop_products.weight_increase.price = default_shop_products.weight_increase.price * get_mult("weight_increase", 2)
	
	# 4. Обновляем имя в интерфейсе
	shop_products.weight_increase.name = "Max weight: " + str(default_max_weight + increase_value * (get_lvl("weight_increase") + 1))
	
	# 5. Применяем изменения к компоненту рюкзака игрока
	if player.backpack_component:
		player.backpack_component.payload += increase_value
		default_max_weight += increase_value
		
		# Принудительно обновляем перегруз, чтобы пересчитать новые штрафы к прыжку и выносливости
		player.on_overweight_changed()
	
	# 6. Ограничение прокачки (максимум 5 уровней)
	if get_lvl("weight_increase") >= 5:
		shop_products.erase("weight_increase")


func increase_tides_deep_callback():
	const increase_value = 50
	next_lvl("deep_increase")
	shop_products.deep_increase.price = default_shop_products.deep_increase.price * pow(2, shop_products.deep_increase.level)
	shop_products.deep_increase.name = "Tides depth: " + str(default_deep + increase_value * (get_lvl("deep_increase") + 1)) + "m"
	
	level.low_tide_y -= increase_value
	
	if not level._is_high_tide and not level.is_transitioning():
		level._timer += 9999
	
	if level.low_tide_y <= -320:
		shop_products.erase("deep_increase")


func increase_tides_duration_callback():
	const increase_value = 15
	next_lvl("duration_increase")
	
	shop_products.duration_increase.price = default_shop_products.duration_increase.price * get_mult("duration_increase", 3)
	shop_products.duration_increase.name = "Tides duration: " + str(default_duration + increase_value * (get_lvl("duration_increase") + 1))
	
	level.tide_duration += increase_value
	
	if level.tide_duration > 60:
		shop_products.erase("duration_increase")


func get_mult(id, v = 2):
	return pow(v, shop_products[id].level)

func next_lvl(id):
	shop_products[id].level += 1

func get_lvl(id):
	return shop_products[id].level


func radar_callback():
	player.hud.radar_container.show()
	level.end_game_resource.global_position = level.end_game_marker.global_position
	
	shop_products.erase("radar")
