class_name PlayerAttachableState extends State

var player: Player

func enter(props: Dictionary):
	super(props)
	player = props.player

func physics_update(delta):
	if player.is_blocked:
		return
	#print(player.stamina)
	
	if player.is_can_climb():
		var side = player.get_attaching_side()
		if player.is_attaching():
			
			# Resource Grabbing
			var resource_hit = Help.get_camera_center_hit(player.max_grab_distance, Help.get_collision_mask([3]))
			
			if not resource_hit.is_empty() and is_can_interact() and player.backpack_component.is_can_put():
				player.backpack_component.put_to_storage(resource_hit.collider)
				player.last_interaction_time = get_time()
				
				# SOUND
				player.sfx_handler.play("Pickup")
			
			if resource_hit.is_empty():
				# Climbing
				var attach_hit = Help.get_camera_center_hit(player.max_attach_distance)
				if not attach_hit.is_empty():
					player.attached_points[side] = attach_hit
					if side == "left":
						player.left_attach_toggled.emit(attach_hit)
					else:
						player.right_attach_toggled.emit(attach_hit)
					
					if self != states.Climb:
						change_state(states.Climb)
	
	if self != states.Climb and get_left_time(player.time_not_climbing) > player.recover_stamina_delay and player.is_on_floor():
		player.restore_stamina(delta * player.recover_stamina_muliplier)


func input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("throw") and is_can_interact():
		var r = player.backpack_component.put_on_floor_from_storage()
		player.last_interaction_time = get_time()
		# SOUND
		if r != null:
			player.sfx_handler.play("Drop")


func is_can_interact():
	return get_left_time(player.last_interaction_time) > player.interaction_delay
