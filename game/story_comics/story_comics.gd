extends Control

@onready var texture_rect: TextureRect = $TextureRect

@export var frames: Array[Texture]
var step: int = 0


func _ready() -> void:
	Player.is_blocked = true
	
	if frames.is_empty():
		advance()
		return
	
	texture_rect.texture = frames.front()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interaction"):
		advance()

func advance() -> void:
	if step == 0 and not frames.is_empty():
		step = 1
		var trans = .2
		Fade.fade_out(trans)
		await get_tree().create_timer(trans).timeout
		Fade.fade_in(trans)
		texture_rect.texture = frames[step]
	else:
		set_process_input(false)
		create_tween().tween_property(self, "scale", Vector2(), 0.15)
		
		Player.is_blocked = false
