class_name PlayerAttachableState extends State

var player: Player

func enter(props: Dictionary):
	super(props)
	player = props.player

func physics_update(delta):
	print(player.stamina)
	
	if player.is_can_climb():
		var side = player.get_attaching_side()
		if player.is_attaching():
			var attach_hit = Help.get_camera_center_hit(player.max_attach_distance)
			if not attach_hit.is_empty():
				player.attached_points[side] = attach_hit
				if self != states.Climb:
					change_state(states.Climb)
	
	if self != states.Climb and get_left_time(player.time_not_climbing) > player.recover_stamina_delay and player.is_on_floor():
		player.restore_stamina(delta)
