extends Node

# =========================================================================
# ПАНЕЛЬ УПРАВЛЕНИЯ БАЛАНСОМ (Править цены, шаги апгрейдов и лимиты ТУТ)
# =========================================================================
const BALANCE = {
	"second_pickaxe": {
		"price": 100
	},
	"radar": {
		"price": 1
	},
	"stamine_increase": {
		"price": 50,         # Начальная цена
		"multiplier": 2.0,   # Во сколько раз растет цена с каждым уровнем (экспонента)
		"step": 2.0,         # На сколько увеличивается стат за один уровень
		"max_level": 5,      # Максимальный уровень прокачки
		"label": "Stamina: " # Префикс для имени в магазине
	},
	"climbing_speed": {
		"price": 200,
		"multiplier": 3.0,
		"step": 0.5,
		"max_level": 5,
		"label": "Climb Speed: "
	},
	"weight_increase": {
		"price": 50,
		"multiplier": 2.0,
		"step": 2.0,
		"max_level": 5,
		"label": "Max weight: "
	},
	"deep_increase": {
		"price": 1,
		"multiplier": 2.0,
		"step": 50.0,
		"max_y": -260,       # Лимит глубины отлива (условие удаления из магазина)
		"label": "Tides depth: ",
		"suffix": "m"        # Суффикс для красивого отображения метров
	},
	"duration_increase": {
		"price": 1,
		"multiplier": 3.0,
		"step": 15.0,
		"max_duration": 60,  # Лимит длительности отлива
		"label": "Tides duration: ",
		"suffix": "s"
	}
}

# --- ПЕРЕМЕННЫЕ СОСТОЯНИЯ ---
var cash: int = 0:
	set(value):
		cash = value
		cash_changed.emit()

var shop_products: Dictionary = {}
var shop_interface: Control

var player: Player:
	set(value):
		player = value
		default_max_stamina = player.max_stamina
		default_climbing_speed = player.lean_speed 
		if player.backpack_component:
			default_max_weight = player.backpack_component.payload

var level: Level:
	set(value):
		level = value
		default_duration = level.tide_duration
		default_deep = abs(level.low_tide_y)

# Базовые значения (служат неизменяемым фундаментом для расчетов интерфейса)
var default_duration: float
var default_deep: float
var default_max_stamina: float
var default_climbing_speed: float  
var default_max_weight: float      

signal cash_changed
signal endgame_founded
signal comics_readed

# --- СИСТЕМНЫЕ ФУНКЦИИ ---
func _ready() -> void:
	_setup_shop_products() # Динамически собираем магазин из конфига баланса
	endgame_founded.connect(_on_endgame_founded)
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
	
	comics_readed.connect(func():
		AmbientPlayer.play_ambient(preload("uid://cmh88cprg8o0k"))
		AmbientPlayer.play_music("island", preload("uid://t8oqsfwkyu20"), true, false, Vector3(0, 3, 0), 80)
	)

func _setup_shop_products() -> void:
	shop_products = {
		"second_pickaxe": {"name": "Second pickaxe", "price": BALANCE.second_pickaxe.price, "callback": second_pickaxe_callback},
		"stamine_increase": {"name": "Increase Stamina", "price": BALANCE.stamine_increase.price, "callback": increase_stamina_callback, "level": 0},
		"weight_increase": {"name": "Increase max weight", "price": BALANCE.weight_increase.price, "callback": increase_weight_capacity_callback, "level": 0},
		"deep_increase": {"name": "Increase tides depth", "price": BALANCE.deep_increase.price, "callback": increase_tides_deep_callback, "level": 0},
		"duration_increase": {"name": "Increase tides duration", "price": BALANCE.duration_increase.price, "callback": increase_tides_duration_callback, "level": 0},
		"climbing_speed": {"name": "Climbing speed", "price": BALANCE.climbing_speed.price, "callback": increase_climbing_speed_callback, "level": 0},
		"radar": {"name": "Target radar", "price": BALANCE.radar.price, "callback": radar_callback},
	}

# Универсальный обработчик рутины: повышает уровень, считает цену и обновляет имя в UI
func _advance_upgrade_progression(id: String, base_value: float) -> float:
	var cfg = BALANCE[id]
	next_lvl(id)
	
	# Расчет прогрессии цены на основе данных из BALANCE
	shop_products[id].price = cfg.price * pow(cfg.multiplier, get_lvl(id))
	
	# Расчет значения характеристики для отображения СЛЕДУЮЩЕГО уровня в магазине
	var next_ui_value = base_value + cfg.step * (get_lvl(id) + 1)
	var suffix = cfg.get("suffix", "")
	shop_products[id].name = cfg.label + str(next_ui_value) + suffix
	
	return cfg.step

# --- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ УРОВНЕЙ ---
func next_lvl(id: String) -> void:
	shop_products[id].level += 1

func get_lvl(id: String) -> int:
	return shop_products[id].level

func get_mult(id: String) -> float:
	return pow(BALANCE[id].get("multiplier", 2.0), shop_products[id].level)


# --- ОБРАБОТЧИКИ ПОКУПОК (CALLBACKS) ---

func second_pickaxe_callback() -> void:
	player.is_right_side_enabled = true
	shop_products.erase("second_pickaxe")

func radar_callback() -> void:
	player.hud.radar_container.show()
	level.end_game_resource.global_position = level.end_game_marker.global_position
	shop_products.erase("radar")
	
	AmbientPlayer.stop_music("island")
	AmbientPlayer.play_music("key", preload("uid://t8oqsfwkyu20"), false, false)
	AmbientPlayer.play_music("key_hidden", preload("uid://t8oqsfwkyu20"), false, true)


func increase_stamina_callback() -> void:
	var step = _advance_upgrade_progression("stamine_increase", default_max_stamina)
	
	player.max_stamina += step
	player.default_max_stamina += step 
	player.restore_stamina(step)
	
	if get_lvl("stamine_increase") >= BALANCE.stamine_increase.max_level:
		shop_products.erase("stamine_increase")

func increase_climbing_speed_callback() -> void:
	var step = _advance_upgrade_progression("climbing_speed", default_climbing_speed)
	
	player.lean_speed += step
	
	if get_lvl("climbing_speed") >= BALANCE.climbing_speed.max_level:
		shop_products.erase("climbing_speed")

func increase_weight_capacity_callback() -> void:
	var step = _advance_upgrade_progression("weight_increase", default_max_weight)
	
	if player.backpack_component:
		player.backpack_component.payload += step
		player.on_overweight_changed()
	
	if get_lvl("weight_increase") >= BALANCE.weight_increase.max_level:
		shop_products.erase("weight_increase")

func increase_tides_deep_callback() -> void:
	var step = _advance_upgrade_progression("deep_increase", default_deep)
	
	level.low_tide_y -= step
	
	if not level._is_high_tide and not level.is_transitioning():
		level._timer += 9999
	
	if level.low_tide_y <= BALANCE.deep_increase.max_y:
		shop_products.erase("deep_increase")

func increase_tides_duration_callback() -> void:
	var step = _advance_upgrade_progression("duration_increase", default_duration)
	
	level.tide_duration += step
	
	if level.tide_duration > BALANCE.duration_increase.max_duration:
		shop_products.erase("duration_increase")


# --- ОСТАЛЬНАЯ ЛОГИКА ---
func _on_endgame_founded() -> void:
	player.hud.radar_container.hide()
	level.low_tide_y -= 500
	level.transition_duration = 5
	level._is_high_tide = false
	level._target_y = level.low_tide_y
	level._transitioning = true
	level._transition_timer = 0.0
	level._start_y = level.water_node.position.y
	level._timer = 0.0
	
	
	await get_tree().create_timer(level.transition_duration).timeout
	level.timer_multiplier = 0.0
	
	await get_tree().create_timer(3).timeout
	AmbientPlayer.fade_music("key_hidden", 0)
	
