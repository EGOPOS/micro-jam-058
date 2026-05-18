extends Control

@onready var authors_mesh: Node3D = %Title
@onready var sub_viewport: SubViewport = %SubViewport
@onready var thx_for_playing: Node3D = %"ThxForP;aying"

func _ready() -> void:
	thx_for_playing.position = Vector3(0, -60, -40)
	sub_viewport.size = get_viewport().get_visible_rect().size
	authors_mesh.get_child(0).material_override.albedo_color = Color.BLACK
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(authors_mesh, "global_position:z", -40, 2.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(authors_mesh.get_child(0), "material_override:albedo_color", Color.WHITE, 2.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	await get_tree().create_timer(3).timeout
	
	tween = create_tween()
	tween.tween_property(authors_mesh, "global_position:x", -120, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(thx_for_playing, "global_position:y", -16, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().quit()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_tree().quit()
