extends Node3D

@onready var static_body: StaticBody3D = %StaticBody3D
@onready var interface_container: PanelContainer = %InterfaceContainer
@onready var sub_viewport: SubViewport = %SubViewport

@onready var display_interaction_area: InteractionArea = %InteractionArea
@onready var sell_interaction_area: InteractionArea = %SellInteractionArea
@onready var sell_marker: Marker3D = %SellMarker3D

@export var shredder_animation_player: AnimationPlayer
@onready var sfx_handler: SfxHandler = %SfxHandler

func _ready() -> void:
	interface_container.hide()
	display_interaction_area.interacted.connect(on_display_interacted)
	sell_interaction_area.interacted.connect(on_sell_interacted)
	display_interaction_area.body_exited.connect(func(b):
		if b is Player and interface_container.visible:
			display_interaction_area.interacted.emit(b)
	)
	Global.cash_changed.connect(update_screen)
	update_screen()


func update_screen():
	if interface_container.visible:
		return
	
	interface_container.show()
	interface_container.modulate.a = 0
	await get_tree().create_timer(.1).timeout
	interface_container.modulate.a = 1
	interface_container.hide()


func on_display_interacted(player: Player):
	if not interface_container.visible:
		#get_tree().paused = true
		Player.is_blocked = true
		interface_container.show()
		player.hud.hide()
		DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
		#var hit = Help.get_camera_center_hit(5, Help.get_collision_mask([4]))
		#if not hit.is_empty():
			#if hit.collider == static_body:
				#interface_container.show()
				##Player.is_blocked = true
	
	else:
		#get_tree().paused = false
		Player.is_blocked = false
		interface_container.hide()
		player.hud.show()
		DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
		#sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS


func on_sell_interacted(player: Player):
	var resource = player.backpack_component.take_from_storage()
	if resource == null:
		return
	
	Global.cash += resource.price
	if shredder_animation_player.is_playing():
		shredder_animation_player.stop()
	shredder_animation_player.play("shredder")
	sfx_handler.play("Eat")
	
	resource.show()
	resource.global_position = sell_marker.global_position
	
	var tween_time = 0.5
	var tween = create_tween().set_parallel(true)
	tween.tween_property(resource, "global_position:y", sell_marker.global_position.y - 1.5, tween_time)
	tween.tween_property(resource, "scale", Vector3(), tween_time)
	
	await get_tree().create_timer(tween_time).timeout
	
	resource.queue_free()
