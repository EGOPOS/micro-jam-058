extends Node

var cash: int = 400:
	set(value):
		cash = value
		cash_changed.emit()

var shop_products: Dictionary = {
	"second_pickaxe": {"name": "Second pickaxe", "price": 100, "callback": second_pickaxe_callback},
	"deep_increase": {"name": "Increase tides deep", "price": 1000, "callback": increase_tides_deep_callback, "level": 0},
	"climbing_speed": {"name": "Climbing speed", "price": 2000, "callback": second_pickaxe_callback},
	"radar": {"name": "Target radar", "price": 1, "callback": radar_callback},
}
var default_shop_products = shop_products.duplicate(true)
var shop_interface: Control
var player: Player
var level: Level

signal cash_changed
signal endgame_founded

func _ready() -> void:
	endgame_founded.connect(_on_endgame_founded)


func _on_endgame_founded():
	Fade.fade_out(1.0)
	player.is_blocked = true
	await get_tree().create_timer(1.0).timeout
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
	#get_tree().change_scene_to_file()


func second_pickaxe_callback():
	player.is_right_side_enabled = true
	shop_products.erase("second_pickaxe")


func increase_tides_deep_callback():
	player.is_right_side_enabled = true
	shop_products.deep_increase.price = default_shop_products.deep_increase.price * pow(2, shop_products.deep_increase.level)
	shop_products.deep_increase.level += 1
	level.low_tide_y -= 50
	
	if not level._is_high_tide and not level.is_transitioning():
		level._timer += 9999
	#level._is_high_tide = true
	
	if level.low_tide_y <= -320:
		shop_products.erase("deep_increase")


func radar_callback():
	player.hud.radar_container.show()
	level.end_game_resource.global_position = level.end_game_marker.global_position
	
	shop_products.erase("radar")
	
