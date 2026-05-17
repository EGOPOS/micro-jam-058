extends Node

var cash: int = 400:
	set(value):
		cash = value
		cash_changed.emit()

var shop_products: Dictionary = {
	"second_pickaxe": {"name": "Second pickaxe", "price": 100, "callback": second_pickaxe_callback},
	"deep_increase": {"name": "Increase tides deep", "price": 1000, "callback": increase_tides_deep_callback, "level": 0},
	"duration_increase": {"name": "Increase tides duration", "price": 50, "callback": increase_tides_duration_callback, "level": 0},
	"climbing_speed": {"name": "Climbing speed", "price": 2000, "callback": second_pickaxe_callback},
	"radar": {"name": "Target radar", "price": 1, "callback": radar_callback},
}
var default_shop_products = shop_products.duplicate(true)
var shop_interface: Control
var player: Player
var level: Level:
	set(value):
		level = value
		default_duration = level.low_tide_duration
		default_deep = abs(level.low_tide_y)

var default_duration: float
var default_deep: float

signal cash_changed
signal endgame_founded

func _ready() -> void:
	endgame_founded.connect(_on_endgame_founded)


func _on_endgame_founded():
	player.is_blocked = true
	
	Fade.fade_out(1.0)
	await get_tree().create_timer(1.0).timeout
	Fade.fade_in(1.0)
	
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://game/credits/credits.tscn")


func second_pickaxe_callback():
	player.is_right_side_enabled = true
	shop_products.erase("second_pickaxe")


func increase_tides_deep_callback():
	const increase_value = 50
	next_lvl("deep_increase")
	shop_products.deep_increase.price = default_shop_products.deep_increase.price * pow(2, shop_products.deep_increase.level)
	shop_products.deep_increase.name = str(default_deep + increase_value * (get_lvl("deep_increase") + 1))
	
	level.low_tide_y -= increase_value
	
	if not level._is_high_tide and not level.is_transitioning():
		level._timer += 9999
	
	if level.low_tide_y <= -320:
		shop_products.erase("deep_increase")


func increase_tides_duration_callback():
	const increase_value = 10
	next_lvl("duration_increase")
	
	shop_products.duration_increase.price = default_shop_products.duration_increase.price * get_mult("duration_increase", 3)
	shop_products.duration_increase.name = str(default_duration + increase_value * (get_lvl("duration_increase") + 1))
	
	level.low_tide_duration += increase_value
	
	if level.low_tide_duration > 60:
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
