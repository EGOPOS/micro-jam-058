extends PlayerAttachableState

func enter(data):
	super(data)
	player.camera_animation_strength = player.camera_animation_floor_strength
	player.reset_jump_buffer()

func update(delta):
	super(delta)
	var direction = player.get_direction()
	
	if direction == Vector3():
		change_state(states.Idle)
	
	if player.is_can_jump() and InputBuffer.is_action_in_buffer("movement_jump"):
		change_state(states.Jump)
	
	if not player.is_on_floor():
		change_state(states.Fall)
	
	player.apply_acceleration(delta, direction)
	player.move_and_slide()
