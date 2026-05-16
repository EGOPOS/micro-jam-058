extends PlayerState

func enter(data):
	super(data)
	player.camera_animation_strength = player.camera_animation_air_strength
	player.jump()


func physics_update(delta):
	var direction = player.get_direction()
	
	if not Input.is_action_pressed("movement_jump"):
		player.velocity *= player.jump_release_multiplier
		change_state(states.Fall)
	
	if player.velocity.y < 0:
		change_state(states.Fall)
	
	if player.is_on_floor():
		if direction == Vector3():
			change_state(states.Idle)
		else:
			change_state(states.Move)
	
	player.apply_air_acceleration(delta, direction)
	
	if abs(player.velocity.y) < player.jump_air_bonus * abs(player.jump_velocity):
		player.apply_jump_gravity(delta * player.jump_air_bonus_multiplier)
	else:
		player.apply_jump_gravity(delta)
	player.move_and_slide()
