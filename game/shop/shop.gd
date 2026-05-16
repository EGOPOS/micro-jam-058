extends Node3D

@onready var static_body: StaticBody3D = %StaticBody3D
@onready var interface_container: PanelContainer = %InterfaceContainer
@onready var sub_viewport: SubViewport = %SubViewport

func _ready() -> void:
	interface_container.hide()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("interaction"):
		if not interface_container.visible:
			var hit = Help.get_camera_center_hit(5, Help.get_collision_mask([4]))
			if not hit.is_empty():
				if hit.collider == static_body:
					interface_container.show()
					#Player.is_blocked = true
					get_tree().paused = true
					DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
		
		else:
			#Player.is_blocked = false
			get_tree().paused = false
			interface_container.hide()
			sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
