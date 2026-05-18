extends Control

@onready var texture_rect: TextureRect = $TextureRect
@onready var sfx_handler: SfxHandler = %SfxHandler

@export var frames: Array[Texture]
var step: int = 0


func _ready() -> void:
	Player.is_blocked = true
	
	if frames.is_empty():
		advance()
		return
	
	texture_rect.texture = frames.front()
	get_tree().paused = true
	
	Global.player.hud.hide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interaction"):
		advance()

func advance() -> void:
	if step < frames.size()-1 and not frames.is_empty():
		step += 1
		var trans = .2
		Fade.fade_out(trans)
		await get_tree().create_timer(trans).timeout
		Fade.fade_in(trans)
		texture_rect.texture = frames[step]
		sfx_handler.play("Flip")
		
	else:
		set_process_input(false)
		
		var trans = .1
		Fade.fade_out(trans)
		await get_tree().create_timer(trans).timeout
		Fade.fade_in(trans)
		get_tree().paused = false
		hide()
		
		Global.player.hud.show()
		Global.comics_readed.emit()
		
		Player.is_blocked = false
