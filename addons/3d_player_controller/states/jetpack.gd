extends PlayerState

func enter(data):
	super(data)
	player.camera_animation_strength = player.camera_animation_jetpack_strength

func physics_update(delta):
	var direction = player.get_direction()
	
	var jetpack_direction = (direction * player.direction_jetpack_multiplier + Vector3.UP) 
	player.velocity += jetpack_direction * player.jetpack_power * delta# * (player.max_jetpack_time/player.jetpack_time)
	player.jetpack_time -= delta
	player.jetpack_time = max(0, player.jetpack_time)
	
	if not Input.is_action_pressed("movement_jump"):
		change_state("Fall")
	
	if player.jetpack_time == 0:
		change_state("Fall")
	
	if player.is_on_floor():
		if direction == Vector3():
			change_state("Idle")
		else:
			change_state("Move")
	
	player.apply_acceleration(delta, direction)
	player.apply_fall_gravity(delta)
	player.move_and_slide()
