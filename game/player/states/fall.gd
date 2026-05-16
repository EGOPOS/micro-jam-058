extends PlayerAttachableState

func enter(data):
	super(data)
	player.camera_animation_strength = player.camera_animation_air_strength

func update(delta):
	super(delta)
	var direction = player.get_direction()
	
	if player.is_on_floor():
		if direction == Vector3():
			change_state(states.Idle)
		else:
			change_state(states.Move)
	
	if get_left_time() < player.coyote_time and player.is_can_jump() and Input.is_action_pressed("movement_jump"):
		change_state(states.Jump)
	
	player.apply_air_acceleration(delta, direction)
	player.apply_fall_gravity(delta)
	player.move_and_slide()
